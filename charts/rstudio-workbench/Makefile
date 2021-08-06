lint:
	helm lint --strict --set service.name=example --set service.version=0.0.1 -f ./ci/complex-values.yaml .
	helm lint --strict --set service.name=example --set service.version=0.0.1 -f ./ci/simple-values.yaml .
	helm lint --strict --set service.name=example --set service.version=0.0.1 -f ./ci/empty-values.yaml .
	helm lint --strict --set service.name=example --set service.version=0.0.1 -f ./ci/overrides-values.yaml .

template:
	helm template -f ci/simple-values.yaml .

template-complex:
	helm template -f ci/complex-values.yaml .

template-debug:
	helm template -f ci/simple-values.yaml --debug .
