DIFF := "diff"

setup:
  #!/bin/bash
  # TODO: idempotency

  # TODO: check for macos
  mkdir -p ./bin/helm-docs-1.5.0/
  curl -L https://github.com/norwoodj/helm-docs/releases/download/v1.5.0/helm-docs_1.5.0_Darwin_x86_64.tar.gz | tar -xzvf - -C ./bin/helm-docs-1.5.0/
  ln -s $PWD/bin/helm-docs-1.5.0/helm-docs $PWD/bin/helm-docs

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
