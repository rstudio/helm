### Off-Host Execution Beta User Migration

The off-host execution beta moving to GA also moves your content from Bionic to
Jammy by default. This will cause all content to get rebuilt. If all content being
rebuilt is acceptable, then no further action is necessary.

If you prefer a phased approach to migration, you may continue using the bionic
images for existing content and jammy images for new content.

> Note: All images used by existing content should be specified in either
`launcher.customRuntimeImages` or `launcher.additionalRuntimeImages`. If content
requires both bionic and jammy images, then you must use R source packages.
Binary packages will not work when multiple OS distributions are used.

1. If you are currently using `customRuntimeImages: 'base'` (the default),
use `values-base.yaml` as a reference for updating your values file.

2. If you are currently using `customRuntimeImages: 'pro'`,
use `values-prod.yaml` as a reference for updating your values file.


#### Technical Details

The values files in this directory contain overrides for the
chart's default `runtime.yaml` configurations. The `v0.5.0` version of the rstudio-connect
Helm chart contains a breaking change for users who are evaluating the Beta off-host execution
feature set. `v0.5.0` changes the default OS from `bionic` to `jammy` which is considered a breaking
change for existing content.

When migrating to the `v0.5.0` release, beta users should be aware that the set of
execution environments defined by `launcher.customRuntimeYaml` and `launcher.additionalRuntimeImages`
will be used to "bootstrap" Connect's database the first time Connect starts. Subsequent
restarts of Connect will not modify the database, even when a runtimes.yaml configuration is defined.

These example values are for users that are evaluating the off-host execution feature
set and have content currently deployed which depends on the default set of `bionic` images.
They define the previous default set of `bionic` images in the `launcher.additionalRuntimeImages` section,
but each image's "matching" has been set to `exact`.

Any new content that is building for the first time, or existing content that is re-building,
will attempt to match against the new default set of `jammy` images. Content that has already been
built with a `bionic` image can continue to _execute_ with that image until it rebuilds. If an
existing piece of content needs to be rebuilt and requires `bionic` for some reason, the Publisher
must _explicitly_ define a default execution environment for that content through the
content-settings (access pane) on the dashboard or via the server API.
