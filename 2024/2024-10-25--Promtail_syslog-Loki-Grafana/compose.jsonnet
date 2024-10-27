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
    + prometheus.withTargets([this.loki, this.promtail, this.grafana]),  //, this.beyla]),
  loki:
    loki.new()
    + loki.withVolume(),
  grafana:
    grafana.new()
    + grafana.withVolume()
    + grafana.withDatasources([
      this.prometheus.asDatasource(true),
      this.loki.asDatasource(),
    ])
    + compose.withDependsOn([this.prometheus, this.loki]),
  /*
  beyla:
    beyla.new()
    + beyla.withContainerPid(this.prometheus),
  */
  promtail:
    promtail.new()
    + promtail.withSyslog()
    + promtail.withDockerLogs()
    + promtail.withLokiPush(this.loki)
    + compose.withDependsOn([this.loki]),
})
