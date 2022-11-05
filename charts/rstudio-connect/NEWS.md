# 0.3.10

- BREAKING: Remove `pod.serviceAccountName` in favor of `rbac.serviceAccount.name`
- Allow un-setting `rbac.serviceAccount.name` ([#294](https://github.com/rstudio/helm/pull/294))

# 0.3.9

- Fix a typo in `launcher.defaultInitContainer.imagePullPolicy` ([#289](https://github.com/rstudio/helm/pull/289))

# 0.3.8

- Add updated templates for `launcher.templateValues` and session container customization
  - Add customization of `securityContext` and `containerSecurityContext` ([#293](https://github.com/rstudio/helm/issues/293))
  - Fix typo in `serviceAccountName` implementation ([#251](https://github.com/rstudio/helm/issues/251))
  - Add `affinity` and `tolerations` ([#271](https://github.com/rstudio/helm/issues/271) and [#283](https://github.com/rstudio/helm/issues/283))
- Add an `image.tagPrefix` value to make customizing the operating system easier
- Add a `launcher.defaultInitContainer.tagPrefix` value to make customizing the operating system easier

# 0.3.7

- Bump Connect version to 2022.11.0

# 0.3.6

- Bump Connect version to 2022.10.0

# 0.3.5

- Fix appVersion to target `bionic-2022.09.0`, to reflect new image naming conventions that include the operating system.

# 0.3.4

- Bump Connect version to 2022.09.0

# 0.3.3

- Add a check to provide faster feedback if `launcher.enabed=true` without setting up shared storage

# 0.3.2

- Bump Connect version to 2022.08.1

# 0.3.1
- Bump Connect version to 2022.08.0

# 0.3.0

- BETA BREAKING: We moved `launcher.contentInitContainer` customizations to `launcher.defaultInitContainer`
  - This should only affect if you are using `launcher.enabled=true`, which is still in Beta
  - Values are treated the same, so a simple modification to the key should resolve any issues
- RStudio Connect with off-host execution is now in Public Beta
- Add support for the `launcher.useTemplates` value
  - This enables greater customization of session creation as well as better labels and annotations out of the box
  - To make use of the default session templates, configure values in `launcher.sessionTemplate`
- Enable logging using RStudio Connect's new logging configuration (effective with version 2022.07)
- Add a toggle for `launcher.defaultInitContainer.enabled` to turn off the default init container
  - When using the launcher, it is important that sessions have the RStudio Connect "session runtime" available
  - By default, we make these available through an init container, but they can also be provided other ways
  - By disabling this setting, you are opting into managing this runtime requirement yourself
- Add values for `pod.port` and `service.targetPort`
- Allow `launcher.additionalRuntimeImages` and `launcher.customRuntimeYaml="pro"` ([#238](https://github.com/rstudio/helm/issues/238), [#92](https://github.com/rstudio/helm/issues/92))

# 0.2.38

- Bump rstudio-library chart version
- Relax RBAC for `pod/logs` to remove write-related privileges

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
