DIFF := "diff"
HELM_DOCS_VERSION := env_var_or_default("HELM_DOCS_VERSION", "1.13.1")
OS := if os() == "macos" {"Darwin"} else if os() == "linux" {"Linux"} else if os() == "windows" {"Windows"} else {""}
ARCH := if arch() == "aarch64" {"arm64"} else if arch() == "x86_64" {"x86_64"} else {""}

setup:
  #!/bin/bash
  set -xe
  if [ -f ./bin/helm-docs ]; then
    echo "Helm-docs is already installed"
    exit 0
  fi
  echo "Installing helm-docs version {{HELM_DOCS_VERSION}}"
  mkdir -p bin
  curl -L -s https://github.com/norwoodj/helm-docs/releases/download/v{{HELM_DOCS_VERSION}}/helm-docs_{{HELM_DOCS_VERSION}}_{{OS}}_{{ARCH}}.tar.gz -o bin/helm-docs.tar.gz
  tar -C ./bin -xz -f bin/helm-docs.tar.gz helm-docs
  rm -rf bin/helm-docs.tar.gz

update-lock:
  #!/bin/bash
  set -xe
  orig_dir=$(pwd)
  for dir in `ls charts`; do
    echo " --> Updating Chart.lock for $dir"
    cd "charts/$dir" && helm dependency update
    cd $orig_dir
  done
  echo " --> Done!"

all-docs:
  just docs rbac

docs:
  #!/bin/bash
  ./bin/helm-docs --chart-search-root=charts --template-files=README.md.gotmpl --template-files=./_templates.gotmpl
  ./bin/helm-docs --chart-search-root=other-charts --template-files=README.md.gotmpl --template-files=./_templates.gotmpl

rbac:
  #!/bin/bash
  set -xe
  cd ./charts/rstudio-launcher-rbac && helm dependency update && helm dependency build && cd -
  helm template -n rstudio rstudio-launcher-rbac ./charts/rstudio-launcher-rbac --set removeNamespaceReferences=true > examples/rbac/rstudio-launcher-rbac.yaml
  CHART_VERSION=$(helm show chart ./charts/rstudio-launcher-rbac | grep '^version' | cut -d ' ' -f 2)
  cp examples/rbac/rstudio-launcher-rbac.yaml examples/rbac/rstudio-launcher-rbac-${CHART_VERSION}.yaml

lint:
  #!/bin/bash
  ct lint ./charts --target-branch main

snapshot-rsw:
  #!/bin/bash
  set -e

  # The snapshots are named after the values files in `lint/`, which is where
  # the lint-only scenarios live. `ci/` belongs to chart-testing (`ct lint` /
  # `ct install`) and is deliberately not snapshotted.
  #
  # `global.secureCookieKey` and `launcherPem` are tables (`.value` /
  # `.existingSecret`), so they have to be set through their `.value` key.
  # Pinning them keeps the render deterministic: without them the chart
  # generates a fresh cookie key and RSA launcher key on every run.
  pin=(--set global.secureCookieKey.value=abc --set launcherPem.value=abc)
  outdir=charts/rstudio-workbench/snapshot
  failed=0

  render() {
    local out="$1"; shift
    echo "==> $out"
    if ! helm template -n rstudio ./charts/rstudio-workbench "${pin[@]}" "$@" > "$out.tmp"; then
      echo "ERROR: helm template failed for $out (snapshot not updated)" >&2
      rm -f "$out.tmp"
      failed=1
      return
    fi
    sed -e 's|\(helm\.sh/chart\:\ [a-zA-Z\-]*\).*|\1VERSION|g' "$out.tmp" > "$out"
    rm -f "$out.tmp"
  }

  render "$outdir/default.yaml"

  for file in ./charts/rstudio-workbench/lint/*.yaml; do
    render "$outdir/$(basename "$file")" -f "$file"
  done

  exit $failed

snapshot-rsw-lock:
  #!/bin/bash
  set -xe
  for file in `ls ./charts/rstudio-workbench/snapshot/*.yaml`; do
    cp $file $file.lock
  done

snapshot-rsw-diff:
  #!/bin/bash
  outdir=charts/rstudio-workbench/snapshot
  differed=0

  for lock in "$outdir"/*.yaml.lock; do
    file="${lock%.lock}"
    if [[ ! -f "$file" ]]; then
      echo "MISSING: $file was not generated (run \`just snapshot-rsw\` first)"
      differed=1
      continue
    fi
    if ! diff -q "$file" "$lock" > /dev/null; then
      echo "DIFF: $file"
      {{ DIFF }} "$lock" "$file"
      differed=1
    fi
  done

  for file in "$outdir"/*.yaml; do
    [[ -f "$file.lock" ]] || { echo "UNTRACKED: $file has no .lock baseline"; differed=1; }
  done

  if [[ $differed -eq 0 ]]; then
    echo "All snapshots match their .lock baselines"
  fi
  exit $differed

test chart='all':
  #!/usr/bin/env bash
  set -xe
  if [[ "{{ chart }}" == 'all' ]]; then
    for dir in $(ls -d {{ justfile_directory() }}/charts/*/); do
      helm unittest $dir
    done
  else
    helm unittest "charts/{{ chart }}"
  fi

test-connect-interpreter-versions:
  #!/usr/bin/env bash
  set -euo pipefail
  cd ./charts/rstudio-connect && helm dependency build && cd -

  # find the default image
  image=$(
    helm template ./charts/rstudio-connect \
    --set backends.kubernetes.enabled=false \
    --show-only templates/deployment.yaml | \
    grep "image\:.*posit/connect\:.*" | \
    awk -F": " '{print $2}' | \
    xargs)

  for lang in "Python" "Quarto" "R"
  do
    echo "Testing $lang"

    # print the default connect config file for local execution in ini format
    # print the section and grep for the Executables to find each interpreter
    executables=$(
      helm template ./charts/rstudio-connect \
      --set backends.kubernetes.enabled=false \
      --show-only templates/configmap.yaml | \
      sed -n -e "/\[$lang\]/,/\[*\]/ p" | \
      grep Executable | awk -F= '{print $2}' | \
      xargs || echo "")

    for ex in $executables
    do
      echo "Checking $ex"
      if ! docker run --rm $image /bin/bash -c "command -v $ex"; then
        echo "ERROR: $lang executable '$ex' configured in charts/rstudio-connect/values.yaml" >&2
        echo "       was not found in image '$image'." >&2
        echo "       Update the $lang Executable path in values.yaml to match the version shipped in the image:" >&2
        # derive the install root from the configured path, e.g.
        #   /opt/python/3.14.6/bin/python -> /opt/python (strip the version dir)
        #   /usr/local/bin/quarto         -> /usr/local (no version dir)
        install_root=$(dirname "$(dirname "$ex")")
        if [[ "$(basename "$install_root")" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
          install_root=$(dirname "$install_root")
        fi
        docker run --rm $image /bin/bash -c "ls -d $install_root/*/ 2>/dev/null" >&2 || true
        exit 1
      fi
    done
  done

push-docs:
    #!/usr/bin/env bash
    set -euxo pipefail

    s3_args=(--dryrun)
    if [[ "${GITHUB_REF:-}" == "refs/heads/main" ]] || [[ "${GITHUB_REF:-}" =~ ^refs/tags/v[0-9]{4}\.[0-9]{2}\.[0-9]+$ ]]; then
        s3_args=("")
    fi

    # The s3 bucket is s3://docs.rstudio.com/, which is available as https://docs.posit.co/
    aws s3 sync ${s3_args[*]:-} \
        _site \
        "s3://docs.rstudio.com/helm/"
