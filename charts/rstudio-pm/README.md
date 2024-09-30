# Posit Package Manager

![Version: 0.5.35](https://img.shields.io/badge/Version-0.5.35-informational?style=flat-square) ![AppVersion: 2024.08.2](https://img.shields.io/badge/AppVersion-2024.08.2-informational?style=flat-square)

#### _Official Helm chart for Posit Package Manager_

IT Administrators use [Posit Package Manager](https://posit.co/products/enterprise/package-manager/) to control and manage
R and Python packages that Data Scientists need to create and share data products.

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

To install the chart with the release name `my-release` at version 0.5.34:

```{.bash}
helm repo add rstudio https://helm.rstudio.com
helm upgrade --install my-release rstudio/rstudio-pm --version=0.5.34
```

To explore other chart versions, look at:

```{.bash}
helm search repo rstudio/rstudio-pm -l
```

## Upgrade guidance

### 0.4.0

- When upgrading to version 0.4.0 or later, the Package Manager service moves from running as `root` to running as
  the `rstudio-pm` user (with `uid:gid` `999:999`).
- A `chown` of persistent storage may be required. The team is working to implement an automatic fix. To disable the automatic fix/hook, set `enableMigrations=false`.

## Required configuration

This chart requires the following in order to function:

* A license file. See the [Licensing](#licensing) section below for more details.
* A Kubernetes [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) that contains the data directory for Package Manager.
  * If `sharedStorage.create` is set, it creates a Persistent Volume Claim (PVC) that relies on the default storage class to generate the
    PersistentVolume.
    Most Kubernetes environments do not have a default storage class that you can use with `ReadWriteMany` access mode out-of-the-box.
    In this case, we recommend you disable `sharedStorage.create` and create your own `PersistentVolume` and `PersistentVolumeClaim`, then
    mount them into the container by specifying the `pod.volumes` and `pod.volumeMounts` parameters, or by specifying your `PersistentVolumeClaim` using `sharedStorage.name` and `sharedStorage.mount`.
  * If you cannot use a `PersistentVolume` to properly mount your data directory, mount your data in the container
    by using a regular [Kubernetes Volume](https://kubernetes.io/docs/concepts/storage/volumes), specified in `pod.volumes` and `pod.volumeMounts`.
  * Alternatively, S3 storage can be used. See the [S3 Configuration](#s3-configuration) section for details.

## Licensing

This chart supports activating the product using a *license file*.

We recommend storing a license file as a `Secret` and setting the `license.file.secret` and `license.file.secretKey` values accordingly.

First, create the secret declaratively with YAML or imperatively using the following command:

```{.bash}
kubectl create secret generic rstudio-pm-license --from-file=licenses/rstudio-pm.lic
```

Second, specify the following values:

```yaml
license:
  file:
    secret: rstudio-pm-license
    secretKey: rstudio-pm.lic
```

Alternatively, license files can be set during `helm install` with the following argument:

```{.bash}
--set-file license.file.contents=licenses/rstudio-pm.lic
```

## Database

Package Manager requires a PostgreSQL database when running in Kubernetes. You must configure a [valid connection URI and a password](https://docs.posit.co/rspm/admin/database/#database-postgres) for the product to function correctly. Both the connection URI and password may be specified in the `config` section of `values.yaml`. However, we recommend only adding the connection URI and putting the database password in a Kubernetes `Secret`, which can be [automatically set as an environment variable](#database-password).

### Database configuration

Add the following to your `values.yaml`, replacing the `URL` with your database details.

```yaml
config:
  Database:
    Provider: "Postgres"
  Postgres:
    URL: "postgres://<USERNAME>@<HOST>:<PORT>/<DATABASE>"
```

### Database password

First, create a `Secret` declaratively with YAML or imperatively using the following command (replacing with your actual password):

```bash
kubectl create secret generic rstudio-pm-database --from-literal=password=YOURPASSWORDHERE
```

Second, specify the following in your `values.yaml`:

```yaml
pod:
  env:
    - name: PACKAGEMANAGER_POSTGRES_PASSWORD
      valueFrom:
        secretKeyRef:
          name: rstudio-pm-database
          key: password
```

Alternatively, database passwords may be set during `helm install` with the following argument:

`--set config.Postgres.Password="<YOUR_PASSWORD_HERE>"`

## S3 configuration

Package Manager [can be configured to store its data in S3
buckets](https://docs.posit.co/rspm/admin/file-storage/file-storage/#data-destinations),
which eliminates the need to provision shared storage for multiple replicas. A
`values.yaml` file using S3 might contain something like the following:

``` yaml
config:
  Storage:
    Default: s3
  S3Storage:
    Bucket: your-s3-bucket
```

If you are running on EKS, we strongly suggest using [IAM Roles for Service
Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
to manage the credentials needed to access S3. In this scenario, once you have
[created an IAM
role](https://docs.aws.amazon.com/eks/latest/userguide/create-service-account-iam-policy-and-role.html),
you can use this role as an annotation on the existing Service Account:

``` yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789000:role/iam-role-name-here
```

If you are unable to use IAM Roles for Service Accounts, there are any number of
alternatives for injecting AWS credentials into a container. As a fallback, the
chart supports setting static credentials:

``` yaml
awsAccessKeyId: your-access-key-id
awsSecretAccessKey: your-secret-access-key
```

Bear in mind that static, long-lived credentials are the least secure option and
should be avoided if at all possible.

## General principles

- In most places, we opt to pass Helm values over configmaps. We translate these into the valid `.gcfg` file format
required by rstudio-pm.

## Configuration file

The configuration values all take the form of usual Helm values
so you can set the database password with something like:

```{.bash}
... --set config.Postgres.Password=mypassword ...
```

The Helm `config` values are converted into the `rstudio-pm.gcfg` service configuration file via go-templating.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | A map used verbatim as the pod's "affinity" definition |
| args | bool | `false` | args is the pod's run arguments. By default, it uses the container's default |
| awsAccessKeyId | bool | `false` | awsAccessKeyId is the access key id for s3 access, used also to gate file creation |
| awsSecretAccessKey | string | `nil` | awsSecretAccessKey is the secret access key, needs to be filled if access_key_id is |
| command | bool | `false` | command is the pod's run command. By default, it uses the container's default |
| config | object | `{"HTTP":{"Listen":":4242"},"Metrics":{"Enabled":true}}` | config is a nested map of maps that generates the rstudio-pm.gcfg file |
| enableMigration | bool | `true` | Enable migrations for shared storage (if necessary) using Helm hooks. |
| enableSandboxing | bool | `true` | Enable sandboxing of Git builds, which requires elevated security privileges for the Package Manager container. |
| extraContainers | list | `[]` | sidecar container list |
| extraObjects | list | `[]` | Extra objects to deploy (value evaluated as a template) |
| fullnameOverride | string | `""` | the full name of the release (can be overridden) |
| image.imagePullPolicy | string | `"IfNotPresent"` | the imagePullPolicy for the main pod image |
| image.imagePullSecrets | list | `[]` | an array of kubernetes secrets for pulling the main pod image from private registries |
| image.repository | string | `"rstudio/rstudio-package-manager"` | the repository to use for the main pod image |
| image.tag | string | `""` | the tag to use for the main pod image |
| image.tagPrefix | string | `"ubuntu2204-"` | A tag prefix for the server image (common selection: ubuntu2204-). Only used if tag is not defined |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts | string | `nil` |  |
| ingress.ingressClassName | string | `""` | The ingressClassName for the ingress resource. Only used for clusters that support networking.k8s.io/v1 Ingress resources |
| ingress.tls | list | `[]` |  |
| initContainers | bool | `false` | the initContainer spec that will be used verbatim |
| license.file | object | `{"contents":false,"mountPath":"/etc/rstudio-licensing","mountSubPath":false,"secret":false,"secretKey":"license.lic"}` | the file section is used for licensing with a license file |
| license.file.contents | bool | `false` | contents is an in-line license file |
| license.file.mountPath | string | `"/etc/rstudio-licensing"` | mountPath is the place the license file will be mounted into the container |
| license.file.mountSubPath | bool | `false` | It can be preferable _not_ to enable this, because then updates propagate automatically |
| license.file.secret | bool | `false` | secret is an existing secret with a license file in it |
| license.file.secretKey | string | `"license.lic"` | secretKey is the key for the secret to use for the license file |
| license.key | string | `nil` | key is the license to use |
| license.server | bool | `false` | server is the <hostname>:<port> for a license server |
| livenessProbe | object | `{"enabled":false,"failureThreshold":10,"httpGet":{"path":"/__ping__","port":4242},"initialDelaySeconds":10,"periodSeconds":5,"timeoutSeconds":2}` | livenessProbe is used to configure the container's livenessProbe |
| nameOverride | string | `""` | the name of the chart deployment (can be overridden) |
| nodeSelector | object | `{}` | A map used verbatim as the pod's "nodeSelector" definition |
| pod.annotations | object | `{}` | annotations is a map of keys / values that will be added as annotations to the pods |
| pod.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"fsGroup":999,"runAsNonRoot":true,"runAsUser":999,"seccompProfile":{"type":"{{ if .Values.enableSandboxing }}Unconfined{{ else }}RuntimeDefault{{ end }}"}}` | the [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for the main Package Manager container. Evaluated as a template. |
| pod.env | list | `[]` | env is an array of maps that is injected as-is into the "env:" component of the pod.container spec |
| pod.labels | object | `{}` | Additional labels to add to the rstudio-pm pods |
| pod.lifecycle | object | `{}` | Container [lifecycle hooks](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/) |
| pod.securityContext | object | `{}` | the [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for the pod |
| pod.serviceAccountName | string | `""` | Deprecated, use `serviceAccount.name` instead |
| pod.terminationGracePeriodSeconds | int | `120` | The termination grace period seconds allowed for the pod before shutdown |
| pod.volumeMounts | list | `[]` | volumeMounts is an array of maps that is injected as-is into the "volumeMounts" component of the pod spec |
| pod.volumes | list | `[]` | volumes is an array of maps that is injected as-is into the "volumes:" component of the pod spec |
| podDisruptionBudget | object | `{}` | Pod disruption budget |
| priorityClassName | string | `""` | The pod's priorityClassName |
| readinessProbe | object | `{"enabled":true,"failureThreshold":3,"httpGet":{"path":"/__ping__","port":4242},"initialDelaySeconds":3,"periodSeconds":3,"successThreshold":1,"timeoutSeconds":1}` | readinessProbe is used to configure the container's readinessProbe |
| replicas | int | `1` | replicas is the number of replica pods to maintain for this service |
| resources | object | `{"limits":{"cpu":"2000m","enabled":false,"ephemeralStorage":"200Mi","memory":"4Gi"},"requests":{"cpu":"100m","enabled":false,"ephemeralStorage":"100Mi","memory":"2Gi"}}` | resources define requests and limits for the rstudio-pm pod |
| rootCheckIsFatal | bool | `true` | Whether the check for root accounts in the config file is fatal. This is meant to simplify migration to the new helm chart version. |
| rstudioPMKey | bool | `false` | rstudioPMKey is the rstudio-pm key used for the RStudio Package Manager service |
| service.annotations | object | `{}` | Annotations for the service, for example to specify [an internal load balancer](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer) |
| service.clusterIP | string | `""` | The cluster-internal IP to use with `service.type` ClusterIP |
| service.loadBalancerIP | string | `""` | The external IP to use with `service.type` LoadBalancer, when supported by the cloud provider |
| service.nodePort | bool | `false` | The explicit nodePort to use for `service.type` NodePort. If not provided, Kubernetes will choose one automatically |
| service.port | int | `80` | The Service port. This is the port your service will run under. |
| service.type | string | `"ClusterIP"` | The service type, usually ClusterIP (in-cluster only) or LoadBalancer (to expose the service using your cloud provider's load balancer) |
| serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount, if any |
| serviceAccount.create | bool | `true` | Whether to create a [Service Account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) |
| serviceAccount.labels | object | `{}` | Labels for the ServiceAccount, if any |
| serviceAccount.name | string | When `serviceAccount.create` is `true` this defaults to the full name of the release | ServiceAccount to use, if any, or an explicit name for the one we create |
| serviceMonitor.additionalLabels | object | `{}` | additionalLabels normally includes the release name of the Prometheus Operator |
| serviceMonitor.enabled | bool | `false` | Whether to create a ServiceMonitor CRD for use with a Prometheus Operator |
| serviceMonitor.namespace | string | `""` | Namespace to create the ServiceMonitor in (usually the same as the one in which the Operator is running). Defaults to the release namespace |
| sharedStorage.accessModes | list | `["ReadWriteMany"]` | accessModes defined for the storage PVC (represented as YAML) |
| sharedStorage.annotations | object | `{"helm.sh/resource-policy":"keep"}` | Define the annotations for the Persistent Volume Claim resource |
| sharedStorage.create | bool | `false` | whether to create the persistentVolumeClaim for shared storage |
| sharedStorage.mount | bool | `false` | Whether the persistentVolumeClaim should be mounted (even if not created) |
| sharedStorage.name | string | `""` | The name of the pvc. By default, computes a value from the release name |
| sharedStorage.path | string | `"/var/lib/rstudio-pm"` | the path to mount the sharedStorage claim within the pod |
| sharedStorage.requests.storage | string | `"10Gi"` | the volume of storage to request for this persistent volume claim |
| sharedStorage.selector | object | `{}` | selector for PVC definition |
| sharedStorage.storageClassName | bool | `false` | storageClassName - the type of storage to use. Must allow ReadWriteMany |
| sharedStorage.volumeName | string | `""` | the volumeName passed along to the persistentVolumeClaim. Optional |
| startupProbe | object | `{"enabled":false,"failureThreshold":30,"httpGet":{"path":"/__ping__","port":4242},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":1}` | startupProbe is used to configure the container's startupProbe |
| startupProbe.failureThreshold | int | `30` | failureThreshold * periodSeconds should be strictly > worst case startup time |
| strategy | object | `{"rollingUpdate":{"maxSurge":"100%","maxUnavailable":0},"type":"RollingUpdate"}` | The update strategy used by the main service pod. |
| tolerations | list | `[]` | An array used verbatim as the pod's "tolerations" definition |
| topologySpreadConstraints | list | `[]` | An array used verbatim as the pod's "topologySpreadConstraints" definition |
| versionOverride | string | `""` | A Package Manager version to override the "tag" for the RStudio Package Manager image. Necessary until https://github.com/helm/helm/issues/8194 |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)

