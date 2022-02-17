# RStudio Workbench with Auto-Scaling

These files show you an example kubernetes auto-scaling configuration with RStudio Workbench. The two subdirectories, autoscaler and rstudio-workbench, contain specific configuration files that outline the parameters required to successfully set up kubernetes with auto-scaling. 

## Autoscaler

The [`values.yaml`](../auto-scaling/autoscaler/values.yaml) in the autoscaler folder outlines the configuration required for the cluster autoscaler. This is a component that automatically adjusts the size of a Kubernetes Cluster so that all pods have a place to run. We have provided a sample configuration for AWS EKS clusters. For more details see the [Kubernetes Autoscaler Repo](https://github.com/kubernetes/autoscaler).

Note: Autoscaler is a third party software maintained by the Kubernetes project. 


## RStudio Workbench
The [`values.yaml`](../auto-scaling/rstudio-workbench/values.yaml) in the rstudio-workbench folder outlines the timeout configurations required to set up this configuration. The file has 3 sections that need to be configured for autoscaling. 

- #### `rsession`
    - This section provides the configuration for the rsession.conf file which controls behaviour of the rsession process, allowing you to tune various R session paramaters. There are 4 parameters that need to be configured in this section. You can learn more about the options in the [RStudio Workbench Admin Guide](https://docs.rstudio.com/ide/server-pro/rstudio_server_configuration/rsession_conf.html#session-settings).

    ```yaml
    ...
    session-timeout-minutes: 5
    session-timeout-suspend: 1
    session-quit-child-processes-on-exit: 1
    session-timeout-kill-hours: 1
    ```

- #### `jupyter`
    - This section provides the configuration for the jupyter.conf file. There are 3 parameters that need to be configured in this section. You can learn more about the options in the [Jupyter Configuration section of the RStudio Workbench Admin Guide](https://docs.rstudio.com/ide/server-pro/latest/jupyter_sessions/configuration.html).

    ```yaml
    ...
    session-cull-minutes: 5
    session-shutdown-minutes: 3
    session-cull-connected: 1
    ```

- #### `launcher.kubernetes.profiles.conf`
    - This section provides the configuration for the Kubernetes Job Launcher Plugin. You will need to specify the job-json-overrides parameter to prevent the automatic eviction of pods. For more details see the [Kubernetes Plugin Configuration Guide](https://docs.rstudio.com/job-launcher/latest/kube.html#kube-config). 
    
    ```yaml
    ...
    job-json-overrides:
      - target: "/spec/template/metadata/annotations/cluster-autoscaler.kubernetes.io~1safe-to-evict"
        json: "false"
        name: evict-annotation
    ```
