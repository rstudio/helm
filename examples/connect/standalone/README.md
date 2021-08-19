# RStudio Connect Standalone

## Example Setup

Add the RStudio Helm charts repository to your Kubernetes cluster:

```sh
helm repo add rstudio https://helm.rstudio.com
```

Export the RStudio Connect license key as an environment variable. 

```sh
export RSC_LICENSE="THIS-IS-THE-LICENSE"
```

Install the Helm chart using the configuration provided in the [`values.yaml`](./values.yaml)
file:

```sh
helm install rstudio/rstudio-connect -f ./values.yaml --set license.key=$RSC_LICENSE --generate-name
```

## Context

The [`values.yaml`](./values.yaml) file in this folder configures a standalone deployment of the
RStudio Connect Helm chart. If you want to see the different configurable values
beyond the ones included in this example execute:

```
helm show values rstudio/rstudio-connect
```

The file for this example has four different sections, separated by
YAML top-level keys, specifying the different areas of configuration:

- #### `sharedStorage`

  - This section configures which storage provisioner to use with the
    deployment, the size of the storage, which access modes it has, and what
    will be the mounting point. The example assigns an empty string as that
    means the deployment will use the cluster's default supported storage provisioner.
    To find more about the different storage provisioners, see
    in the [Kubernetes
    documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner).
    

- #### `image`

  - This section configures which image to use for the deployment. The example
    deploys the `rstudio/rstudio-connect:1.8.6.2` image from DockerHub, but it
    can use a custom image if needed to by either publishing a public image or
    by configuring the Kubernetes cluster to pull from a private image registry.
    

- #### `replicas`

  - This section configures how many pods to deploy of your application. The
    example uses 1 because it's for a single deployment. However this doesn't
    mean that by increasing replicas `> 1` you will have a High
    Availability deployment configured. If you want to deploy a High
    Availability setup you can read about all of the requirements in the
    [product's Admin Guide](https://docs.rstudio.com/connect/admin/)

- #### `config`

  - This section configures RStudio Connect and its different components. The
    different YAML key-value pairs will be injected into the RStudio Connect
    configuration file. To read more about how to configure RStudio Connect
    follow the [product's Admin Guide](https://docs.rstudio.com/connect/admin/appendix/configuration/#Server).
