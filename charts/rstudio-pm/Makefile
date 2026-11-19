# Developer helpers. Not shipped with the chart (see .helmignore).
#
# lint/  - values files used for linting/templating only. Some of these
#          describe configurations that are too heavy (or impossible) to
#          actually install, so they deliberately live outside ci/.
# ci/    - fixtures consumed by chart-testing (`ct lint` / `ct install`).
#
# The lint target globs lint/*.yaml rather than listing files so it cannot
# drift as values files are added or renamed.

LINT_VALUES := $(wildcard lint/*.yaml)
HELM_SET := --set service.name=example --set service.version=0.0.1

.PHONY: lint template template-debug

lint:
	@for f in $(LINT_VALUES); do \
		echo "==> helm lint --strict -f $$f"; \
		helm lint --strict $(HELM_SET) -f "$$f" . || exit 1; \
	done

template:
	helm template $(HELM_SET) -f lint/simple-values.yaml .

template-debug:
	helm template $(HELM_SET) -f lint/simple-values.yaml --debug .
