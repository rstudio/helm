# YAML Files

## Daemonset for `r-session-complete`

The following daemonsets are defined for either pre-pulling or forcing a re-pull of existing images

- [`daemonset-r-session-complete-dockerhub`](daemonset-r-session-complete-dockerhub)
- [`daemonset-r-session-complete-ghcr`](daemonset-r-session-complete-ghcr)

They differ only in which repository image they re-pull. This differs based on:

- Repository: `ghcr.io` (GitHub container registry) or `DockerHub`.
    - `DockerHub` images look like `rstudio/r-session-complete:2021.09.2-382.pro1`
    - `ghcr.io` images look like `ghcr.io/rstudio/r-session-complete:2021.09.2-382.pro1`
- Product version

Feel free to download one of these files and modify it for your purposes. It is important that your
daemonset references the exact same images that are used by your RStudio Workbench installation to ensure the image you are using is updated.  

### What is it

A
[daemonset](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
runs a single pod on every node of a Kubernetes cluster. In this case, we
deploy a daemonset that has an `initContainer` with `imagePullPolicy: "Always"`
that runs a simple `echo` command. Then the `pause` container takes over, and
nothing else happens for the life of the daemonset. When run in your kubernetes environment, this daemonset will force the specified image to be updated on each node. Later when sessions are started on that same node, they will use the updated image. 

### Usage

- Let's say that my Workbench installation uses images `rstudio/r-session-complete:2021.09.2-382.pro1`
- I would choose the repository (`DockerHub`) and product version (`2021.09.2-382.pro1`)
- This would lead me to the file [`daemonset-r-session-complete-dockerhub/prepull-rstudio-r-session-complete-bionic-2021.09.2-382.pro1.yaml`](./daemonset-r-session-complete-dockerhub/prepull-rstudio-r-session-complete-bionic-2021.09.2-382.pro1.yaml)
- I would get the "Raw" version of the file, and either download it or copy the URL. In this case, I would get:

https://raw.githubusercontent.com/rstudio/helm/main/examples/yaml/daemonset-r-session-complete-dockerhub/prepull-rstudio-r-session-complete-bionic-2021.09.2-382.pro1.yaml

- Apply this daemonset to my kubernetes cluster in the desired namespace (`default` in this case):
```
kubectl apply -n default -f https://raw.githubusercontent.com/rstudio/helm/main/examples/yaml/daemonset-r-session-complete-dockerhub/prepull-rstudio-r-session-complete-bionic-2021.09.2-382.pro1.yaml

# look at the status of the daemonset
kubectl -n default get pods
```

- When finished, if I do not want to keep the daemonset around:
```
kubectl delete -n default -f https://raw.githubusercontent.com/rstudio/helm/main/examples/yaml/daemonset-r-session-complete-dockerhub/prepull-rstudio-r-session-complete-bionic-2021.09.2-382.pro1.yaml
```

### Simple Usage for DockerHub

- Modify the below URL to select your desired product version

```
kubectl apply -n default -f https://raw.githubusercontent.com/rstudio/helm/main/examples/yaml/daemonset-r-session-complete-dockerhub/prepull-rstudio-r-session-complete-bionic-2021.09.2-382.pro1.yaml

# look at the status of the daemonset
kubectl -n default get pods

# When finished, if I do not want to keep the daemonset around:
# kubectl delete -n default -f https://raw.githubusercontent.com/rstudio/helm/main/examples/yaml/daemonset-r-session-complete-dockerhub/prepull-rstudio-r-session-complete-bionic-2021.09.2-382.pro1.yaml
```
