# 0.2.2

- Update default RStudio Connect version to 2021.08.0

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
