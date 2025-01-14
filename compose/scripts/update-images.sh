#!/bin/bash

# Function to get latest release tag for Docker Hub images
get_dockerhub_tag() {
    local image=$1
    local filter=$2
    curl -s "https://hub.docker.com/v2/repositories/${image}/tags?page_size=1000" | \
        jq -r ".results[].name" | \
        grep -v "latest\|master\|main\|dev\|rc\|beta\|alpha" |\
        grep -E "${filter}" | \
        sort -V | \
        tail -n1
}

# Function to update version in jsonnet file
update_version() {
    local file=$1
    local image=$2
    local tag_tail=$3
    local old_version new_version

    img_patt="v?[0-9]+\.[0-9]+\.[0-9]+${tag_tail}[^\"']*"
    old_version=$(grep "$image" "$JSONNET_FILE" | grep -Eo "${img_patt}")
    : ${old_version:?}
    new_version=$(get_dockerhub_tag "$image" "v?[0-9]+\.[0-9]+\.[0-9]+${tag_tail}$")
    [ -z "${new_version}" ] && echo "skipping "${image}", no new version found" && return
    if [ "$old_version" != "$new_version" ]; then
        echo "Updating ${image} from ${old_version} to ${new_version}"
        sed -i "s|${image}:${old_version}|${image}:${new_version}|g" "$file"
    else
        echo "No update needed for ${image}, already at ${new_version}"
    fi
}

JSONNET_FILE=${1:?missing path to images.libsonnet file}

for imgx in prom/prometheus: grafana/grafana:-ubuntu grafana/loki: grafana/tempo:; do
	img=${imgx%:*}
	tag=${imgx#*:}
	update_version "$JSONNET_FILE" "${img}" "$tag"
done
