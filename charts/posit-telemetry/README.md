# Posit Telemetry

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

#### _Official Helm chart for Posit Telemetry, which receives Opentelemetry data from the Chronicle agents in Posit products and stores it in Clickhouse_

## Chart versioning

Chart versions use [SemVer](https://semver.org/) and follow [Helm's chart
versioning guidance](https://helm.sh/docs/topics/charts/#charts-and-versioning). They describe the chart.

Product versions belong in `appVersion`.

While a chart is below `1.0.0`:

- Minor: breaking changes or changes that require user action
- Patch: product releases, enhancements, bug fixes, and other compatible changes
- Major: not used

After `1.0.0`, standard SemVer applies.

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

This chart deploys the Posit Telemetry server, which receives Opentelemetry data from the Chronicle agents in Posit
products and stores it in Clickhouse. Clickhouse runs from its own image as a sidecar container in the server's pod,
so the two talk over the pod's loopback and nothing they exchange crosses the cluster network. Clickhouse listens only
there: nothing outside the pod can reach it. Kubernetes starts Clickhouse before the server and stops it after, so the
server can write what it still holds as it shuts down. Sidecar containers need Kubernetes 1.29 or later.

The server creates its Clickhouse database and runs the schema migrations each time it starts, before it accepts
data, so the chart runs exactly one pod, as a StatefulSet, which stops it before starting its replacement. An upgrade
of either image restarts both. Agents don't queue or retry, so they drop what they send while the pod restarts.

## Sending data from Posit products

Agents send their data to the server's Service, `http://<release>-posit-telemetry.<namespace>.svc:4318`, or
`http://<release>.<namespace>.svc:4318` if the release name already contains `posit-telemetry`; `helm install` prints
it. Connect, Workbench, and Package Manager each run a Chronicle agent. Point it at the server, and turn off the
Chronicle server that otherwise runs beside it, with `chronicle.localConfig` in the product's chart:

```yaml
# values for the rstudio-connect, rstudio-workbench, or rstudio-pm chart
chronicle:
  localConfig:
    Server:
      Enabled: false
      Address: http://my-release-posit-telemetry.my-namespace.svc:4318
```

In Chronicle's own configuration this is `[Server] Enabled = false` with `[Server] Address` set to the server's
address. Chronicle's `[Agent] RemoteServerAddress` setting is an alternative to those two.

## TLS

The server speaks plain HTTP. Inside one cluster, agents reach it through its `ClusterIP` Service. For agents outside
the cluster, enable the Ingress, which is where TLS is terminated, and use its `https://` address as the address
the agents send to:

```yaml
ingress:
  enabled: true
  ingressClassName: nginx
  hosts:
    - telemetry.example.com
  tls:
    - secretName: telemetry-example-tls
      hosts:
        - telemetry.example.com
```

The server doesn't authenticate agents, so restrict who can reach the Ingress.

## Clickhouse

The chart pins `clickhouse.image.tag` to the Clickhouse LTS release the server is tested with.

Clickhouse keeps its data on a PersistentVolumeClaim, `data-<release>-posit-telemetry-0` (or `data-<release>-0` if the
release name contains `posit-telemetry`), which Kubernetes keeps when the release is uninstalled. Delete it to remove
the data. Use block storage (for example `gp3` on EKS) rather than a network filesystem such as NFS or EFS:

```yaml
clickhouse:
  persistence:
    storageClass: gp3
    size: 100Gi
```

Clickhouse limits its own memory use to 90% of `clickhouse.resources.limits.memory`.

To query it, run `clickhouse-client` in its container; `helm install` prints the command.

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
| affinity | object | `{}` | Affinity for the pod |
| clickhouse.auth.existingSecret | string | `""` | An existing Secret with the server's Clickhouse password. The chart generates one if empty. |
| clickhouse.auth.existingSecretKey | string | `"password"` | The key in `existingSecret` that holds the password |
| clickhouse.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| clickhouse.image.repository | string | `"clickhouse/clickhouse-server"` | The Clickhouse image repository |
| clickhouse.image.tag | string | `"26.8.39.19"` | The Clickhouse image tag, the LTS release the server is tested with |
| clickhouse.persistence.size | string | `"20Gi"` | The size of Clickhouse's data volume |
| clickhouse.persistence.storageClass | string | `""` | The storage class for Clickhouse's data, defaults to the cluster's default. Use block storage, not a network    filesystem such as NFS or EFS. |
| clickhouse.resources | object | `{"limits":{"memory":"4Gi"},"requests":{"cpu":"500m","memory":"1Gi"}}` | Resources for the Clickhouse container. Clickhouse limits its own memory use to 90% of the memory limit. |
| clickhouse.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":101,"runAsUser":101}` | The Clickhouse container's security context. The image runs Clickhouse as uid 101. |
| env | list | `[]` | Additional environment variables for the server, such as `POSIT_TELEMETRY_LOGGING_LEVEL` |
| fullnameOverride | string | `""` | Override for the full name of the release |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `"ghcr.io/posit-dev/posit-telemetry"` | The Posit Telemetry server's image repository |
| image.tag | string | `""` | The image tag, defaults to the chart's appVersion |
| imagePullSecrets | list | `[]` | Secrets for pulling the server and Clickhouse images |
| ingress.annotations | object | `{}` | Annotations for the Ingress |
| ingress.enabled | bool | `false` | Expose the server outside the cluster with an Ingress, for agents that run elsewhere. The server itself speaks    plain HTTP, so this is where TLS is terminated. |
| ingress.hosts | list | `[]` | The hostnames to route to the server. Agents post to paths under `/v1/`. |
| ingress.ingressClassName | string | `""` | The Ingress class |
| ingress.tls | list | `[]` | TLS certificates for the hostnames, as Secrets |
| nameOverride | string | `""` | Override for the name of the chart |
| nodeSelector | object | `{}` | Node selector for the pod |
| podSecurityContext | object | `{"fsGroup":101,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | The pod's security context, shared by the server and Clickhouse. `fsGroup` is the group of the Clickhouse image's    user, so that Clickhouse can write to its data volume. |
| resources | object | `{}` | Resources for the server container |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsUser":1000}` | The server container's security context. The image runs the server as uid 1000. |
| service.annotations | object | `{}` | Annotations for the Service |
| service.port | int | `4318` | The port agents send Opentelemetry data to, over HTTP (OTLP HTTP) |
| service.type | string | `"ClusterIP"` | The Service type for the server |
| tolerations | list | `[]` | Tolerations for the pod |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)

