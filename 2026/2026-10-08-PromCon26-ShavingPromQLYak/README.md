# promql-cli, a full PromQL cli-only engine ✨ .. but WHY?!

Lightning talk, PromCon EU 2026 (under 5 minutes). It is a live demo, and `lightning-promql-cli-deck.html` is the backup deck: every terminal it shows is captured output from the demo data.

[promql-cli](https://github.com/jjo/promql-cli) is a PromQL REPL with the real upstream engine inside: no Prometheus server, no TSDB on disk. Data comes from scraping an exporter, from a Prometheus API, or from a plain `.prom` text file. This build uses a Prometheus fork ([jjo/prometheus](https://github.com/jjo/prometheus)) for the new PromQL functions shown in WHY #4.

## The five WHYs

| # | WHY | Shows |
|---|---|---|
| 1 | PromQL without a Prometheus | `.scrape` a local node-exporter, then `rate()` in the REPL |
| 2 | CI your exporters with PromQL | `promql-cli check` runs a contract file (`ci/node-exporter.contract.promql`) and fails on a cardinality budget |
| 3 | Prod in a file: the bug report reproducer | `.prom_scrape_range` 6h of prod series, `.save incident.prom`, then plain PromQL with Wi-Fi off ✈️ |
| 4 | An engine playground | `zscore` against `robust_zscore` (fork functions) on the same file |
| 5 | Alerts on prod data, before they page | `.rules rules/disk.rules.yaml`, a recording rule plus an alert on `time_to_threshold()` |

## Files

| File | What it is |
|---|---|
| `lightning-promql-cli-deck.html` | Backup deck. Open it in a browser: arrows or space to move, `T` starts the timer |
| `CUE.md` | Run of show: timings, what to say, what to type, and what to do when something breaks |
| `preflight.sh` | Run about 10 minutes before the talk: builds promql-cli, starts node-exporter, port-forwards the Prometheus, saves the snapshots, smoke-tests the contract |
| `demo.sh` | The live demo sequencer: one real REPL per beat. `OFFLINE=1` uses the saved snapshots, `REPL=prompt` the completion-popup backend, `./demo.sh 3` jumps to a beat |
| `ci/node-exporter.contract.promql` | The WHY #2 metrics contract: one PromQL per line, a non-empty result passes |
| `ci/check.sh` | The pre-`check` shell version of the same thing, kept as a fallback |
| `rules/disk.rules.yaml` | The WHY #5 recording rule and alert |

`snapshots/` and `bin/` are created by `preflight.sh` and not committed: the snapshots hold real cluster metrics.

## Running it

Requirements:
- **Go:** 1.26 or newer, to build promql-cli at v0.6.3 or later. `check`, the `pinat` file header and the multi-line paste need v0.6.3.
- **Docker:** for the local node-exporter.
- **kubectl:** for a Prometheus to port-forward. The default is the `monitoring/prometheus-stack-kube-prom-prometheus` service, set by `KUBECONFIG_UM` and `PROM_PORT` in `preflight.sh`.

```sh
./preflight.sh            # build, node-exporter, port-forward, snapshots, smoke test (4 PASS, 1 FAIL is expected)
./demo.sh                 # live
OFFLINE=1 ./demo.sh 3     # from WHY #3 on, using the saved snapshots
```

`preflight.sh` keeps an existing `snapshots/um-flight.prom`, because the deck's numbers come from that exact file. Use `FRESH=1 ./preflight.sh` to re-fetch it after a backup. A fresh capture gives different numbers than the deck.

`preflight.sh` builds promql-cli from `../..`, that is, it expects this folder at `talks/promcon26-lightning/` inside a promql-cli checkout. Anywhere else, build promql-cli yourself and point `B=` in both scripts at the binary:

```sh
git clone https://github.com/jjo/promql-cli && (cd promql-cli && go build -o promql-cli ./cmd/promql-cli)
```

`go install github.com/jjo/promql-cli/cmd/promql-cli@latest` does not work, because promql-cli's `go.mod` has a `replace` directive for the Prometheus fork. The `xjjo/promql-cli` Docker image works for everything except the local node-exporter scrape, unless you run it with `--network host`.
