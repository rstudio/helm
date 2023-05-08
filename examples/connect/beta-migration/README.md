### Off-Host Execution Beta User Migration Values Examples

The values files `values-base.yaml` and `values-pro.yaml` contain overrides for the
chart's default `runtime.yaml` configurations. The `v0.5.0` version of the rstudio-connect
Helm chart contains a breaking change for users who are evaluating the Beta off-host execution
feature set. `v0.5.0` changes the default OS from `bionic` to `jammy` which is considered a breaking
change for existing content.

When migrating to the `v0.5.0` release, beta users should be aware that the set of
execution environments defined by `launcher.customRuntimeYaml` and `launcher.additionalRuntimeImages`
will be used to "bootstrap" Connect's database the first time Connect starts. Subsequent
restarts of Connect will not modify the database, even when a runtimes.yaml configuration is defined.

These sample values are for users that are evaluating the off-host execution feature
set and have content currently deployed which depends on the default set of `bionic` images.
These example values files define the default set of `bionic` images in the
`launcher.customRuntimeYaml` section, but each image's "matching" has been set to `exact`.
The `launcher.additionalRuntimeImages` contains the _new_ default set of `jammy` images,
however the `jammy` images _do not_ define a matching strategy.

Any new content that is building for the first time, or existing content that is re-building,
will attempt to match against the set of `jammy` images. Content that has already been
built with a `bionic` image can continue to _execute_ with that image until it rebuilds. If an existing
piece of content needs to be rebuilt and requires `bionic` for some reason, the Publisher
must _explcitly_ define a default execution enviornment for that content through the content-settings
(access pane) on the dashboard or via the server API.
