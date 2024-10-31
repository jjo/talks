// lib/beyla.libsonnet
local images = import '../images.libsonnet';

{
  new(name='minio', port=9000):: {
    local root = self,
    name:: name,
    port:: port,
    metrics_port:: root.port,
    metrics_path:: '/minio/v2/metrics/bucket',
    service: {
      image: images.minio,
      container_name: root.name,
      ports: [
        '%d:%d' % [root.port, root.port],
      ],
      _environment:: {
        MINIO_ROOT_USER: 'admin',
        MINIO_ROOT_PASSWORD: 'supersecret',
        MINIO_PROMETHEUS_AUTH_TYPE: 'public',
      },
      environment: [
        '%s=%s' % [kv.key, kv.value]
        for kv in std.objectKeysValues(self._environment)
      ],
      entrypoint: [''],
      command: ['sh', '-c', 'mkdir -p /data/mimir && minio server --quiet /data'],
    },
  },
  withVolume():: {
    local volume_name = self.name + '-storage',
    service+: {
      volumes+: [
        '%s:/data' % volume_name,
      ],
    },
    volumes+: {
      [volume_name]: {},
    },
  },
  withAuth(user, password):: {
    service+: {
      _environment+:: {
        MINIO_ROOT_USER: user,
        MINIO_ROOT_PASSWORD: password,
      },
    },
  },
}
