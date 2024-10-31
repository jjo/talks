// main.jsonnet
local c = import 'lib/containers/main.libsonnet';
local compose = import 'lib/docker_compose.libsonnet';

local manifest = compose.new({
  local root = self,
  simplesrv:
    c.generic.new('simplesrv', 8080)
    + c.generic.withBuild('simplesrv/'),
  prometheus:
    c.prometheus.new()
    + c.prometheus.withVolume()
    + c.prometheus.withTargets([root.beyla]),
  loki:
    c.loki.new()
    + c.loki.withVolume(),
  tempo_init:
    c.tempo.initContainer(root.tempo),
  tempo:
    c.tempo.new()
    + c.tempo.withVolume()
    + c.tempo.withMetricsRemoteWrite(root.prometheus)
    + compose.withDependsOn([root.tempo_init]),
  grafana_plugin_traces_app:
    c.grafana.initPlugin(
      root.grafana,
      'https://storage.googleapis.com/integration-artifacts/grafana-exploretraces-app/grafana-exploretraces-app-latest.zip',
      'grafana-traces-app'
    ),
  grafana:
    local datasources = std.objectValues({
      prom: c.grafana.datasource.withPrometheus(root.prometheus, true),
      loki: c.grafana.datasource.withLoki(root.loki),
      tempo: c.grafana.datasource.withTempo(root.tempo, self.prom.uid, self.loki),
    });
    c.grafana.new()
    + c.grafana.withVolume()
    + c.grafana.withDatasources(datasources)
    + compose.withDependsOn([root.prometheus, root.loki]),
  beyla:
    c.beyla.new()
    + c.beyla.withContainerPid(root.simplesrv)
    + c.beyla.withOTELTraces(root.simplesrv, root.tempo),
  promtail:
    c.promtail.new()
    + c.promtail.withDockerLogs()
    + c.promtail.withLokiPush(root.loki)
    + compose.withDependsOn([root.loki]),
  k6: c.generic.new('k6')
      + c.generic.withImage('loadimpact/k6:latest')
      + c.generic.withLocalVolume('./k6/load_test.js', '/k6/load_test.js')
      + c.generic.withField('restart', 'unless-stopped')
      + c.generic.withCommand('run --out json /k6/load_test.js'),
});

compose.splitFiles(manifest)
