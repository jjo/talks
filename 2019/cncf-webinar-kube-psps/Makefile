# Simple Makefile to build out/... yaml tree, from src/... jsonnet sources
#
SRCS=src/c01/psp.jsonnet

all: reqs jb-install build

build:
	./scripts/build.sh $(SRCS)

jb-install:
	@test -d vendor/kube-libsonnet || jb install

reqs: check-jq check-jsonnet check-python3 check-kubecfg

check-%:
	@which $(*) >/dev/null || $(call missing,$(*))

URL_jb := https://github.com/jsonnet-bundler/jsonnet-bundler
URL_kubecfg := https://github.com/bitnami/kubecfg
URL_jsonnet := https://github.com/google/go-jsonnet
URL_python3 := your distro?
missing = { $(eval URL=$(URL_$(1))) echo "ERROR: missing $(1), install from: $(URL)"; exit 1; }
