# Changelog

## 0.9.12 

- Enable Positron sessions (enabled, by default) and configure default settings.

## 0.9.11

- Bump Chronicle Agent to version 2025.08.0

## 0.9.10

- Fix a bug with the new `ephermalStorage` options where it was set every time, even if it was unset in the `values.yaml`.

## 0.9.9

- Add options to specify resources for the Chronicle Agent container.

## 0.9.8

- Allow setting ephemeral-storage limit and request for Workbench session pods via the settings `launcher.templateValues.pod.ephemeralStorage.request` and `launcher.templateValues.pod.ephemeralStorage.limit`.

## 0.9.7

- Correct the `README.md` example to use the correct `imagePullSecrets` syntax for the launcher template values (`launcher.templateValues.pod.imagePullSecrets`).

## 0.9.6

- Switch to a hardcoded default for `chronicleAgent.image.tag` to be regularly updated for new releases.
- Move user provided init containers ahead of the Chronicle Agent init container in priority.

## 0.9.5

- Align VSCode and Positron settings with Workbench defaults
- Remove JupyterHub sessions by default, per Posit Workbench 2024.09.0

## 0.9.4

- Add recommended labels to all PVCs created by the chart.

## 0.9.3

- Bump Workbench version to 2025.05.1

## 0.9.2

- Bump `rstudio-library` chart version to `0.1.34`.
- Adds a shortcut resource deployment for Chronicle Agent via `chronicleAgent.enabled`. The value is disabled by default
  and does not affect existing deployments that use `sidecar` or `initContainer` to deploy the Chronicle Agent.

## 0.9.1

- Bump Workbench version to 2025.05.0
- Enable `audited-jobs`

## 0.9.0

- BREAKING: `launcher.useTemplates: true` is now the default. `launcher.templateValues` settings are the recommended way to pass values to the launcher jobs. If you must use the older `job-json-overrides` method, set `launcher.useTemplates: false`, the two methods cannot be used concurrently and will error if detected.
  - Update the README to add more information about using `launcher.templateValues` settings.

## 0.8.14

- Add `sharedStorage.subPath` for parity

## 0.8.13

- Add `service.targetPort`
- Add `pod.hostAliases` and `launcher.templateValues.pod.hostAliases`
- Fix `pod.port`: now mapped correctly in `_helpers.tpl`

## 0.8.12

- Bump Chronicle Agent to version 2025.03.0

## 0.8.11

- Bump Workbench version to 2024.12.1

## 0.8.10

- Bump Workbench version to 2024.12.0
- Bump version of launcher templates `job.tpl` and `service.tpl`
  - Populate pod `initContainers` from `.Job.initContainers`

## 0.8.9

- Fix a logic bug where the resource limit key was set even if `resources.limits.enabled` is false

## 0.8.8

- Bump Chronicle Agent to version 2024.11.0

## 0.8.7

- Bump Workbench version to 2024.09.1

## 0.8.6

- Pin the rstudio-library version dependency so we can update the library chart without breaking all the charts that depend on it.

## 0.8.5

- Add helm unit test scaffold.

## 0.8.4

- Move the values files for linting and installation testing outside the chart directory so that we can iterate on them without releasing a new version of the chart

## 0.8.3

- Bump version of launcher templates `job.tpl` and `service.tpl`
  - `enableServiceLinks` now defaults to `false` for sessions (instead of not being set).
    To enable them for sessions, set `launcher.templateValues.enableServiceLinks: true`
  - Also see related discussion [on the Kubernetes project](https://github.com/kubernetes/kubernetes/issues/121787)

## 0.8.2

- Bump Workbench version to 2024.09.0

## 0.8.1

- Bump Chronicle Agent to version 2024.09.0

## 0.8.0

- BREAKING: the prometheus endpoint has changed from port `9108` to `8989` by default
  - We are now using an internal prometheus endpoint with new metrics
  - As a result, the `graphiteExporter` sidecar has been removed
  - Some metrics from the `graphiteExporter` will no longer be present
  - The parent / main "off-switch" for prometheus is at `prometheus.enabled`
  - To revert to the old exporter, set `prometheus.legacy=true` (and please reach out to let us know why!)

## 0.7.6

- Bump Workbench version to 2024.04.2

## 0.7.5

- Add documentation about PostgreSQL database configuration and mounting passwords from secrets as env variables

## 0.7.4

- Documentation site updates

## 0.7.3

- Bump Workbench version to 2024.04.0

## 0.7.2

- Bump Chronicle Agent to version 2024.03.0

## 0.7.1

- Updates to support standalone documentation site

## 0.7.0

- BREAKING: The generated service will now have type `ClusterIP` set by default.
- Add support for setting the `loadBalancerIP` or `clusterIP`.
- Ignore `nodePort` settings when the service is not a `NodePort`.
- Improve the documentation for some service-related settings.

## 0.6.16

- Update default package manager repo in `config.session.repos.conf`
- Remove `--verbose` from args in `config.server.vscode.conf`
- Add instructions for configuring R and Python repos in the README
- Add empty JSON to `rstudio-prefs.json` default
- Add documentation for `databricks.conf`
- Increase `readinessProbe.initialDelaySeconds` to `10`

## 0.6.15

- Add `ttlSecondsAfterFinished` to `job.tpl` for session jobs.

## 0.6.14

- Add option to set `pod.terminationGracePeriodSeconds`
- Add protection for `prestart-launcher.bash` to be OS-agnostic in certificate modification
  ([#453](https://github.com/rstudio/helm/pull/453))

## 0.6.13

- Bump Workbench version to 2023.12.1

## 0.6.12

- Bump Workbench version to 2023.12.0

## 0.6.11

- Add licensing section to the README to provide guidance on using a license file, license key or license server.

## 0.6.10

- Bump rstudio-library to `0.1.27`
  - Fix an issue with `mountPath` and `subPath` when `license.file.mountSubPath` is `true`

## 0.6.9

- Bump Workbench version to 2023.09.1

## 0.6.8

- Bump Workbench version to 2023.09.0

## 0.6.7

- Add native session support for `pip.conf`
  - In order to mount a `pip.conf` file to `/etc/pip.conf` on server and sessions,
    just define the file in `config.session.pip\\.conf`

## 0.6.6

- Bump Workbench version to 2023.06.1

## 0.6.5

- Add support for `homeStorage.subPath` (and for launcher sessions)

## 0.6.4

- Add support for serviceAccount labels (`rbac.serviceAccount.labels`)

## 0.6.3

- Fix support for `pod.env` on sessions

## 0.6.2

- Add support for [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)

## 0.6.1

- Bump Workbench version to 2023.06.0

## 0.6.0

- BREAKING: Change default OS / OS prefix to `ubuntu2204-`.
  [Bionic support is EOL as of 2023-04-30](https://posit.co/about/platform-support/)
  - If you want to revert this change, set `session.image.tagPrefix=bionic-` (sessions) and `image.tagPrefix=bionic-` (
    server)
- BREAKING: change the "home volume mount" for sessions to happen automatically, regardless of whether you define other
  values in `config.serverDcf.launcher-mounts`
  - Previously, if you specify anything in `launcher-mounts`, then we did not mount the home volume onto the session
  - Now, we continue to mount the home volume onto the session, unless:
    - You set `session.defaultHomeMount=false`
    - You have the same (or a parent) `mountPath` defined in an existing `launcher-mounts` volume
    - You have the same PVC `ClaimName` defined in an existing `launcher-mounts` volume
  - If you mount the volume yourself and want to keep doing so, you can set `session.defaultHomeMount=false`
  - If you mount the volume yourself and would like to stop doing so, you can now unset the home mount
    in `launcher-mounts`
- Update documentation and README for a bit more clarity
- Update product to version `2023.03.1`
- Allow customizing the `pod.command` associated with sessions for some highly custom startup cases. This should
  not be necessary in most cases and will be removed at a later date, once the product supports startup customization.
  Please reach out if you have questions about this functionality!
- Add `podDisruptionBudget` values
- Add `topologySpreadConstraints` values
- Start to utilize the `pod.securityContext` values for pod `securityContext` values

## 0.5.32

- Add `priorityClassName` to product configuration

## 0.5.31

- Update documentation to make `.Values.server.profiles` and `.Values.profiles.profiles` differences
  more clear.

## 0.5.30

- Add `pod.lifecycle` hook

## 0.5.29

- Update documentation to remove "beta" label and explain production recommendations

## 0.5.28

- Bump rstudio-library to `0.1.24`
  - Update RBAC definition to support listing of service accounts

## 0.5.27

- Bump Workbench version to 2022.12.0

## 0.5.26

- Add a `prometheusExporter.resources` configuration section for consistency with the Connect chart

## 0.5.25

- Add `homeStorage.otherArgs` and `sharedStorage.otherArgs` for other PVC arguments
  - This can be useful for arguments like `volumeName` when using a PVC that references a PV

## 0.5.24

- BREAKING: remove `serviceAccountName` in favor of `rbac.serviceAccount.name`.
  - Also fix a handful of consistency issues with serviceAccount
    creation ([##251](https://github.com/rstudio/helm/issues/251))
  - Allow un-setting `rbac.serviceAccount.name` ([##294](https://github.com/rstudio/helm/pull/294))
- Add `prometheusExporter.securityContext` for the ability to configure the sidecar `securityContext`
- Add `revisionHistoryLimit` value for the Workbench deployment
  - This can be helpful particularly when CI systems such as `ArgoCD` leave replicasets around

## 0.5.23

- Add updated templates for `launcher.templateValues` and session container customization
  - Add customization of `securityContext` and `containerSecurityContext` ([##293](https://github.com/rstudio/helm/issues/293))
  - Fix typo in `serviceAccountName` implementation ([##251](https://github.com/rstudio/helm/issues/251))
  - Add `affinity` and `tolerations` ([##271](https://github.com/rstudio/helm/issues/271) and [##283](https://github.com/rstudio/helm/issues/283))

## 0.5.22

- BREAKING: change jupyter path from `/opt/python/3.6.5/bin/jupyter` to `/usr/local/bin/jupyter`
  - This will hopefully not affect your deployment, but it depends on how your image is built
  - We have recently changed all of our images to symlink jupyter to `/usr/local/bin/jupyter`
- add option and values for `launcher.useTemplates` and `launcher.templateValues`
  - this mechanism is useful for simplifying session configuration and replaces `job-json-overrides`
  - both will continue being used for now, but they are incompatible and will generate an error if both are used
  - Advanced topics include `launcher.includeDefaultTemplates=false` and `launcher.extraTemplates`
- bump Workbench version to 2022.07.2-576.pro12
- add a value for `image.tagPrefix` to make choosing operating system for the server image easier. Default is `bionic-`

## 0.5.21

- Fix an issue in the startup script to verify that the dir exists

## 0.5.20

- Fix an issue where chowning fails in the startup script
  - This is particularly problematic if ConfigMaps or Secrets are mounted into this directory
- Change appVersion to reflect the new docker image naming convention: `bionic-***` to include the OS in the image name.

## 0.5.19

- Add a simple mechanism for snapshot testing to make stronger backwards compatibility guarantees

## 0.5.18

- Add a ServiceMonitor CRD and values to configure
- Add `pod.affinity` value for configuration of pod affinity
- Fix issue where hostnames are not routable within kubernetes while load balancing
  - Because `hostname` output is not routable between pods, we use `www-host-name=$(hostname -i)`
    to route by IP address
  - This fixes a load balancing issue with some hard to understand `asio.netdb` errors

## 0.5.17

- Bump rstudio-library chart version
- Relax RBAC for `pod/logs` to remove write-related privileges

## 0.5.16

- Add the ability to set annotations to the Persistent Volume Claim.

## 0.5.15

- Bump Workbench to version 2022.02.3-492.pro3
- Fix typo in the README

## 0.5.14

- Bump Workbench to version 2022.02.2+485.pro2

## 0.5.13

- Allow specifying `defaultMode` for most/all configMap and secret mounts
  - this _should_ be backwards compatible. Please let us know if any issues arise
  - use cases include adding executable startup scripts, additional services,
    changing access for files to be more/less secure, changing permissions in
    accordance with different runAs, runAsGroup config.

## 0.5.12

- Allow Launcher to Auto Configure Kubernetes variables
  - Removes dynamic generation of `launcher.kubernetes.conf` file
  - Add `launcher.kubernetes.conf` to default values, setting `kubernetes-namespace` to the value of `launcher.namespace`
- Update `rstudio-library` chart version. Add support for lists in INI file sections.

## 0.5.11

- Update docs for `job-json-overrides` (fix a key reference issue and link to new docs in the helm repo)

## 0.5.10

- Fix ingress definition issues with older Kubernetes clusters ([##139](https://github.com/rstudio/helm/issues/139))

## 0.5.9

- Upgrade Workbench to version 2022.02.1+461.pro1

## 0.5.8

- Update README docs
- Add `selector` for storage definition ([##136](https://github.com/rstudio/helm/issues/136))
- Fix default permissions (0644) on pam mounts ([##141](https://github.com/rstudio/helm/issues/141))

## 0.5.7

- Update `logging.conf` to default to output logs on `stderr`

## 0.5.6

- Fix the version update. Our annotations were incorrect.

## 0.5.5

- Update RStudio Workbench to version 2021.09.2+382.pro1 (the second patch release of 2021.09)

## 0.5.4

- BUGFIX: address an important issue in RStudio Workbench load balancing
  - Ever since 0.5.0, we did not create a `load-balancer` file
  - This means that even "HA" installations of Workbench would function like independent nodes
  - We now touch an empty file and let the nodes report themselves to the database in this case

## 0.5.3

- Make `startupProbe`, `readinessProbe` and `livenessProbe` more configurable ([##97](https://github.com/rstudio/helm/issues/97))
  - They still use the `enabled` key to turn on or off
  - We then remove this key with `omit`, and pass the values verbatim to the template (as YAML)

## 0.5.2

- Update `rstudio-library` chart version. This adds support for `extraObjects`
- Add `extraObjects` value. This allows deploying additional resources (with templating) straight from the values file!

## 0.5.1

- Update `rstudio-library` chart version. This adds a helper for rendering `Ingress` resources
- Create `k8s.networking.io/v1` `Ingress` resource when `ingress.enabled: true` and Kubernetes version is >=1.19 ([##117](https://github.com/rstudio/helm/issues/117))

## 0.5.0

- BREAKING: Bump RStudio version to Ghost Orchid (2021.09.0+351.pro6)
  - This version of the chart is no longer compatible (by default) with older versions (1.4 and previous).
  - Previous versions of the chart are not compatible (by default) with 2021.09 or later
  - If you want to use charts across versions, you will need to change `command`, `args`, and some configmaps.
  - RSP environment variables for user creation, licensing, etc. are now RSW
- BREAKING: Change RStudio Workbench execution model to use supervisord
- BREAKING: Add `vscode.conf` defaults. This enables VS Code sessions, which is dependent on your images having
  code-server installed at `/opt/code-server/`
- Create `diagnostics` values (`diagnostics.enabled` and `diagnostics.directory`) to control diagnostic output
- Add values to `launcher.kubernetesHealthCheck` to control the behavior of the "Kubernetes Health Check" that launcher
  runs at startup
- Enable PAM sessions by default (i.e. `auth-pam-sessions-enabled=1`). This is important for proper home
  directory creation, for instance. Disable by setting `config.server.rserver\.conf.auth-pam-sessions-enabled=0`
- Add `imagePullSecrets` value option ([##57](https://github.com/rstudio/helm/issues/57))
- Add `config.pam` values option to add pam config files
- Add config-maps to configure startup behavior (`config.startupCustom`)
- Add a config setting for `sssd` (now in the container by default) (`config.userProvisioning`)
- Add a "secret" configmap for session components (useful for shared database credentials, `odbc.ini`,
  etc.) (`config.sessionSecret`)
- Update README to make `job-json-overrides`, profiles, user provisioning, etc. more clear
- Update `rstudio-library` chart dependency
  - BUGFIX: Address an issue with how `launcher-mounts` was generated incorrectly ([##108](https://github.com/rstudio/helm/issues/108))
- Add a `pod.labels` values option ([##101](https://github.com/rstudio/helm/issues/101))
- Modify how supervisord starts sssd with `config.startupUserProvisioning` values option ([##110](https://github.com/rstudio/helm/issues/110))

## 0.4.6

- Updated svc.yml to remove hardcoded port 80 and add .Values.service.port in its place. Updated values.yaml to include .Values.service.port (previously missing).

## 0.4.5

- Update `rstudio-library` chart version. This adds `pods/exec` privilege to RBAC
  - This is important for sessions to exit properly

## 0.4.4

- Added a new parameter `rbac.clusterRoleCreate` to `values.yaml` to allow for disabling the creation of the
  `ClusterRole` that allows for access to the nodes API. This API is used to ensure that all of the IP addresses
  for nodes are available when reporting the addresses of the node that is running a particular job so that
  clients can connect to it. This is generally not a needed permission for the Launcher as the internal IP is
  usually sufficient, so it is disabled by default.

## 0.4.3

- BUGFIX: The load-balancer sidecar container was not selecting app labels properly. This is now fixed. It could have been causing issues in load-balanced setups

## 0.4.2

- BUGFIX: session configuration is now mounted to the proper location on session pods
- BUGFIX: Prometheus annotations are now properly defined (they were using the wrong port)
- BUGFIX: The Graphite Exporter regex had a bug that did not handle certain hostnames
- Customizing the graphite exporter "mapping.yaml" is now configurable by defining `.Values.prometheusExporter.mappingYaml`

## 0.4.1

- Update docs

## 0.4.0

- BREAKING: `serviceAccountName` is now `rbac.serviceAccount.name` for consistency with our other charts
- BREAKING: `launcher=true` is now `launcher.enabled = true` and `launcherNamespace` is now `launcher.namespace` for consistency with our other charts
- Breaking: Licensing configuration now uses a `license` section. For example,
  `license: my-key` should be changed to
  ```yaml
  license:
    key: my-key
  ```
- Added support for floating licenses and license files.
- BREAKING: defaults have changed for `config.server.launcher\.kubernetes\.profiles\.conf`.
  - To avoid the breaking change, add the defaults to your explicitly enumerated values
  - See why this happened and an alternative forward-looking pattern below
  - The previous defaults:

```yaml
config:
  server:
    launcher.kubernetes.profiles.conf:
      "*":
        default-container-image: rstudio/r-session-complete:bionic-1.4.1106-5
        container-images: rstudio/r-session-complete:bionic-1.4.1106-5
        allow-unknown-images: 1
```

- BREAKING: we now automatically mount session configuration into the session pod

  - This adds default `job-json-overrides` using the mechanism above
  - This can be disabled by setting `session.defaultConfigMount=false`
  - This is useful for things like `repos.conf`, `rsession.conf` (default Connect server, etc.), etc.

- Switch to using the `rstudio-library` chart for configuration generation
  - This enables putting verbatim files in place if that is preferred to values-interpolation (converting values into a config file dynamically by the chart)
  - i.e. passing a string to the configuration value will short-circuit configuration generation

```yaml
config:
  server:
    some-config-file: |
      interpret-verbatim-please
```

- Update appVersion to 1.4.1717-3

- Add a new `config.profiles` option for configuring profiles files more naturally.
  - This will only be used if the `launcher.kubernetes.profiles.conf` key is not in `config.server` (testing for key
    duplication is tricky in helm, so we pick the most common key)
  - Before, we would have something like this in `values.yaml`:

```yaml
jobJsonOverridesFiles:
  some.json: "text"
  other.json:
    - an
    - array
config:
  server:
    launcher.kubernetes.profiles.conf:
      "*":
        job-json-overrides: '"some/target:some.json","other/target:other.json"'
        container-images: "one-image:tag,two-image:tag"
```

- Now, we can do something like the following. A bit more verbose, but much easier to read and understand:

```yaml
config:
  profiles:
    launcher.kubernetes.profiles.conf:
      "*":
        job-json-overrides:
          - target: "some/target"
            json: "text"
            name: some
          - target: "other/target"
            json:
              - an
              - array
            name: other
        container-images:
          - "one-image:tag"
          - "two-image:tag"
```

- Moreover, job-json-overrides defined under `config.profiles` now have inheritance within the chart. That is, `*`
  job-json-overrides are appended to everyone else's configuration. Documentation and possible extension of this pattern
  to container images, etc. to follow.

- Now hiding the rstudio-workbench container's configuration files under `/etc/rstudio` as we are mounting
  them in different directories as defined by the `XDG_CONFIG_DIRS` environment variable. This is to prevent confusion
  that can occur when someone edits `/etc/rstudio` configuration files and then sees no changes after reloading the
  server configuration.

- When specifying a `server` for floating licensing, the RSW chart will now automatically be configured to set
  `server-licensing-type=remote` in the `rserver.conf` configuration file.

## 0.3.7

- Make `secure-cookie-key` and `launcher.pem` autogeneration static
  - This means that the auto-generated values will persist across helm upgrades
  - It is still safest to define these values yourself

## 0.3.6

- Fix small reference issue in the prestart.bash script

## 0.3.5

- Decouple securityContext values from the main RSW container and the sidecar container

## 0.3.4

- remove "privileged: true", which is not necessary for rstudio-workbench server or sessions
- Add ingress as an option
- Add annotations to deployment so that the pods roll when config changes
- Switch the "secret" configurations to being an actual Secret

## 0.3.3

- Bump `load-balancer-manager` again (to `2.2`)
- Allow customization of load-balancer-manager env vars

## 0.3.2

- Fix a bug in the `load-balancer-manager` (`sidecar` container)
  - The helm chart (as a result of previous changes) no longer defines an `app` label, but an `app.kubernetes.io/name` label.
  - update the selector, make error handling better, etc. This requires version 2.0 of the load-balancer-manager

## 0.3.1

- allow `global.secureCookieKey` as an option along with `secureCookieKey`
- ensure that no empty `launcher.pub` file is generated by default
- default image.tag to Chart.AppVersion

## 0.3.0

- BREAKING: changed `rstudio` container `command` and `args` to tell `tini` how to supervise processes and run a differently named prestart script. Also made `/usr/local/bin/startup.sh` script execution a part of the `args`.

## 0.2.2

- Update Workbench version to 1.4.1106-5
- Update docs

## 0.2.1

- rename to `rstudio-workbench` corresponding to upcoming `rstudio-server-pro` rebranding
- fix bug that was creating a test user by default
- add other licensing options (via `server`, `file`, and `secret` values)

## 0.2.0

- Change naming convention
  - Fix issues with namespacing
  - However, this will damage backwards compatibility, particularly for PVCs if using `sharedStorage.create = true`
  - If you need to migrate data, set `replicas: 0`, upgrade, and then copy the data to the new PVC
  - Alternatively, you can set `fullnameOverride: "previous-release-name"` to force backwards compatibility
  - Finally, deployment selectors have changed, so you will need to delete the current deployment manually, then put back with `helm upgrade --install`
  - Use `helm diff upgrade` to ensure things are working as you expect before upgrading

## 0.0.8

- add `jobJsonOverridesFiles` value option

## 0.0.7

- Made HA functional

## 0.0.5

- BREAKING: move storage\* values to a sharedStorage map
- Add homeStorage
- Add logging.conf

## 0.0.4

- Add a secret configmap for pem and pub keys

## 0.0.3

- BREAKING: Restructure the image values object
- Add image.pullPolicy
- Switch to image.repository and image.tag from image
- Allow customizing pod command and args

## 0.0.2

- Add database.conf and notifications.conf

## 0.0.1

- Initial pass!
