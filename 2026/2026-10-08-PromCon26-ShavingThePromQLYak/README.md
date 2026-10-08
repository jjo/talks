# Shaving the PromQL Yak

**~6 PromQL functions to escape from analytical workarounds.**

PromCon EU 2026 talk by JuanJo Ciarlante ([@jjo](https://github.com/jjo)).

> A yak shave that started with "are these two timeseries related?" and ended with a need to have a matrix solver inside a query engine 😬

- **Slides:** [Google Slides](https://docs.google.com/presentation/d/16Gasf3wwKQXtIknHa_S-p-0oLfbyHY9UiKUIhVIGOkE/edit), or [`shaving-the-promql-yak.pdf`](shaving-the-promql-yak.pdf) in this folder (36 slides, including an appendix with every query in full).
- **Code:** [jjo/prometheus](https://github.com/jjo/prometheus), branch `jjo/all-add-branches`.
- **Container images:** [`xjjo/prometheus`](https://hub.docker.com/r/xjjo/prometheus/tags?name=jjo-all), `jjo-all*` tags.
- **Companion lightning talk:** [promql-cli, a full PromQL cli-only engine ✨ .. but WHY?!](../2026-10-08-PromCon26-LightningPromCLIbutWHY/), which runs these functions on a laptop without a Prometheus.

## The functions

All of them are pure PromQL: there's no new storage format, sidecar or rewrite, just `--enable-feature=promql-experimental-functions`.

| Function | Question it answers |
|---|---|
| `time_to_threshold` | How long until we cross a threshold? |
| `zscore` / `robust_zscore` | Is this sample unusual? |
| `ewma_over_time` | What's the signal under the noise? |
| `correlation_over_time` | Do two series move together? |
| `regression_over_time` / `lm_over_time` | What value should I expect, given one driver or several? |
| `timeseries_gen` | Synthetic series, for testing rules and joins |

Every live example ran against one homelab Prometheus built from `jjo/all-add-branches`. The appendix (slides A1 to A11) has each query exactly as executed, plus the plain-PromQL rewrites that are possible today, for comparison.
