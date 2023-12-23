# Changelog

## 0.1.28

- Tweak docs a bit

## 0.1.27

## 0.1.27

- Fix an issue with `mountPath` and `subPath` when `license.file.mountSubPath` is `true` ([##427](https://github.com/rstudio/helm/issues/427)).

## 0.1.26

- Add the capability to add labels to service accounts

## 0.1.25

- Update documentation to remove "beta" label and explain production recommendations

## 0.1.24

- Update RBAC to support listing of service accounts

## 0.1.23

- Add helpers for launcher template usage
- Relax rbac constraints on `pod/logs` ([##215](https://github.com/rstudio/helm/issues/215))

## 0.1.22

- Add support for list of INI file sections, like the following example

    ```yaml
    config:
      server:
        launcher.conf:
          cluster:
            - name: Cluster1
              type: Kubernetes
            - name: Cluster2
              type: Kubernetes
              config-file: /path/to/config/file
    ```

- Fixes issue where RBAC service account is always created even when `serviceAccountCreate: false`
  `serviceAccountCreate` is required and must be specified as a boolean

## 0.1.20

- Add a `_tplvalues.tpl` helper
  - this allows templating "extra" deployments in values
  - taken from [this excellent example by bitnami](https://github.com/bitnami/charts/blob/master/bitnami/common/templates/_tplvalues.tpl)

## 0.1.19

- Add an `Ingress` helper
  - Provides template for rendering `Ingress` `apiVersion` based on
    Kubernetes version
  - Provides template for rendering `Ingress` `backend` based on 
    `apiVersion`
  - Provides template for determining if `Ingress` `apiVersion` supports
    the `ingressClassName` field
  - Provides template for determining if `Ingress` `apiVersion` supports
    the `pathType` field

## 0.1.18

- Add newlines between array entries for `config.dcf` generation ([##108](https://github.com/rstudio/helm/issues/108))

## 0.1.17

- Add a `rstudio-library.config.txt` helper
  - Creates a generic text output
  - Allows comments (if using `key=value` pairs) and customizing the comment "delimiter" (`##` by default)
  - Example usage:
```
{{- $config := dict "data" (dict "some-file.txt" (dict "key" "value")) }} 
{{- include "rstudio-library.config.txt" $config }}

## results in
some-file.txt: |
  ## key
  value
```


## 0.1.16

- add `pods/exec` API access

## 0.1.15

- Added a new parameter `clusterRoleCreate` to `rstudio-library.rbac` to allow for disabling the creation of the 
  `ClusterRole` that allows for access to the nodes API. This API is used to ensure that all of the IP addresses
  for nodes are available when reporting the addresses of the node that is running a particular job so that 
  clients can connect to it. This is generally not a needed permission for the Launcher as the internal IP is 
  usually sufficient, so it is disabled by default. 

## 0.1.12 - 0.1.14

- Various descriptive changes to prepare for official release to the public

## 0.1.11

- Fix whitespace issue in `.ini` for arrays

## 0.1.10

- Fix a bug in `.dcf` and `.ini` file config that did not convert non-strings (i.e. bool, float64, etc.) to strings
  properly

## 0.1.9

- Make rstudio-library.config.ini handle plaintext values
- Make rstudio-library.config.dcf handle plaintext values
- Add testing for .ini and .dcf config files

## 0.1.8

- Add more json validation for cleaner error messaging
- Add a "debug" helper for type validation

## 0.1.7

- Allow separating `targetNamespace` from `namespace` for RBAC definition
  - In a future state, we might allow multiple namespaces... but we have not taken that on yet,
  because launcher does not support multiple namespaces yet

## 0.1.6

- Fix a few bugs in defaults ordering
- Add `deepCopy` to some of the more complex `profiles` helpers
  - This is important so that our modifications of objects do not surface to users of the chart
  - (i.e. this ensures they avoid weird edge cases and using `deepCopy` themselves)

## 0.1.5

- Fix a bug in empty profiles

## 0.1.4

- Add a bunch of profiles helpers

## 0.1.1

- Specify namespace in ClusterRoleBinding always (it is required)
  - This is unfortunate, because it makes our output YAML less portable

## 0.1.0

- Initial release
- Add RBAC, config helpers
