# RStudio Workbench

![Version: 0.5.0-rc09](https://img.shields.io/badge/Version-0.5.0--rc09-informational?style=flat-square) ![AppVersion: 2021.09.0-351.pro6](https://img.shields.io/badge/AppVersion-2021.09.0--351.pro6-informational?style=flat-square)

#### _Official Helm chart for RStudio Workbench_

Data Scientists use [RStudio Workbench](https://www.rstudio.com/products/workbench/) to analyze data and create data
products using R and Python.

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

To install the chart with the release name `my-release` at version 0.5.0-rc09:

```bash
helm repo add rstudio https://helm.rstudio.com
helm install --devel my-release rstudio/rstudio-workbench --version=0.5.0-rc09
```

## Required Configuration

This chart requires the following in order to function:

* A license key, license file, or address of a running license server. See the `license` configuration below.
* A Kubernetes [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) that contains the
  home directory for users.
  * If `homeStorage.create` is set, a PVC that relies on the default storage class will be created to generate the
    PersistentVolume. Most Kubernetes environments do not have a default storage class that you can use
    with `ReadWriteMany` access mode out-of-the-box. In this case, we recommend you disable `homeStorage.create` and
    create your own `PersistentVolume` and `PersistentVolumeClaim`, then mount them into the container by specifying
    the `pod.volumes` and `pod.volumeMounts` parameters, or by specifying your `PersistentVolumeClaim`
    using `homeStorage.name` and `homeStorage.mount`.
  * If you cannot use a `PersistentVolume` to properly mount your users' home directories, you'll need to mount your
    data in the container by using a
    regular [Kubernetes Volume](https://kubernetes.io/docs/concepts/storage/volumes/#nfs), specified in `pod.volumes`
    and `pod.volumeMounts`.
  * If you cannot use a `Volume` to mount the directories, you'll need to manually mount them during container startup
    with a mechanism similar to what is described below for joining to auth domains.
  * If not using `homeStorage.create`, you'll need to configure `config.serverDcf.launcher-mounts` to ensure that the correct mounts are used when users create new sessions.
* If using load balancing (by setting `replicas > 1`), you will need similar storage defined for `sharedStorage` to
  store shared project configuration. However, you can also configure the product to store its shared data underneath `/home` by
  setting `config.server.rserver\.conf.server-shared-storage-path=/home/some-shared-dir`.
* A method to join the deployed `rstudio-workbench` container to your auth domain. The default `rstudio/rstudio-workbench` image has `sssd` installed and started by default.
  You can include `sssd` configuration in `config.userProvisioning` like so:
```yaml
config:
  userProvisioning:
    mysssd.conf:
      sssd:
        config_file_version: 2
        services: nss, pam
        domains: rstudio.com
      domain/rstudio.com:
        id_provider: ldap
        auth_provider: ldap
```

## Recommended Configuration

In addition to the above required configuration, we recommend setting the following to ensure a reliable deployment:

* Set the `launcherPem` value to ensure that it stays the same between releases.
  This will ensure that users can continue to properly connect to older sessions even after a redeployment of the chart. See the
  [RSW Admin Guide](https://docs.rstudio.com/ide/server-pro/job-launcher.html#authentication) for details on generating the file.
* Set the `global.secureCookieKey` so that user authentication continues to work between deployments. A valid value can be obtained
  by simply running the `uuid` command.
* Some use-cases may require special PAM profiles to run. By default, no PAM profiles other than the basic `auth` profile will be used to authenticate users.
  If this is not sufficient then you will need to add your PAM profiles into the container using a volume and volumeMount.

## General Principles

- In most places, we opt to pass Helm values directly into ConfigMaps. We automatically translate these into the
  valid `.ini` or `.dcf` file formats required by RStudio Workbench. Those config files and their mount locations are
  below.
- If you need to modify the jobs launched by RStudio Workbench, you want to use `job-json-overrides`. There is a section on this below
  and [a support article](https://support.rstudio.com/hc/en-us/articles/360051652094-Using-Job-Json-Overrides-with-RStudio-Server-Pro-and-Kubernetes)
  on the topic in general.
- The prestart scripts for RStudio Workbench and RStudio Launcher are highly customized to:
  - Get the service account information off of the RStudio Workbench pod for use in launching jobs
  - Generate `launcher.pub` as needed (if `launcher.pem` is provided). If it is not provided, the Helm chart will
    generate it automatically but this information can be lost if deleting the chart or moving to a new cluster. This
    can cause users to be locked out sessions started by a previous deployment.
- RStudio Workbench does not export prometheus metrics on its own. Instead, we run a sidecar graphite exporter
  [as described here](https://support.rstudio.com/hc/en-us/articles/360044800273-Monitoring-RStudio-Team-Using-Prometheus-and-Graphite)

## Configuration files

These configuration values all take the form of usual helm values
so you can set the database password with something like:

```
... --set config.secret.database\.conf.password=mypassword ...
```

The files are converted into configuration files in the necessary format via go-templating. If you want to "in-line" a config file or mount it verbatim, you can use a pattern like:

```yaml
config:
  server:
    rserver.conf: |
      verbatim-file=format
```

The names of files are dynamically used, so you can add new files as needed. Beware that some files have default values,
so moving them can have adverse effects. Also, if you use a different mounting paradigm, you will need to change
the `XDG_CONFIG_DIRS` environment variable

- Session Configuration
  - These configuration files are mounted into the server and
    are mounted into the session pods as well.
  - `repos.conf`, `rsession.conf`, `notifications.conf`
  - located in the `config.session.<< name of file >>` helm values
  - mounted at `/mnt/session-configmap/rstudio/`
- Session Secret Configuration
  - These configuration files are mounted into the server and session pods as well
  - `odbc.ini` and other similar shared secrets 
  - located in `config.sessionSecret.<< name of file>>` helm values
  - mounted at `/mnt/session-secret/`
- Secret Configuration
  - These configuration files are mounted into the server with more restrictive permissions (0600)
  - `database.conf`, `openid-client-secret`, etc.
  - They are located in the `config.secret.<< name of file >>` helm values
  - mounted at `/mnt/secret-configmap/rstudio/`
- Server Configuration
  - These configuration files are mounted into the server (.ini file format)
  - `rserver.conf`, `launcher.conf`, `jupyter.conf`, `logging.conf`
  - They are located at `config.server.<< name of file >>` helm values
  - mounted at `/mnt/configmap/rstudio/`
- Server DCF Configuration
  - These configuration files are mounted into the server (.dcf file format)
  - `launcher-mounts`, `launcher-env`
  - They are located at `config.serverDcf.<< name of file >>` helm values
  - included at `/mnt/configmap/rstudio/`
- Profiles Configuration 
  - These configuration files are mounted into the server (.ini file format)
  - `launcher.kubernetes.profiles.conf`
  - They are located at `config.profiles.<< name of file >>` helm values
  - included at `/mnt/configmap/rstudio/`
  - See the `Profiles` section below for more information
- Prestart
  - This is provided by the helm chart in a configmap
  - It is mounted into the pod at `/scripts/`
  - `prestart-workbench.bash` is used to start workbench
  - `prestart-launcher.bash` is used to start launcher
- User Provisioning Configuration
  - These configuration files are used for configuring user provisioning (i.e. `sssd`)
  - Located at `config.userProvisioning.<< name of file >>` helm values 
  - Mounted onto `/etc/sssd/conf.d/` with `0600` permissions by default
- Custom Startup Configuration
  - `supervisord` service / unit definition `.conf` files
  - Located at `config.startupCustom.<< name of file >>` helm values
  - Will use the `.ini` file format, by default
  - Mounted at `/startup/custom`
  - As with all config files above, can override with a verbatim string if desired, like so:
```yaml
config:
  startupCustom:
    myfile.conf: |
      file-used-verbatim
```
- PAM configuration
  - `pam` configuration files
  - Located at `config.pam.<< name of file >>` helm values
  - Will be mounted verbatim as individual files (using `subPath` mounts) at `/etc/pam.d/<< name of file >>`

## User Provisioning

Provisioning users in RStudio Workbench containers is challenging. Session images have users created automatically (with
consistent UIDs / GIDs), but creating users in the Workbench containers is a responsibility that falls to the
administrator today.

The most common way to provision users is via `sssd`.
The [latest RStudio Workbench container](https://github.com/rstudio/rstudio-docker-products/tree/main/workbench#user-provisioning)
has `sssd` included and running by default (see `userProvisioning` configuration files above).

The other way that this can be managed is via a lightweight "startup service" (runs once at startup and then sleeps forever)
or a polling service (checks at regular intervals). Either can be written easily in `bash` or another programming language.
However, it is important to be careful of a few points:

- UID / GID consistency: linux usernames and their matching to UID/GID must be consistent across all nodes and across
  time. Failing this can cause security issues and access by some users to files they should not be allowed to see
- usernames cannot have `@`. The `@` sign (often used in emails with SSO) is a problem for RStudio Workbench because
  some operating systems disallow `@` signs in linux usernames
- `supervisord` is configured by default to exit if any of its child processes exit. If you use `config.startupCustom`
  to configure a user management service, be careful that it does not exist unnecessarily

We do not provide such a service out of the box because we intend for RStudio Workbench to solve this problem in a
future release. Please get in touch with your account representative if you have feedback or questions about this
workflow.

### PAM

When starting sessions on RStudio Workbench, PAM configuration is often very important, even if PAM is not being used as
an authentication mechanism. The RStudio Workbench helm chart allows creating custom PAM files via the `config.pam`
values section.

Each key under `config.pam` will become a PAM config file, and will be mounted into `/etc/pam.d/` in the container. For
example:

```yaml
config:
  pam:
    rstudio: |
      # the rstudio PAM config file
      # will be used verbatim
    rstudio-session: |
      # the rstudio-session PAM config file
      # will be used verbatim
```
   
## RStudio Profiles

Profiles are used to define product behavior (in `.ini` file format) based on user and group membership.

Sections define whether a set of configuration is applied to a user's jobs based on the following criteria:

- if section header is `[*]`, it applies to all users
- if a user's username is `myusername`, the section `[myusername]` will apply to them
- if a user is in the `allusers` group, then the section `[@allusers]` will applly to them

The product reads configuration from top-to-bottom, and "last-in-wins" for a given configuration value.

However, the `config.profiles` section has a couple of niceties that are added in by default.

- YAML arrays like the following will be "comma-joined." For instance, the following will become: `some-key=value1,value2`
```yaml
some-key:
  - value1
  - value2
```
- The `[*]` section will have arrays "appended" to user and group sections, along with "defaults" defined by the chart.

### A Full Example

```yaml
config:
  profiles:
    launcher.kubernetes.profiles.conf:
      "*":
        some-key:
          - value1
          - value2
      myuser:
        some-key:
          - value4
          - value5
```

Becomes:

```ini
[*]
some-key: value1,value2
[myuser]
some-key: value1,value2,value3,value4
```

> NOTE: this appending / concatenation / array translation behavior only works with the helm chart

### Job Json Overrides

If you want to customize the job launch process (i.e. how sessions are defined), you will need to edit the following
configuration:
  - modify `config.profiles.launcher.kubernetes.profiles.conf.<< some selector >>.job-json-overrides`
  - create an array of maps with the following keys:
    - `target`: the "target" part of the job spec to replace
    - `name`: a unique identifier (ideally with no spaces) that will become a config filename on disk
    - `json`: a YAML value that will be translated directly to JSON and injected into the job spec at `target`

Note that several examples are provided
in [this support article](https://support.rstudio.com/hc/en-us/articles/360051652094-Using-Job-Json-Overrides-with-RStudio-Server-Pro-and-Kubernetes)
(however, examples do not use the helm chart syntax there).

```yaml
config:
  profiles:
    launcher.kubernetes.profiles.conf:
      "*":
        job-json-overrides:
          - target: "/spec/template/spec/containers/0/imagePullPolicy"
            json: "Always"
            name: imagePullPolicy
          - target: "/spec/template/spec/imagePullSecrets"
            json:
              name: my-pull-secret
            name: imagePullSecrets
        container-images:
          - "one-image:tag"
          - "two-image:tag
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| args | list | `[]` | args is the pod container's run arguments. |
| command | list | `[]` | command is the pod container's run command. By default, it uses the container's default. However, the chart expects a container using `supervisord` for startup |
| config.pam | object | `{}` | a map of pam config files. Will be mounted into the container directly / per file, in order to avoid overwriting system pam files |
| config.profiles | object | `{}` | a map of server-scoped config files (akin to `config.server`), but with specific behavior that supports profiles. See README for more information. |
| config.secret | object | `{"database.conf":{}}` | a map of secret, server-scoped config files. Mounted to `/mnt/secret-configmap/rstudio/` with 0600 permissions |
| config.server | object | `{"jupyter.conf":{"default-session-cluster":"Kubernetes","jupyter-exe":"/opt/python/3.6.5/bin/jupyter","labs-enabled":1,"notebooks-enabled":1},"launcher.conf":{"cluster":{"name":"Kubernetes","type":"Kubernetes"},"server":{"address":"127.0.0.1","admin-group":"rstudio-server","authorization-enabled":1,"enable-debug-logging":0,"port":5559,"server-user":"rstudio-server","thread-pool-size":4}},"logging.conf":{},"rserver.conf":{"admin-enabled":1,"launcher-address":"127.0.0.1","launcher-default-cluster":"Kubernetes","launcher-port":5559,"launcher-sessions-enabled":1,"monitor-graphite-client-id":"rstudio","monitor-graphite-enabled":1,"monitor-graphite-host":"127.0.0.1","monitor-graphite-port":9109,"server-health-check-enabled":1,"server-project-sharing":1,"www-port":8787},"vscode-user-settings.json":"{\n      \"terminal.integrated.shell.linux\": \"/bin/bash\",\n      \"extensions.autoUpdate\": false,\n      \"extensions.autoCheckUpdates\": false\n}\n","vscode.conf":{"args":"--verbose --host=0.0.0.0","enabled":1,"exe":"/opt/code-server/bin/code-server"}}` | a map of server config files. Mounted to `/mnt/configmap/rstudio/` |
| config.serverDcf | object | `{"launcher-mounts":[]}` | a map of server-scoped config files (akin to `config.server`), but with .dcf file formatting (i.e. `launcher-mounts`, `launcher-env`, etc.) |
| config.session | object | `{"notifications.conf":{},"repos.conf":{"CRAN":"https://packagemanager.rstudio.com/cran/__linux__/bionic/latest","RSPM":"https://packagemanager.rstudio.com/cran/__linux__/bionic/latest"},"rsession.conf":{}}` | a map of session-scoped config files. Mounted to `/mnt/session-configmap/rstudio/` on both server and session, by default. |
| config.sessionSecret | object | `{}` | a map of secret, session-scoped config files (odbc.ini, etc.). Mounted to `/mnt/session-secret/` on both server and session, by default |
| config.startupCustom | object | `{}` | a map of supervisord .conf files to define custom services. Mounted into the container at /startup/custom/ |
| config.userProvisioning | object | `{}` | a map of sssd config files, used for user provisioning. Mounted to `/etc/sssd/conf.d/` with 0600 permissions |
| dangerRegenerateAutomatedValues | bool | `false` |  |
| fullnameOverride | string | `""` | the full name of the release (can be overridden) |
| global.secureCookieKey | string | `""` |  |
| homeStorage.accessModes | list | `["ReadWriteMany"]` | accessModes defined for the storage PVC (represented as YAML) |
| homeStorage.create | bool | `false` | whether to create the persistentVolumeClaim for homeStorage |
| homeStorage.mount | bool | `false` | Whether the persistentVolumeClaim should be mounted (even if not created) |
| homeStorage.name | string | `""` | The name of the pvc. By default, computes a value from the release name |
| homeStorage.path | string | `"/home"` | the path to mount the homeStorage claim within the pod |
| homeStorage.requests.storage | string | `"10Gi"` | the volume of storage to request for this persistent volume claim |
| homeStorage.storageClassName | bool | `false` | storageClassName - the type of storage to use. Must allow ReadWriteMany |
| image.imagePullPolicy | string | `"IfNotPresent"` | the imagePullPolicy for the main pod image |
| image.imagePullSecrets | list | `[]` | an array of kubernetes secrets for pulling the main pod image from private registries |
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
| launcherPem | string | `""` | An inline launcher.pem key. If not provided, one will be auto-generated. See README for more details. |
| launcherPub | bool | `false` | An inline launcher.pub key to pair with launcher.pem. If `false` (the default), we will try to generate a `launcher.pub` from the provided `launcher.pem` |
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
| nodeSelector | object | `{}` |  |
| pod.annotations | object | `{}` | podAnnotations is a map of keys / values that will be added as annotations to the rstudio-pm pods |
| pod.env | list | `[]` | env is an array of maps that is injected as-is into the "env:" component of the pod.container spec |
| pod.sidecar | bool | `false` | sidecar is an array of containers that will be run alongside the main container |
| pod.volumeMounts | list | `[]` | volumeMounts is injected as-is into the "volumeMounts:" component of the pod.container spec |
| pod.volumes | list | `[]` | volumes is injected as-is into the "volumes:" component of the pod.container spec |
| priorityClassName | string | `nil` |  |
| prometheusExporter.enabled | bool | `true` | whether the  prometheus exporter sidecar should be enabled |
| prometheusExporter.image.imagePullPolicy | string | `"IfNotPresent"` |  |
| prometheusExporter.image.repository | string | `"prom/graphite-exporter"` |  |
| prometheusExporter.image.tag | string | `"v0.9.0"` |  |
| prometheusExporter.mappingYaml | string | `nil` | Yaml that defines the graphite exporter mapping. null by default, which uses the embedded / default mapping yaml file |
| rbac.clusterRoleCreate | bool | `false` | Whether to create the ClusterRole that grants access to the Kubernetes nodes API. This is used by the Launcher to get all of the IP addresses associated with the node that is running a particular job. In most cases, this can be disabled as the node's internal address is sufficient to allow proper functionality. |
| rbac.create | bool | `true` | Whether to create rbac. (also depends on launcher.enabled = true) |
| rbac.serviceAccount | object | `{"annotations":{},"create":true,"name":""}` | The serviceAccount to be associated with rbac (also depends on launcher.enabled = true) |
| readinessProbe | object | `{"enabled":true,"failureThreshold":3,"initialDelaySeconds":3,"periodSeconds":3,"successThreshold":1,"timeoutSeconds":1}` | readinessProbe is used to configure the container's readinessProbe |
| replicas | int | `1` | replicas is the number of replica pods to maintain for this service. Use 2 or more to enable HA |
| resources | object | `{"limits":{"cpu":"2000m","enabled":false,"ephemeralStorage":"200Mi","memory":"4Gi"},"requests":{"cpu":"100m","enabled":false,"ephemeralStorage":"100Mi","memory":"2Gi"}}` | resources define requests and limits for the rstudio-server pod |
| secureCookieKey | string | `""` |  |
| securityContext | object | `{}` |  |
| service.annotations | object | `{}` | annotations for the service definition |
| service.nodePort | bool | `false` | the nodePort to use when using service type NodePort. If not defined, Kubernetes will provide one automatically |
| service.port | int | `80` | The Service port. This is the port your service will run under. |
| service.type | string | `"NodePort"` | the service type (i.e. NodePort, LoadBalancer, etc.) |
| session.defaultConfigMount | bool | `true` | Whether to automatically mount the config.session configuration into session pods. If launcher.namespace is different from Release Namespace, then the chart will duplicate the session configmap in both namespaces to facilitate this |
| session.defaultSecretMountPath | string | `"/mnt/session-secret/"` | The path to mount the sessionSecret (from `config.sessionSecret`) onto the server and session pods |
| session.image.repository | string | `"rstudio/r-session-complete"` | The repository to use for the session image |
| session.image.tag | string | `""` | A tag override for the session image. Overrides the "tagPrefix" above, if set. Default tag is `{{ tagPrefix }}{{ version }}` |
| session.image.tagPrefix | string | `"bionic-"` | A tag prefix for session images (common selections: bionic-, centos-). Only used if tag is not defined |
| shareProcessNamespace | bool | `false` | whether to provide `shareProcessNamespace` to the pod. |
| sharedStorage.accessModes | list | `["ReadWriteMany"]` | accessModes defined for the storage PVC (represented as YAML) |
| sharedStorage.create | bool | `false` | whether to create the persistentVolumeClaim for shared storage |
| sharedStorage.mount | bool | `false` | Whether the persistentVolumeClaim should be mounted (even if not created) |
| sharedStorage.name | string | `""` | The name of the pvc. By default, computes a value from the release name |
| sharedStorage.path | string | `"/var/lib/rstudio-server"` | the path to mount the sharedStorage claim within the pod |
| sharedStorage.requests.storage | string | `"10Gi"` | the volume of storage to request for this persistent volume claim |
| sharedStorage.storageClassName | bool | `false` | storageClassName - the type of storage to use. Must allow ReadWriteMany |
| startupProbe | object | `{"enabled":false,"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":1}` | startupProbe is used to configure the container's startupProbe |
| startupProbe.failureThreshold | int | `30` | failureThreshold * periodSeconds should be strictly > worst case startup time |
| strategy | object | `{"rollingUpdate":{"maxSurge":"100%","maxUnavailable":0},"type":"RollingUpdate"}` | How to handle updates to the service. RollingUpdate (the default) minimizes downtime, but will not work well if your license only allows a single activation. |
| tolerations | list | `[]` |  |
| userCreate | bool | `false` | userCreate determines whether a user should be created at startup (if true) |
| userName | string | `"rstudio"` | userName determines the username of the created user |
| userPassword | string | `"rstudio"` | userPassword determines the password of the created user |
| userUid | string | `"10000"` | userUid determines the UID of the created user |
| versionOverride | string | `""` | A Workbench version to override the "tag" for the RStudio Workbench image and the session images. Necessary until https://github.com/helm/helm/issues/8194 |
| xdgConfigDirs | string | `"/mnt/dynamic:/mnt/session-configmap:/mnt/secret-configmap:/mnt/configmap:/mnt/load-balancer/"` | The XDG config dirs (directories where configuration will be read from). Do not change without good reason. |
| xdgConfigDirsExtra | list | `[]` | A list of additional XDG config dir paths |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)

