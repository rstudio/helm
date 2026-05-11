# Gateway API examples (shared gateway)

These examples show how to front **Posit Connect**, **Package Manager**, and **Workbench** with a **single** Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/) `Gateway` and one external load balancer / proxy, while the Helm charts create only `HTTPRoute` resources (`gatewayApi` values).

Pick the track that matches your ingress implementation:

| Directory | Controller / dataplane | Notes |
|-----------|------------------------|--------|
| [aws](./aws/) | [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) (ALB) | AWS-specific `LoadBalancerConfiguration`, ACM certificate ARNs, subnet tagging |
| [kgateway](./kgateway/) | [KGateway](https://kgateway.dev/) (Envoy) | Cloud-agnostic Gateway API; install KGateway first, then apply the example `Gateway` |

For classic **Ingress** on AWS (multiple `Ingress` objects, one ALB), see the [IngressGroup / `group.name`](../connect/ingress/aws-alb.qmd) notes in the per-product ALB examples.

The product charts do not render `Gateway` or `GatewayClass`; apply the manifests in these directories (or your own equivalents), then set `gatewayApi.parentRefs` on each Helm release as shown in each track’s `values-gateway-api.yaml`.
