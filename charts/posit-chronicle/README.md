# Posit Chronicle

![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![AppVersion: 2024.03.0](https://img.shields.io/badge/AppVersion-2024.03.0-informational?style=flat-square)

#### _Official Helm chart for Posit Chronicle Server_

Chronicle helps data science managers and other stakeholders understand their
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

To install the chart with the release name `my-release` at version 0.3.0:

```{.bash}
helm repo add rstudio https://helm.rstudio.com
helm upgrade --install my-release rstudio/posit-chronicle --version=0.3.0
```

To explore other chart versions, look at:

```{.bash}
helm search repo rstudio/posit-chronicle -l
```

## Usage

This chart deploys only the Chronicle server and is meant to be used in tandem
with the Workbench and Connect charts. To actually send data to the server, you
will need to run the Chronicle agent as a sidecar container on your
Workbench or Connect server pods by setting `pod.sidecar` in their respective `values.yaml` files

Here is an example of Helm values to run the agent sidecar in **Workbench**,
where we set up a shared volume between containers for audit logs:

```yaml
pod:
  # We will need to create a new volume to share audit logs between
  # the rstudio (workbench) and chronicle-agent containers
  volumes:
    - name: logs
      emptyDir: {}
  volumeMounts:
    - name: logs
      mountPath: "/var/lib/rstudio-server/audit"
  sidecar:
    - name: chronicle-agent
      image: ghcr.io/rstudio/chronicle-agent:2024.03.0
      volumeMounts:
      - name: logs
        mountPath: "/var/lib/rstudio-server/audit"
      env:
      - name: CHRONICLE_SERVER_ADDRESS
        value: "http://chronicle-server.default"
```

And here is an example of Helm values for Connect, where a **Connect**
API key from a Kubernetes Secret is used to unlock more detailed metrics:

```yaml
pod:
  sidecar:
    - name: chronicle-agent
      image: ghcr.io/rstudio/chronicle-agent:2024.03.0
      env:
      - name: CHRONICLE_SERVER_ADDRESS
        value: "http://chronicle-server.default"
      - name: CONNECT_API_KEY
        valueFrom:
          secretKeyRef:
            name: connect
            key: apikey
```

Note that it is up to the user to provision this Kubernetes Secret for the
Connect API key.

## Storage Configuration

Chronicle can be configured to persist data to a local Kubernetes Volume, AWS S3, or both.

The default configuration uses a local volume, which is suitable if you'd like to
access and analyze the data within your cluster:

```yaml
config:
  LocalStorage:
    Enabled: true
    Location: "/chronicle-data"
    RetentionPeriod: "30d"
```

`retentionPeriod` controls how long usage data are kept. For example, `"120m"`
for 120 minutes, `"36h"` for 36 hours, `14d` for two weeks, or `"0"` for unbounded retention.
(Units smaller than seconds or larger than days are not supported.)

You can also persist data to AWS S3 instead of (or in addition to) local
storage:

```yaml
config:
  S3Storage:
    Enabled: true
    Bucket: "posit-chronicle"
    Region: "us-east-2"
```

### Using Iam for S3

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

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.HTTPS.Certificate | string | `""` |  |
| config.HTTPS.Enabled | bool | `false` |  |
| config.HTTPS.Key | string | `""` |  |
| config.LocalStorage.Enabled | bool | `false` |  |
| config.LocalStorage.Location | string | `"./chronicle-data"` |  |
| config.LocalStorage.RetentionPeriod | string | `"30d"` |  |
| config.Logging.ServiceLog | string | `"STDOUT"` |  |
| config.Logging.ServiceLogFormat | string | `"TEXT"` |  |
| config.Logging.ServiceLogLevel | string | `"INFO"` |  |
| config.Metrics.Enabled | bool | `true` |  |
| config.Profiling.Enabled | bool | `false` |  |
| config.S3Storage.Bucket | string | `"posit-chronicle"` |  |
| config.S3Storage.Enabled | bool | `false` |  |
| config.S3Storage.Prefix | string | `""` |  |
| config.S3Storage.Profile | string | `""` |  |
| config.S3Storage.Region | string | `"us-east-2"` |  |
| image.imagePullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"ghcr.io/rstudio/chronicle"` |  |
| image.tag | string | `"2024.03.0"` |  |
| nodeSelector | object | `{}` | A map used verbatim as the pod's "nodeSelector" definition |
| pod.affinity | object | `{}` | A map used verbatim as the pod's "affinity" definition |
| pod.annotations | object | `{}` | Additional annotations to add to the chronicle-server pods |
| pod.args[0] | string | `"start"` |  |
| pod.args[1] | string | `"-c"` |  |
| pod.args[2] | string | `"/etc/posit-chronicle/posit-chronicle.gcfg"` |  |
| pod.command | string | `"/chronicle"` | The command and args to run in the chronicle-server container |
| pod.env | list | `[]` | Optional environment variables |
| pod.labels | object | `{}` | Additional labels to add to the chronicle-server pods |
| pod.selectorLabels | object | `{}` | Additional selector labels to add to the chronicle-server pods |
| pod.terminationGracePeriodSeconds | int | `30` | The termination grace period seconds allowed for the pod before shutdown |
| pod.tolerations | list | `[]` | An array used verbatim as the pod's "tolerations" definition |
| replicas | int | `1` | The number of replica pods to maintain for this service |
| service.annotations | object | `{}` | Additional annotations to add to the chronicle-server service |
| service.labels | object | `{}` | Additional labels to add to the chronicle-server service |
| service.port | int | `80` | The port to use for the REST service |
| service.selectorLabels | object | `{}` | Additional selector labels to add to the chronicle-server service |
| serviceaccount.annotations | object | `{}` | Additional annotations to add to the chronicle-server serviceaccount |
| serviceaccount.create | bool | `false` |  |
| serviceaccount.labels | object | `{}` | Additional labels to add to the chronicle-server serviceaccount |
| storage.persistentVolumeSize | string | `"1Gi"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)

