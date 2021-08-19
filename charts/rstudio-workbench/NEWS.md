# 0.4.1

- Update docs

# 0.4.0

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
  some.json:
    "text"
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

# 0.3.7

- Make `secure-cookie-key` and `launcher.pem` autogeneration static
  - This means that the auto-generated values will persist across helm upgrades
  - It is still safest to define these values yourself

# 0.3.6

- Fix small reference issue in the prestart.bash script

# 0.3.5

- Decouple securityContext values from the main RSW container and the sidecar container

# 0.3.4

- remove "privileged: true", which is not necessary for rstudio-workbench server or sessions
- Add ingress as an option
- Add annotations to deployment so that the pods roll when config changes
- Switch the "secret" configurations to being an actual Secret

# 0.3.3

- Bump `load-balancer-manager` again (to `2.2`)
- Allow customization of load-balancer-manager env vars

# 0.3.2

- Fix a bug in the `load-balancer-manager` (`sidecar` container)
    - The helm chart (as a result of previous changes) no longer defines an `app` label, but an `app.kubernetes.io/name` label. 
    - update the selector, make error handling better, etc. This requires version 2.0 of the load-balancer-manager

# 0.3.1

- allow `global.secureCookieKey` as an option along with `secureCookieKey`
- ensure that no empty `launcher.pub` file is generated by default
- default image.tag to Chart.AppVersion

# 0.3.0
- BREAKING: changed `rstudio` container `command` and `args` to tell `tini` how to supervise processes and run a differently named prestart script. Also made `/usr/local/bin/startup.sh` script execution a part of the `args`.

# 0.2.2

- Update Workbench version to 1.4.1106-5
- Update docs

# 0.2.1

- rename to `rstudio-workbench` corresponding to upcoming `rstudio-server-pro` rebranding
- fix bug that was creating a test user by default
- add other licensing options (via `server`, `file`, and `secret` values)

# 0.2.0

- Change naming convention
    - Fix issues with namespacing
    - However, this will damage backwards compatibility, particularly for PVCs if using `sharedStorage.create = true`
    - If you need to migrate data, set `replicas: 0`, upgrade, and then copy the data to the new PVC
    - Alternatively, you can set `fullnameOverride: "previous-release-name"` to force backwards compatibility
    - Finally, deployment selectors have changed, so you will need to delete the current deployment manually, then put back with `helm upgrade --install`
    - Use `helm diff upgrade` to ensure things are working as you expect before upgrading
    
# 0.0.8

- add `jobJsonOverridesFiles` value option

# 0.0.7

- Made HA functional

# 0.0.5

- BREAKING: move storage\* values to a sharedStorage map
- Add homeStorage
- Add logging.conf

# 0.0.4

- Add a secret configmap for pem and pub keys

# 0.0.3

- BREAKING: Restructure the image values object
- Add image.pullPolicy
- Switch to image.repository and image.tag from image
- Allow customizing pod command and args

# 0.0.2

- Add database.conf and notifications.conf

# 0.0.1

- Initial pass!
