# Shared gateway with KGateway (Gateway API only)

This track is **not** tied to AWS. It assumes you run [KGateway](https://kgateway.dev/) (Envoy-based Kubernetes Gateway API) in your cluster. Install KGateway and the Gateway API CRDs using the [project documentation](https://kgateway.dev/docs/envoy/latest/) for your release.

When you install KGateway, a `GatewayClass` named **`kgateway`** with `controllerName: kgateway.dev/kgateway` is typically created for you. This example adds a **single shared `Gateway`** that multiple Posit Helm releases attach to via `gatewayApi.parentRefs`.

## TLS

The example [`gateway.yaml`](./gateway.yaml) terminates HTTPS using a Kubernetes `tls` **Secret** referenced from the listener (`certificateRefs`), which is portable across clouds. Create the secret in the same namespace as the `Gateway` (for example with `kubectl create secret tls posit-gateway-tls --cert=... --key=...`).

If you use HTTP only in a lab environment, you can remove the `https` listener and keep a single `http` listener; adjust `gatewayApi.parentRefs` in [`values-gateway-api.yaml`](./values-gateway-api.yaml) to reference only that listener’s `sectionName`.

## Cross-namespace routes

If product releases run in namespaces other than the `Gateway` namespace, keep `listeners[].allowedRoutes.namespaces.from: All` (or a selector that includes them) and apply [`referencegrant.yaml`](./referencegrant.yaml) in the **Gateway** namespace. For a single shared namespace, you can use `from: Same` on listeners and omit the `ReferenceGrant`.

## Apply

1. Install KGateway per upstream docs.
2. Create TLS secret if using HTTPS (see above).
3. Apply [`gateway.yaml`](./gateway.yaml) (edit namespace / names as needed).
4. Optionally apply [`referencegrant.yaml`](./referencegrant.yaml).
5. Enable `gatewayApi` on each chart using [`values-gateway-api.yaml`](./values-gateway-api.yaml).

## Files

| File | Purpose |
|------|---------|
| `gateway.yaml` | Shared `Gateway` using `gatewayClassName: kgateway` |
| `referencegrant.yaml` | Optional cross-namespace `HTTPRoute` → `Gateway` |
| `values-gateway-api.yaml` | `gatewayApi` fragments for Connect, PM, Workbench |
