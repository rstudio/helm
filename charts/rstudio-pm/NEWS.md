# 0.2.1

- Update docs

# 0.2.0
- Breaking: Licensing configuration now uses a `license` section. For example,
  `license: my-key` should be changed to
  ```yaml
  license:
    key: my-key
  ```
- Added support for floating licenses and license files.

# 0.1.4

- Fix product config values to make our default container work
    - Add `Launcher.ServerUser=root` and `Launcher.AdminGroup=root`
- Bump RSPM version to 1.2.2.1-17
- Use `appVersion` from `Chart.yaml` and add `versionOverride`

# 0.1.3

- Add LICENSE.md for clarity

# 0.1.2

- Add ingress as an option
- Add annotations to deployment so that the pods roll when config changes

# 0.1.1

- Update Package Manager version to 1.2.2-4
- Update docs

# 0.1.0

- Change naming convention
    - This fixes issues with namespacing
    - However, it will damage backwards compatibility, particularly for PVCs if using `sharedStorage.create = true`
    - If you need to migrate data, set `replicas: 0`, upgrade, and then copy the data to the new PVC
    - Alternatively, you can set `fullnameOverride: "previous-release-name"` to force backwards compatibility
    - Finally, deployment selectors have changed, so you will need to delete the current deployment manually, then put back with `helm upgrade --install`
    - Use `helm diff upgrade` to ensure things are working as you expect before upgrading

# 0.0.8

- Fix quoting

# 0.0.7

- Add option for `podAnnotations`

# 0.0.6

- Add `autoNodePort` parameter to allow auto-providing the node port

# 0.0.5

- Revert apiVersion back to v1 for working in helm2

# 0.0.4

- BREAKING: rename secret for managing AWS credentials
- Add a secret for managing the rstudio-pm.key
- Add a command and args configuration options

# 0.0.3

- Add secret for managing AWS credentials

# 0.0.1

- Initial pass!
