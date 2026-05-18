# Posit Helm charts

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/rstudio)](https://artifacthub.io/packages/search?repo=rstudio)
[![GitHub license](https://img.shields.io/github/license/rstudio/helm.svg)](https://github.com/rstudio/helm/blob/main/LICENSE)

> [!IMPORTANT]
> **Chart version 0.20.0 contains breaking changes:**
>
> - Default images moved from `rstudio/` and `ghcr.io/rstudio/` to
>   `posit/` on [Docker Hub](https://hub.docker.com/u/posit) and
>   `ghcr.io/posit-dev/` on [GitHub Container Registry (GHCR)](https://github.com/orgs/posit-dev/packages).
> - The default tag format changed from `{tagPrefix}{appVersion}` to
>   `{appVersion}-{os}`.
>
> If you are upgrading from an earlier version, read the
> [image migration guide](https://docs.posit.co/helm/docs/migrating-to-posit-images.html) first.

## Usage

1. Install [Helm](https://helm.sh). Please refer to Helm's [documentation](https://helm.sh/docs/) for more information on getting started.

2. Add the Helm repo:

   ```console
   helm repo add rstudio https://helm.rstudio.com
   ```

3. View charts:

   ```console
   helm search repo rstudio
   ```

## Contents

Individual helm charts have their own documentation

- [Posit Connect](./charts/rstudio-connect) ([documentation](https://docs.posit.co/helm/charts/rstudio-connect/README.html))
- [Posit Workbench](./charts/rstudio-workbench) ([documentation](https://docs.posit.co/helm/charts/rstudio-workbench/README.html))
- [Posit Package Manager](./charts/rstudio-pm) ([documentation](https://docs.posit.co/helm/charts/rstudio-pm/README.html))
- [Posit Chronicle](./charts/posit-chronicle) ([documentation](https://docs.posit.co/helm/charts/posit-chronicle/README.html))

Examples:

- [All Examples](./examples)
    - [Posit Connect](./examples/connect/)
    - [Standalone RBAC for the Job Launcher](./examples/rbac)

### Other Charts

Supporting and miscellaneous charts with varying levels of maintenance, usefulness, and support

- [Library Chart](./charts/rstudio-library)
    - Supporting tools for building helm charts
- [Pre-pull Daemonset](./other-charts/prepull-daemonset)
    - Chart for deploying a daemonset that pulls container images to nodes

## Support

**IMPORTANT:**

These charts are provided as a convenience to Posit customers. If you have
questions about these charts, you can ask them in the
[issues](https://github.com/rstudio/helm/issues/new/choose) in the repository
or to your support representative, who will route them appropriately.

Bugs or feature requests should be opened in an [issue](https://github.com/rstudio/helm/issues/new/choose).

## Contributing

Posit values your contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for more information.

## License

[MIT License](./LICENSE)
