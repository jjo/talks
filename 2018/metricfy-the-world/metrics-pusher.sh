#!/bin/sh
get_builds_counter() {
    local name=${1:?}
    case "$name" in
        foo) idx=3;;
        bar) idx=11;;
    esac
    # Fake some monotonically increasing number
    set -x
    awk "/eth0:/{ print \$$idx }" /proc/net/dev
    set +x
}
generate_metrics() {
cat << EOF
asset_build_duration_seconds{stack="foo"} $((100+RANDOM%10))
asset_build_duration_seconds{stack="bar"} $((200+RANDOM%10))
asset_build_runs_total{stack="foo"} $(get_builds_counter foo)
asset_build_runs_total{stack="bar"} $(get_builds_counter bar)
EOF
}
JOB=jenkins
INSTANCE=app
while sleep 0.1; do
    generate_metrics | curl -s --data-binary @- http://pushgateway:9091/metrics/job/$JOB/instance/$INSTANCE
    sleep 1.9 || break
done
