# Changelog

## 0.4.0

- Improvements for chart annotations.
- Values changes.
  - Replace upper-case values with lower-case to avoid confusion and follow Helm best practices.
  - Allow name and namespace overrides in chart values.
  - Add common labels and annotations values to apply to all resources.
  - Moves default tag source to appVersion, image.tag changed to a blank override.
  - Separated an image.registry value from the image.repository value.
  - Improve documentation of values.yaml and add a values.schema.json definition for input validation.
  - An S3 bucket must now be specified in S3 Storage backend is enabled.
- Changes to chart behavior.
  - Resource names are now applied dynamically based on the release name.
  - Additional default recommended Kubernetes labels have been applied to all resources.
  - Storage configuration is now validated and requires at least one of local or s3 storage be enabled.
  - `extraSecretMounts` can now be specified to mount additional secrets, such as certificates, into the pod.
  - Storage class can now be overridden on the pod's volume claim template.
  - Selector labels definitions between pod and service are now merged into a single definition. Removed the ability to override these values.
  - Add support for additional custom manifest input via `extraObjects` value.
- Add unittests for chart templates.
- Various Chart.yaml metadata changes.
  - Fix logo URL.
  - Add suggestions for compatible product charts.
  - Add annotation to include source image used in pod.

## 0.3.8

- Update documentation and support links.

## 0.3.7

- Bump Chronicle to version 2025.03.0

## 0.3.6

- Bump Chronicle to version 2024.11.0

## 0.3.5

- Change the default value for LocalStorage.Enabled to `true` in order for installations with the default values to work out of the box.

## 0.3.4

- Add helm unit test scaffold.

## 0.3.3

- Move the values files for linting and installation testing outside the chart directory so that we can iterate on them without releasing a new version of the chart

## 0.3.2

- Bump Chronicle to version 2024.09.0

## 0.3.1

- Documentation site updates

## 0.3.0

- Bump Chronicle to version 2024.03.0
- Moves `pod.NodeSelector` value to the top level as `NodeSelector`, in line with other charts
- Disable local storage by default

## 0.2.2

- Updates to support standalone documentation site

## 0.2.1

- Update docs

## 0.2.0

- Add values for `pod.terminationGracePeriodSeconds` and default `image.imagePullPolicy` = `IfNotPresent`

## 0.1.0

- Initial public release and integration into Posit's Helm repository. Includes
  the new `posit-chronicle` chart, CI components, and documentation.
