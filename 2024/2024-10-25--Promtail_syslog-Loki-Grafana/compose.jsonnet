// main.jsonnet
local c = import 'lib/containers/main.libsonnet';
local compose = import 'lib/docker_compose.libsonnet';

local manifest = compose.new({
  local root = self,
  prometheus:
    c.prometheus.new()
    + c.prometheus.withVolume()
    + c.prometheus.withTargets([root.prometheus, root.loki, root.promtail, root.grafana]),
  loki:
    c.loki.new()
    + c.loki.withVolume(),
  grafana:
    c.grafana.new()
    + c.grafana.withVolume()
    + c.grafana.withDatasources([
      c.grafana.datasource.withPrometheus(root.prometheus, true),
      c.grafana.datasource.withLoki(root.loki),
    ])
    + compose.withDependsOn([root.prometheus, root.loki]),
  promtail:
    c.promtail.new()
    + c.promtail.withSyslog()
    + c.promtail.withDockerLogs()
    + c.promtail.withLokiPush(root.loki)
    + compose.withDependsOn([root.loki]),
});

compose.splitFiles(manifest)
