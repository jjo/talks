// main.jsonnet
local compose = import 'lib/docker_compose.libsonnet';

local grafana = import 'lib/grafana.libsonnet';
local loki = import 'lib/loki.libsonnet';
local prometheus = import 'lib/prometheus.libsonnet';
local promtail = import 'lib/promtail.libsonnet';

local c = {
  prometheus: prometheus.new(),
  loki: loki.new(),
};

compose.new({
  local this = self,
  prometheus:
    prometheus.new()
    + prometheus.withVolume()
    + prometheus.withTargets([this.loki, this.promtail, this.grafana]),
  loki:
    loki.new()
    + loki.withVolume(),
  grafana:
    grafana.new()
    + compose.withDependsOn([this.prometheus, this.loki])
    + grafana.withVolume()
    + grafana.withDatasources([
      this.prometheus.asDatasource(true),
      this.loki.asDatasource(),
    ]),
  promtail:
    promtail.new()
    + promtail.withSyslog()
    + promtail.withDockerLogs()
    + promtail.withLokiPush(this.loki)
    + compose.withDependsOn([this.loki]),
})