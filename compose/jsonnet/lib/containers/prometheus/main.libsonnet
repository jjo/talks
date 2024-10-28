// lib/prometheus.libsonnet
local images = import '../images.libsonnet';

{
  new(name='prometheus', port=9090):: {
    local root = self,
    name:: name,
    port:: port,
    config_name:: root.name + '_config',
    service: {
      image: images.prometheus,
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
