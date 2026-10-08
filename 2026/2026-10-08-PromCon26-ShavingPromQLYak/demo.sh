#!/usr/bin/env bash
# Live demo sequencer for "promql-cli ... but WHY?!" (PromCon EU 2026 lightning talk).
# Each beat opens a real REPL with its pre-commands already run: keep typing live,
# `quit` (or Ctrl-D) to move on. OFFLINE=1 uses the snapshots saved by preflight.sh.
# REPL=prompt switches to the go-prompt backend (context-aware completion popup).
#
# usage: ./demo.sh [first-beat]     e.g. ./demo.sh 3 to jump ahead
set -euo pipefail

cd "$(dirname "$0")"
B=./bin/promql-cli
PROM=http://localhost:${PROM_PORT:-19090}
NODE=http://localhost:9100/metrics
OFFLINE=${OFFLINE:-0}
FIRST=${1:-1}
T0=$(date +%s)

clock() {
	local s=$(($(date +%s) - T0))
	printf '%d:%02d' $((s / 60)) $((s % 60))
}

beat() { # beat <n> <budget-end m:ss> <title>
	printf '\n\e[1;38;5;208m━━ WHY #%s · %s ━━\e[0m  \e[2m[clock %s · must end by %s]\e[0m\n' "$1" "$3" "$(clock)" "$2"
}

say() { printf '\e[2m# %s\e[0m\n' "$*"; }

next() { read -rp $'\e[2m⏎ next beat\e[0m ' _ || true; }

repl() { # repl <pre-commands>
	printf '\e[32m$ promql-cli query -c "%s"\e[0m\n' "$1"
	"$B" ${REPL:+--repl="$REPL"} query -c "$1" || true
}

# ── WHY #1: PromQL without a Prometheus ─────────────────────── 0:40 → 1:10
if ((FIRST <= 1)); then
	beat 1 1:10 "PromQL without a Prometheus"
	say "try: .metrics | grep -c node_      rate(node_cpu<TAB>      .labels node_cpu_seconds_total"
	if ((OFFLINE)); then
		repl ".load snapshots/node-exporter.prom; .pinat node_cpu_seconds_total; sort_desc(sum by (mode) (rate(node_cpu_seconds_total[1m])))"
	else
		repl ".scrape $NODE 2 5s; .pinat node_cpu_seconds_total; sort_desc(sum by (mode) (rate(node_cpu_seconds_total[1m])))"
	fi
	next
fi

# ── WHY #2: CI your exporters with PromQL ───────────────────── 1:10 → 2:00
if ((FIRST <= 2)); then
	beat 2 2:00 "CI your exporters with PromQL"
	say "a metrics contract: one PromQL expression per line, non-empty = pass, the comment above names the check"
	grep -v '^$' ci/node-exporter.contract.promql | tail -n +3
	printf '\e[32m$ promql-cli check --scrape %s --count 2 --interval 1s ci/node-exporter.contract.promql\e[0m\n' "$NODE"
	"$B" check --scrape "$NODE" --count 2 --interval 1s ci/node-exporter.contract.promql && rc=0 || rc=$?
	say "exit code: $rc  (1116 series on my laptop vs a 1000 budget: CI goes red)"
	next
fi

# ── WHY #3 + #4 + #5: flight, bug repro, engine playground, alerts ── 2:00 → 4:10
if ((FIRST <= 3)); then
	beat 3 2:50 "the long-haul flight: prod in a file"
	if ((OFFLINE)); then
		incident=snapshots/um-flight.prom
		say "(offline) using pre-saved $incident"
	else
		incident=/tmp/incident.prom
		end=$(date +%s)
		say "on the ground, with wifi: grab 6h of raw series, save them"
		repl ".prom_scrape_range $PROM '{__name__=~\"node_load1|node_netstat_Tcp_RetransSegs|kubelet_volume_stats_available_bytes\"}' $((end - 6 * 3600)) $end 30s; .pinat node_load1; .save $incident"
	fi
	say "✈️  wifi off. 30,000 ft. same PromQL. this file is also your bug report reproducer."
	say "WHY #4 (until 3:30), same REPL: the fork's new functions, on prod data, no Prometheus deployed"
	say "  topk(1, max_over_time(zscore(rate(node_netstat_Tcp_RetransSegs[5m]))[6h:30s]))   sqrt(count(node_load1) - 1)"
	say "  topk(1, max_over_time(robust_zscore(rate(node_netstat_Tcp_RetransSegs[5m]))[6h:30s]))"
	say "WHY #5 (until 4:10), same REPL: your alert, on prod data, before it pages anyone"
	say "  !cat rules/disk.rules.yaml   .rules rules/disk.rules.yaml   sort(pvc:days_to_full:6h)   ALERTS"
	repl ".load $incident; .pinat node_load1; sum(rate(node_netstat_Tcp_RetransSegs[5m])); topk(3, rate(node_netstat_Tcp_RetransSegs[6h]))"
fi

printf '\n\e[1;38;5;208m━━ close: "because PromQL deserves a REPL" ━━\e[0m  \e[2m[clock %s · must end by 4:40]\e[0m\n' "$(clock)"
