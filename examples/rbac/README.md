# RBAC yaml examples

The RBAC associated with the RStudio Job Launcher is maintained in the
[rstudio-library](../../charts/rstudio-library) and
[rstudio-launcher-rbac](../../charts/rstudio-launcher-rbac) helm charts.

However, it is also maintained here in this directory [by CI](../../.github/workflows/chart-doc.yaml) for ease of use.
In order to generate these files from the chart, you can use:
```
helm repo add rstudio https://helm.rstudio.com
helm template -n rstudio rstudio-launcher-rbac rstudio/rstudio-launcher-rbac
```

> NOTE: the `rstudio-workbench` and `rstudio-connect` helm charts also use the
> `rstudio-library` chart to deploy their own RBAC


## Important Note

The rbac currently contains a `ClusterRoleBinding`, which requires a namespace
reference.

As a result, even though we use `--removeNamespaceReferences=true`, the
namespace persists on the `ClusterRoleBiding`. We use the `rstudio` namespace
by default.

Please modify the namespace as needed for your installation.

# Usage

If you are using the `rstudio` namespace (our default), then you can use either the "latest" RBAC directly:

```
kubectl apply -f https://raw.githubusercontent.com/rstudio/helm/main/examples/rbac/rstudio-launcher-rbac.yaml
```

Or you can use a particular version (versioned with the [`rstudio-launcher-rbac`](../../charts/rstudio-launcher-rbac)
helm chart):

```
kubectl apply -f https://raw.githubusercontent.com/rstudio/helm/main/examples/rbac/rstudio-launcher-rbac-0.2.2.yaml
```
