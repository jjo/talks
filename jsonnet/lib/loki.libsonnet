// lib/loki.libsonnet
{
  local defaults = {
    image: 'grafana/loki:2.9.10',
  },

  new(name='loki', port=3100, grpc_port=9096):: defaults {
    local root = self,
    name:: name,
    port:: port,
    config_name:: root.name + '_config',
    service: {
      image: defaults.image,
      container_name: root.name,
      ports: [
        '%d:%d' % [root.port, root.port],
        '%d:%d' % [grpc_port, grpc_port],
      ],
      command: '-config.file=/etc/loki/local-config.yaml',
      healthcheck: {
        test: ['CMD-SHELL', 'wget -q --tries=1 -O- http://localhost:%d/ready || exit 1' % root.port],
        interval: '30s',
        timeout: '3s',
        retries: 3,
        start_period: '30s',
      },
      configs: [
        {
          source: root.config_name,
          target: '/etc/loki/local-config.yaml',
        },
      ],
      restart: 'unless-stopped',
    },
    config:: {
      auth_enabled: false,
      server: { http_listen_port: root.port },
      common: {
        path_prefix: '/loki',
        storage: {
          filesystem: {
            chunks_directory: '/loki/chunks',
            rules_directory: '/loki/rules',
          },
        },
        replication_factor: 1,
        ring: {
          kvstore: {
            store: 'inmemory',
          },
        },
      },
      schema_config: {
        configs: [
          {
            from: '2020-05-15',
            store: 'boltdb-shipper',
            object_store: 'filesystem',
            schema: 'v11',
            index: {
              prefix: 'index_',
              period: '24h',
            },
          },
        ],
      },
      storage_config: {
        boltdb_shipper: {
          active_index_directory: '/loki/index',
          cache_location: '/loki/boltdb-cache',
          shared_store: 'filesystem',
          cache_ttl: '24h',
        },
      },
      compactor: {
        working_directory: '/loki/boltdb-shipper-compactor',
        shared_store: 'filesystem',
      },
      limits_config: {
        enforce_metric_name: false,
        reject_old_samples: true,
        reject_old_samples_max_age: '168h',
        max_cache_freshness_per_query: '10m',
        volume_enabled: true,
        ingestion_rate_mb: 32,
        ingestion_burst_size_mb: 64,
        per_stream_rate_limit: '32MB',
        per_stream_rate_limit_burst: '64MB',
        max_global_streams_per_user: 5000,
        max_line_size: '2MB',
      },
      chunk_store_config: {
        max_look_back_period: '0s',
      },
      ruler: {
        storage: {
          type: 'local',
          'local': {
            directory: '/loki/rules',
          },
        },
      },
      table_manager: {
        retention_deletes_enabled: true,
        retention_period: '672h',
      },
    },
    configs+: {
      [root.config_name]: {
        content: std.manifestYamlDoc(root.config, quote_keys=false),
      },
    },
    asDatasource(isDefault=false):: {
      name: root.name,
      type: 'loki',
      access: 'proxy',
      url: 'http://%s:%d' % [root.name, root.port],
      orgId: 1,
      basicAuth: false,
      version: 1,
      isDefault: isDefault,
    },
  },
  withVolume():: {
    local volume_name = self.name + '-storage',
    service+: {
      volumes+: [
        '%s:/loki' % volume_name,
      ],
    },
    volumes+: {
      [volume_name]: {},
    },
  },
}
