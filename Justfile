DIFF := "diff"
HELM_DOCS_VERSION := env_var_or_default("HELM_DOCS_VERSION", "1.13.1")
OS := if os() == "macos" {"Darwin"} else if os() == "linux" {"Linux"} else if os() == "windows" {"Windows"} else {""}
ARCH := if arch() == "aarch64" {"arm64"} else if arch() == "x86_64" {"x86_64"} else {""}

setup:
  #!/bin/bash
  set -xe
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
  set -xe

  helm template -n rstudio ./charts/rstudio-workbench --set global.secureCookieKey="abc" --set launcherPem="abc" | sed -e 's|\(helm\.sh/chart\:\ [a-zA-Z\-]*\).*|\1VERSION|g' > charts/rstudio-workbench/snapshot/default.yaml

  for file in `ls ./charts/rstudio-workbench/ci/*.yaml`; do
    filename=$(basename $file)
    helm template -n rstudio ./charts/rstudio-workbench --set global.secureCookieKey="abc" --set launcherPem="abc" -f $file | sed -e 's|\(helm\.sh/chart\:\ [a-zA-Z\-]*\).*|\1VERSION|g' > charts/rstudio-workbench/snapshot/$filename
  done

snapshot-rsw-lock:
  #!/bin/bash
  set -xe
  for file in `ls ./charts/rstudio-workbench/snapshot/*.yaml`; do
    cp $file $file.lock
  done

snapshot-rsw-diff:
  #!/bin/bash
  set -x
  for file in `ls ./charts/rstudio-workbench/snapshot/*.yaml`; do
    echo Diffing $file
    if [[ `diff -q $file $file.lock` ]]; then
        {{ DIFF }} $file $file.lock
    fi
  done

test-connect-interpreter-versions:
  #!/usr/bin/env bash
  set -xe
  cd ./charts/rstudio-connect && helm dependency build && cd -

  # find the default image
  image=$(
    helm template ./charts/rstudio-connect \
    --show-only templates/deployment.yaml | \
    grep "image\:.*rstudio-connect.*" | \
    awk -F": " '{print $2}' | \
    xargs)

  for lang in "Python" "Quarto" "R"
  do
    # print the default connect config file for local execution in ini format
    # print the section and grep for the Executables to find each interpreter
    executables=$(
      helm template ./charts/rstudio-connect \
      --set config.Launcher.Enabled=false \
      --show-only templates/configmap.yaml | \
      sed -n -e "/\[$lang\]/,/\[*\]/ p" | \
      grep Executable | awk -F= '{print $2}' | \
      xargs)

    for ex in $executables
    do
      docker run --rm $image /bin/bash -c "command -v $ex"
    done
  done
