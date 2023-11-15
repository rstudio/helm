lint:
	helm lint --strict --set service.name=example --set service.version=0.0.1 -f ./ci/empty-values.yaml .
	helm lint --strict --set service.name=example --set service.version=0.0.1 -f ./ci/simple-values.yaml .

template:
	helm template -f ci/simple-values.yaml .

template-debug:
	helm template -f ci/simple-values.yaml --debug .
