# Posit Chronicle

![Version: 0.4.0](https://img.shields.io/badge/Version-0.4.0-informational?style=flat-square) ![AppVersion: 2025.03.0](https://img.shields.io/badge/AppVersion-2025.03.0-informational?style=flat-square)

#### _Official Helm chart for Posit Chronicle Server_

[Posit Chronicle](https://docs.posit.co/chronicle/) helps data science managers and other stakeholders understand their
organization's use of other Posit products, primarily Posit Connect and
Workbench.

## For production

To ensure a stable production deployment:

* "Pin" the version of the Helm chart that you are using. You can do this using the:
  * `helm dependency` command *and* the associated "Chart.lock" files *or*
  * the `--version` flag.
 
    ::: {.callout-important}
    This protects you from breaking changes.
    :::

* Before upgrading check for breaking changes using `helm-diff` plugin and `helm diff upgrade`.
* Read [`NEWS.md`](./NEWS.md) for updates on breaking changes and the documentation below on how to use the chart.

## Installing the chart

To install the chart with the release name `my-release` at version 0.4.0:

```{.bash}
helm repo add rstudio https://helm.rstudio.com
helm upgrade --install my-release rstudio/posit-chronicle --version=0.4.0
```

To explore other chart versions, look at:

```{.bash}
helm search repo rstudio/posit-chronicle -l
```

## Usage

This chart deploys only the Chronicle server and is meant to be used in tandem
with the Workbench and Connect charts. To actually send data to the server, you
will need to run the Chronicle agent as a sidecar container on your
Workbench or Connect server pods by adding a native sidecar Chronicle agent
definition to the `initContainers` value in their respective `values.yaml` files.

Here is an example of Helm values to run the agent sidecar in **Workbench**,
where we set up a shared volume between containers for audit logs:

```yaml
pod:
  # We will need to create a new volume to share audit logs between
  # the rstudio (workbench) and chronicle-agent containers
  volumes:
    - name: logs
      emptyDir: {}
  volumeMounts:
    - name: logs
      mountPath: "/var/lib/rstudio-server/audit"
initContainers:
  - name: chronicle-agent
    image: ghcr.io/rstudio/chronicle-agent: