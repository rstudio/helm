# Posit Chronicle

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 2023.11.0](https://img.shields.io/badge/AppVersion-2023.11.0-informational?style=flat-square)

#### _Helm chart for the Chronicle Server_

IT Administrators and Business Users use [Posit Chronicle](https://docs.posit.co/chronicle) to aggregate and monitor
posit product usage.

## For Production

To ensure a stable production deployment, please:

* Ensure you "pin" the version of the Helm chart that you are using. You can do
  this using the `helm dependency` command and the associated "Chart.lock" files
  or the `--version` flag. **IMPORTANT: This protects you from breaking changes**
* Before upgrading, to avoid breaking changes, use `helm diff upgrade` to check
  for breaking changes
* Pay close attention to [`NEWS.md`](./NEWS.md) for updates on breaking
  changes, as well as documentation below on how to use the chart

## Installing the Chart

To install the chart with the release name `my-release` at version 0.1.0:

```bash
helm repo add rstudio https://helm.rstudio.com
helm upgrade --install my-release rstudio/posit-chronicle --version=0.1.0
```

To explore other chart versions, take a look at:
```
helm search repo rstudio/posit-chronicle -l
```

## Usage

The Chronicle chart is meant to be used in tandem with other Workbench and Connect instances.
To enable the Chronicle agent, additional values will have to be passed to your
Workbench and Connect values.

Here's some example agent helm values to run the agent sidecar in Workbench:

```yaml
pod:
  ...
  sidecar:
    - name: chronicle-agent
      image: posit-chronicle:latest
      volumeMounts:
      - name: CHRONICLE_PRODUCT_CLUSTER_ID
        value: "posit-cluster-1"
      - name: logs
        mountPath: "/var/lib/rstudio-server/audit"
      env:
      - name: CHRONICLE_SERVER_ADDRESS
        value: "http://chronicle-server.default.svc.cluster.local"
...
```

And here's some example agent helm values for Connect, where we utilize an API key stored as a k8s secret
to scrape the Connect metrics REST service:

```yaml
pod:
  ...
  sidecar:
    - name: chronicle-agent
      image: posit-chronicle:latest
      env:
      - name: CHRONICLE_PRODUCT_CLUSTER_ID
        value: "posit-cluster-1"
      - name: CHRONICLE_SERVER_ADDRESS
        value: "http://chronicle-server.default.svc.cluster.local"
      - name: CONNECT_API_KEY
        valueFrom:
          secretKeyRef:
            name: connect
            key: apikey
```

Note that it will be up to the user to provision that Connect API key Kubernetes secret.

## Storage Configuration

Chronicle can be configured to store its data in a local kubernetes volime, in S3,
or in both.

The default configuration uses a local volume, which is suitable if you'd like to
access and analyze the data within your cluster:

``` yaml
config:
  localStorage:
    enabled: true
    location: "./chronicle-data"
    retentionPeriod: "30d"
```

`RetentionPeriod` accepts a duration string input. `0` implies infinite retention, disabling file expiration.
For example:
`1s` for 1 second, `5m` for 5 minutes, `12h` for 12 hours, `7d` for one week, `365d` for one year, `0` for unbound retention.
Units shorter than seconds or longer than days, such as milliseconds and weeks, are not supported.

You can disable local storage by setting `localStorage.enabled` to `false`, and you can enable S3
storage by setting `S3Storage.enabled` to `true`. Enabling both is also acceptable,
and the server will store to both places. When using S3, you must also set the `S3Storage.Bucket`
parameter, like so:

``` yaml
config:
  s3Storage:
    enabled: true
    bucket: "posit-chronicle"
    prefix: ""
    profile: ""
    region: "us-east-2"
```

If you are running on EKS, we strongly suggest using [IAM Roles for Service
Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
to manage the credentials needed to access S3. In this scenario, once you have
[created an IAM
role](https://docs.aws.amazon.com/eks/latest/userguide/create-service-account-iam-policy-and-role.html),
you can use this role as an annotation on the existing Service Account:

``` yaml
serviceaccount:
  enabled: false
  # -- Additional annotations to add to the chronicle-server serviceaccount
  annotations: {
    eks.amazonaws.com/role-arn:  arn:aws:iam::123456789000:role/iam-role-name-here
  }
  # -- Additional labels to add to the chronicle-server serviceaccount
  labels: {}
```

If you are unable to use IAM Roles for Service Accounts, there are any number of
alternatives for injecting AWS credentials into a container. As a fallback,
the S3 storage config allows specifying a profile:

``` yaml
config:
  s3Storage:
    enabled: true
    bucket: "posit-chronicle"
    prefix: ""
    profile: "my-aws-account"
    region: "us-east-2"
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.http.listen | string | `":5252"` |  |
| config.https.certificate | string | `""` |  |
| config.https.enabled | bool | `false` |  |
| config.https.key | string | `""` |  |
| config.https.listen | string | `":443"` |  |
| config.localStorage.enabled | bool | `true` |  |
| config.localStorage.location | string | `"./chronicle-data"` |  |
| config.localStorage.retentionPeriod | string | `"30d"` |  |
| config.logging.serviceLog | string | `"STDOUT"` |  |
| config.logging.serviceLogFormat | string | `"TEXT"` |  |
| config.logging.serviceLogLevel | string | `"INFO"` |  |
| config.metrics.enabled | bool | `true` |  |
| config.profiling.enabled | bool | `false` |  |
| config.profiling.listen | string | `":3030"` |  |
| config.s3Storage.bucket | string | `"posit-chronicle"` |  |
| config.s3Storage.compactionEnabled | bool | `false` |  |
| config.s3Storage.enabled | bool | `false` |  |
| config.s3Storage.prefix | string | `""` |  |
| config.s3Storage.profile | string | `""` |  |
| config.s3Storage.region | string | `"us-east-2"` |  |
| config.tracing.address | string | `""` |  |
| config.tracing.enabled | bool | `false` |  |
| image.imagePullPolicy | string | `"Always"` |  |
| image.repository | string | `"ghcr.io/rstudio/chronicle"` |  |
| image.tag | string | `"latest"` |  |
| pod.affinity | object | `{}` | A map used verbatim as the pod's "affinity" definition |
| pod.annotations | object | `{}` | Additional annotations to add to the chronicle-server pods |
| pod.args[0] | string | `"start"` |  |
| pod.args[1] | string | `"-c"` |  |
| pod.args[2] | string | `"/opt/chronicle/config.gcfg"` |  |
| pod.command | string | `"/chronicle"` |  |
| pod.env | list | `[]` | Optional environment variables |
| pod.labels | object | `{}` | Additional labels to add to the chronicle-server pods |
| pod.nodeSelector | object | `{}` | A map used verbatim as the pod's "nodeSelector" definition |
| pod.rest.port | int | `5252` |  |
| pod.tolerations | list | `[]` | An array used verbatim as the pod's "tolerations" definition |
| replicas | int | `1` | The number of replica pods to maintain for this service |
| service..annotations | object | `{}` | Additional annotations to add to the chronicle-server service |
| service..labels | object | `{}` | Additional labels to add to the chronicle-server service |
| service..port | int | `80` | The port to use for the REST service |
| service..targetPort | int | `5252` | The port to forward REST requests to on the pod. Also see pod.port |
| serviceaccount.annotations | object | `{}` | Additional annotations to add to the chronicle-server serviceaccount |
| serviceaccount.create | bool | `false` |  |
| serviceaccount.labels | object | `{}` | Additional labels to add to the chronicle-server serviceaccount |
| storage.persistentVolumeSize | string | `"1Gi"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)

