// main.jsonnet
local c = import 'lib/containers/main.libsonnet';
local compose = import 'lib/docker_compose.libsonnet';

compose.new({
  local this = self,
  simplesrv:
    c.generic.new('simplesrv', 8080)
    + c.generic.withBuild('simplesrv/'),
  prometheus:
    c.prometheus.new()
    + c.prometheus.withVolume()
    + c.prometheus.withTargets([this.beyla]),
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
  beyla:
    c.beyla.new()
    + c.beyla.withContainerPid(this.simplesrv),
  promtail:
    c.promtail.new()
    + c.promtail.withDockerLogs()
    + c.promtail.withLokiPush(this.loki)
    + compose.withDependsOn([this.loki]),
  k6: c.generic.new('k6')
      + c.generic.withImage('loadimpact/k6:latest')
      + c.generic.withLocalVolume('./k6/load_test.js', '/k6/load_test.js')
      + c.generic.withField('restart', 'unless-stopped')
      + c.generic.withCommand('run --out json /k6/load_test.js'),
})
