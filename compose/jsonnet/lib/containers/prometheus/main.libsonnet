// lib/prometheus.libsonnet
local images = import '../images.libsonnet';

{
  new(name='prometheus', port=9090):: {
    local root = self,
    name:: name,
    port:: port,
    metrics_port:: root.port,
    config_name:: root.name + '_config',
    service: {
      image: images.prometheus,
      container_name: root.name,
      command: [
        '--config.file=/etc/prometheus/prometheus.yml',
        '--web.enable-remote-write-receiver',
      ],
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
    // NB: import raw YAML, letting root.config to be overridden.
    local etc_config = std.parseYaml(importstr '../etc/prometheus/prometheus.yml'),
    config:: etc_config {
      scrape_configs: [],
    },
    configs+: {
      [root.config_name]: {
        content: std.manifestYamlDoc(root.config, quote_keys=false),
      },
    },
  },
  withVolume():: {
    local root = self,
    volume_name:: root.name + '-storage',
    service+: {
      volumes+: [
        '%s:/prometheus' % root.volume_name,
      ],
    },
    volumes+: {
      [root.volume_name]: {},
    },
  },
  withTargets(containers):: {
    config+: {
      scrape_configs+: [
        local metrics_path = std.get(c, 'metrics_path', null);
        {
          job_name: c.name,
          [if metrics_path != null then 'metrics_path']: metrics_path,
          static_configs: [
            {
              targets: ['%s:%d' % [c.name, c.metrics_port]],
            },
          ],
        }
        for c in containers
        if std.objectHasAll(c, 'metrics_port')
      ],
    },
  },
  withRemoteWrite(containers, headers={}):: {
    config+: {
      remote_write: [
        {
          url: 'http://%s:%d/api/v1/push' % [c.name, c.port],
          [if headers != {} then 'headers']: headers,
        }
        for c in containers
      ],
    },
  },
}
