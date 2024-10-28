// main.jsonnet
local compose = import 'lib/docker_compose.libsonnet';

local beyla = import 'lib/beyla.libsonnet';
local grafana = import 'lib/grafana.libsonnet';
local loki = import 'lib/loki.libsonnet';
local prometheus = import 'lib/prometheus.libsonnet';
local promtail = import 'lib/promtail.libsonnet';

compose.new({
  local this = self,
  prometheus:
    prometheus.new()
    + prometheus.withVolume()
    + prometheus.withTargets([this.prometheus, this.loki, this.promtail, this.grafana]),
  loki:
    loki.new()
    + loki.withVolume(),
  grafana:
    grafana.new()
    + grafana.withVolume()
    + grafana.withDatasources([
      grafana.datasource.withPrometheus(this.prometheus, true),
      grafana.datasource.withLoki(this.loki),
    ])
    + compose.withDependsOn([this.prometheus, this.loki]),
  promtail:
    promtail.new()
    + promtail.withSyslog()
    + promtail.withDockerLogs()
    + promtail.withLokiPush(this.loki)
    + compose.withDependsOn([this.loki]),
})
