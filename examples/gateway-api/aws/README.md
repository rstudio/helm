# Shared AWS ALB via Gateway API

This walkthrough provisions **one** Application Load Balancer for **Connect**, **Package Manager**, and **Workbench** using the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) (LBC) **Layer 7 Gateway API** support. Each product Helm release attaches `HTTPRoute` objects to the same `Gateway` via `gatewayApi.parentRefs`.

## Validation matrix (verify-aws-lbc)

Confirm versions against [LBC Gateway API documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/gateway/gateway/) (upstream moves with releases):

| Requirement | Typical minimum / note |
|---------------|-------------------------|
| AWS Load Balancer Controller | **≥ v2.14.0** for ALB + `HTTPRoute` |
| Gateway API CRDs | **v1.5.0** standard install (per LBC docs) |
| LBC Gateway CRDs | `gateway-crds.yaml` from the [LBC repo](https://github.com/kubernetes-sigs/aws-load-balancer-controller) (includes `LoadBalancerConfiguration`, etc.) |
| `GatewayClass.spec.controllerName` | `gateway.k8s.aws/alb` |

**AWS-specific behavior:** ALB Gateway does **not** use `ListenerTLSConfig.certificateRefs` on the `Gateway`; TLS uses **`LoadBalancerConfiguration`** (`defaultCertificate` ACM ARN). See [L7 gateway guide](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/gateway/l7gateway/).

**Cross-namespace routes:** If each product runs in a different namespace than the `Gateway`, set `listeners[].allowedRoutes.namespaces.from: All` (or a `Selector` that includes those namespaces) **and** create a [`ReferenceGrant`](https://gateway-api.sigs.k8s.io/api-types/referencegrant/) in the **Gateway’s namespace** so `HTTPRoute`s in product namespaces may attach to the `Gateway`. Example: [`referencegrant.yaml`](./referencegrant.yaml).

**Same namespace:** If the `Gateway` and all products share one namespace, you can use `allowedRoutes.namespaces.from: Same` and omit `ReferenceGrant`.

**Subnet tags, security groups, target type:** Follow LBC [subnet discovery](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/subnet_discovery/) and [Gateway API](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/gateway/gateway/) notes. For pod IP targeting and stickiness similar to the Ingress ALB examples, use [`TargetGroupConfiguration`](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/gateway/customization/) (`targetType: ip`) per Service as needed.

## Apply order

1. Install Gateway API CRDs and LBC Gateway CRDs (see LBC prerequisites).
2. Edit and apply [`gatewayclass.yaml`](./gatewayclass.yaml).
3. Edit **ACM ARN** (and namespace) in [`loadbalancerconfiguration.yaml`](./loadbalancerconfiguration.yaml).
4. Edit namespace/name consistency and apply [`gateway.yaml`](./gateway.yaml).
5. If routes are cross-namespace, edit namespaces in [`referencegrant.yaml`](./referencegrant.yaml) and apply it in the **Gateway** namespace.
6. Install or upgrade each product chart with the matching fragment from [`values-gateway-api.yaml`](./values-gateway-api.yaml).

## `parentRefs` and HTTP + HTTPS

The AWS LBC example attaches an `HTTPRoute` to **both** `http` and `https` listeners via `sectionName`. The charts pass `parentRefs` through verbatim, so list **two** parent refs (same `name` / `namespace`, different `sectionName`) as in `values-gateway-api.yaml`.

## Files

| File | Purpose |
|------|---------|
| `gatewayclass.yaml` | `GatewayClass` with `controllerName: gateway.k8s.aws/alb` |
| `loadbalancerconfiguration.yaml` | ACM certificate on HTTPS listener |
| `gateway.yaml` | Shared `Gateway` with HTTP/HTTPS listeners and `allowedRoutes` |
| `referencegrant.yaml` | Optional cross-namespace attachment for `HTTPRoute` → `Gateway` |
| `values-gateway-api.yaml` | `gatewayApi` Helm values for Connect, PM, and Workbench |
