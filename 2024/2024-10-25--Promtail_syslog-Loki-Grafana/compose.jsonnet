// main.jsonnet
local c = import 'lib/containers/main.libsonnet';
local compose = import 'lib/docker_compose.libsonnet';

compose.new({
  local this = self,
  prometheus:
    c.prometheus.new()
    + c.prometheus.withVolume()
    + c.prometheus.withTargets([this.prometheus, this.loki, this.promtail, this.grafana]),
  loki:
    c.loki.new()
    + c.loki.withVolume(),
  grafana:
    c.grafana.new()
    + c.grafana.withVolume()
    + c.grafana.withDatasources([
      c.grafana.datasource.withPrometheus(this.prometheus, true),
      c.grafana.datasource.withLoki(this.loki),
    ])
    + compose.withDependsOn([this.prometheus, this.loki]),
  promtail:
    c.promtail.new()
    + c.promtail.withSyslog()
    + c.promtail.withDockerLogs()
    + c.promtail.withLokiPush(this.loki)
    + compose.withDependsOn([this.loki]),
})
