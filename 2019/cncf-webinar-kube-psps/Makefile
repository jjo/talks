all: reqs jb-install build

SRCS=src/c01/psp.jsonnet

build:
	./scripts/build.sh $(SRCS)
jb-install:
	@test -d vendor/kube-libsonnet || jb install

reqs: check-jq check-jsonnet check-python3 check-kubecfg

check-%:
	@which $(*) >/dev/null || $(call missing,$(*))

URL_jb :=
URL_kubecfg :=
URL_jsonnet :=
URL_python3 := your distro?
missing = { $(eval URL=$(URL_$(1))) echo "ERROR: missing $(1) from $(URL)"; exit 1; }
