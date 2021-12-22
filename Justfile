update-lock:
  #!/bin/bash
  orig_dir=$(pwd)
  for dir in `ls charts`; do
    echo " --> Updating Chart.lock for $dir"
    cd "charts/$dir" && helm dependency update
    cd $orig_dir
  done
  echo " --> Done!"

docs:
  #!/bin/bash
  helm-docs --chart-search-root=charts --template-files=README.md.gotmpl --template-files=./_templates.gotmpl
  just rbac

rbac:
  #!/bin/bash
  cd ./charts/rstudio-launcher-rbac && helm dependency update && helm dependency build && cd -
  helm template -n rstudio rstudio-launcher-rbac ./charts/rstudio-launcher-rbac --set removeNamespaceReferences=true > examples/rbac/rstudio-launcher-rbac.yaml
  CHART_VERSION=$(helm show chart ./charts/rstudio-launcher-rbac | grep '^version' | cut -d ' ' -f 2)
  cp examples/rbac/rstudio-launcher-rbac.yaml examples/rbac/rstudio-launcher-rbac-${CHART_VERSION}.yaml
