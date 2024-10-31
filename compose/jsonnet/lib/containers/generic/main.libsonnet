// lib/generic.libsonnet
{
  new(name, port=null):: {
    local root = self,
    name:: name,
    port:: port,
    // metrics_port:: root.port,
    service: {
      container_name: root.name,
      ports:
        if port != null then
          [
            '%d:%d' % [root.port, root.port],
          ]
        else [],
      environment: [],
    },
  },
  withImage(image):: {
    local root = self,
    image:: image,
    service+: {
      image: image,
    },
  },
  withBuild(context='./', dockerfile='Dockerfile'):: {
    local root = self,
    context:: context,
    dockerfile:: dockerfile,
    service+: {
      build+: {
        context: root.context,
        dockerfile: root.dockerfile,
      },
    },
  },
  withCommand(command):: {
    local root = self,
    command:: command,
    service+: {
      command+: command,
    },
  },
  withEnv(key, value):: {
    local root = self,
    key:: key,
    value:: value,
    service+: {
      environment+: root + [
        '%s=%s' % [key, value],
      ],
    },
  },
  withEmbeddedConfig(content, container_path):: {
    local root = self,
    config_name:: root.name + '_config',
    config:: content,
    service+: {
      configs: [
        '%s:%s' % [root.config_name, container_path],
      ],
    },
    configs+: {
      [root.config_name]: {
        content: content,
      },
    },
  },
  withLocalVolume(local_path, container_path):: {
    service+: {
      volumes+: [
        '%s:%s' % [local_path, container_path],
      ],
    },
  },
  withField(key, value):: {
    service+: {
      [if value != null then key]: value,
      [if value == null then key]:: null,
    },
  },
}
