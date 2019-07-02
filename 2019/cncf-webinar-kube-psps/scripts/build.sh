#!/bin/bash
# Generate JSON manifests from src/path/to/foo.jsonnet to out/path/to/<fields>.json
j2y() {
    local src=${1} dst=${1/json/yaml}
    echo "${src} -> ${dst}"
    python3 -c 'import json,yaml,sys; print (yaml.dump(json.load(sys.stdin),default_flow_style=False))' < ${src} > ${dst} && rm ${src}
}
gen() {
    local file=${1:?missing src/cluster/file.jsonnet}
    d=$(dirname ${file})
    f=$(basename ${file})
    rm -f ${d}/*.json
    jsonnet --multi "${d/src/out}" --exec "local f = (import \"${1}\"); {[k + '.json']: f[k] for k in std.objectFields(f)}"
    rm -f ${d/src/out}/*.yaml
    for f in ${d/src/out}/*.json; do j2y $f;done
}

for f in "${@}"; do gen "${f}"; done

