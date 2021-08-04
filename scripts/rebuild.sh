#!/usr/bin/env bash

# Set this to a valid URL *without* an index.yaml if you want to regenerate
# a new index.html. If you want to append to an existing one, you can
# use a real address like `https://helm.rstudio.com`. If an existing
# index.yaml is found at this URL, then any packages we generate will
# be appended, which can result in duplicates.
HELM_REPO=${HELM_REPO:-https://rstudio.com}

PACKAGE_DIR=${PACKAGE_DIR:-./.cr-release-packages}
CHARTS_DIR=${CHARTS_DIR:-charts}
INDEX=${INDEX:-index.yaml}
GITHUB_OWNER=${GITHUB_OWNER:-rstudio}
GITHUB_REPO=${GITHUB_REPO:-helm}

# Run this script from the root of the helm repo, e.g.
# ./scripts/rebuild.sh

# List all tags oldest to newest, followed by the 'main' branch.
tags="$(git tag -l  --sort=creatordate) main"

# Clean the packages release directory that `cr` uses.
mkdir -p ${PACKAGE_DIR}
rm -rf ${PACKAGE_DIR}/*

for tag in $tags; do
  git checkout "${tag}"
  charts=$(ls -1 ${CHARTS_DIR}/)
  for chart in $charts; do
    if [[ "${tag}" =~ ^${chart}.* ]]; then
      if [ -d ${CHARTS_DIR}/$chart ]; then
        if [ -f ${CHARTS_DIR}/$chart/Chart.yaml ]; then
          echo "Packaging chart $chart for tag ${tag}"
          cr package ${CHARTS_DIR}/$chart --package-path ${PACKAGE_DIR}
        fi
      fi
    fi
  done
done

echo "Writing index to ${INDEX}"
rm ${INDEX}
cr index --owner ${GITHUB_OWNER} --git-repo ${GITHUB_REPO} --charts-repo ${HELM_REPO} -p ${PACKAGE_DIR} -i ${INDEX}
