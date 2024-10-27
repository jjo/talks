// lib/prometheus.libsonnet
{
  local defaults = {
    image: 'prom/prometheus:v3.0.0-beta.1',
  },

  new(name='prometheus', port=9090):: defaults {
    local root = self,
    name:: name,
    port:: port,
    config_name:: root.name + '_config',
    service: {
      image: defaults.image,
      container_name: root.name,
      ports: [
        '%d:%d' % [root.port, root.port],
      ],
      configs: [
        {
          source: root.config_name,
          target: '/etc/prometheus/prometheus.yml',
        },
      ],
    },
    config:: {
      global: {
        scrape_interval: '15s',
      },
      scrape_configs: [
        {
          job_name: 'prometheus',
          static_configs: [
            { targets: ['localhost:%d' % root.port] },
          ],
        },
      ],
    },
    configs+: {
      [root.config_name]: {
        content: std.manifestYamlDoc(root.config, quote_keys=false),
      },
    },
    asDatasource(isDefault=false):: {
      name: root.name,
      access: 'proxy',
      type: 'prometheus',
      url: 'http://%s:%d' % [root.name, root.port],
      isDefault: isDefault,
    },
  },
  withVolume():: {
    local volume_name = self.name + '-storage',
    service+: {
      volumes+: [
        '%s:/prometheus' % volume_name,
      ],
    },
    volumes+: {
      [volume_name]: {},
    },
  },
  withTargets(containers):: {
    config+: {
      scrape_configs+: [
        {
          job_name: c.name,
          static_configs: [
            { targets: ['%s:%d' % [c.name, c.port]] },
          ],
        }
        for c in containers
      ],
    },
  },
}
