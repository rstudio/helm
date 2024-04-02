# Changelog

## 0.5.22

- Add documentation on running the Chronicle Agent on version 2024.03.0 as a sidecar container

## 0.5.21

- Updates to support standalone documentation site

## 0.5.20

- Removed`config.Server.RVersion` from the values.yaml. This does not need to be configured, R version auto-detection will be used ([#473](https://github.com/rstudio/helm/issues/473)).

## 0.5.19

- Add option to set `pod.terminationGracePeriodSeconds`

## 0.5.18

- Update default Posit Package Manager version to 2023.12.0-13

## 0.5.17

- Add licensing section to the README to provide guidance on using a license file, license key or license server.

## 0.5.16

- Update default Posit Package Manager version to 2023.08.4-20

## 0.5.15

- Bump rstudio-library to `0.1.27`
  - Fix an issue with `mountPath` and `subPath` when `license.file.mountSubPath` is `true`

## 0.5.14

- Update default Posit Package Manager version to 2023.08.0-16

## 0.5.13

- Change default operating system from `bionic` to `ubuntu2204` (`jammy`)
  - This is not a breaking change since it does not affect how Package Manager serves packages

## 0.5.12

- Add values for `serviceAccount.labels`

## 0.5.11

- Add `topologySpreadConstraints` values

## 0.5.10

- Add `podDisruptionBudget` values

## 0.5.9

- Update documentation and README for a bit more clarity

## 0.5.8

- Update default Posit Package Manager version to 2023.04.0-6

## 0.5.7

- Remove `pod.nodeSelector` value. It was not used before

## 0.5.6

- Update documentation to remove "beta" label and explain production recommendations

## 0.5.5

- Bump rstudio-library to `0.1.24`
  - Update RBAC definiton to support listing of service accounts

## 0.5.4

- Update default Posit Package Manager version to 2022.11.4-20

## 0.5.3

- Fix Package Manager default image reference

## 0.5.2

- Add `sharedStorage.volumeName` for PVCs that reference a PV
- Add `sharedStorage.selector` as well

## 0.5.1

- Fix a bug in the image reference. Images now have an operating system reference
  - Add an `image.tagPrefix` value for configuring the (current) `bionic-` prefix

## 0.5.0

- Update default Posit Package Manager version to 2022.11.2-18

## 0.4.0

- Update default RStudio Package Manager version to 2022.07.2-11

- Package Manager now runs as non-root by default and the default
  `containerSecurityContext` has been updated to reflect the permissions
  required to do so.

- There is a new top-level `enableSandboxing` setting that gives users a direct
  way to disable sandboxing of Git builds, which reduces the Kubernetes security
  requirements and should allow the Package Manager chart to run on any
  non-OpenShift cluster without modification.

- To handle the migration of existing data owned by `root`, there is now a Helm hook that essentially runs chown on the
  data directory every time a user runs `helm upgrade`. Unfortunately, we can't detect when we actually need to run this
  migration, so it currently runs unconditionally. The rook only runs when a PersistentVolumeClaim is being used for
  Package Manager storage. The hook can be disabled by setting `enableMigrations=false`; in the future when we no longer
  expect users to have root-owned data, this will become the default.

- Package Manager's encryption key (if specified in `rstudioPMKey`) is now read
  from an environment variable rather than being mounted into the container.
  This sidesteps an issue where this file is owned as root when mounted by
  Kubernetes but Package Manager itself requires 0600 file permissions.

## 0.3.15

- Bump rstudio-library chart version

## 0.3.14

- A Service Account is now created by default. This is primarily to facilitate
  better IAM security when using Package Manager with S3.

- `pod.serviceAccountName` has been deprecated in favour of the new
  `serviceAccount.name` setting.

## 0.3.13

- Package Manager now enables the bundled R version (which is required to use
  Git-backed packages) by default.

## 0.3.12

- Add the ability to set annotations to the Persistent Volume Claim.

## 0.3.11

- Add configuration values for the pod's `labels`, `affinity`, `nodeSelector`, `tolerations`, and `priorityClassName` ([##206](https://github.com/rstudio/helm/issues/206)).

## 0.3.10

- The Package Manager container no longer runs as privileged by default.
  Instead, it uses stricter security settings with a smaller set of elevated
  privileges.

## 0.3.9

- Update `rstudio-library` chart version. Add support for lists in INI file sections.

## 0.3.8

- Add `securityContext` for pod and container as documented [here](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

## 0.3.7

-  Add `extraContainers` value. This allows adding a list of additional containers.

## 0.3.6

-  Add `pod.lifecycle` value. This allows running lifecycle hooks like postStart commands!

## 0.3.5

- Update default RStudio Package Manager version to 2022.04.0-7

## 0.3.4

- Fix ingress definition issues with older Kubernetes clusters ([##139](https://github.com/rstudio/helm/issues/139))

## 0.3.3

- Make `startupProbe`, `readinessProbe` and `livenessProbe` more configurable ([##97](https://github.com/rstudio/helm/issues/97))
  - They still use the `enabled` key to turn on or off
  - We then remove this key with `omit`, and pass the values verbatim to the template (as YAML)

## 0.3.2

- Update default RStudio Package Manager version to 2021.12.0-3

## 0.3.1

- Update `rstudio-library` chart version. This adds support for `extraObjects`
- Add `extraObjects` value. This allows deploying additional resources (with templating) straight from the values file!

## 0.3.0

- BREAKING: The generated service will now have type `ClusterIP` by default.
- Add support for setting the `loadBalancerIP` or `clusterIP`.
- Ignore `nodePort` settings when the service is not a `NodePort`.
- Improve the documentation for some service-related settings.

## 0.2.10

- Update `rstudio-library` chart version. This adds a helper for rendering `Ingress` resources
- Create `k8s.networking.io/v1` `Ingress` resource when `ingress.enabled: true` and Kubernetes version is >=1.19 ([##117](https://github.com/rstudio/helm/issues/117))

## 0.2.9

- Add `serviceMonitor` values for use with a Prometheus Operator

## 0.2.8

- Update `rstudio-library` chart dependency

## 0.2.7

- BREAKING: change `.image.pullPolicy` to `.image.imagePullPolicy` for consistency with other charts
- Add `imagePullSecrets` value option ([##57](https://github.com/rstudio/helm/issues/57))

## 0.2.6

- Update `rstudio-library` chart dependency

## 0.2.5

- Updated svc.yml to remove hardcoded port 80 and add .Values.service.port in its place. Updated values.yaml to include .Values.service.port (previously missing).

## 0.2.4

- Update `rstudio-library` dependency

## 0.2.3

- Update default RStudio Package Manager version to 2021.09.0-1

## 0.2.2

- Update `rstudio-library` dependency

## 0.2.1

- Update docs

## 0.2.0
- Breaking: Licensing configuration now uses a `license` section. For example,
  `license: my-key` should be changed to
  ```yaml
  license:
    key: my-key
  ```
- Added support for floating licenses and license files.

## 0.1.4

- Fix product config values to make our default container work
    - Add `Launcher.ServerUser=root` and `Launcher.AdminGroup=root`
- Bump RSPM version to 1.2.2.1-17
- Use `appVersion` from `Chart.yaml` and add `versionOverride`

## 0.1.3

- Add LICENSE.md for clarity

## 0.1.2

- Add ingress as an option
- Add annotations to deployment so that the pods roll when config changes

## 0.1.1

- Update Package Manager version to 1.2.2-4
- Update docs

## 0.1.0

- Change naming convention
    - This fixes issues with namespacing
    - However, it will damage backwards compatibility, particularly for PVCs if using `sharedStorage.create = true`
    - If you need to migrate data, set `replicas: 0`, upgrade, and then copy the data to the new PVC
    - Alternatively, you can set `fullnameOverride: "previous-release-name"` to force backwards compatibility
    - Finally, deployment selectors have changed, so you will need to delete the current deployment manually, then put back with `helm upgrade --install`
    - Use `helm diff upgrade` to ensure things are working as you expect before upgrading

## 0.0.8

- Fix quoting

## 0.0.7

- Add option for `podAnnotations`

## 0.0.6

- Add `autoNodePort` parameter to allow auto-providing the node port

## 0.0.5

- Revert apiVersion back to v1 for working in helm2

## 0.0.4

- BREAKING: rename secret for managing AWS credentials
- Add a secret for managing the rstudio-pm.key
- Add a command and args configuration options

## 0.0.3

- Add secret for managing AWS credentials

## 0.0.1

- Initial pass!
