// main.jsonnet
local compose = import 'lib/docker_compose.libsonnet';

local beyla = import 'lib/beyla.libsonnet';
local generic = import 'lib/generic.libsonnet';
local grafana = import 'lib/grafana.libsonnet';
local loki = import 'lib/loki.libsonnet';
local prometheus = import 'lib/prometheus.libsonnet';
local promtail = import 'lib/promtail.libsonnet';

compose.new({
  local this = self,
  simplesrv:
    generic.new('simplesrv', 8080)
    + generic.withBuild('simplesrv/'),
  prometheus:
    prometheus.new()
    + prometheus.withVolume()
    + prometheus.withTargets([this.beyla]),
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
  beyla:
    beyla.new()
    + beyla.withContainerPid(this.simplesrv),
  promtail:
    promtail.new()
    + promtail.withDockerLogs()
    + promtail.withLokiPush(this.loki)
    + compose.withDependsOn([this.loki]),
  k6: generic.new('k6')
      + generic.withImage('loadimpact/k6:latest')
      + generic.withLocalVolume('./k6/load_test.js', '/k6/load_test.js')
      + generic.withField('restart', 'unless-stopped')
      + generic.withCommand('run --out json /k6/load_test.js'),
})
