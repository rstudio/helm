# rstudio-library-test

Test harness chart for unit testing the `rstudio-library` Helm library chart.

## Overview

Helm library charts cannot be installed or tested directly because they only define template functions. This test harness chart depends on `rstudio-library` and creates test templates that exercise all library functions, enabling comprehensive unit testing with [helm-unittest](https://github.com/helm-unittest/helm-unittest).

## Prerequisites

- Helm 3.x
- helm-unittest plugin: `helm plugin install https://github.com/helm-unittest/helm-unittest.git`

## Running Tests

```bash
# Update dependencies first
helm dependency update other-charts/rstudio-library-test

# Run all tests
helm unittest other-charts/rstudio-library-test
```

## Test Coverage

The test suite covers all `rstudio-library` template functions:

| Test File | Library Templates Tested |
|-----------|-------------------------|
| `config_test.yaml` | `config.gcfg`, `config.ini`, `config.dcf`, `config.json`, `config.txt` |
| `ingress_test.yaml` | `ingress.apiVersion`, `ingress.path`, `ingress.backend`, `ingress.supportsIngressClassName`, `ingress.supportsPathType` |
| `license_test.yaml` | `license-env`, `license-mount`, `license-volume`, `license-secret` |
| `rbac_test.yaml` | `rbac` (ServiceAccount, Role, RoleBinding, ClusterRole) |
| `profiles_test.yaml` | `profiles.ini`, `profiles.ini.singleFile`, `profiles.ini.collapse-array`, `profiles.ini.advanced`, `profiles.json-from-overrides-config`, `profiles.apply-everyone-and-default-to-others` |
| `debug_test.yaml` | `debug.type-check` |
| `launcher_templates_test.yaml` | `templates.skeleton`, `templates.dataOutput`, `templates.dataOutputPretty` |
| `tplvalues_test.yaml` | `tplvalues.render` |
| `chronicle_agent_test.yaml` | `chronicle-agent.image`, `chronicle-agent.serverAddress` |

## Test Structure

Each test file follows this pattern:
1. Includes the base values file (`tests/_base_values.yaml`) which nullifies all test categories
2. Overrides only the specific test values needed for that test
3. Uses assertions to verify expected output

The `_base_values.yaml` file provides test isolation by setting all test categories to `null`, preventing unrelated templates from rendering during tests.

## Adding New Tests

When adding tests for new `rstudio-library` templates:

1. Create a test template in `templates/test-*.yaml` that invokes the library template
2. Add test values to `values.yaml` with documentation comments
3. Update `tests/_base_values.yaml` to include the new test category (set to `null`)
4. Create a test file in `tests/*_test.yaml` that includes `_base_values.yaml` and overrides only needed values

## Manual Verification

To manually verify template output:

```bash
helm template test-release other-charts/rstudio-library-test

# Test specific template
helm template test-release other-charts/rstudio-library-test -s templates/test-config.yaml
```
