// lib/beyla.libsonnet
local images = import '../images.libsonnet';

{
  new(name='mimir', port=8080):: {
    local root = self,
    name:: name,
    port:: port,
    config_name:: root.name + '_config',
    service: {
      image: images.mimir,
      container_name: root.name,
      ports: [
        '%d:%d' % [root.port, root.port],
      ],
      configs: [
        {
          source: root.config_name,
          target: '/etc/mimir/mimir.yaml',
        },
      ],
      command: '-config.file=/etc/mimir/mimir.yaml',
    },
    // NB: import raw YAML, letting root.config to be overridden.
    local etc_config = std.parseYaml(importstr '../etc/mimir/mimir.yaml'),
    config:: etc_config {},
    configs+: {
      [root.config_name]: {
        content: std.manifestYamlDoc(root.config, quote_keys=false),
      },
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
  withS3StorageBackend(container, bucket, access_key_id, secret_access_key, insecure=true):: {
    config+: {
      common+: {
        storage: {
          backend: 's3',
          s3: {
            endpoint: '%s:%d' % [container.name, container.port],
            access_key_id: access_key_id,
            secret_access_key: secret_access_key,
            bucket_name: bucket,
            insecure: insecure,
          },
        },
      },
    },
  },
}
