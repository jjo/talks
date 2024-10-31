// lib/promtail.libsonnet
local dc = import '../../docker_compose.libsonnet';
local common = import '../common.libsonnet';

local images = import '../images.libsonnet';

{
  new(name='promtail', port=9080):: {
    local root = self,
    name:: name,
    port:: port,
    metrics_port:: root.port,
    config_name:: root.name + '_config',
    service: {
      image: images.promtail,
      container_name: root.name,
      ports: [
        '%d:%d' % [port, port],
      ],
      configs: [
        {
          source: root.config_name,
          target: '/etc/promtail/promtail.yml',
        },
      ],
      command: '-config.file=/etc/promtail/promtail.yml',
    },
    local etc_config = std.parseYaml(importstr '../etc/promtail/promtail.yml'),
    config:: etc_config {
      server+: {
        http_listen_port: root.port,
      },
    },
    configs+: {
      [root.config_name]: {
        content: std.manifestYamlDoc(root.config, quote_keys=false),
      },
    },
  },
  withSyslog(port=1514):: {
    service+: {
      ports+: ['%d:%d/udp' % [port, port]],
    },
    local etc_config = std.parseYaml(dc.escape(importstr '../etc/promtail/promtail-scrape_configs-syslog.yml')),
    config+: etc_config {
      scrape_configs: common.mapMixin(super.scrape_configs, 'job_name', 'syslog', {
        syslog+: {
          listen_address: '0.0.0.0:%d' % [port],
        },
      }),
    },
  },
  withDockerLogs(port=9081):: {
    local etc_config = std.parseYaml(dc.escape(importstr '../etc/promtail/promtail-scrape_configs-docker.yml')),
    service+: {
      volumes+: [
        '/var/run/docker.sock:/var/run/docker.sock',
      ],
    },
    config+: {
      scrape_configs+: etc_config.scrape_configs,
    },
  },
  withContainerLogs():: {
    local etc_config = std.parseYaml(dc.escape(importstr '../etc/promtail/promtail-scrape_configs-containers.yml')),
    config+: {
      scrape_configs+: etc_config.scrape_configs,
    },
  },
  withLokiPush(container):: {
    config+: {
      clients+: [
        { url: 'http://%s:%d/loki/api/v1/push' % [container.name, container.port] },
      ],
    },
  },
}
