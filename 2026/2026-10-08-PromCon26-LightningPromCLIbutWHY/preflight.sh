#!/usr/bin/env bash
# Run ~10 minutes before the talk. Builds promql-cli (against the jjo/prometheus
# fork via go.mod replace), starts a local node-exporter, port-forwards the um
# Prometheus, and pre-saves every scrape the demo needs into snapshots/ so each
# live beat has an offline fallback. An existing snapshots/um-flight.prom is kept
# (the deck's numbers come from it); FRESH=1 re-fetches it after a backup.
set -euo pipefail

cd "$(dirname "$0")"
KUBECONFIG_UM=${KUBECONFIG_UM:-$HOME/.kube/um-metal-via-rancher.kubeconfig}
PROM_PORT=${PROM_PORT:-19090}
PROM=http://localhost:$PROM_PORT
NODE=http://localhost:9100/metrics
B=./bin/promql-cli
mkdir -p bin snapshots

step() { printf '\n\e[1;33m==> %s\e[0m\n' "$*"; }

step "build promql-cli"
(cd ../.. && go build -o talks/promcon26-lightning/bin/promql-cli ./cmd/promql-cli)
"$B" version

step "node-exporter (docker)"
if ! docker ps --format '{{.Names}}' | grep -qx node-exporter; then
	docker run -d --rm --name node-exporter -p 9100:9100 --pid=host \
		-v /:/host:ro,rslave quay.io/prometheus/node-exporter:latest --path.rootfs=/host >/dev/null
	sleep 2
fi
curl -fsS "$NODE" | grep -c '^node_' | xargs printf '%s node_* series\n'

step "port-forward um Prometheus -> $PROM"
if ! curl -fsS -o /dev/null "$PROM/-/ready" 2>/dev/null; then
	kubectl --kubeconfig "$KUBECONFIG_UM" -n monitoring \
		port-forward svc/prometheus-stack-kube-prom-prometheus "$PROM_PORT:9090" >/tmp/um-port-forward.log 2>&1 &
	echo $! >/tmp/um-port-forward.pid
	for _ in $(seq 20); do
		if curl -fsS -o /dev/null "$PROM/-/ready" 2>/dev/null; then break; fi
		sleep 0.5
	done
fi
curl -fsS "$PROM/-/ready"

step "pre-save node-exporter scrapes"
"$B" query -s -c ".scrape $NODE 2 5s; .save snapshots/node-exporter.prom" -q 'vector(1)' >/dev/null

FLIGHT=snapshots/um-flight.prom
if [[ -s $FLIGHT && ${FRESH:-0} != 1 ]]; then
	# The deck's numbers come from this exact file: keep it unless FRESH=1.
	step "keep um 'flight' data ($FLIGHT, FRESH=1 to re-fetch)"
	head -1 "$FLIGHT" | grep '^# promql-cli: pinat=' || echo "WARNING: $FLIGHT has no pinat header"
else
	step "pre-save um 'flight' data (6h, raw selectors only)"
	if [[ -s $FLIGHT ]]; then
		cp "$FLIGHT" "$FLIGHT.$(date +%Y%m%d-%H%M%S).bak"
		echo "backed up the previous $FLIGHT: deck numbers will no longer match"
	fi
	end=$(date +%s)
	"$B" query -s -c "\
.prom_scrape_range $PROM '{__name__=~\"node_load1|node_netstat_Tcp_RetransSegs|kubelet_volume_stats_available_bytes\"}' $((end - 6 * 3600)) $end 30s; \
.pinat node_load1; .save $FLIGHT" -q 'vector(1)' >/dev/null
fi
ls -la snapshots/

step "smoke: exporter contract (expect 4 PASS, 1 FAIL)"
"$B" check --scrape "$NODE" --count 2 --interval 1s ci/node-exporter.contract.promql || true

step "ready"
