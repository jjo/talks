// main.jsonnet
local c = import 'lib/containers/main.libsonnet';
local compose = import 'lib/docker_compose.libsonnet';

local mimirConf = {
  orgId: 'demo',
  bucket: 'mimir',
  access_key_id: 'mimir',
  secret_access_key: 'supersecret',
};

compose.new({
  local this = self,
  prometheus:
    c.prometheus.new()
    + c.prometheus.withVolume()
    + c.prometheus.withTargets([this.prometheus, this.loki, this.promtail, this.grafana])
    + c.prometheus.withRemoteWrite([this.mimir], { 'X-Scope-OrgID': mimirConf.orgId }),
  loki:
    c.loki.new()
    + c.loki.withVolume(),
  grafana:
    c.grafana.new()
    + c.grafana.withVolume()
    + c.grafana.withDatasources([
      c.grafana.datasource.withPrometheus(this.prometheus, true),
      c.grafana.datasource.withLoki(this.loki),
      c.grafana.datasource.withMimir(this.mimir, mimirConf.orgId),
    ])
    + compose.withDependsOn([this.prometheus, this.loki]),
  promtail:
    c.promtail.new()
    + c.promtail.withSyslog()
    + c.promtail.withDockerLogs()
    + c.promtail.withLokiPush(this.loki)
    + compose.withDependsOn([this.loki]),
  mimir:
    c.mimir.new()
    + c.mimir.withVolume()
    + c.mimir.withS3StorageBackend(this.minio, mimirConf.bucket, mimirConf.access_key_id, mimirConf.secret_access_key)
    + compose.withDependsOn([this.minio]),
  minio:
    c.minio.new()
    + c.minio.withAuth(mimirConf.access_key_id, mimirConf.secret_access_key)
    + c.minio.withVolume(),
})
