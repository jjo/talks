# promql-cli, a full PromQL cli-only engine ✨ .. but WHY?!

PromCon EU 2026 lightning talk. Hard limit 5:00, target 4:40. Live demo first, `lightning-promql-cli-deck.html` is the backup.

## T-10 min

```sh
./preflight.sh          # build, node-exporter, um port-forward, pre-save snapshots, smoke (4 PASS + 1 FAIL)
```

Terminal: big font, dark theme, 100+ columns. Second tab: `lightning-promql-cli-deck.html` open on slide 1 (press `T` to start its timer).

## Run of show

| Clock | Beat | Say | Do |
|---|---|---|---|
| 0:00–0:15 | Title | "A full PromQL engine, CLI only. ...but WHY?!" | slide 1 |
| 0:15–0:30 | The flight | "12h long-haul, no Wi-Fi, lots of PromQL in mind... and *at hand*." | slide 2 |
| 0:30–0:40 | REPL | Read: scrape/load. Eval: the real upstream engine. Print. Loop. | slide 3, then `./demo.sh` |
| 0:40–1:10 | WHY #1 | "Debugging an exporter shouldn't need a Prometheus." | type `.metrics \| grep -c node_` (287), `rate(node_cpu<TAB>`, `quit` |
| 1:10–2:00 | WHY #2 | "Your exporter has unit tests. Its metrics don't." Point at the red FAIL: 1116 series vs a 1000 budget. | ⏎ (runs `promql-cli check`): read the `got: ... = 1116` line |
| 2:00–2:50 | WHY #3 | "On the ground: 6h of raw series, one selector, 2 seconds, one file. ✈️ In the air: same PromQL." "That file is your bug report reproducer." | ⏎, read the fleet total (13.45/s) and point at .75 on top: "remember .75" |
| 2:50–3:30 | WHY #4 | "The fork's new functions, on prod data, no Prometheus deployed." | type the 3 zscore lines below (Up + Alt-B to swap the function name) |
| 3:30–4:10 | WHY #5 | "Your alert, on a function prod doesn't even run, fires on prod data. Before it pages anyone." | type `!cat rules/disk.rules.yaml`, `.rules rules/disk.rules.yaml`, `sort(pvc:days_to_full:6h)`, then `ALERTS` |
| 4:10–4:40 | Close | MCP server, JSON, docker image. "Because PromQL deserves a REPL." | slide 9 |

WHY #4 and #5 lines (same REPL as WHY #3):

```promql
topk(1, max_over_time(zscore(rate(node_netstat_Tcp_RetransSegs[5m]))[6h:30s]))         # ~3.55 on 172.16.16.75: stuck under the ceiling
sqrt(count(node_load1) - 1)                                                       # 3.61: the ceiling, sqrt(n-1)
topk(1, max_over_time(robust_zscore(rate(node_netstat_Tcp_RetransSegs[5m]))[6h:30s]))  # ~30.9: the unicorn vs its peers (172.16.16.75)
!cat rules/disk.rules.yaml                                  # show the rules: `!` runs a shell command
.rules rules/disk.rules.yaml                                # record + alert: "Rules: added 3 samples; 1 alerts"
sort(pvc:days_to_full:6h)                                   # the recording rule: mariadb ~8.9 days first
ALERTS                                                      # the alert: a real series, severity="page"
```

## If things break

| Symptom | Fix (≤ 5 s) |
|---|---|
| Wi-Fi / port-forward dead | `OFFLINE=1 ./demo.sh 3` (pre-saved `snapshots/um-flight.prom`) |
| docker / node-exporter dead | `OFFLINE=1 ./demo.sh 1` (WHY #2 needs the live exporter: skip to slide 5) |
| behind at 2:30 | skip WHY #4 typing, say it over the WHY #3 output |
| behind at 3:20 | skip WHY #5 typing, show slide 8 instead |
| behind at 3:50 | `quit`, go straight to slide 9 |
| anything else | switch to `lightning-promql-cli-deck.html`, it has the captured outputs |

## Rehearse once

- `REPL=prompt ./demo.sh` gives the context-aware completion popup (labels, values, function docs). It looks better on stage but needs a real TTY, so it's untested here. Fall back to the default readline backend if it misbehaves.

## Traps found while rehearsing

- `.scrape` needs the scheme: `http://localhost:9100/metrics`, not `localhost:9100/metrics`.
- Don't put `|` in a `.scrape` regex: the REPL pipes it to `/bin/sh` (that's the `.metrics | grep` feature).
- `-s` also hides the output of `-c` pre-commands.
- `.pinat` with no argument only shows the pin. `.pinat <metric>` pins to that metric's newest sample (ms-exact), which is what the demo uses.
- `time_to_threshold()` (like `predict_linear()`) counts from the eval time: pin it when querying a file.
- 👻 Optional rant (WHY #3, ≤ 10 s): `node_netstat_Tcp_RetransSegs` is `# TYPE ... untyped`, no `_total`, yet a true counter (14/14 series, 0 resets, `deriv` > 0 over 6h). Prometheus attaches `PossibleNonCounterInfo` to that `rate()`; promql-cli doesn't print annotations yet, so you won't see it on screen.
- `rate(node_intr_total)` looks like a better zscore demo (`robust_zscore` ~141000) but it's two counter resets on one node, not an anomaly. Stick to retransmits.
- Rules evaluate at one instant (the pin): `for:` isn't modelled, alerts go straight to `firing`. Don't promise `pending` on stage.
- `check` needs `--count 2`: with one scrape `rate()` is empty (FAIL) and `resets()` passes trivially.
- `ci/check.sh` is the old shell version, kept only as a fallback if the new binary misbehaves.
