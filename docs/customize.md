# Customize Kubernetes Jobs

This doc discusses customizing Kubernetes Jobs in the context of the Posit Job Launcher.
This is relevant for both Posit Workbench and Posit Connect when the job launcher is enabled.

## Job Json Overrides

The original mechanism for modifying kubernetes jobs using the Job Launcher is to use 
[`job-json-overrides`](https://docs.posit.co/ide/server-pro/job_launcher/job_launcher.html).

See the [documentation](https://docs.posit.co/ide/server-pro/job_launcher/kubernetes_plugin.html#kube-json) discussing this topic in more detail.

In helm, there is a helper that simplifies some of this configuration. As a result, we will include several snippets
below to simplify use cases.

### How it works

The `rstudio-library` chart will ensure that:
- this "nicer format" will be transformed into a "real" `job-json-overrides` configuration field
```
"*":
  job-json-overrides:
    - name:
      target:
      json:
```
  - overrides in the `"*"` section are added to groups (`@mygroup`) and users (`username`)
  - json blobs (`json` key) are written to disk at an appropriate location with filename `{{ name }}.json`
  - the array is aggregated into the required comma-separated list
  - the `target` part of the job spec will be modified by the Job Launcher

**IMPORTANT:** `name` is arbitrary, but must be unique! (And should contain no spaces)

See examples below.

### Override Syntax

The `job-json-override` spec is discussed in detail [in the Posit Launcher documentation](https://docs.posit.co/ide/server-pro/job_launcher/job_launcher.html).
It uses the [JSON Pointer RFC](https://tools.ietf.org/html/rfc6901).

Some points that are helpful to reference:

- An array suffixed with `-` will "append" to the array (i.e. `/spec/templates/spec/volumes/-` will leave pre-defined volumes
  intact, but add a new entry)
- The character combination `~1` in the `target` will resolve to `/`. This can be especially useful for [annotation keys](#annotation).
- The character combination `~0` in the `target` will resolve to `~`

### Examples

#### nodeSelector / Placement Constraints

Add a placement constraint to the session pod with key `kubernetes.io/key` and value `value`

```
"*":
  job-json-overrides:
    - name: placement-constraint
      target: /spec/template/spec/nodeSelector/kubernetes.io~1key
      json: "value"
```

**NOTE**: it is possible to use
the [`placement-constraints` configuration](https://docs.posit.co/ide/server-pro/job_launcher/job_launcher.html) within the "
Profiles" configuration. However, this modifies the Workbench UI and is not enabled by default. (It requires user input to have
the profiles included)

It is also possible to override the entire `nodeSelector` object, but this would conflict with any user-defined
placement constraints.

#### serviceAccountName

Set the `serviceAccountName` to `my-service-account`

```
"*":
  job-json-overrides:
    - name: service-account
      target: /spec/template/spec/serviceAccountName
      json: "my-service-account"
```

#### imagePullSecrets

Set an `imagePullSecret` called `my-pull-secret`

```
"*":
  job-json-overrides:
    - name: imagePullSecrets
      target: "/spec/template/spec/imagePullSecrets"
      json:
        - name: my-pull-secret
```

#### imagePullPolicy

Set the `imagePullPolicy` to `"Always"`

```
"*":
  job-json-overrides:
    - target: "/spec/template/spec/containers/0/imagePullPolicy"
      json: "Always"
      name: imagePullPolicy
```

#### annotation

Add an annotation with key `my.company.com/key` and value `my-annotation-value`

```
"*":
  job-json-overrides:
    - name: add-company-annotation
      target: /spec/template/metadata/annotations/my.company.com~1key
      json: "my-annotation-value"
```

#### nodeAffinity

Add a `nodeAffinity` for nodes with `kubernetes.io/hostname` label `node-hostname`

```
"*":
  job-json-overrides:
    - name: node-affinity
      target: /spec/template/spec/affinity
      json:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                - key: kubernetes.io/hostname
                  operator: "In"
                  values:
                    - node-hostname
```

#### ConfigMap

Add a ConfigMap called `my-configmap` to the session pod at `/etc/configmap`

```
"*":
  job-json-overrides:
    - name: add-configmap-volume
      target: /spec/template/spec/volumes/-
      json:
        name: configmap-volume
        configMap:
            name: my-configmap
    - name: add-configmap-volume-mount
      target: /spec/template/spec/containers/0/volumeMounts/-
      json:
        name: configmap-volume
        mountPath: /etc/configmap
```

#### PersistentVolumeClaim / Other Volume

Add another volume to the session pod. This time, a `PersistentVolumeClaim` named `my-pvc`, mounted at `/mnt/data`

```
"*":
  job-json-overrides:
    - name: add-pvc-volume
      target: /spec/template/spec/volumes/-
      json:
        name: pvc-volume
        persistentVolumeClaim:
          claimName: my-pvc
    - name: add-pvc-volume-mount
      target: /spec/template/spec/containers/0/volumeMounts/-
      json:
        name: pvc-volume
        mountPath: /mnt/data
```
