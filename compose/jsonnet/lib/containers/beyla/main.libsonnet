// lib/beyla.libsonnet
local images = import '../images.libsonnet';

{
  new(name='beyla', port=9400):: {
    local root = self,
    name:: name,
    port:: port,
    metrics_port:: root.port,
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
      cap_add: [
        'SYS_ADMIN',
        'SYS_RESOURCE',
        'NET_RAW',
        'DAC_READ_SEARCH',
        'SYS_PTRACE',
        'PERFMON',
        'BPF',
        'CHECKPOINT_RESTORE',
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
  withOTELTraces(container, otelEndpointContainer, otelEndpointPort=4317):: {
    service+: {
      environment+: [
        'OTEL_SERVICE_NAME=%s' % container.name,
        'OTEL_EXPORTER_OTLP_TRACES_INSECURE=true',
        'OTEL_EXPORTER_OTLP_PROTOCOL=grpc',
        'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://%s:%d' % [otelEndpointContainer.name, otelEndpointPort],
      ],
    },
  },
}
