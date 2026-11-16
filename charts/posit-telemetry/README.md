# Posit Telemetry

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

#### _Official Helm chart for the Posit telemetry server, which can run as either the Clickhouse-backed posit-telemetry server or the classic Chronicle server_

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

This chart deploys one of two server types from the [posit-dev/chronicle](https://github.com/posit-dev/chronicle)
image, set with `serverType`:

- `posit-telemetry` (the default): receives Opentelemetry data from Chronicle agents and stores it in Clickhouse.
  This chart also deploys Clickhouse beside it as a StatefulSet, from Clickhouse's own image.
- `chronicle`: the classic Chronicle server, storing data on a local volume (`chronicle.localStorage`) and/or in S3
  (`chronicle.s3Storage`), with its own in-process agent disabled since no product runs on this pod.

Both server types accept connections from the same Chronicle agent. Agents send their data to the server's Service,
`<release>-posit-telemetry.<namespace>.svc:4318`, or `<release>.<namespace>.svc:4318` if the release name already
contains `posit-telemetry`; `helm install` prints it. Set it as each agent's `[Server] Address`, in a
`*-local.gcfg` beside the agent's config file, or with `CHRONICLE_SERVER_ADDRESS`. The Connect, Workbench, and
Package Manager charts don't configure an agent yet.

With `serverType: posit-telemetry`, the server creates its Clickhouse database and runs the schema migrations each
time it starts, before it accepts data, so the chart runs exactly one server and replaces it rather than rolling it
on upgrade. Agents don't queue or retry, so they drop what they send while it restarts.

## Clickhouse

Only deployed when `serverType` is `posit-telemetry`.

The chart pins `clickhouse.image.tag` to the Clickhouse LTS release the server is tested with.

Clickhouse keeps its data on a PersistentVolumeClaim, `data-<release>-posit-telemetry-clickhouse-0` (or
`data-<release>-clickhouse-0` if the release name contains `posit-telemetry`), which Kubernetes keeps when the release
is uninstalled. Delete it to remove the data. Use block storage (for example `gp3` on EKS) rather than a network
filesystem such as NFS or EFS:

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

## Chronicle server storage

Only used when `serverType` is `chronicle`. Enable `chronicle.localStorage`, `chronicle.s3Storage`, or both:

```yaml
serverType: chronicle
chronicle:
  localStorage:
    enabled: false
  s3Storage:
    enabled: true
    bucket: my-chronicle-bucket
    region: us-east-1
```

`chronicle.localStorage` keeps data on a PersistentVolumeClaim, `<release>-posit-telemetry-data` (or `<release>-data`
if the release name already contains `posit-telemetry`), which Kubernetes keeps when the release is uninstalled.
`chronicle.s3Storage` relies on AWS credentials already present in the pod's environment, such as from an IAM role;
this chart doesn't manage them.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for the server pod |
| chronicle | object | `{"localStorage":{"enabled":true,"persistence":{"size":"20Gi","storageClass":""}},"s3Storage":{"bucket":"","enabled":false,"endpoint":"","prefix":"","profile":"","region":""}}` | Settings for the `chronicle` server type. Ignored when `serverType` is `posit-telemetry`. |
| chronicle.localStorage.enabled | bool | `true` | Store data on a local volume. Can be used together with `s3Storage`. |
| chronicle.localStorage.persistence.size | string | `"20Gi"` | The size of the local data volume |
| chronicle.localStorage.persistence.storageClass | string | `""` | The storage class for the local data volume, defaults to the cluster's default. Use block storage, not a    network filesystem such as NFS or EFS. |
| chronicle.s3Storage.bucket | string | `""` | The S3 bucket |
| chronicle.s3Storage.enabled | bool | `false` | Store data in S3. Can be used together with `localStorage`. Credentials come from the pod's environment    (for example an IAM role), not from this chart. |
| chronicle.s3Storage.endpoint | string | `""` | A custom S3-compatible endpoint (for example MinIO); enables path-style addressing |
| chronicle.s3Storage.prefix | string | `""` | The prefix within the bucket |
| chronicle.s3Storage.profile | string | `""` | The AWS profile, defaults to the `$AWS_PROFILE` environment variable |
| chronicle.s3Storage.region | string | `""` | The AWS region, defaults to the `$AWS_REGION` environment variable |
| clickhouse.affinity | object | `{}` | Affinity for the Clickhouse pod |
| clickhouse.auth.existingSecret | string | `""` | An existing Secret with the posit-telemetry server's Clickhouse password. The chart generates one if empty. |
| clickhouse.auth.existingSecretKey | string | `"password"` | The key in `existingSecret` that holds the password |
| clickhouse.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| clickhouse.image.repository | string | `"clickhouse/clickhouse-server"` | The Clickhouse image repository |
| clickhouse.image.tag | string | `"26.8.34.13"` | The Clickhouse image tag, the LTS release the posit-telemetry server is tested with |
| clickhouse.nodeSelector | object | `{}` | Node selector for the Clickhouse pod |
| clickhouse.persistence.size | string | `"20Gi"` | The size of Clickhouse's data volume |
| clickhouse.persistence.storageClass | string | `""` | The storage class for Clickhouse's data, defaults to the cluster's default. Use block storage, not a network    filesystem such as NFS or EFS. |
| clickhouse.podSecurityContext | object | `{"fsGroup":101,"runAsGroup":101,"runAsNonRoot":true,"runAsUser":101,"seccompProfile":{"type":"RuntimeDefault"}}` | Clickhouse's pod-level security context. The image runs Clickhouse as uid 101. |
| clickhouse.resources | object | `{"limits":{"memory":"4Gi"},"requests":{"cpu":"500m","memory":"1Gi"}}` | Resources for the Clickhouse container. Clickhouse limits its own memory use to 90% of the memory limit. |
| clickhouse.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}` | Clickhouse's container-level security context |
| clickhouse.service.port | int | `9000` | The port for Clickhouse's native protocol, which the posit-telemetry server uses |
| clickhouse.tolerations | list | `[]` | Tolerations for the Clickhouse pod |
| env | list | `[]` | Additional environment variables for the server, such as `POSIT_TELEMETRY_LOGGING_LEVEL` or `CHRONICLE_LOGGING_LEVEL` |
| fullnameOverride | string | `""` | Override for the full name of the release |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.repository | string | `"ghcr.io/posit-dev/chronicle"` | The chronicle image repository. Chronicle builds the posit-telemetry server, the classic chronicle server, and    the agent from one codebase; this placeholder should be replaced once that image is published. |
| image.tag | string | `""` | The image tag, defaults to the chart's appVersion |
| imagePullSecrets | list | `[]` | Secrets for pulling the chronicle and Clickhouse images |
| nameOverride | string | `""` | Override for the name of the chart |
| nodeSelector | object | `{}` | Node selector for the server pod |
| podSecurityContext | object | `{"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | The server's pod-level security context |
| resources | object | `{}` | Resources for the server container |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | The server's container-level security context |
| serverType | string | `"posit-telemetry"` | Which server type the chronicle image runs: `posit-telemetry` (stores data in Clickhouse, deployed alongside it    by this chart) or `chronicle` (the classic server, storing data on a local volume and/or in S3). Both server    types accept data from the same Chronicle agent, just pointed at a different address. |
| service.annotations | object | `{}` | Annotations for the Service |
| service.port | int | `4318` | The port agents send data to: OTLP HTTP for the posit-telemetry server type, or Chronicle's own protocol for    the chronicle server type |
| service.type | string | `"ClusterIP"` | The Service type for the server |
| tolerations | list | `[]` | Tolerations for the server pod |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)

