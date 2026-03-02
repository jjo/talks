// main.jsonnet
local c = import 'lib/containers/main.libsonnet';
local compose = import 'lib/docker_compose.libsonnet';

local mimirConf = {
  orgId: 'demo',
  bucket: 'mimir',
  access_key_id: 'mimir',
  secret_access_key: 'supersecret',
};

local manifest = compose.new({
  local root = self,
  simplesrv:
    c.generic.new('simplesrv', 8080)
    + c.generic.withBuild('simplesrv/')
    + c.generic.withField('ports', ['8081:8080']),
  beyla:
    c.beyla.new()
    + c.beyla.withContainerPid(root.simplesrv)
    + c.beyla.withOTELTraces(root.simplesrv, root.tempo),
  k6: c.generic.new('k6')
      + c.generic.withImage('loadimpact/k6:latest')
      + c.generic.withLocalVolume('./k6/load_test.js', '/k6/load_test.js')
      + c.generic.withField('restart', 'unless-stopped')
      + c.generic.withCommand('run --out json /k6/load_test.js'),
  prometheus:
    c.prometheus.new()
    + c.prometheus.withVolume()
    + c.prometheus.withTargets(std.objectValues(root))
    + c.prometheus.withRemoteWrite([root.mimir], { 'X-Scope-OrgID': mimirConf.orgId }),
  loki:
    c.loki.new()
    + c.loki.withVolume(),
  tempo_init:
    c.tempo.initContainer(root.tempo),
  tempo:
    c.tempo.new()
    + c.tempo.withVolume()
    + c.tempo.withMetricsRemoteWrite(root.mimir)
    + compose.withDependsOn([root.tempo_init]),
  grafana:
    local datasources = std.objectValues({
      prom: c.grafana.datasource.withPrometheus(root.prometheus, true),
      loki: c.grafana.datasource.withLoki(root.loki),
      mimir: c.grafana.datasource.withMimir(root.mimir, mimirConf.orgId),
      tempo: c.grafana.datasource.withTempo(root.tempo, self.mimir.uid, self.loki),
    });
    c.grafana.new()
    + c.grafana.withVolume()
    + c.grafana.withDatasources(datasources)
    + compose.withDependsOn([root.prometheus, root.loki]),
  promtail:
    c.promtail.new()
    + c.promtail.withSyslog()
    + c.promtail.withDockerLogs()
    + c.promtail.withLokiPush(root.loki)
    + compose.withDependsOn([root.loki]),
  mimir:
    c.mimir.new()
    + c.mimir.withVolume()
    + c.mimir.withS3StorageBackend(root.minio, mimirConf.bucket, mimirConf.access_key_id, mimirConf.secret_access_key)
    + { config+: {
      server+: { log_level: 'info' },
      blocks_storage+: { tsdb+: { block_ranges_period: ['15m'] } },
    } }
    + compose.withDependsOn([root.minio]),
  minio:
    c.minio.new()
    + c.minio.withAuth(mimirConf.access_key_id, mimirConf.secret_access_key)
    + c.minio.withVolume(),
});

compose.splitFiles(manifest)
