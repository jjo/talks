// lib/beyla.libsonnet
{
  local defaults = {
    image: 'grafana/beyla:latest',
  },

  new(name='beyla', port=9400):: defaults {
    local root = self,
    name:: name,
    port:: port,
    service: {
      image: defaults.image,
      container_name: root.name,
      privileged: true,
      ports: [
        '%d:%d' % [root.port, root.port],
      ],
      environment: [
        'BEYLA_PROMETHEUS_PORT=%d' % root.port,
      ],
    },
  },
  withContainerPid(container):: {
    service+: {
      pid: 'service:%s' % container.name,
      environment+: [
        'BEYLA_OPEN_PORT=%d' % container.port,
      ],
    },
  },
}
