# Posit Chronicle

![Version: 0.4.3](https://img.shields.io/badge/Version-0.4.3-informational?style=flat-square) ![AppVersion: 2025.05.3](https://img.shields.io/badge/AppVersion-2025.05.3-informational?style=flat-square)

#### _Official Helm chart for Posit Chronicle Server_

[Posit Chronicle](https://docs.posit.co/chronicle/) helps data science managers and other stakeholders understand their
organization's use of other Posit products, primarily Posit Connect and
Workbench.

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

To install the chart with the release name `my-release` at version 0.4.3:

```{.bash}
helm repo add rstudio https://helm.rstudio.com
helm upgrade --install my-release rstudio/posit-chronicle --version=0.4.3
```

To explore other chart versions, look at:

```{.bash}
helm search repo rstudio/posit-chronicle -l
```

## Usage

This chart deploys the Chronicle server and is intended to be used in tandem
with the Workbench and Connect charts. For the server to receive data,
the Chronicle agent must be deployed as a sidecar container alongside
Workbench or Connect server pods.

Both [Workbench](https://docs.posit.co/helm/charts/rstudio-workbench/README.html#chronicle-agent)
(`>=0.9.2`) and [Connect](https://docs.posit.co/helm/charts/rstudio-connect/README.html#chronicle-agent)
(`>=0.7.26`) charts include out of the box support for Chronicle agent sidecars.
The sidecar can be enabled by setting the `chronicleAgent.enabled` value to `true`
in either product's chart.

For additional information on deploying and configuring Chronicle agents,
see the [Workbench](https://docs.posit.co/helm/charts/rstudio-workbench/README.html#chronicle-agent)
or [Connect](https://docs.posit.co/helm/charts/rstudio-connect/README.html#chronicle-agent)
chart documentation.

## HTTPS Configuration

Chronicle can be configured to use HTTPS for secure communication. The
`config.HTTPS` section of the configuration allows you to specify the certificate
and key files to use for HTTPS. Both `config.HTTPS.Certificate` and
`config.HTTPS.Key` are expected to be paths to files accessible by Chronicle.
The `extraSecretMounts` value can be used to mount the certificate and key files
into the Chronicle pod. Here is an example of how to do this, assuming that
the certificate and key files are stored together in a Kubernetes TLS secret:

```yaml
extraSecretMounts:
  - name: chronicle-https
    mountPath: /etc/chronicle/ssl
    secretName: chronicle-https
    items:
      - key: tls.crt
      - key: tls.key
config:
  HTTPS:
    Enabled: true
    Certificate: "/etc/chronicle/ssl/tls.crt"
    Key: "/etc/chronicle/ssl/tls.key"
```

## Storage Configuration

Chronicle can be configured to persist data to local storage, AWS S3, or both.

### Local Storage

The default configuration will save data to a persistent volume, which
is suitable if you'd like to access and analyze the data within your cluster.
The below values show the default configuration for storage:

```yaml
persistence:
  enabled: true
  accessModes:
    - ReadWriteOnce
  size: 10Gi
config:
  LocalStorage:
    Enabled: true
    Location: "/opt/chronicle-data"
```

The `persistence` section configures the persistent volume claim in the
cluster while the `config.LocalStorage` section directly applies to Chronicle's
configuration file. The persistent volume will always mount to the path specified
by `config.LocalStorage.Path` to avoid potential misconfiguration and data loss.

By default, Chronicle requests 10Gi of storage. In most cases, this amount of
storage should be sufficient for thirty days of monitoring data.

::: {.callout-important}
Users are responsible for managing the size of the persistent volume, retention
of stored data, and controlling access to the data from other pods. Consider
utilizing a dynamic volume provisioner to avoid storage-related service
interruptions.
:::

While attaching the volume to Workbench is a valid method of accessing the data,
keep in mind that some data captured by Chronicle may be considered sensitive and
should be handled with care.

#### Alternate Storage Class

Depending on the environment or cloud hosting Chronicle, many CSI drivers may
be available to use as the persistent volume's storage class. While Chronicle
only natively supports local storage or S3, CSI drivers may be used to provide
support for other storage backends such as Azure Blob Storage, Azure Files, Google
Cloud Storage, or other object storage solutions. The storage class for persistent
volumes can be set with the following value:

```yaml
persistence:
  storageClass: "alternate-storage-class"
```

Please report and performance or stability issues with alternate storage configurations
to the [issue tracker](https://github.com/rstudio/helm/issues/new?template=chronicle.md).

### S3 Storage

Chronicle can also be configured to store data in an S3 bucket. This can be
useful for controlling access to data or taking advantage of S3 features
such as lifecycle management.

```yaml
config:
  S3Storage:
    Enabled: true
    Bucket: "posit-chronicle"
    Region: "us-east-2"
```

#### Using IAM roles for S3 access

If Chronicle is running on EKS, [IAM Roles for Service
Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
can be utilized to manage the credentials needed to access S3. Once [an IAM role has been
created](https://docs.aws.amazon.com/eks/latest/userguide/create-service-account-iam-policy-and-role.html),
the role can be attached as an annotation on Chronicle's Service Account:

```yaml
serviceaccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn:  arn:aws:iam::123456789000:role/iam-role-name-here
```

There are alternatives for injecting AWS credentials into a container. As a fallback,
the S3 storage config allows specifying a profile:

```yaml
config:
  S3Storage:
    Enabled: true
    Bucket: "posit-chronicle"
    Profile: "my-aws-account"
    Region: "us-east-2"
```

#### Needed S3 Policy Permissions

The credentials Chronicle uses for S3 storage must have the following permissions enabled:

- `s3:GetObject`
- `s3:ListBucket`
- `s3:PutObject`
- `s3:DeleteObject`

## Additional Configuration

Chronicle has additional configuration options not specifically mentioned in this
README. For additional information on administrating or using Posit Chronicle, see
the [Chronicle documentation](https://docs.posit.co/chronicle/).

For details on server configuration options, see the [advanced server configuration
reference page](https://docs.posit.co/chronicle/appendix/library/advanced-server.html).

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| commonAnnotations | object | `{}` | Common annotations to add to all resources |
| commonLabels | object | `{}` | Common labels to add to all resources |
| config.HTTPS.Certificate | string | `""` | Path to a PEM encoded certificate file, required if `HTTPS.Enabled=true` |
| config.HTTPS.Enabled | bool | `false` | If set to true, Chronicle will use HTTPS instead of HTTP |
| config.HTTPS.Key | string | `""` | Path to a PEM encoded private key file corresponding to the specified certificate, required if `HTTPS.Enabled=true` |
| config.LocalStorage.Enabled | bool | `true` | Use `config.LocalStorage.Path` for data storage if true, use in conjunction with `persistence.enabled=true` for persistent data storage |
| config.LocalStorage.Path | string | `"/opt/chronicle-data"` | The path to use for local storage |
| config.Logging.ServiceLog | string | `"STDOUT"` | Specifies the output for log messages, can be one of "STDOUT", "STDERR", or a file path |
| config.Logging.ServiceLogFormat | string | `"TEXT"` | The log format for the service, can be one of "TEXT" or "JSON" |
| config.Logging.ServiceLogLevel | string | `"INFO"` | The log level for the service, can be one of "TRACE", "DEBUG", "INFO", "WARN", or "ERROR" |
| config.Metrics.Enabled | bool | `false` | Exposes a metrics endpoint for Prometheus if true |
| config.Profiling.Enabled | bool | `false` | Exposes a pprof profiling server if true |
| config.Profiling.Port | int | `3030` | The port to use for the profiling server |
| config.S3Storage.Bucket | string | `""` | The S3 bucket to use for storage, required if `S3Storage.Enabled=true` |
| config.S3Storage.Enabled | bool | `false` | Use S3 for data storage if true |
| config.S3Storage.Prefix | string | `""` | An optional prefix path to use when writing to the S3 bucket |
| config.S3Storage.Profile | string | `""` | An IAM Profile to use for accessing the S3 bucket, default is to read from the `AWS_PROFILE` env var |
| config.S3Storage.Region | string | `""` | Region of the S3 bucket, default is to read from the `AWS_REGION` env var |
| extraObjects | list | `[]` | Additional manifests to deploy with the chart with template value rendering |
| extraSecretMounts | list | `[]` | Additional secrets to mount to the Chronicle server pod |
| fullnameOverride | string | `""` | Override for the full name of the release |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.registry | string | `"ghcr.io"` | The image registry |
| image.repository | string | `"rstudio/chronicle"` | The image repository |
| image.securityContext | object | `{"allowPrivilegeEscalation":false,"runAsNonRoot":true}` | The container-level security context    ([reference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#securitycontext-v1-core)) |
| image.sha | string | `""` | The image digest |
| image.tag | string | `""` | The image tag, defaults to the chart app version |
| nameOverride | string | `""` | Override for the name of the release |
| namespaceOverride | string | `""` | Override for the namespace of the chart deployment |
| persistence.accessModes | list | `["ReadWriteMany"]` | Persistent Volume Access Modes |
| persistence.annotations | object | `{}` | Additional annotations for the PVC |
| persistence.enabled | bool | `true` | Enable persistence using Persistent Volume Claims |
| persistence.finalizers | list | `["kubernetes.io/pvc-protection"]` | Finalizers for the PVC |
| persistence.labels | object | `{}` | Additional labels for the PVC |
| persistence.selectorLabels | object | `{}` | Selector to match an existing Persistent Volume for the data PVC |
| persistence.size | string | `"10Gi"` | Size of the data volume |
| persistence.storageClassName | string | `""` | Persistent Volume Storage Class, defaults to the default Storage Class for the cluster |
| pod.affinity | object | `{}` | A map used verbatim as the pod "affinity" definition |
| pod.annotations | object | `{}` | Additional annotations for pods |
| pod.args | list | `[]` | The arguments to pass to the command, defaults to the image `CMD` values |
| pod.command | list | `[]` | The command to run in the Chronicle server container, defaults to the image `ENTRYPOINT` value |
| pod.env | list | `[]` | Additional environment variables to set on the Chronicle server container |
| pod.labels | object | `{}` | Additional labels for pods |
| pod.nodeSelector | object | `{}` | A map used verbatim as the pod "nodeSelector" definition |
| pod.securityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | The pod-level security context    ([reference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#podsecuritycontext-v1-core)) |
| pod.terminationGracePeriodSeconds | int | `30` | The termination grace period seconds allowed for the pod before shutdown |
| pod.tolerations | list | `[]` | An array used verbatim as the pod "tolerations" definition |
| replicas | int | `1` | The number of replica pods to maintain |
| resources.limits.cpu | string | `"2000m"` |  |
| resources.limits.ephemeralStorage | string | `"200Mi"` |  |
| resources.limits.memory | string | `"3Gi"` |  |
| resources.requests.cpu | string | `"1000m"` |  |
| resources.requests.ephemeralStorage | string | `"100Mi"` |  |
| resources.requests.memory | string | `"2Gi"` |  |
| service.annotations | object | `{}` | Annotations to add to the service |
| service.labels | object | `{}` | Labels to add to the service |
| service.port | int | `80` | The port to use for the REST API service |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `false` | Creates a service account for Posit Chronicle if true |
| serviceAccount.labels | object | `{}` | Labels to add to the service account |
| serviceAccount.name | string | `""` | Override for the service account name, defaults to fullname |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)

