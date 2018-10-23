#!/bin/sh
random() {
    od -An -N2 -d /dev/urandom
}
get_builds_counter() {
    local name=${1:?}
    case "$name" in
        foo) idx=3;;
        bar) idx=11;;
    esac
    # Fake some monotonically increasing number by feeding it with pkt counters
    sort -k2nr /proc/net/dev | awk "{ print \$$idx; exit }"
}
generate_metrics() {
cat << EOF
asset_build_duration_seconds{stack="foo"} $((100+$(random)%10))
asset_build_duration_seconds{stack="bar"} $((200+$(random)%10))
asset_build_runs_total{stack="foo"} $(get_builds_counter foo)
asset_build_runs_total{stack="bar"} $(get_builds_counter bar)
EOF
}
if [ -n "$PUSHGATEWAY_URL" -a -n "$JOB" -a -n "$INSTANCE" ]; then
    while sleep 0.1; do
        generate_metrics | curl -s --data-binary @- $PUSHGATEWAY_URL/metrics/job/$JOB/instance/$INSTANCE
        sleep 1.9 || break
    done
else
    generate_metrics
fi
