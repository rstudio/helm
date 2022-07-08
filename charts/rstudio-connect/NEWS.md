# 0.2.38

- Bump rstudio-library chart version

# 0.2.37

- Bump Connect version to 2022.06.2

# 0.2.36

- Bump Connect version to 2022.06.0

# 0.2.35

- Add the ability to set annotations to the Persistent Volume Claim.

# 0.2.34

- Make `resources` configuration backwards compatible with the previous `enabled`
  flag ([#218](https://github.com/rstudio/helm/issues/218))

# 0.2.33

- Add `sharedStorage.mountContent` value configuration option. When this setting
  is enabled, the chart will configure Connect's `Launcher.DataDirPVCName` to use
  the PVC defined by `sharedStorage.name`. If this setting is used, then
  `config.Launcher.DataDir` must not be set.

# 0.2.32

- Update `rstudio-library` chart version. Add support for lists in INI file sections.

# 0.2.31

- Bump Connect version to 2022.05.0

# 0.2.30

- Simplify `resources` configuration and allow `resources` configuration on the
  sidecar container
  - Worth noting that _if baseline `enabled`_, defaults have changed to not
    specify resources. Prototype recommendations remain in the chart values as
    a comment

# 0.2.29

- Add `pod.securityContext` value configuration option

# 0.2.28

- Bump Connect version to 2022.04.2

# 0.2.27

- Bump Connect version to 2022.04.1

# 0.2.26

- Fix ingress definition issues with older Kubernetes clusters ([#139](https://github.com/rstudio/helm/issues/139))

# 0.2.25

- Bump Connect version to 2022.03.2

# 0.2.24

- Bump Connect version to 2022.03.1

# 0.2.23

- Bump Connect version to 2022.02.3

# 0.2.22

- Bump Connect version to 2022.02.2

# 0.2.21

- Bump Connect version to 2022.02.0

# 0.2.20

- Add `pod.affinity` value to define affinity for the pod

# 0.2.19

- Update `rstudio-library` chart version. This adds support for `extraObjects`
- Add `extraObjects` value. This allows deploying additional resources (with templating) straight from the values file!

# 0.2.18

- Bump Connect version to 2021.12.1

# 0.2.17

- Make `startupProbe`, `readinessProbe` and `livenessProbe` more configurable ([#97](https://github.com/rstudio/helm/issues/97))
  - They still use the `enabled` key to turn on or off
  - We then remove this key with `omit`, and pass the values verbatim to the template (as YAML)

# 0.2.16

- Update `rstudio-library` chart version. This adds a helper for rendering `Ingress` resources
- Create `k8s.networking.io/v1` `Ingress` resource when `ingress.enabled: true` and Kubernetes version is >=1.19 ([#117](https://github.com/rstudio/helm/issues/117))

# 0.2.15

- Bump Connect version to 2021.12.0

# 0.2.14

- Bump library-chart version

# 0.2.13

- Add configuration values for `pod.haste` to set (or unset) the `RSTUDIO_CONNECT_HASTE` variable
- Add a `pod.labels` values option ([#101](https://github.com/rstudio/helm/issues/101))

# 0.2.12

- Bump Connect version to 2021.11.1

# 0.2.11

- move "privileged: true" into `values.yaml`, because it is no longer necessary
  for rstudio-connect server or sessions when launcher is enabled.
  - To disable when using the launcher, set `securityContext: null`
  - NOTE: `securityContext: {}` will not remove the default, because helm values merge objects by default
- location for RStudio Connect's KubernetesProfilesConfig file has changed from
  `/etc/rstudio/launcher.kubernetes.profiles.conf` to
  `/etc/rstudio-connect/launcher/launcher.kubernetes.profiles.conf` so as to not
  conflict with RStudio Workbench

# 0.2.10

- Update default RStudio Connect version to 2021.11.0

# 0.2.9

- Add `imagePullSecrets` value option ([#57](https://github.com/rstudio/helm/issues/57))

# 0.2.8

- Bump `rstudio-library` chart version

# 0.2.7

- Update default RStudio Connect version to 2021.10.0

# 0.2.6

- Update `rstudio-library` chart version

# 0.2.5

- Update default RStudio Connect version to 2021.09.0

# 0.2.4

- Enabled Python support in Connect by default when `launcher.enabled=true`
- Any values defined in the `config` section now take precendence over
  those that are set by the Helm chart's logic.

# 0.2.3

- Update default RStudio Connect version to 2021.08.2

# 0.2.2

- Added a new parameter `rbac.clusterRoleCreate` to `values.yaml` to allow for disabling the creation of the
  `ClusterRole` that allows for access to the nodes API. This API is used to ensure that all of the IP addresses
  for nodes are available when reporting the addresses of the node that is running a particular job so that
  clients can connect to it. This is generally not a needed permission for the Launcher as the internal IP is
  usually sufficient, so it is disabled by default.

# 0.2.1

- Update docs

# 0.2.0
- BREAKING: Licensing configuration now uses a `license` section. For example,
  `license: my-key` should be changed to
  ```yaml
  license:
    key: my-key
  ```
- Added support for floating licenses and license files.
- Default RStudio Connect version is now 1.9.0.1
- Add a `prestart.bash` script for use when `launcher.enabled=true`
  - when `launcher.enabled=true`, the chart changes `command` and `args` dynamically to use this script
  - if you set `command` and `args` yourself, we will use your settings instead. Be sure:
    - that `/scripts/prestart.bash` is executed (for Kubernetes setup)
    - that `/usr/local/bin/startup.sh` is executed (for licensing)
- Add RBAC via the `rstudio-library` chart
- Add `runtime.yaml` configuration (for runtime containers)
- Change default configuration when launcher is enabled
- Add the ability to more easily customize `launcher.kubernetes.profiles.conf`
  - Set up the profiles defaults to include the init container
- Allow more easily mounting a named PVC that was not created by the chart
- Make the "target" launcher namespace configurable
- Add a default value for `service.port: 80`

# 0.1.2

- Add ingress as an option
- Add annotations to deployment so that the pods roll when config changes

# 0.1.1

- Update to 1.8.6.2
- Update docs

# 0.1.0

- Change naming convention
  - This fixes issues with namespacing
  - However, it will damage backwards compatibility, particularly for PVCs if using `sharedStorage.create = true`
  - If you need to migrate data, set `replicas: 0`, upgrade, and then copy the data to the new PVC
  - Alternatively, you can set `fullnameOverride: "previous-release-name"` to force backwards compatibility
    - Finally, deployment selectors have changed, so you will need to delete the current deployment manually, then put back with `helm upgrade --install`
  - Use `helm diff upgrade` to ensure things are working as you expect before upgrading

# 0.0.3

- Add HA, Postgres, PVC, monitoring

# 0.0.2

- Minimally viable
