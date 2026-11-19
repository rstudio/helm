# Shared gateway with KGateway (Gateway API only)

This track is **not** tied to AWS. It assumes you run [KGateway](https://kgateway.dev/) (Envoy-based Kubernetes Gateway API) in your cluster. Install KGateway and the Gateway API CRDs using the [project documentation](https://kgateway.dev/docs/envoy/latest/) for your release.

When you install KGateway, a `GatewayClass` named **`kgateway`** with `controllerName: kgateway.dev/kgateway` is typically created for you. This example adds a **single shared `Gateway`** that multiple Posit Helm releases attach to via `gatewayApi.parentRefs`.

## TLS

The example [`gateway.yaml`](./gateway.yaml) terminates HTTPS using a Kubernetes `tls` **Secret** referenced from the listener (`certificateRefs`), which is portable across clouds. Create the secret in the same namespace as the `Gateway` (for example with `kubectl create secret tls posit-gateway-tls --cert=... --key=...`).

If you use HTTP only in a lab environment, you can remove the `https` listener and keep a single `http` listener; adjust `gatewayApi.parentRefs` in [`values-gateway-api.yaml`](./values-gateway-api.yaml) to reference only that listener’s `sectionName`.

## Cross-namespace routes

If product releases run in namespaces other than the `Gateway` namespace, keep `listeners[].allowedRoutes.namespaces.from: All` (or a selector that includes them) and apply [`referencegrant.yaml`](./referencegrant.yaml) in the **Gateway** namespace. For a single shared namespace, you can use `from: Same` on listeners and omit the `ReferenceGrant`.

## Tuning for Posit products

A bare `HTTPRoute` does not cover four Envoy behaviors that Posit products need. Each one is a kgateway policy resource that targets the `Gateway`, the `HTTPRoute`, or the `Service`. None of them needs a change to the route that the chart renders.

| Setting | Policy resource and target | Workbench | Connect | Package Manager | Example |
|---------|----------------------------|:---------:|:-------:|:---------------:|---------|
| WebSocket upgrades | `HTTPListenerPolicy` on the `Gateway` | Required | Required | Not needed | [`httplistenerpolicy.yaml`](./httplistenerpolicy.yaml) |
| Request and stream-idle timeouts | `TrafficPolicy` on the `HTTPRoute` | Required | Required | Recommended | [`trafficpolicy.yaml`](./trafficpolicy.yaml) |
| Disable request buffering (large uploads) | `TrafficPolicy` on the `HTTPRoute` | Recommended | Required | Required | [`trafficpolicy.yaml`](./trafficpolicy.yaml) |
| Session-affinity cookie | `BackendConfigPolicy` on the `Service` | When `replicas > 1` | When `replicas > 1` | Not needed | [`backendconfigpolicy.yaml`](./backendconfigpolicy.yaml) |

- **WebSockets.** kgateway rejects WebSocket upgrades with `403 Forbidden` by default. RStudio, Jupyter, VS Code, Shiny, Dash, and Streamlit sessions use WebSockets, so the UI loads but sessions fail without this policy. The policy targets the `Gateway`, so one policy covers every product on the shared gateway.
- **Timeouts and uploads.** Envoy defaults (15 s request timeout, 5 min stream-idle timeout, and a request-body buffer cap) cut off long sessions and return `413` on large Connect bundles or Package Manager packages. The `TrafficPolicy` targets the route by its generated name, `<release fullname>-gw-<host index>`. Run `kubectl get httproute -n <namespace>` to find it.
- **Session affinity.** With more than one replica, users must stay on the pod that serves their session. The `BackendConfigPolicy` uses consistent-hash load balancing on a cookie that kgateway sets.

Verification status (kgateway v2.2.4, AWS Load Balancer Controller v2.11, EKS, Kubernetes 1.35):

- WebSocket upgrade: a bare `HTTPRoute` returned `403`. With the `HTTPListenerPolicy`, the same route returned `101 Switching Protocols`.
- Request timeout: `request: "3s"` returned `504` at 3.01 s, and `request: "0s"` let an 8 s request finish.
- Session affinity: the response carried a `Set-Cookie` header with `HttpOnly`.
- `TrafficPolicy` (timeouts and buffer in one resource) and `BackendConfigPolicy` both reported `Accepted` and `Attached`. The `streamIdle` and `buffer` settings were not exercised under load.

Policy field names can change between kgateway releases. Check the [kgateway documentation](https://kgateway.dev/docs/envoy/latest/) for your release.

## Apply

1. Install KGateway per upstream docs.
2. Create TLS secret if using HTTPS (see above).
3. Apply [`gateway.yaml`](./gateway.yaml) (edit namespace / names as needed).
4. Optionally apply [`referencegrant.yaml`](./referencegrant.yaml).
5. Apply [`httplistenerpolicy.yaml`](./httplistenerpolicy.yaml) so that WebSocket upgrades work.
6. Enable `gatewayApi` on each chart using [`values-gateway-api.yaml`](./values-gateway-api.yaml).
7. After the releases create their `HTTPRoute` resources, apply [`trafficpolicy.yaml`](./trafficpolicy.yaml) and, for multi-replica releases, [`backendconfigpolicy.yaml`](./backendconfigpolicy.yaml). Edit the route and service names first.

## Files

| File | Purpose |
|------|---------|
| `gateway.yaml` | Shared `Gateway` using `gatewayClassName: kgateway` |
| `referencegrant.yaml` | Optional cross-namespace `HTTPRoute` → `Gateway` |
| `httplistenerpolicy.yaml` | Enable WebSocket upgrades on the shared `Gateway` |
| `trafficpolicy.yaml` | Timeouts and request buffering per product `HTTPRoute` |
| `backendconfigpolicy.yaml` | Session-affinity cookie for multi-replica Workbench and Connect |
| `values-gateway-api.yaml` | `gatewayApi` fragments for Connect, PM, Workbench |
