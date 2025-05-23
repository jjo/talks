// lib/loki.libsonnet
local images = import '../images.libsonnet';

{
  new(name='loki', port=3100, grpc_port=9096):: {
    local root = self,
    name:: name,
    port:: port,
    metrics_port:: root.port,
    config_name:: root.name + '_config',
    service: {
      image: images.loki,
      container_name: root.name,
      ports: [
        '%d:%d' % [root.port, root.port],
        '%d:%d' % [grpc_port, grpc_port],
      ],
      command: [
        '-config.file=/etc/loki/loki.yaml',
        '--pattern-ingester.enabled=true',
      ],
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
          target: '/etc/loki/loki.yaml',
        },
      ],
      restart: 'unless-stopped',
    },
    // NB: import raw YAML, overridding fields like `server.http_listen_port`
    local etc_config = std.parseYaml(importstr '../etc/loki/loki.yaml'),
    config:: etc_config {
      server: { http_listen_port: root.port },
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
        '%s:/loki' % root.volume_name,
      ],
    },
    volumes+: {
      [root.volume_name]: {},
    },
  },
}
