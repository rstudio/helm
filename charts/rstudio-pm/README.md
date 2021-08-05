# rstudio-pm

Kubernetes deployment for RStudio Package Manager

![Version: 0.2.0-rc04](https://img.shields.io/badge/Version-0.2.0--rc04-informational?style=flat-square) ![AppVersion: 1.2.2.1-17](https://img.shields.io/badge/AppVersion-1.2.2.1--17-informational?style=flat-square)

## Disclaimer

> This chart is "beta" quality. It will likely undergo
> breaking changes without warning as it moves towards stability.

As a result, please:
- Ensure you "pin" the version of the helm chart that you are using. You can do
this using the `helm dependency` command and the associated "Chart.lock" files
or the `--version` flag. IMPORTANT: This protects you from breaking changes
- Before upgrading, to avoid breaking changes, use `helm diff upgrade` to check
for breaking changes
- Pay close attention to [`NEWS.md`](./NEWS.md) for updates on breaking
changes, as well as documentation below on how to use the chart

## Installing the Chart

To install the chart with the release name `my-release` at version 0.2.0-rc04:

```bash
helm repo add rstudio https://helm.rstudio.com
helm install my-release rstudio/rstudio-pm --version=0.2.0-rc04
```

## General Principles

- In most places, we opt to pass helm values over configmaps. We translate these into the valid `.gcfg` file format
required by rstudio-pm.

## Configuration File

The configuration values all take the form of usual helm values
so you can set the database password with something like:

```
... --set config.Postgres.Password=mypassword ...
```

The values are converted into configuration files in the necessary format via go-templating.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| args | bool | `false` | args is the pod's run arguments. By default, it uses the container's default |
| awsAccessKeyId | bool | `false` | awsAccessKeyId is the access key id for s3 access, used also to gate file creation |
| awsSecretAccessKey | string | `nil` | awsSecretAccessKey is the secret access key, needs to be filled if access_key_id is |
| command | bool | `false` | command is the pod's run command. By default, it uses the container's default |
| config | object | `{"HTTP":{"Listen":":4242"},"Launcher":{"AdminGroup":"root","ServerUser":"root"},"Metrics":{"Enabled":true}}` | config is a nested map of maps that generates the rstudio-pm.gcfg file |
| fullnameOverride | string | `""` | the full name of the release (can be overridden) |
| image.pullPolicy | string | `"IfNotPresent"` | the pullPolicy for the main pod image |
| image.repository | string | `"rstudio/rstudio-package-manager"` | the repository to use for the main pod image |
| image.tag | string | `""` | the tag to use for the main pod image |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts | string | `nil` |  |
| ingress.tls | list | `[]` |  |
| initContainers | bool | `false` | the initContainer spec that will be used verbatim |
| license.file | object | `{"contents":false,"mountPath":"/etc/rstudio-licensing","mountSubPath":false,"secret":false,"secretKey":"license.lic"}` | the file section is used for licensing with a license file |
| license.file.contents | bool | `false` | contents is an in-line license file |
| license.file.mountPath | string | `"/etc/rstudio-licensing"` | mountPath is the place the license file will be mounted into the container |
| license.file.mountSubPath | bool | `false` | mountSubPath is whether to mount the subPath for the file secret. -- It can be preferable _not_ to enable this, because then updates propagate automatically |
| license.file.secret | bool | `false` | secret is an existing secret with a license file in it |
| license.file.secretKey | string | `"license.lic"` | secretKey is the key for the secret to use for the license file |
| license.key | string | `nil` | key is the license to use |
| license.server | bool | `false` | server is the <hostname>:<port> for a license server |
| livenessProbe | object | `{"enabled":false,"failureThreshold":10,"initialDelaySeconds":10,"periodSeconds":5,"timeoutSeconds":2}` | livenessProbe is used to configure the container's livenessProbe |
| nameOverride | string | `""` | the name of the chart deployment (can be overridden) |
| pod.annotations | object | `{}` | annotations is a map of keys / values that will be added as annotations to the pods |
| pod.env | list | `[]` | env is an array of maps that is injected as-is into the "env:" component of the pod.container spec |
| pod.serviceAccountName | bool | `false` | serviceAccountName is a string representing the service account of the pod spec |
| pod.volumeMounts | list | `[]` | volumeMounts is an array of maps that is injected as-is into the "volumeMounts" component of the pod spec |
| pod.volumes | list | `[]` | volumes is an array of maps that is injected as-is into the "volumes:" component of the pod spec |
| readinessProbe | object | `{"enabled":true,"failureThreshold":3,"initialDelaySeconds":3,"periodSeconds":3,"successThreshold":1,"timeoutSeconds":1}` | readinessProbe is used to configure the container's readinessProbe |
| replicas | int | `1` | replicas is the number of replica pods to maintain for this service |
| resources | object | `{"limits":{"cpu":"2000m","enabled":false,"ephemeralStorage":"200Mi","memory":"4Gi"},"requests":{"cpu":"100m","enabled":false,"ephemeralStorage":"100Mi","memory":"2Gi"}}` | resources define requests and limits for the rstudio-pm pod |
| rstudioPMKey | bool | `false` | rstudioPMKey is the rstudio-pm key used for the RStudio Package Manager service |
| service.annotations | object | `{}` | The annotations for the service |
| service.nodePort | bool | `false` | The nodePort (for service type NodePort). If not provided, Kubernetes will decide one automatically |
| service.type | string | `"NodePort"` | The service type (NodePort, LoadBalancer, etc.) |
| sharedStorage.accessModes | list | `["ReadWriteMany"]` | accessModes defined for the storage PVC (represented as YAML) |
| sharedStorage.create | bool | `false` | whether to create the persistentVolumeClaim for shared storage |
| sharedStorage.path | string | `"/var/lib/rstudio-pm"` | the path to mount the sharedStorage claim within the pod |
| sharedStorage.requests.storage | string | `"10Gi"` | the volume of storage to request for this persistent volume claim |
| sharedStorage.storageClassName | bool | `false` | storageClassName - the type of storage to use. Must allow ReadWriteMany |
| startupProbe | object | `{"enabled":false,"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":1}` | startupProbe is used to configure the container's startupProbe |
| startupProbe.failureThreshold | int | `30` | failureThreshold * periodSeconds should be strictly > worst case startup time |
| strategy.rollingUpdate.maxSurge | string | `"100%"` |  |
| strategy.rollingUpdate.maxUnavailable | int | `0` |  |
| strategy.type | string | `"RollingUpdate"` |  |
| versionOverride | string | `""` | A Package Manager version to override the "tag" for the RStudio Package Manager image. Necessary until https://github.com/helm/helm/issues/8194 |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)

