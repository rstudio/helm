# RStudio Helm charts

## Usage

1. Install [Helm](https://helm.sh). Please refer to Helm's [documentation](https://helm.sh/docs/) for more information on getting started.

2. Add the RStudio Helm repo:

   ```console
   helm repo add rstudio https://helm.rstudio.com
   ```

3. View charts:

   ```console
   helm search repo rstudio
   ```

## Contents

Individual helm charts have their own documentation

- [RStudio Connect](./charts/rstudio-connect)
- [RStudio Workbench](./charts/rstudio-workbench)
- [RStudio Package Manager](./charts/rstudio-pm)

Examples:

- [All Examples](./examples)
    - [RStudio Connect](./examples/connect/)
    - [Standalone RBAC for the Job Launcher](./examples/rbac)

## Support

**IMPORTANT:** 

These charts are provided as a convenience to RStudio customers and are not formally supported by RStudio. If you
have questions about these charts, you can ask them in the [issues](https://github.com/rstudio/helm/issues/new/choose) 
in the repository or to your support representative, who will route them appropriately.

Bugs or feature requests should be opened in an [issue](https://github.com/rstudio/helm/issues/new/choose).

## Contributing

RStudio values your contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for more information.

## License

[MIT License](./LICENSE)
