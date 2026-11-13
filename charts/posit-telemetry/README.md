# Posit Telemetry

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

#### _Official Helm chart for the Posit telemetry server and the Clickhouse database it writes to_

## For production

To ensure a stable production deployment:

* "Pin" the version of the Helm chart that you are using. You can do this using the:
  * `helm dependency` command *and* the associated "Chart.lock" files *or*
  * the `--version` flag.

    ::: {.callout-important}
    This protects you from breaking changes.
    :::

* Before upgrading check for breaking changes using `helm-diff` plugin and `helm diff upgrade`.
* Read [`NEWS.md`](./NEWS.md) for updates on breaking changes and the documentation below on how to use the chart.

## Installing the chart

To install the chart with the release name `my-release` at version 0.1.0:

```{.bash}
helm repo add rstudio https://helm.rstudio.com
helm upgrade --install my-release rstudio/posit-telemetry --version=0.1.0
```

To explore other chart versions, look at:

```{.bash}
helm search repo rstudio/posit-telemetry -l
```

## Usage

This chart deploys the telemetry server, which receives Opentelemetry data from the agents that run in Posit product
pods and stores it in Clickhouse. Clickhouse runs beside it as a StatefulSet, from Clickhouse's own image.

Agents send OTLP gRPC to the server's Service, `<release>-posit-telemetry.<namespace>.svc:4317`.

The server creates its Clickhouse database and runs the schema migrations each time it starts, before it accepts
data, so the chart runs exactly one server and replaces it rather than rolling it on upgrade. The agents retry while
it restarts.

## Clickhouse

The chart pins `clickhouse.image.tag` to the Clickhouse LTS release the server is tested with.

Clickhouse keeps its data on a PersistentVolumeClaim, `data-<release>-posit-telemetry-clickhouse-0`, which Kubernetes
keeps when the release is uninstalled. Delete it to remove the data. Use block storage (for example `gp3` on EKS) rather
than a network filesystem such as NFS or EFS:

```yaml
clickhouse:
  persistence:
    storageClass: gp3
    size: 100Gi
```

Clickhouse limits its own memory use to 90% of `clickhouse.resources.limits.memory`.

### Password

The chart generates a password for the server's Clickhouse user on install and reuses it on upgrade. Tools that render
the chart without a cluster, such as `helm template` or Argo CD, generate a new one each time, so with them create a
Secret yourself and set `clickhouse.auth.existingSecret`:

```yaml
clickhouse:
  auth:
    existingSecret: telemetry-clickhouse
    existingSecretKey: password
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for the telemetry server pod |
| clickhouse.affinity | object | `{}` | Affinity for the Clickhouse pod |
| clickhouse.auth.existingSecret | string | `""` | An existing Secret with the telemetry server's Clickhouse password. The chart generates one if empty. |
| clickhouse.auth.existingSecretKey | string | `"password"` | The key in `existingSecret` that holds the password |
| clickhouse.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| clickhouse.image.repository | string | `"clickhouse/clickhouse-server"` | The Clickhouse image repository |
| clickhouse.image.tag | string | `"26.8.34.13"` | The Clickhouse image tag, the LTS release the telemetry server is tested with |
| clickhouse.nodeSelector | object | `{}` | Node selector for the Clickhouse pod |
| clickhouse.persistence.size | string | `"20Gi"` | The size of Clickhouse's data volume |
| clickhouse.persistence.storageClass | string | `""` | The storage class for Clickhouse's data, defaults to the cluster's default. Use block storage, not a network    filesystem such as NFS or EFS. |
| clickhouse.podSecurityContext | object | `{"fsGroup":101,"runAsGroup":101,"runAsNonRoot":true,"runAsUser":101,"seccompProfile":{"type":"RuntimeDefault"}}` | Clickhouse's pod-level security context. The image runs Clickhouse as uid 101. |
| clickhouse.resources | object | `{"limits":{"memory":"4Gi"},"requests":{"cpu":"500m","memory":"1Gi"}}` | Resources for the Clickhouse container. Clickhouse limits its own memory use to 90% of the memory limit. |
| clickhouse.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}` | Clickhouse's container-level security context |
| clickhouse.service.port | int | `9000` | The port for Clickhouse's native protocol, which the telemetry server uses |
| clickhouse.tolerations | list | `[]` | Tolerations for the Clickhouse pod |
| env | list | `[]` | Additional environment variables for the telemetry server, such as `TELEMETRY_SERVER_LOGGING_LEVEL` |
| fullnameOverride | string | `""` | Override for the full name of the release |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `"ghcr.io/posit-dev/telemetry-server"` | The telemetry server image repository |
| image.tag | string | `""` | The telemetry server image tag, defaults to the chart's appVersion |
| imagePullSecrets | list | `[]` | Secrets for pulling the telemetry server and Clickhouse images |
| nameOverride | string | `""` | Override for the name of the chart |
| nodeSelector | object | `{}` | Node selector for the telemetry server pod |
| podSecurityContext | object | `{"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | The telemetry server's pod-level security context |
| resources | object | `{}` | Resources for the telemetry server container |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | The telemetry server's container-level security context |
| service.annotations | object | `{}` | Annotations for the Service |
| service.port | int | `4317` | The port agents send Opentelemetry (OTLP gRPC) data to |
| service.type | string | `"ClusterIP"` | The Service type for the telemetry server |
| tolerations | list | `[]` | Tolerations for the telemetry server pod |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)

