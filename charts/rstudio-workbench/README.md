# rstudio-workbench

Kubernetes deployment for RStudio Workbench

![Version: 0.4.0-rc11](https://img.shields.io/badge/Version-0.4.0--rc11-informational?style=flat-square) ![AppVersion: 1.4.1717-3](https://img.shields.io/badge/AppVersion-1.4.1717--3-informational?style=flat-square)

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

To install the chart with the release name `my-release` at version 0.4.0-rc11:

```bash
helm repo add rstudio https://helm.rstudio.com
helm install my-release rstudio/rstudio-workbench --version=0.4.0-rc11
```

## Required Configuration

This chart requires the following in order to function:

* A license key, license file, or address of a running license server. See the `license` configuration below.
* A Kubernetes [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) that contains the home directory for users.
  * If `homeStorage.create` is set, a PVC that relies on the default storage class will be created to generate the PersistentVolume.
    Most Kubernetes environments do not have a default storage class that you can use with `ReadWriteMany` access mode out-of-the-box.
    In this case, we recommend you disable `homeStorage.create` and  create your own `PersistentVolume` and `PersistentVolumeClaim`, then mount them
    into the container by specifying the `pod.volumes` and `pod.volumeMounts` parameters.
  * If you cannot use a `PersistentVolume` to properly mount your users' home directories, you'll need to mount your data in the container
    by using a regular [Kubernetes Volume](https://kubernetes.io/docs/concepts/storage/volumes/#nfs), specified in `pod.volumes` and `pod.volumeMounts`.
  * If you cannot use a `Volume` to mount the directories, you'll need to manually mount them during container startup  with a mechanism similar to what
    is described below for joining to auth domains.
  * If not using `homeStorage.create`, you'll need to configure `config.serverDcf.launcher-mounts` to ensure that the correct mounts are used when users create new sessions.
* If using load balancing (by setting `replicas > 1`), you will need similar storage defined for `sharedStorage` to store shared project configuration.
* A method to join the deployed `rstudio-workbench` container to your auth domain. The default `rstudio/rstudio-server-pro` image does not contain a way to join domains.
  We recommend creating your own Docker image that derives from this base image to provide domain joining that fits your needs. Your image can then use a process supervisor
  like [supervisord](http://supervisord.org/) to run multiple processes: in the most common case, `rstudio-server`, `rstudio-launcher`, and `sssd`. See
  [here](https://github.com/rstudio/sol-eng-demo-server/tree/main/helper/workbench) for an example of this.

## Recommended Configuration

In addition to the above required configuration, we recommend setting the following to ensure a reliable deployment:

* Set the `launcherPem` value to ensure that it stays the same between releases.
  This will ensure that users can continue to properly connect to older sessions even after a redeployment of the chart. See the
  [RSW Admin Guide](https://docs.rstudio.com/ide/server-pro/job-launcher.html#authentication) for details on generating the file.
* Set the `global.secureCookieKey` so that user authentication continues to work between deployments. A valid value can be obtained
  by simply running the `uuid` command.
* Some use-cases may require special PAM profiles to run. By default, no PAM profiles other than the basic `auth` profile will be used to authenticate users.
  If this is not sufficient then you will need to add your PAM profiles into the container (similar to adding `sssd.conf` as specified above).

## General Principles

- In most places, we opt to pass helm values over configmaps. We translate these into the valid `.ini` or `.dcf` file formats
required by RStudio Server Pro. Those config files and their mount locations are below.
- If you need to modify the jobs launched by RStudio Server Pro, you want to use `job-json-overrides`. There is a section on this below
  and [a support article](https://support.rstudio.com/hc/en-us/articles/360051652094-Using-Job-Json-Overrides-with-RStudio-Server-Pro-and-Kubernetes)
  on the topic in general.
- If you are running in an HA environment, there is [an experimental sidecar container](https://hub.docker.com/r/colearendt/rstudio-load-balancer-manager)
  that maintains the `load-balancer` file and HUPs the rstudio-server service.
- The prestart script for RStudio Server is highly customized to:
  - Get the service account information off of the RStudio Server pod for use in launching jobs
  - Generate `launcher.pub` as needed (if `launcher.pem` is provided). If it is not provided,
  the helm chart will generate it automatically but this information will be lost for subsequent deployments and
  can cause users to be locked out sessions started by a previous deployment.
- RStudio Server Pro does not export prometheus metrics on its own. Instead, we run a sidecar graphite exporter
  [as described here](https://support.rstudio.com/hc/en-us/articles/360044800273-Monitoring-RStudio-Team-Using-Prometheus-and-Graphite)

## Configuration files

These configuration values all take the form of usual helm values
so you can set the database password with something like:

```
... --set config.secret.database\.conf.password=mypassword ...
```

The files are converted into configuration files in the necessary format via go-templating.

The names of files are dynamically used, so you can usually add new files as needed. Beware that
some files have default values, so moving them can have adverse effects. Also, if you use a different
mounting paradigm, you will need to change the `XDG_CONFIG_DIRS` environment variable

- Session Configuration
  - These configuration files are mounted into the server and
    will ideally be mounted into the session pods as well.
  - `repos.conf`, `rsession.conf`, `notifications.conf`
  - located in the `config.session.<< name of file >>` helm values
  - mounted at `/mnt/session-configmap/rstudio/`
- Secret Configuration
  - These configuration files are mounted into the server with more restrictive permissions
  - `database.conf`, `launcher.pem`
  - They are located in the `config.secret.<< name of file >>` helm values
  - mounted at `/mnt/secret-configmap/rstudio/`
- Server Configuration
  - These configuration files are mounted into the server (.ini file format)
  - `rserver.conf`, `launcher.conf`, `jupyter.conf`, `launcher.kubernetes.profiles.conf`, `logging.conf`
  - They are located at `config.server.<< name of file >>` helm values
  - mounted at `/mnt/configmap/rstudio/`
- Server DCF Configuration
  - These configuration files are mounted into the server (.dcf file format)
  - `launcher-mounts`, `launcher-env`
  - They are located at `config.serverDcf.<< name of file >>` helm values
  - included at `/mnt/configmap/rstudio/`
- Load Balancer file
  - If `replicas > 1` then we create and maintain a load balancer file at `/mnt/load-balancer/rstudio/`
  - This is maintained by [a sidecar](https://hub.docker.com/r/colearendt/rstudio-load-balancer-manager) (written in bash)
  that queries the Kubernetes API for other RStudio pods
- Prestart
  - This is provided by the helm chart in a configmap
  - It is mounted into the pod at `/scripts/`
- Job Json Overrides
  - If you want to customize the job launch process, you will need to edit a few items:
    - Set the `job-json-overrides` config values in `config.server.launcher\.kubernetes\.profiles\.conf`
    - Set the `jobJsonOverridesFiles` helm value to be a map of files, which are translated verbatim from YAML to JSON
    - These are written to `/mnt/job-json-overrides/<< key / file name >>`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| args | list | `["/scripts/prestart.bash","/usr/local/bin/startup.sh"]` | args is the pod container's run arguments. By default, it uses a kubernetes-specific prestart script that exec's the default container startup script. |
| command | list | `["tini","-s","--"]` | command is the pod container's run command. |
| config.profiles | object | `{}` |  |
| config.secret."database.conf" | object | `{}` |  |
| config.server."jupyter.conf".default-session-cluster | string | `"Kubernetes"` |  |
| config.server."jupyter.conf".jupyter-exe | string | `"/opt/python/3.6.5/bin/jupyter"` |  |
| config.server."jupyter.conf".labs-enabled | int | `1` |  |
| config.server."jupyter.conf".notebooks-enabled | int | `1` |  |
| config.server."launcher.conf".cluster.name | string | `"Kubernetes"` |  |
| config.server."launcher.conf".cluster.type | string | `"Kubernetes"` |  |
| config.server."launcher.conf".server.address | string | `"127.0.0.1"` |  |
| config.server."launcher.conf".server.admin-group | string | `"rstudio-server"` |  |
| config.server."launcher.conf".server.authorization-enabled | int | `1` |  |
| config.server."launcher.conf".server.enable-debug-logging | int | `1` |  |
| config.server."launcher.conf".server.port | int | `5559` |  |
| config.server."launcher.conf".server.server-user | string | `"rstudio-server"` |  |
| config.server."launcher.conf".server.thread-pool-size | int | `4` |  |
| config.server."logging.conf" | object | `{}` |  |
| config.server."rserver.conf".admin-enabled | int | `1` |  |
| config.server."rserver.conf".launcher-address | string | `"127.0.0.1"` |  |
| config.server."rserver.conf".launcher-default-cluster | string | `"Kubernetes"` |  |
| config.server."rserver.conf".launcher-port | int | `5559` |  |
| config.server."rserver.conf".launcher-sessions-callback-address | string | `"http://127.0.0.1:8787"` |  |
| config.server."rserver.conf".launcher-sessions-enabled | int | `1` |  |
| config.server."rserver.conf".monitor-graphite-client-id | string | `"rstudio"` |  |
| config.server."rserver.conf".monitor-graphite-enabled | int | `1` |  |
| config.server."rserver.conf".monitor-graphite-host | string | `"127.0.0.1"` |  |
| config.server."rserver.conf".monitor-graphite-port | int | `9109` |  |
| config.server."rserver.conf".server-health-check-enabled | int | `1` |  |
| config.server."rserver.conf".server-project-sharing | int | `1` |  |
| config.server."rserver.conf".www-port | int | `8787` |  |
| config.serverDcf.launcher-mounts | list | `[]` |  |
| config.session."notifications.conf" | object | `{}` |  |
| config.session."repos.conf".CRAN | string | `"https://packagemanager.rstudio.com/cran/__linux__/bionic/latest"` |  |
| config.session."repos.conf".RSPM | string | `"https://packagemanager.rstudio.com/cran/__linux__/bionic/latest"` |  |
| config.session."rsession.conf" | object | `{}` |  |
| dangerRegenerateAutomatedValues | bool | `false` |  |
| fullnameOverride | string | `""` | the full name of the release (can be overridden) |
| global.secureCookieKey | string | `""` |  |
| homeStorage.accessModes | list | `["ReadWriteMany"]` | accessModes defined for the storage PVC (represented as YAML) |
| homeStorage.create | bool | `false` | whether to create the persistentVolumeClaim for homeStorage |
| homeStorage.path | string | `"/home"` | the path to mount the homeStorage claim within the pod |
| homeStorage.requests.storage | string | `"10Gi"` | the volume of storage to request for this persistent volume claim |
| homeStorage.storageClassName | bool | `false` | storageClassName - the type of storage to use. Must allow ReadWriteMany |
| image.imagePullPolicy | string | `"IfNotPresent"` | the imagePullPolicy for the main pod image |
| image.repository | string | `"rstudio/rstudio-workbench"` | the repository to use for the main pod image |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts | string | `nil` |  |
| ingress.tls | list | `[]` |  |
| initContainers | bool | `false` | the initContainer spec that will be used verbatim |
| jobJsonOverridesFiles | object | `{}` | jobJsonOverridesFiles is a map of maps. Each item in the map will become a file (named by the key), and the underlying object will be converted to JSON as the file's contents |
| launcher.enabled | bool | `true` | determines whether the launcher should be started in the container |
| launcher.namespace | string | `""` | allow customizing the namespace that sessions are launched into. Note RBAC and some config issues today |
| launcherPem | string | `""` |  |
| launcherPub | bool | `false` |  |
| license.file | object | `{"contents":false,"mountPath":"/etc/rstudio-licensing","mountSubPath":false,"secret":false,"secretKey":"license.lic"}` | the file section is used for licensing with a license file |
| license.file.contents | bool | `false` | contents is an in-line license file |
| license.file.mountPath | string | `"/etc/rstudio-licensing"` | mountPath is the place the license file will be mounted into the container |
| license.file.mountSubPath | bool | `false` | mountSubPath is whether to mount the subPath for the file secret. -- It can be preferable _not_ to enable this, because then updates propagate automatically |
| license.file.secret | bool | `false` | secret is an existing secret with a license file in it |
| license.file.secretKey | string | `"license.lic"` | secretKey is the key for the secret to use for the license file |
| license.key | string | `nil` | key is the license to use |
| license.server | bool | `false` | server is the <hostname>:<port> for a license server |
| livenessProbe | object | `{"enabled":false,"failureThreshold":10,"initialDelaySeconds":10,"periodSeconds":5,"timeoutSeconds":2}` | livenessProbe is used to configure the container's livenessProbe |
| loadBalancer.appLabelKey | string | `"app.kubernetes.io/name"` |  |
| loadBalancer.env | list | `[]` | env is an array of maps that is injected as-is into the "env:" component of the loadBalancer sidecar spec |
| loadBalancer.forceEnabled | bool | `false` | whether to force the loadBalancer to be enabled. Otherwise requires replicas > 1. Worth setting if you are HA but may only have one node |
| loadBalancer.image.imagePullPolicy | string | `"IfNotPresent"` | the imagePullPolicy to use for the side-car pod image |
| loadBalancer.image.repository | string | `"rstudio/rstudio-server-load-balancer-manager"` | the repository to use for the side-car pod image |
| loadBalancer.image.tag | string | `"2.2"` | the tag to use for the side-car pod image |
| loadBalancer.securityContext.capabilities.add[0] | string | `"SYS_PTRACE"` |  |
| loadBalancer.sleepDuration | int | `15` |  |
| nameOverride | string | `""` | the name of the chart deployment (can be overridden) |
| pod.annotations | object | `{}` | podAnnotations is a map of keys / values that will be added as annotations to the rstudio-pm pods |
| pod.env | list | `[]` | env is an array of maps that is injected as-is into the "env:" component of the pod.container spec |
| pod.sidecar | bool | `false` | sidecar is an array of containers that will be run alongside the main container |
| pod.volumeMounts | list | `[]` | volumeMounts is injected as-is into the "volumeMounts:" component of the pod.container spec |
| pod.volumes | list | `[]` | volumes is injected as-is into the "volumes:" component of the pod.container spec |
| prometheusExporter.enabled | bool | `true` | whether the  prometheus exporter sidecar should be enabled |
| prometheusExporter.image.imagePullPolicy | string | `"IfNotPresent"` |  |
| prometheusExporter.image.repository | string | `"prom/graphite-exporter"` |  |
| prometheusExporter.image.tag | string | `"v0.9.0"` |  |
| rbac.create | bool | `true` | Whether to create rbac. (also depends on launcher.enabled = true) |
| rbac.serviceAccount | object | `{"annotations":{},"create":true,"name":""}` | The serviceAccount to be associated with rbac (also depends on launcher.enabled = true) |
| readinessProbe | object | `{"enabled":true,"failureThreshold":3,"initialDelaySeconds":3,"periodSeconds":3,"successThreshold":1,"timeoutSeconds":1}` | readinessProbe is used to configure the container's readinessProbe |
| replicas | int | `1` | replicas is the number of replica pods to maintain for this service. Use 2 or more to enable HA |
| resources | object | `{"limits":{"cpu":"2000m","enabled":false,"ephemeralStorage":"200Mi","memory":"4Gi"},"requests":{"cpu":"100m","enabled":false,"ephemeralStorage":"100Mi","memory":"2Gi"}}` | resources define requests and limits for the rstudio-server pod |
| secureCookieKey | string | `""` |  |
| securityContext | object | `{}` |  |
| service.annotations | object | `{}` | annotations for the service definition |
| service.nodePort | bool | `false` | the nodePort to use when using service type NodePort. If not defined, Kubernetes will provide one automatically |
| service.type | string | `"NodePort"` | the service type (i.e. NodePort, LoadBalancer, etc.) |
| session.defaultConfigMount | bool | `true` |  |
| session.image.repository | string | `"rstudio/r-session-complete"` | The repository to use for the session image |
| session.image.tag | string | `""` | A tag override for the session image. Overrides the "tagPrefix" above, if set. Default tag is `{{ tagPrefix }}{{ version }}` |
| session.image.tagPrefix | string | `"bionic-"` | A tag prefix for session images (common selections: bionic-, centos-). Only used if tag is not defined |
| shareProcessNamespace | bool | `true` | whether to provide `shareProcessNamespace` to the pod. Important for HA environments for the sidecar |
| sharedStorage.accessModes | list | `["ReadWriteMany"]` | accessModes defined for the storage PVC (represented as YAML) |
| sharedStorage.create | bool | `false` | whether to create the persistentVolumeClaim for shared storage |
| sharedStorage.path | string | `"/var/lib/rstudio-server"` | the path to mount the sharedStorage claim within the pod |
| sharedStorage.requests.storage | string | `"10Gi"` | the volume of storage to request for this persistent volume claim |
| sharedStorage.storageClassName | bool | `false` | storageClassName - the type of storage to use. Must allow ReadWriteMany |
| startupProbe | object | `{"enabled":false,"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":1}` | startupProbe is used to configure the container's startupProbe |
| startupProbe.failureThreshold | int | `30` | failureThreshold * periodSeconds should be strictly > worst case startup time |
| strategy.rollingUpdate.maxSurge | string | `"100%"` |  |
| strategy.rollingUpdate.maxUnavailable | int | `0` |  |
| strategy.type | string | `"RollingUpdate"` |  |
| userCreate | bool | `false` | userCreate determines whether a user should be created at startup (if true) |
| userName | string | `"rstudio"` | userName determines the username of the created user |
| userPassword | string | `"rstudio"` | userPassword determines the password of the created user |
| userUid | string | `"10000"` | userUid determines the UID of the created user |
| versionOverride | string | `""` | A Workbench version to override the "tag" for the RStudio Workbench image and the session images. Necessary until https://github.com/helm/helm/issues/8194 |
| xdgConfigDirs | string | `"/mnt/dynamic:/mnt/session-configmap:/mnt/secret-configmap:/mnt/configmap:/mnt/load-balancer/"` | The XDG config dirs (directories where configuration will be read from). Do not change without good reason. |
| xdgConfigDirsExtra | list | `[]` | A list of additional XDG config dir paths |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)

