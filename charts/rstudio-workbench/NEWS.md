# 0.5.3

- Make `startupProbe`, `readinessProbe` and `livenessProbe` more configurable ([#97](https://github.com/rstudio/helm/issues/97))
  - They still use the `enabled` key to turn on or off
  - We then remove this key with `omit`, and pass the values verbatim to the template (as YAML)

# 0.5.2

- Update `rstudio-library` chart version. This adds support for `extraObjects`
- Add `extraObjects` value. This allows deploying additional resources (with templating) straight from the values file!

# 0.5.1

- Update `rstudio-library` chart version. This adds a helper for rendering `Ingress` resources
- Create `k8s.networking.io/v1` `Ingress` resource when `ingress.enabled: true` and Kubernetes version is >=1.19 ([#117](https://github.com/rstudio/helm/issues/117))

# 0.5.0

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
- Add `imagePullSecrets` value option ([#57](https://github.com/rstudio/helm/issues/57))
- Add `config.pam` values option to add pam config files
- Add config-maps to configure startup behavior (`config.startupCustom`)
- Add a config setting for `sssd` (now in the container by default) (`config.userProvisioning`)
- Add a "secret" configmap for session components (useful for shared database credentials, `odbc.ini`,
  etc.) (`config.sessionSecret`)
- Update README to make `job-json-overrides`, profiles, user provisioning, etc. more clear
- Update `rstudio-library` chart dependency
  - BUGFIX: Address an issue with how `launcher-mounts` was generated incorrectly ([#108](https://github.com/rstudio/helm/issues/108))
- Add a `pod.labels` values option ([#101](https://github.com/rstudio/helm/issues/101))
- Modify how supervisord starts sssd with `config.startupUserProvisioning` values option ([#110](https://github.com/rstudio/helm/issues/110))

# 0.4.6

- Updated svc.yml to remove hardcoded port 80 and add .Values.service.port in its place. Updated values.yaml to include .Values.service.port (previously missing).

# 0.4.5

- Update `rstudio-library` chart version. This adds `pods/exec` privilege to RBAC
  - This is important for sessions to exit properly

# 0.4.4

- Added a new parameter `rbac.clusterRoleCreate` to `values.yaml` to allow for disabling the creation of the 
  `ClusterRole` that allows for access to the nodes API. This API is used to ensure that all of the IP addresses
  for nodes are available when reporting the addresses of the node that is running a particular job so that 
  clients can connect to it. This is generally not a needed permission for the Launcher as the internal IP is 
  usually sufficient, so it is disabled by default.

# 0.4.3

- BUGFIX: The load-balancer sidecar container was not selecting app labels properly. This is now fixed. It could have been causing issues in load-balanced setups

# 0.4.2

- BUGFIX: session configuration is now mounted to the proper location on session pods
- BUGFIX: Prometheus annotations are now properly defined (they were using the wrong port)
- BUGFIX: The Graphite Exporter regex had a bug that did not handle certain hostnames
- Customizing the graphite exporter "mapping.yaml" is now configurable by defining `.Values.prometheusExporter.mappingYaml`

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
