# RBAC yaml examples

The RBAC associated with the RStudio Job Launcher is maintained in the
[rstudio-launcher-rbac](../../charts/rstudio-launcher-rbac) helm chart.

However, it is also maintained here in this directory for ease of use. In order
to generate these files yourselves from the chart, you can use:
```
helm repo add rstudio https://helm.rstudio.com
helm template -n rstudio rstudio-launcher-rbac rstudio/rstudio-launcher-rbac
```

## Important Note

The rbac currently contains a `ClusterRoleBinding`, which requires a namespace
reference.

As a result, even though we use `--removeNamespaceReferences=true`, the
namespace persists on the `ClusterRoleBiding`. We use the `rstudio` namespace
by default.

Please modify the namespace as needed for your installation.
