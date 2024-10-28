// lib/beyla.libsonnet
local images = import '../images.libsonnet';

{
  new(name='beyla', port=9400):: {
    local root = self,
    name:: name,
    port:: port,
    service: {
      image: images.beyla,
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
