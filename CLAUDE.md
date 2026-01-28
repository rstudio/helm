# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the official Helm charts repository for Posit (formerly RStudio) products: Connect, Workbench, Package Manager, and Chronicle.

## Common Commands

### Just Commands (primary tool)
```bash
just setup              # Install helm-docs
just docs               # Generate README.md files from templates
just test               # Run helm unittest on all charts
just test <chart-name>  # Run tests for specific chart (e.g., just test rstudio-connect)
just lint               # Run chart-testing lint (ct lint)
just update-lock        # Update Chart.lock files for all charts
```

### Per-Chart Makefile Commands
```bash
cd charts/<chart-name>
make lint               # Lint chart with multiple values files
make template           # Generate Kubernetes manifests
make template-debug     # Generate with debug output
```

## Architecture

### Shared Library Pattern
- `rstudio-library` is a library chart containing reusable templates in `templates/*.tpl`
- All product charts depend on it via `repository: https://helm.rstudio.com`
- Key templates: `_helpers.tpl`, `_config.tpl`, `_rbac.tpl`, `_ingress.tpl`, `_license-*.tpl`, `_launcher-templates.tpl`

### Chart Structure
```
charts/<chart-name>/
├── Chart.yaml          # Metadata and dependencies
├── values.yaml         # Default configuration
├── README.md.gotmpl    # Documentation template (edit this, not README.md)
├── templates/          # Kubernetes resource templates
├── ci/                 # Test value files (excluded from package)
├── tests/              # helm-unittest test files
└── files/              # Static files (launcher templates)
```

### Documentation Generation
- READMEs are auto-generated using helm-docs from `README.md.gotmpl` templates
- Never edit `README.md` directly - edit the `.gotmpl` template
- CI auto-generates and commits docs back to PRs

## Critical Workflow Requirements

1. **Version bumping is mandatory**: Any change (including README templates) requires bumping the chart version in `Chart.yaml`
2. **CI runs only on local branches**: PRs from forks won't trigger full CI - contributors need branch access
3. **Library chart changes propagate**: Changes to `rstudio-library` affect all dependent charts

## Testing

Tests use [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin. Test files in `tests/*.yaml`:
```yaml
suite: Test Suite Name
templates:
  - deployment.yaml
tests:
  - it: should render correctly
    set:
      key: value
    asserts:
      - isKind:
          of: Deployment
```

## Job Launcher Templates

Template inheritance for Kubernetes job execution:
- Original templates: `examples/launcher-templates/default/<version>`
- Helm-modified versions: `examples/launcher-templates/helm/<version>-vN`
- Chart-embedded: `charts/<chart>/files/`

Template versions follow product versions, not launcher versions. Helm modifications use `vN` suffix.
