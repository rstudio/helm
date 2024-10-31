# Changelog

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
