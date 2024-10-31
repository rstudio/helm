# Changelog

## 0.2.23

- Add helm unit test scaffold.

## 0.2.22

- Move the values files for linting and installation testing outside the chart directory so that we can iterate on them without releasing a new version of the chart

## 0.2.21

- Documentation site updates

## 0.2.20

- Updates to support standalone documentation site

## 0.2.18

- Bump rstudio-library to `0.1.27`
  - Fix an issue with `mountPath` and `subPath` when `license.file.mountSubPath` is `true`

## 0.2.17

- Update `rstudio-library` chart dependency
- Add the ability to add serviceAccount labels

## 0.2.16

- Update documentation for more clarity

## 0.2.15

- Update documentation to remove "beta" label and explain production recommendations

## 0.2.13+

- Update `rstudio-library` chart dependency
- Relax RBAC for `pod/logs` to remove write-related privileges

## 0.2.7+

- Update `rstudio-library` chart dependency

## 0.2.6

- Update `rstudio-library` dependency. This adds `pods/exec` access to the API
  - This is important for quitting sessions properly.

## 0.2.5

- Added a new parameter `clusterRoleCreate` to `values.yaml` to allow for disabling the creation of the
  `ClusterRole` that allows for access to the nodes API. This API is used to ensure that all of the IP addresses
  for nodes are available when reporting the addresses of the node that is running a particular job so that
  clients can connect to it. This is generally not a needed permission for the Launcher as the internal IP is
  usually sufficient, so it is disabled by default.

## 0.1.2

- Specify namespace in ClusterRoleBinding always (it is required)
    - This is unfortunate, because it makes our output YAML examples less portable

## 0.1.1

- Add `services.delete` permissions, which are required for proper launcher functioning

## 0.1.0

- Initial release
