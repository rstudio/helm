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
