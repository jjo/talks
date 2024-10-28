// lib/promtail.libsonnet
local images = import 'images.libsonnet';

{
  new(name='promtail', port=9080):: {
    local root = self,
    name:: name,
    port:: port,
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
          target: '/etc/promtail/docker-config.yml',
        },
      ],
      command: '-config.file=/etc/promtail/docker-config.yml',
    },
    config:: {
      server: {
        http_listen_address: '0.0.0.0',
        http_listen_port: root.port,
      },
      positions: {
        filename: '/tmp/positions.yaml',
      },
      scrape_configs: [],
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
    config+: {
      scrape_configs+: [
        {
          job_name: 'syslog',
          syslog: {
            listen_address: '0.0.0.0:%d' % [port],
            listen_protocol: 'udp',
            labels: {
              job: 'syslog',
            },
          },
          relabel_configs: [
            {
              source_labels: ['__syslog_connection_ip_address'],
              target_label: 'host',
            },
            {
              source_labels: ['__syslog_message_severity'],
              target_label: 'severity',
            },
            {
              source_labels: ['__syslog_message_facility'],
              target_label: 'facility',
            },
            {
              source_labels: ['__syslog_message_hostname'],
              target_label: 'hostname',
            }
            // Create service_name label by combining "syslog/" with facility
            {
              source_labels: ['__syslog_message_facility'],
              target_label: 'service_name',
              regex: '(.*)',
              replacement: 'syslog/$${1}',  // $$ is used to escape $ in replacement
            },
          ],
        },
      ],
    },
  },
  withDockerLogs(port=9081):: {
    service+: {
      volumes+: [
        '/var/run/docker.sock:/var/run/docker.sock',
      ],
    },
    config+: {
      scrape_configs+: [
        {
          job_name: 'docker',
          docker_sd_configs: [
            {
              host: 'unix:///var/run/docker.sock',
              refresh_interval: '5s',
            },
          ],
          relabel_configs: [
            {
              source_labels: ['__meta_docker_container_name'],
              regex: '/(.*)',
              target_label: 'container',
            },
            {
              source_labels: ['__meta_docker_container_name'],
              regex: '/(.*)',
              target_label: 'service_name',
            },
            {
              source_labels: ['__meta_docker_container_log_stream'],
              target_label: 'logstream',
            },
            {
              source_labels: ['__meta_docker_container_label_logging_jobname'],
              target_label: 'job',
            },
          ],
        },
      ],
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
