# function-template-python

[![CI](https://github.com/crossplane/function-template-python/actions/workflows/ci.yml/badge.svg)](https://github.com/crossplane/function-template-go/actions/workflows/ci.yml)

A template for writing a [composition function][functions] in [Python][python].

To learn how to use this template:

* [Follow the guide to writing a composition function in Python][function guide]
* [Learn about how composition functions work][functions]
* [Read the function-sdk-python package documentation][package docs]

If you just want to jump in and get started:

1. Replace `function-template-python` with your function's name in
   `package/crossplane.yaml`.
1. Add your logic to `RunFunction` in `function/fn.py`
1. Add tests for your logic in `test/test_fn.py`
1. Update this file, `README.md`, to be about your function!

This template uses [Python][python], [Docker][docker], and the [Crossplane
CLI][cli] to build functions.

```shell
# Run the code in development mode, for crossplane beta render
hatch run development

# Lint and format the code - see pyproject.toml
hatch fmt

# Run unit tests - see tests/test_fn.py
hatch test

# Build the function's runtime image - see Dockerfile
$ docker build . --tag=runtime

# Build a function package - see package/crossplane.yaml
$ crossplane xpkg build -f package --embed-runtime-image=runtime
```

[functions]: https://docs.crossplane.io/latest/concepts/composition-functions
[function guide]: https://docs.crossplane.io/knowledge-base/guides/write-a-composition-function-in-python
[package docs]: https://crossplane.github.io/function-sdk-python
[python]: https://python.org
[docker]: https://www.docker.com
[cli]: https://docs.crossplane.io/latest/cli


# Notes

```
hatch run development

cd example
crossplane render xr.yaml composition.yaml functions.yaml
```

CHAINSAW=chainsaw KUBECTL=kubectl ./uptest_darwin-arm64 e2e example/xr.yaml --setup-script="test/setup.sh"

CHAINSAW=chainsaw KUBECTL=kubectl CROSSPLANE_CLI=crossplane CROSSPLANE_NAMESPACE=crossplane-system YQ=yq ./uptest_darwin-arm64 e2e example/xr.yaml --test-directory=testtest --setup-script="test/setup.sh"

CHAINSAW=chainsaw KUBECTL=kubectl ./uptest_darwin-arm64 e2e example/xr.yaml --setup-script="test/setup.sh" --render-only --test-directory=test-manifests --default-conditions="Ready,Synced"


UPTEST_COMMAND = SKIP_DEPLOY_ARGO=$(SKIP_DEPLOY_ARGO) \
	KUBECTL=$(KUBECTL) \
	CHAINSAW=$(CHAINSAW) \
	CROSSPLANE_CLI=$(CROSSPLANE_CLI) \
	CROSSPLANE_NAMESPACE=$(CROSSPLANE_NAMESPACE) \
	YQ=$(YQ) \
	$(UPTEST) e2e $(UPTEST_INPUT_MANIFESTS) \
	--data-source="${UPTEST_DATASOURCE_PATH}" \
	--setup-script=$(UPTEST_SETUP_SCRIPT) \
	$(UPTEST_ARGS)