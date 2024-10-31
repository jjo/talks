// lib/tempo.libsonnet
local images = import '../images.libsonnet';

{
  new(name='tempo', port=3200, other_ports=[4317, 4318, 9411, 14250]):: {
    local root = self,
    name:: name,
    port:: port,
    config_name:: root.name + '_config',
    service: {
      image: images.tempo,
      container_name: root.name,
      other_ports:: [
        '%d:%d' % [p, p]
        for p in other_ports
      ],
      ports: [
        '%d:%d' % [root.port, root.port],
      ] + self.other_ports,
      command: '-config.file=/etc/tempo/tempo.yaml',
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
          target: '/etc/tempo/tempo.yaml',
        },
      ],
      restart: 'unless-stopped',
    },
    // NB: import raw YAML, overridding fields like `server.http_listen_port`
    local etc_config = std.parseYaml(importstr '../etc/tempo/tempo.yaml'),
    config:: etc_config {
      server: { http_listen_port: root.port },
    },
    configs+: {
      [root.config_name]: {
        content: std.manifestYamlDoc(root.config, quote_keys=false),
      },
    },
  },
  // From https://github.com/grafana/tempo/blob/main/cmd/tempo/Dockerfile
  initContainer(container, userId=10001, groupId=10001):: {
    // HACK: matches withVolume() below
    local root = self,
    name:: container.name + '-init',
    service: {
      user: 'root',
      container_name: root.name,
      image: 'alpine',
      group_add: [groupId],
      volumes+: [
        '%s:/tempo_stor' % container.volume_name,
      ],
      command: ['sh', '-xc', 'chown -R %d:%d /tempo_stor' % [userId, groupId]],
    },
  },
  withVolume():: {
    local root = self,
    volume_name:: root.name + '-storage',
    service+: {
      volumes+: [
        '%s:/tempo_stor' % root.volume_name,
      ],
    },
    volumes+: {
      [root.volume_name]: {},
    },
  },
  withMetricsRemoteWrite(container, apiRoute=null, send_exemplars=true):: {
    // Heuristic to determine the API route based on the image (mimir vs e.g. prometheus)
    local getApiRoute(image) =
      if std.startsWith(image, 'grafana/mimir')
      then 'api/v1/push'
      else 'api/v1/write',
    local apiRouteFinal = if apiRoute == null then getApiRoute(container.service.image) else apiRoute,
    config+: {
      metrics_generator+: {
        storage+: {
          remote_write: [
            {
              url: 'http://%s:%d/%s' % [container.name, container.port, apiRouteFinal],
              send_exemplars: send_exemplars,
            },
          ],
        },
      },
    },
  },
}
