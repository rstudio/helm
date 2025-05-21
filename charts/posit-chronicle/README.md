# Posit Chronicle

![Version: 0.4.0](https://img.shields.io/badge/Version-0.4.0-informational?style=flat-square) ![AppVersion: 2025.03.0](https://img.shields.io/badge/AppVersion-2025.03.0-informational?style=flat-square)

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

To install the chart with the release name `my-release` at version 0.4.0:

```{.bash}
helm repo add rstudio https://helm.rstudio.com
helm upgrade --install my-release rstudio/posit-chronicle --version=0.4.0
```

To explore other chart versions, look at:

```{.bash}
helm search repo rstudio/posit-chronicle -l
```

## Usage

This chart deploys only the Chronicle server and is meant to be used in tandem
with the Workbench and Connect charts. To actually send data to the server, you
will need to run the Chronicle agent as a sidecar container on your
Workbench or Connect server pods by adding a native sidecar Chronicle agent
definition to the `initContainers` value in their respective `values.yaml` files.

Here is an example of Helm values to run the agent sidecar in **Workbench**:

```yaml
initContainers:
  - name: chronicle-agent
    restartPolicy: Always
    image: ghcr.io/rstudio/chronicle-agent:2025.03.0
    env:
      - name: CHRONICLE_SERVER_ADDRESS
        value: "http://<service>.<namespace>"
```

And here is an example of Helm values for Connect, where a **Connect**
API key from a Kubernetes Secret is used to unlock more detailed metrics:

```yaml
initContainers:
- name: chronicle-agent
  restartPolicy: Always
  image: ghcr.io/rstudio/chronicle-agent:2025.03.0
  env:
    - name: CHRONICLE_SERVER_ADDRESS
      value: "http://<service>.<namespace>"
    - name: CHRONICLE_CONNECT_APIKEY
      valueFrom:
        secretKeyRef:
          name: connect
          key: apikey
```

It is up to the user to provision this Kubernetes Secret for the
Connect API key. The `extraObjects` value in the Connect chart can be used to
create the secret and mount it to the Chronicle agent container. Due to the
nature of the Chronicle agent, the pod may need to be restarted to pick up
changes to the secret after initial deployment.

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

The default configuration uses a local volume with persistence enabled, which
is suitable if you'd like to access and analyze the data within your cluster:

```yaml
persistence:
  enabled: true
  accessModes:
    - ReadWriteOnce
  size: 10Gi
config:
  LocalStorage:
    Enabled: true
    Location: "/chronicle-data"
```

The `persistence` section configures the persistent volume claim in the
cluster while the `config.LocalStorage` section directly applies to Chronicle's
configuration file. The persistent volume will always mount to the path specified
by `config.LocalStorage.Path` to avoid potential misconfiguration and data loss.

By default, Chronicle requests 10Gi of storage. In most cases, this amount of
storage should be sufficient for thirty days of monitoring data. Organizations
are responsible for managing the size of the persistent volume.

You can also persist data to AWS S3 in place of or in tandem with local storage:

```yaml
config:
  S3Storage:
    Enabled: true
    Bucket: "posit-chronicle"
    Region: "us-east-2"
```

### Using IAM roles for S3 access

If you are running on EKS, you can use [IAM Roles for Service
Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
to manage the credentials needed to access S3. In this scenario, once you have [created an IAM
role](https://docs.aws.amazon.com/eks/latest/userguide/create-service-account-iam-policy-and-role.html),
you can use this role as an annotation on the existing Service Account:

```yaml
serviceaccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn:  arn:aws:iam::123456789000:role/iam-role-name-here
```

If you are unable to use IAM Roles for Service Accounts, there are any number of
alternatives for injecting AWS credentials into a container. As a fallback,
the S3 storage config allows specifying a profile:

```yaml
config:
  S3Storage:
    Enabled: true
    Bucket: "posit-chronicle"
    Profile: "my-aws-account"
    Region: "us-east-2"
```

### Needed S3 Policy Permissions

The credentials Chronicle uses for S3 storage must have the following permissions enabled:

- `s3:GetObject`
- `s3:ListBucket`
- `s3:PutObject`
- `s3:DeleteObject`

## Additional Configuration

Chronicle has a multitude of configuration options not specifically mentioned in this
README. For a complete list of configuration options, please refer to the
[Chronicle documentation](https://docs.posit.co/chronicle/).

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| commonAnnotations | object | `{}` | Common annotations to add to all resources |
| commonLabels | object | `{}` | Common labels to add to all resources |
| config.HTTPS.Certificate | string | `""` | Path to a PEM encoded TLS certificate file |
| config.HTTPS.Enabled | bool | `false` | If set to true, Chronicle will use HTTPS instead of HTTP |
| config.HTTPS.Key | string | `""` | Path to a PEM encoded private key file corresponding to the specified certificate |
| config.LocalStorage | object | `{"Enabled":true,"Path":"/opt/chronicle-data"}` | Configuration for local data storage with Chronicle, for configuring persistence of this data see the persistence section |
| config.LocalStorage.Enabled | bool | `true` | If set to true, Chronicle will use a local path for data storage. This should be used in conjunction with persistence. |
| config.LocalStorage.Path | string | `"/opt/chronicle-data"` | The path to the local storage location |
| config.Logging.ServiceLog | string | `"STDOUT"` | Specifies the output for log messages, can be one of "STDOUT", "STDERR", or a file path |
| config.Logging.ServiceLogFormat | string | `"TEXT"` | The log format for the service, can be one of "TEXT" or "JSON" |
| config.Logging.ServiceLogLevel | string | `"INFO"` | The log level for the service, can be one of "TRACE", "DEBUG", "INFO", "WARN", or "ERROR" |
| config.Metrics.Enabled | bool | `false` | If set to true, Chronicle will expose a metrics endpoint for Prometheus |
| config.Profiling.Enabled | bool | `false` | If set to true, Chronicle will expose a pprof profiling server |
| config.Profiling.Port | int | `3030` | The port to use for the profiling server |
| config.S3Storage | object | `{"Bucket":"","Enabled":false,"Prefix":"","Profile":"","Region":""}` | Configuration for S3 data storage with Chronicle |
| config.S3Storage.Bucket | string | `""` | The S3 bucket to use for storage |
| config.S3Storage.Enabled | bool | `false` | If set to true, Chronicle will use S3 for data storage |
| config.S3Storage.Prefix | Optional | `""` | the prefix to use when writing to the S3 bucket, defaults to the bucket root |
| config.S3Storage.Profile | Optional | `""` | the profile to use when writing to the S3 bucket, defaults is to use the `AWS_PROFILE` env var |
| config.S3Storage.Region | Optional | `""` | the region to use when writing to the S3 bucket, defaults is to use the `AWS_REGION` env var |
| extraObjects | list | `[]` | Additional manifests to deploy with the chart |
| extraSecretMounts | list | `[]` |  |
| fullnameOverride | string | `""` | Override for the full name of the release |
| image.pullPolicy | string | `"IfNotPresent"` | The image pull policy |
| image.registry | string | `"ghcr.io"` | The image registry |
| image.repository | string | `"rstudio/chronicle"` | The image repository |
| image.securityContext | object | `{"allowPrivilegeEscalation":false,"runAsNonRoot":true}` | The verbatim securityContext for the Chronicle server container in the pod    ref: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#securitycontext-v1-core |
| image.sha | Optional | `""` | The image digest |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion |
| nameOverride | string | `""` | Override for the name of the chart deployment |
| namespaceOverride | string | `""` | Override for the namespace of the chart deployment |
| persistence.accessModes | list | `["ReadWriteOnce"]` | Persistent Volume Access Modes |
| persistence.annotations | object | `{}` | Additional annotations to add to the PVC |
| persistence.enabled | bool | `true` | Enable persistence using Persistent Volume Claims |
| persistence.finalizers | list | `["kubernetes.io/pvc-protection"]` | Finalizers added verbatim to the PVC |
| persistence.labels | object | `{}` | Additional labels to add to the PVC |
| persistence.selectorLabels | object | `{}` | Selector to match an existing Persistent Volume for the data PVC |
| persistence.size | string | `"10Gi"` | Size of the data volume |
| persistence.storageClassName | string | `""` | Persistent Volume Storage Class    (Leave empty if using the default storage class) |
| pod.affinity | object | `{}` | A map used verbatim as the pod's "affinity" definition |
| pod.annotations | object | `{}` | Additional annotations to add to the chronicle-server pods |
| pod.args | list | `[]` |  |
| pod.command | list | `[]` | The command and args to run in the chronicle-server container, defaults to the image entrypoint and args |
| pod.env | list | `[]` | Optional environment variables |
| pod.labels | object | `{}` | Additional labels to add to the chronicle-server pods |
| pod.nodeSelector | object | `{}` | A map used verbatim as the pod's "nodeSelector" definition |
| pod.securityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | The verbatim pod-level securityContext    ref: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.32/#podsecuritycontext-v1-core |
| pod.terminationGracePeriodSeconds | int | `30` | The termination grace period seconds allowed for the pod before shutdown |
| pod.tolerations | list | `[]` | An array used verbatim as the pod's "tolerations" definition |
| replicas | int | `1` | The number of replica pods to maintain for this service |
| service.annotations | object | `{}` | Additional annotations to add to the chronicle-server service |
| service.labels | object | `{}` | Additional labels to add to the chronicle-server service |
| service.port | int | `80` | The port to use for the REST service |
| serviceAccount.annotations | object | `{}` | Additional annotations to add to the chronicle-server serviceaccount |
| serviceAccount.create | bool | `false` |  |
| serviceAccount.labels | object | `{}` | Additional labels to add to the chronicle-server serviceaccount |
| serviceAccount.name | string | `""` | The name of the service account to use |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)

