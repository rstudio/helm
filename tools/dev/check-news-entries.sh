#!/usr/bin/env bash
#
# Verify that changed charts with a version bump also have a NEWS.md entry
# for the new version. Runs in CI alongside the existing version bump check.
#
set -euo pipefail

TARGET_BRANCH="${1:-main}"
exit_code=0

for chart_dir in charts/*/  other-charts/*/; do
  chart_yaml="${chart_dir}Chart.yaml"
  news_md="${chart_dir}NEWS.md"

  [ -f "$chart_yaml" ] || continue

  # Get the current version
  current_version=$(grep '^version:' "$chart_yaml" | awk '{print $2}')

  # Get the version on the target branch
  base_version=$(git show "origin/${TARGET_BRANCH}:${chart_yaml}" 2>/dev/null | grep '^version:' | awk '{print $2}' || echo "")

  # Skip if version didn't change
  [ "$current_version" != "$base_version" ] || continue

  # Version was bumped — check for NEWS.md entry
  if [ ! -f "$news_md" ]; then
    echo "Error: ${chart_dir} has a version bump ($base_version -> $current_version) but no NEWS.md file."
    exit_code=1
    continue
  fi

  if ! grep -q "^## ${current_version}$" "$news_md"; then
    echo "Error: ${chart_dir}NEWS.md is missing an entry for version ${current_version}."
    echo "  Add a '## ${current_version}' section to ${news_md}."
    exit_code=1
  fi
done

if [ $exit_code -eq 0 ]; then
  echo "All changed charts have NEWS.md entries."
fi

exit $exit_code
