# Posit Connect

![Version: 0.7.17](https://img.shields.io/badge/Version-0.7.17-informational?style=flat-square) ![AppVersion: 2024.11.0](https://img.shields.io/badge/AppVersion-2024.11.0-informational?style=flat-square)

#### _Official Helm chart for Posit Connect_

Business Users and Collaborators use R and Python data products on [Posit Connect](https://posit.co/products/enterprise/connect/)
that are published by Data Scientists.

## Best practices

Helm charts are very useful tools for deploying resources into Kubernetes, however, they do require
some familiarity with kubernetes and `helm` itself. Please ensure you have adequate training and
IT support before deploying these charts into production environments. Reach out to your account representative
if you need help deciding whether Helm is a good choice for your deployment.

To ensure reproducibility in your environment and insulate yourself from future changes, please:

* "Pin" the version of the Helm chart that you are using. You can do
  this using the:
    * `helm dependency` command and the associated "Chart.lock" files _or_
    * the `--version` flag.

      :::{.callout-important}
      This protects you from breaking changes**
      :::

* Before upgrading check for breaking changes using `helm-diff` plugin and `helm diff upgrade`.
* Read [`NEWS.md`](./NEWS.md) for updates on breaking changes and the documentation below on how to use the chart.

## Installing the chart

To install the chart with the release name `my-release` at version 0.7.17:

```{.bash}
helm repo add rstudio https://helm.rstudio.com
helm upgrade --install my-release rstudio/rstudio-connect --version=0.7.17
```

To explore other chart versions, look at:

```{.bash}
helm search repo rstudio/rstudio-connect -l
```

## Required configuration

To function, this chart requires the following:

* A license file. See the [Licensing](#licensing) section below for more details.
* A Kubernetes [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) that contains the data directory for Connect.
  * If `sharedStorage.create` is set, it creates a Persistent Volume Claim (PVC) that relies on the default storage class to generate the
    PersistentVolume.
    Most Kubernetes environments do not have a default storage class that you can use with `ReadWriteMany` access mode out-of-the-box.
    In this case, we recommend you disable `sharedStorage.create` and create your own `PersistentVolume` and `PersistentVolumeClaim`, then
    mount them into the container by specifying the `pod.volumes` and `pod.volumeMounts` parameters, or by specifying your `PersistentVolumeClaim` using `sharedStorage.name` and `sharedStorage.mount`.
  * If you cannot use a `PersistentVolume` to properly mount your data directory, mount your data in the container
    by using a regular [Kubernetes Volume](https://kubernetes.io/docs/concepts/storage/volumes), specified in `pod.volumes` and `pod.volumeMounts`.

## Licensing

This chart supports activating the product using a *license file*.

We recommend storing a license file as a `Secret` and setting the `license.file.secret` and `license.file.secretKey` values accordingly.

First, create the secret declaratively with YAML or imperatively using the following command:

```{.bash}
kubectl create secret generic rstudio-connect-license --from-file=licenses/rstudio-connect.lic
```

Second, specify the following values:

```yaml
license:
  file:
    secret: rstudio-connect-license
    secretKey: rstudio-connect.lic
```

Alternatively, license files can be set during `helm install` with the following argument:

```{.bash}
--set-file license.file.contents=licenses/rstudio-connect.lic
```

## Database

Connect requires a PostgreSQL database when running in Kubernetes. You must configure a [valid connection URI and a password](https://docs.posit.co/connect/admin/database/postgres/) for the product to function correctly. Both the connection URI and password may be specified in the `config` section of `values.yaml`. However, we recommend only adding the connection URI and putting the database password in a Kubernetes `Secret`, which can be [automatically set as an environment variable](#database-password).

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
kubectl create secret generic rstudio-connect-database --from-literal=password=YOURPASSWORDHERE
```

Second, specify the following in your `values.yaml`:

```yaml
pod:
  env:
    - name: CONNECT_POSTGRES_PASSWORD
      valueFrom:
        secretKeyRef:
          name: rstudio-connect-database
          key: password
```

Alternatively, database passwords may be set during `helm install` with the following argument:

`--set config.Postgres.Password="<YOUR_PASSWORD_HERE>"`

## General principles

- In most places, we opt to pass Helm values over configmaps. We translate these into the valid `.gcfg` file format
required by rstudio-connect.
- rstudio-connect does not export many prometheus metrics on its own. Instead, we run a sidecar graphite exporter
  [as described here](https://support.rstudio.com/hc/en-us/articles/360044800273-Monitoring-RStudio-Team-Using-Prometheus-and-Graphite)

## Configuration file

The configuration values all take the form of usual Helm values
so you can set the database password with something like:

```{.bash}
... --set config.Postgres.Password=mypassword ...
```

The Helm `config` values are converted into the `rstudio-connect.gcfg` service configuration file via go-templating.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | A map used verbatim as the pod's "affinity" definition |
| args | list | `[]` | The pod's run arguments. By default, it uses the container's default |
| command | list | `[]` | The pod's run command. By default, it uses the container's default |
| config | object | [Posit Connect Configuration Reference](https://docs.posit.co/connect/admin/appendix/off-host/helm-reference/) | A nested map of maps that generates the rstudio-connect.gcfg file |
| extraObjects | list | `[]` | Extra objects to deploy (value evaluated as a template) |
| fullnameOverride | string | `""` | The full name of the release (can be overridden) |
| image | object | `{"imagePullPolicy":"IfNotPresent","imagePullSecrets":[],"repository":"ghcr.io/rstudio/rstudio-connect","tag":"","tagPrefix":"ubuntu2204-"}` | Defines the Posit Connect image to deploy |
| image.imagePullPolicy | string | `"IfNotPresent"` | The imagePullPolicy for the main pod image |
| image.imagePullSecrets | list | `[]` | an array of kubernetes secrets for pulling the main pod image from private registries |
| image.repository | string | `"ghcr.io/rstudio/rstudio-connect"` | The repository to use for the main pod image |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| image.tagPrefix | string | `"ubuntu2204-"` | A tag prefix for the server image (common selections: jammy-, ubuntu2204-). Only used if tag is not defined |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts | string | `nil` |  |
| ingress.ingressClassName | string | `""` | The ingressClassName for the ingress resource. Only used for clusters that support networking.k8s.io/v1 Ingress resources |
| ingress.tls | list | `[]` |  |
| initContainers | bool | `false` | The initContainer spec that will be used verbatim |
| launcher.additionalRuntimeImages | list | `[]` | Optional. Additional images to append to the end of the "launcher.customRuntimeYaml" (in the "images" key). If `customRuntimeYaml` is a "map", then "additionalRuntimeImages" will only be used if it is a "list". |
| launcher.customRuntimeYaml | string | `"base"` | Optional. The runtime.yaml definition of Kubernetes runtime containers. Defaults to "base", which pulls in the default runtime.yaml file. If changing this value, be careful to include the images that you have already used. If set to "pro", will pull in the "pro" versions of the default runtime images (i.e. including the pro drivers at the cost of a larger image). Starting with Connect v2023.05.0, this configuration is used to bootstrap the initial set of execution environments the first time the server starts. If any execution environments already exist in the database, these values are ignored; execution environments are not created or modified during subsequent restarts. |
| launcher.defaultInitContainer | object | `{"enabled":true,"imagePullPolicy":"","repository":"ghcr.io/rstudio/rstudio-connect-content-init","resources":{},"securityContext":{},"tag":"","tagPrefix":"ubuntu2204-"}` | Image definition for the default Posit Connect Content InitContainer |
| launcher.defaultInitContainer.enabled | bool | `true` | Whether to enable the defaultInitContainer. If disabled, you must ensure that the session components are available another way. |
| launcher.defaultInitContainer.imagePullPolicy | string | `""` | The imagePullPolicy for the default initContainer |
| launcher.defaultInitContainer.repository | string | `"ghcr.io/rstudio/rstudio-connect-content-init"` | The repository to use for the Content InitContainer image |
| launcher.defaultInitContainer.resources | object | `{}` | Optional resources for the default initContainer |
| launcher.defaultInitContainer.securityContext | object | `{}` | The securityContext for the default initContainer |
| launcher.defaultInitContainer.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| launcher.defaultInitContainer.tagPrefix | string | `"ubuntu2204-"` | A tag prefix for the Content InitContainer image (common selections: jammy-, ubuntu2204-). Only used if tag is not defined |
| launcher.enabled | bool | `false` | Whether to enable the launcher |
| launcher.extraTemplates | object | `{}` | extra templates to render in the template directory. |
| launcher.includeDefaultTemplates | bool | `true` | whether to include the default `job.tpl` and `service.tpl` files included with the chart |
| launcher.includeTemplateValues | bool | `true` | whether to include the templateValues rendering process |
| launcher.launcherKubernetesProfilesConf | object | `{}` | User definition of launcher.kubernetes.profiles.conf for job customization |
| launcher.namespace | string | `""` | The namespace to launch sessions into. Uses the Release namespace by default |
| launcher.templateValues | object | `{"job":{"annotations":{},"labels":{}},"pod":{"affinity":{},"annotations":{},"command":[],"containerSecurityContext":{},"defaultSecurityContext":{},"env":[],"extraContainers":[],"hostAliases":[],"imagePullPolicy":"","imagePullSecrets":[],"initContainers":[],"labels":{},"nodeSelector":{},"priorityClassName":"","securityContext":{},"serviceAccountName":"","tolerations":[],"volumeMounts":[],"volumes":[]},"service":{"annotations":{},"labels":{},"type":"ClusterIP"}}` | Values to pass along to the Posit Connect session templating process |
| launcher.templateValues.pod.command | list | `[]` | command for all pods. This is really not something we should expose and will be removed once we have a better option |
| launcher.useTemplates | bool | `true` | Whether to use launcher templates when launching sessions. Defaults to true |
| license.file | object | `{"contents":false,"mountPath":"/etc/rstudio-licensing","mountSubPath":false,"secret":false,"secretKey":"license.lic"}` | the file section is used for licensing with a license file |
| license.file.contents | bool | `false` | contents is an in-line license file |
| license.file.mountPath | string | `"/etc/rstudio-licensing"` | mountPath is the place the license file will be mounted into the container |
| license.file.mountSubPath | bool | `false` | It can be preferable _not_ to enable this, because then updates propagate automatically |
| license.file.secret | bool | `false` | secret is an existing secret with a license file in it |
| license.file.secretKey | string | `"license.lic"` | secretKey is the key for the secret to use for the license file |
| license.key | string | `nil` | key is the license to use |
| license.server | bool | `false` | server is the <hostname>:<port> for a license server |
| livenessProbe | object | `{"enabled":false,"failureThreshold":10,"httpGet":{"path":"/__ping__","port":3939},"initialDelaySeconds":10,"periodSeconds":5,"timeoutSeconds":2}` | Used to configure the container's livenessProbe. Only included if enabled = true |
| nameOverride | string | `""` | The name of the chart deployment (can be overridden) |
| nodeSelector | object | `{}` | A map used verbatim as the pod's "nodeSelector" definition |
| pod.affinity | object | `{}` | A map used verbatim as the pod's "affinity" definition |
| pod.annotations | object | `{}` | Additional annotations to add to the rstudio-connect pods |
| pod.env | list | `[]` | An array of maps that is injected as-is into the "env:" component of the pod.container spec |
| pod.haste | bool | `true` | A helper that defines the RSTUDIO_CONNECT_HASTE environment variable |
| pod.hostAliases | list | `[]` | Array of hostnames to supply to the main pod |
| pod.labels | object | `{}` | Additional labels to add to the rstudio-connect pods |
| pod.port | int | `3939` | The containerPort used by the main pod container |
| pod.securityContext | object | `{}` | Values to set the `securityContext` for the connect pod |
| pod.sidecar | bool | `false` | An array of containers that will be run alongside the main pod |
| pod.terminationGracePeriodSeconds | int | `120` | The termination grace period seconds allowed for the pod before shutdown |
| pod.volumeMounts | list | `[]` | An array of maps that is injected as-is into the "volumeMounts" component of the pod spec |
| pod.volumes | list | `[]` | An array of maps that is injected as-is into the "volumes:" component of the pod spec |
| podDisruptionBudget | object | `{}` | Pod disruption budget |
| priorityClassName | string | `""` | The pod's priorityClassName |
| prometheus.enabled | bool | `true` | The parent setting for whether to enable prometheus metrics. Default is to use the built-in product exporter |
| prometheus.legacy | bool | `false` | Whether to enable the legacy prometheusExporter INSTEAD OF the built-in product exporter. If you change this to `true`, please let us know why! Requires prometheusExporter.enabled=true too |
| prometheus.port | int | `3232` | The port that prometheus will listen on. If legacy=true, then this will be hard-coded to 9108 |
| prometheusExporter.enabled | bool | `true` | DEPRECATED. Whether the  prometheus exporter sidecar should be enabled. See prometheus.enabled instead. |
| prometheusExporter.image.imagePullPolicy | string | `"IfNotPresent"` |  |
| prometheusExporter.image.repository | string | `"prom/graphite-exporter"` |  |
| prometheusExporter.image.tag | string | `"v0.9.0"` |  |
| prometheusExporter.mappingYaml | string | `nil` | Yaml that defines the graphite exporter mapping. null by default, which uses the embedded / default mapping yaml file |
| prometheusExporter.resources | object | `{}` | resource specification for the prometheus exporter sidecar |
| prometheusExporter.securityContext | object | `{}` | securityContext for the prometheus exporter sidecar |
| rbac.clusterRoleCreate | bool | `false` | Whether to create the ClusterRole that grants access to the Kubernetes nodes API. This is used by the Launcher to get all of the IP addresses associated with the node that is running a particular job. In most cases, this can be disabled as the node's internal address is sufficient to allow proper functionality. |
| rbac.create | bool | `true` | Whether to create rbac. (also depends on launcher.enabled = true) |
| rbac.serviceAccount | object | `{"annotations":{},"create":true,"labels":{},"name":""}` | The serviceAccount to be associated with rbac (also depends on launcher.enabled = true) |
| readinessProbe | object | `{"enabled":true,"failureThreshold":3,"httpGet":{"path":"/__ping__","port":3939},"initialDelaySeconds":3,"periodSeconds":3,"successThreshold":1,"timeoutSeconds":1}` | Used to configure the container's readinessProbe. Only included if enabled = true |
| replicas | int | `1` | The number of replica pods to maintain for this service |
| resources | object | `{}` | Defines resources for the rstudio-connect container |
| securityContext | object | `{"privileged":true}` | Values to set the `securityContext` for Connect container. It must include "privileged: true" or "CAP_SYS_ADMIN" when launcher is not enabled. If launcher is enabled, this can be removed with `securityContext: null` |
| service.annotations | object | `{}` | Annotations for the service, for example to specify [an internal load balancer](https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer) |
| service.clusterIP | string | `""` | The cluster-internal IP to use with `service.type` ClusterIP |
| service.loadBalancerIP | string | `""` | The external IP to use with `service.type` LoadBalancer, when supported by the cloud provider |
| service.nodePort | bool | `false` | The explicit nodePort to use for `service.type` NodePort. If not provided, Kubernetes will choose one automatically |
| service.port | int | `80` | The port to use for the Connect service |
| service.targetPort | int | `3939` | The port to forward to on the Connect pod. Also see pod.port |
| service.type | string | `"ClusterIP"` | The service type, usually ClusterIP (in-cluster only) or LoadBalancer (to expose the service using your cloud provider's load balancer) |
| serviceMonitor.additionalLabels | object | `{}` | additionalLabels normally includes the release name of the Prometheus Operator |
| serviceMonitor.enabled | bool | `false` | Whether to create a ServiceMonitor CRD for use with a Prometheus Operator |
| serviceMonitor.namespace | string | `""` | Namespace to create the ServiceMonitor in (usually the same as the one in which the Prometheus Operator is running). Defaults to the release namespace |
| sharedStorage.accessModes | list | `["ReadWriteMany"]` | A list of accessModes that are defined for the storage PVC (represented as YAML) |
| sharedStorage.annotations | object | `{"helm.sh/resource-policy":"keep"}` | Annotations for the Persistent Volume Claim |
| sharedStorage.create | bool | `false` | Whether to create the persistentVolumeClaim for shared storage |
| sharedStorage.mount | bool | `false` | Whether the persistentVolumeClaim should be mounted (even if not created) |
| sharedStorage.mountContent | bool | `true` | Whether the persistentVolumeClaim should be mounted to the content pods created by the Launcher |
| sharedStorage.name | string | `""` | The name of the pvc. By default, computes a value from the release name |
| sharedStorage.path | string | `"/var/lib/rstudio-connect"` | The path to mount the sharedStorage claim within the Connect pod |
| sharedStorage.requests.storage | string | `"10Gi"` | The volume of storage to request for this persistent volume claim |
| sharedStorage.selector | object | `{}` | selector for PVC definition |
| sharedStorage.storageClassName | bool | `false` | The type of storage to use. Must allow ReadWriteMany |
| sharedStorage.subPath | string | `""` | an optional subPath for the volume mount |
| sharedStorage.volumeName | string | `""` | the volumeName passed along to the persistentVolumeClaim. Optional |
| startupProbe | object | `{"enabled":false,"failureThreshold":30,"httpGet":{"path":"/__ping__","port":3939},"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":1}` | Used to configure the container's startupProbe. Only included if enabled = true |
| startupProbe.failureThreshold | int | `30` | failureThreshold * periodSeconds should be strictly > worst case startup time |
| strategy | object | `{"rollingUpdate":{"maxSurge":"100%","maxUnavailable":0},"type":"RollingUpdate"}` | Defines the update strategy for a deployment |
| tolerations | list | `[]` | An array used verbatim as the pod's "tolerations" definition |
| topologySpreadConstraints | list | `[]` | An array used verbatim as the pod's "topologySpreadConstraints" definition |
| versionOverride | string | `""` | A Connect version to override the "tag" for the Posit Connect image and the Content Init image. Necessary until https://github.com/helm/helm/issues/8194 |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)

