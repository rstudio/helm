# RStudio Connect

![Version: 0.2.26](https://img.shields.io/badge/Version-0.2.26-informational?style=flat-square) ![AppVersion: 2022.03.2](https://img.shields.io/badge/AppVersion-2022.03.2-informational?style=flat-square)

#### _Official Helm chart for RStudio Connect_

Business Users and Collaborators use R and Python data products on [RStudio Connect](https://www.rstudio.com/products/connect/)
that are published by Data Scientists.

## Disclaimer

> This chart is "beta" quality. It will likely undergo
> breaking changes without warning as it moves towards stability.

As a result, please:
* Ensure you "pin" the version of the Helm chart that you are using. You can do
  this using the `helm dependency` command and the associated "Chart.lock" files
  or the `--version` flag. IMPORTANT: This protects you from breaking changes
* Before upgrading, to avoid breaking changes, use `helm diff upgrade` to check
  for breaking changes
* Pay close attention to [`NEWS.md`](./NEWS.md) for updates on breaking
  changes, as well as documentation below on how to use the chart

## Installing the Chart

To install the chart with the release name `my-release` at version 0.2.26:

```bash
helm repo add rstudio https://helm.rstudio.com
helm install my-release rstudio/rstudio-connect --version=0.2.26
```

## Required Configuration

This chart requires the following in order to function:

* A license key, license file, or address of a running license server. See the `license` configuration below.
* A Kubernetes [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) that contains the data directory for Connect.
  * If `sharedStorage.create` is set, a PVC that relies on the default storage class will be created to generate the PersistentVolume.
    Most Kubernetes environments do not have a default storage class that you can use with `ReadWriteMany` access mode out-of-the-box.
    In this case, we recommend you disable `sharedStorage.create` and create your own `PersistentVolume` and `PersistentVolumeClaim`, then
    mount them into the container by specifying the `pod.volumes` and `pod.volumeMounts` parameters, or by specifying your `PersistentVolumeClaim` using `sharedStorage.name` and `sharedStorage.mount`.
  * If you cannot use a `PersistentVolume` to properly mount your data directory, you'll need to mount your data in the container
    by using a regular [Kubernetes Volume](https://kubernetes.io/docs/concepts/storage/volumes), specified in `pod.volumes` and `pod.volumeMounts`.

## General Principles

- In most places, we opt to pass helm values over configmaps. We translate these into the valid `.gcfg` file format
required by rstudio-connect.
- rstudio-connect does not export many prometheus metrics on its own. Instead, we run a sidecar graphite exporter
  [as described here](https://support.rstudio.com/hc/en-us/articles/360044800273-Monitoring-RStudio-Team-Using-Prometheus-and-Graphite)

## Configuration File

The configuration values all take the form of usual helm values
so you can set the database password with something like:

```
... --set config.Postgres.Password=mypassword ...
```

The Helm `config` values are converted into the `rstudio-connect.gcfg` service configuration file via go-templating.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| args | list | `[]` | The pod's run arguments. By default, it uses the container's default |
| command | list | `[]` | The pod's run command. By default, it uses the container's default |
| config | object | [RStudio Connect Configuration Reference](https://docs.rstudio.com/connect/admin/appendix/configuration/) | A nested map of maps that generates the rstudio-connect.gcfg file |
| extraObjects | list | `[]` | Extra objects to deploy (value evaluated as a template) |
| fullnameOverride | string | `""` | The full name of the release (can be overridden) |
| image | object | `{"imagePullPolicy":"IfNotPresent","imagePullSecrets":[],"repository":"ghcr.io/rstudio/rstudio-connect","tag":""}` | Defines the RStudio Connect image to deploy |
| image.imagePullPolicy | string | `"IfNotPresent"` | The imagePullPolicy for the main pod image |
| image.imagePullSecrets | list | `[]` | an array of kubernetes secrets for pulling the main pod image from private registries |
| image.repository | string | `"ghcr.io/rstudio/rstudio-connect"` | The repository to use for the main pod image |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts | string | `nil` |  |
| ingress.ingressClassName | string | `""` | The ingressClassName for the ingress resource. Only used for clusters that support networking.k8s.io/v1 Ingress resources |
| ingress.tls | list | `[]` |  |
| initContainers | bool | `false` | The initContainer spec that will be used verbatim |
| launcher.contentInitContainer | object | `{"repository":"ghcr.io/rstudio/rstudio-connect-content-init","tag":""}` | Image definition for the RStudio Connect Content InitContainer |
| launcher.contentInitContainer.repository | string | `"ghcr.io/rstudio/rstudio-connect-content-init"` | The repository to use for the Content InitContainer image |
| launcher.contentInitContainer.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| launcher.customRuntimeYaml | bool | `false` | Optional. The runtime.yaml definition of Kubernetes runtime containers. Defaults to "false," which pulls in the default runtime.yaml file. If changing this value, be careful to include the images that you have already used. |
| launcher.enabled | bool | `false` | Whether to enable the launcher |
| launcher.launcherKubernetesProfilesConf | object | `{}` | User definition of launcher.kubernetes.profiles.conf for job customization |
| launcher.namespace | string | `""` | The namespace to launch sessions into. Uses the Release namespace by default |
| license.file | object | `{"contents":false,"mountPath":"/etc/rstudio-licensing","mountSubPath":false,"secret":false,"secretKey":"license.lic"}` | the file section is used for licensing with a license file |
| license.file.contents | bool | `false` | contents is an in-line license file |
| license.file.mountPath | string | `"/etc/rstudio-licensing"` | mountPath is the place the license file will be mounted into the container |
| license.file.mountSubPath | bool | `false` | mountSubPath is whether to mount the subPath for the file secret. -- It can be preferable _not_ to enable this, because then updates propagate automatically |
| license.file.secret | bool | `false` | secret is an existing secret with a license file in it |
| license.file.secretKey | string | `"license.lic"` | secretKey is the key for the secret to use for the license file |
| license.key | string | `nil` | key is the license to use |
| license.server | bool | `false` | server is the <hostname>:<port> for a license server |
| livenessProbe | object | `{"enabled":false,"failureThreshold":10,"httpGet":{"path":"/__ping__","port":3939},"initialDelaySeconds":10,"periodSeconds":5,"timeoutSeconds":2}` | Used to configure the container's livenessProbe. Only included if enabled = true |
| nameOverride | string | `""` | The name of the chart deployment (can be overridden) |
| pod.affinity | object | `{}` | A map used verbatim as the pod's "affinity" definition |
| pod.annotations | object | `{}` | Additional annotations to add to the rstudio-connect pods |
| pod.env | list | `[]` | An array of maps that is injected as-is into the "env:" component of the pod.container spec |
| pod.haste | bool | `true` | A helper that defines the RSTUDIO_CONNECT_HASTE environment variable |
| pod.labels | object | `{}` | Additional labels to add to the rstudio-connect pods |
| pod.serviceAccountName | bool | `false` | A string representing the service account of the pod spec |
| pod.sidecar | bool | `false` | An array of containers that will be run alongside the main pod |
| pod.volumeMounts | list | `[]` | An array of maps that is injected as-is into the "volumeMounts" component of the pod spec |
| pod.volumes | list | `[]` | An array of maps that is injected as-is into the "volumes:" component of the pod spec |
| prometheusExporter.enabled | bool | `true` | Whether the  prometheus exporter sidecar should be enabled |
| prometheusExporter.image.imagePullPolicy | string | `"IfNotPresent"` |  |
| prometheusExporter.image.repository | string | `"prom/graphite-exporter"` |  |
| prometheusExporter.image.tag | string | `"v0.9.0"` |  |
| rbac.clusterRoleCreate | bool | `false` | Whether to create the ClusterRole that grants access to the Kubernetes nodes API. This is used by the Launcher to get all of the IP addresses associated with the node that is running a particular job. In most cases, this can be disabled as the node's internal address is sufficient to allow proper functionality. |
| rbac.create | bool | `true` | Whether to create rbac. (also depends on launcher.enabled = true) |
| rbac.serviceAccount | object | `{"annotations":{},"create":true,"name":""}` | The serviceAccount to be associated with rbac (also depends on launcher.enabled = true) |
| readinessProbe | object | `{"enabled":true,"failureThreshold":3,"httpGet":{"path":"/__ping__","port":3939},"initialDelaySeconds":3,"periodSeconds":3,"successThreshold":1,"timeoutSeconds":1}` | Used to configure the container's readinessProbe. Only included if enabled = true |
| replicas | int | `1` | The number of replica pods to maintain for this service |
| resources.limits | object | `{"cpu":"2000m","enabled":false,"ephemeralStorage":"200Mi","memory":"2Gi"}` | Defines resource limits for the rstudio-connect pod |
| resources.requests | object | `{"cpu":"100m","enabled":false,"ephemeralStorage":"100Mi","memory":"1Gi"}` | Defines resource requests for the rstudio-connect pod |
| securityContext | object | `{"privileged":true}` | Values to set the `securityContext` for Connect pods. It must include "privileged: true" or "CAP_SYS_ADMIN" when launcher is not enabled. If launcher is enabled, this can be removed with `securityContext: null` |
| service.annotations | object | `{}` | Annotations that will be added onto the service |
| service.nodePort | bool | `false` | The nodePort to use when using service type NodePort. If not provided, Kubernetes will provide one automatically |
| service.port | int | `80` | The port to use for the Connect service |
| service.type | string | `"NodePort"` | The service type (LoadBalancer, NodePort, etc.) |
| sharedStorage.accessModes | list | `["ReadWriteMany"]` | A list of accessModes that are defined for the storage PVC (represented as YAML) |
| sharedStorage.create | bool | `false` | Whether to create the persistentVolumeClaim for shared storage |
| sharedStorage.mount | bool | `false` | Whether the persistentVolumeClaim should be mounted (even if not created) |
| sharedStorage.name | string | `""` | The name of the pvc. By default, computes a value from the release name |
| sharedStorage.path | string | `"/var/lib/rstudio-connect"` | The path to mount the sharedStorage claim within the pod |
| sharedStorage.requests.storage | string | `"10Gi"` | The volume of storage to request for this persistent volume claim |
| sharedStorage.storageClassName | bool | `false` | The type of storage to use. Must allow ReadWriteMany |
| startupProbe | object | `{"enabled":false,"failureThreshold":30,"httpGet":{"path":"/__ping__","port":3939},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":1}` | Used to configure the container's startupProbe. Only included if enabled = true |
| startupProbe.failureThreshold | int | `30` | failureThreshold * periodSeconds should be strictly > worst case startup time |
| strategy | object | `{"rollingUpdate":{"maxSurge":"100%","maxUnavailable":0},"type":"RollingUpdate"}` | Defines the update strategy for a deployment |
| versionOverride | string | `""` | A Connect version to override the "tag" for the RStudio Connect image and the Content Init image. Necessary until https://github.com/helm/helm/issues/8194 |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)

