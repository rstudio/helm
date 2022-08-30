## Off-Host Execution with Custom Images

Uses `my-org/` as the docker image repository and `my-regcred` as
the [registry credential / imagePullSecret](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
for this
imaginary environment.

> NOTE: the `launcher.templateValues.pod.imagePullSecrets` provides the pod-level `imagePullSecret` that provides
> the secret to pull the `launcher.defaultInitContainer` as well.

### Usage

```bash
helm template rsc rstudio/rstudio-connect -f values.yaml -f runtime-values.yaml
```

### `values.yaml`

The `values.yaml` file contains most of the product configuration for this example. We discuss many of these
values [here.](https://docs.rstudio.com/helm/rstudio-connect/kubernetes-howto/appendices/arch_overview.html#remote-execution)

### `runtime-values.yaml`

In order to keep the size of values files manageable, this example also has a `runtime-values.yaml` values file. This
file contains configuration for `runtime.yaml` images for executing content. Documentation for content images
is [here](https://docs.rstudio.com/helm/rstudio-connect/kubernetes-howto/appendices/content_images.html).
