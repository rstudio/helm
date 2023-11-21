lint:
	helm lint --strict --set service.name=example --set service.version=0.0.1 -f ./ci/empty-values.yaml .
	helm lint --strict --set service.name=example --set service.version=0.0.1 -f ./ci/simple-values.yaml .
	helm lint --strict --set service.name=example --set service.version=0.0.1 -f ./ci/complex-values.yaml .

template:
	helm template -f ci/complex-values.yaml . --debug

template-all:
	helm template -f ci/empty-values.yaml .
	helm template -f ci/simple-values.yaml .
	helm template -f ci/no-local-storage-values.yaml .
	helm template -f ci/complex-values.yaml .
