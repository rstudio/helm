# 0.3.14

- A Service Account is now created by default. This is primarily to facilitate
  better IAM security when using Package Manager with S3.

- `pod.serviceAccountName` has been deprecated in favour of the new
  `serviceAccount.name` setting.

# 0.3.13

- Package Manager now enables the bundled R version (which is required to use
  Git-backed packages) by default.

# 0.3.12

- Add the ability to set annotations to the Persistent Volume Claim.

# 0.3.11

- Add configuration values for the pod's `labels`, `affinity`, `nodeSelector`, `tolerations`, and `priorityClassName` ([#206](https://github.com/rstudio/helm/issues/206)).

# 0.3.10

- The Package Manager container no longer runs as privileged by default.
  Instead, it uses stricter security settings with a smaller set of elevated
  privileges.

# 0.3.9

- Update `rstudio-library` chart version. Add support for lists in INI file sections.

# 0.3.8

- Add `securityContext` for pod and container as documented [here](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

# 0.3.7

-  Add `extraContainers` value. This allows adding a list of additional containers.

# 0.3.6

-  Add `pod.lifecycle` value. This allows running lifecycle hooks like postStart commands!

# 0.3.5

- Update default RStudio Package Manager version to 2022.04.0-7

# 0.3.4

- Fix ingress definition issues with older Kubernetes clusters ([#139](https://github.com/rstudio/helm/issues/139))

# 0.3.3

- Make `startupProbe`, `readinessProbe` and `livenessProbe` more configurable ([#97](https://github.com/rstudio/helm/issues/97))
  - They still use the `enabled` key to turn on or off
  - We then remove this key with `omit`, and pass the values verbatim to the template (as YAML)

# 0.3.2

- Update default RStudio Package Manager version to 2021.12.0-3

# 0.3.1

- Update `rstudio-library` chart version. This adds support for `extraObjects`
- Add `extraObjects` value. This allows deploying additional resources (with templating) straight from the values file!

# 0.3.0

- BREAKING: The generated service will now have type `ClusterIP` by default.
- Add support for setting the `loadBalancerIP` or `clusterIP`.
- Ignore `nodePort` settings when the service is not a `NodePort`.
- Improve the documentation for some service-related settings.

# 0.2.10

- Update `rstudio-library` chart version. This adds a helper for rendering `Ingress` resources
- Create `k8s.networking.io/v1` `Ingress` resource when `ingress.enabled: true` and Kubernetes version is >=1.19 ([#117](https://github.com/rstudio/helm/issues/117))

# 0.2.9

- Add `serviceMonitor` values for use with a Prometheus Operator

# 0.2.8

- Update `rstudio-library` chart dependency

# 0.2.7

- BREAKING: change `.image.pullPolicy` to `.image.imagePullPolicy` for consistency with other charts
- Add `imagePullSecrets` value option ([#57](https://github.com/rstudio/helm/issues/57))

# 0.2.6

- Update `rstudio-library` chart dependency

# 0.2.5

- Updated svc.yml to remove hardcoded port 80 and add .Values.service.port in its place. Updated values.yaml to include .Values.service.port (previously missing).

# 0.2.4

- Update `rstudio-library` dependency

# 0.2.3

- Update default RStudio Package Manager version to 2021.09.0-1

# 0.2.2

- Update `rstudio-library` dependency

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
