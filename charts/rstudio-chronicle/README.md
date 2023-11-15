# rstudio-chronicle

## Metrics
If you're running on a platform EKS cluster, you should be able to see metrics forwarded to datadog at https://posit-platform.datadoghq.com/dashboard/ey6-3dz-gf7/

## Releasing A New Chart Version
When you bump the chart version in the code, this should trigger an autorelease for you following the [release.yaml](https://github.com/rstudio/platform-helm/blob/main/.github/workflows/release.yaml) github action. https://github.com/rstudio/platform-helm/pull/102/files is a good example of this, where we bumped up the chronicle chart to version `1.1.0`.
