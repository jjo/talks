// lib/grafana.libsonnet
{
  local defaults = {
    image: 'grafana/grafana:11.3.0-ubuntu',
    admin_password: 'admin',
    allow_signup: false,
  },

  new(name='grafana', port=3000):: defaults {
    local root = self,
    name:: name,
    port:: port,
    config_name:: root.name + '_config',
    service: {
      image: defaults.image,
      container_name: root.name,
      ports: [
        '%d:%d' % [root.port, root.port],
      ],
      environment: [
        'GF_SECURITY_ADMIN_PASSWORD=%s' % defaults.admin_password,
        'GF_USERS_ALLOW_SIGN_UP=%s' % defaults.allow_signup,
      ],
      configs: [
        {
          source: root.config_name,
          target: '/etc/grafana/grafana.ini',
        },
      ],
    },
    config:: {
      sections: {
        feature_toggles: {
          enable: true,
          exploreMetrics: true,
        },
      },
    },
    configs+: {
      [root.config_name]: {
        content: std.manifestIni(root.config),
      },
    },
  },
  withVolume():: {
    local volume_name = self.name + '-storage',
    service+: {
      volumes+: [
        '%s:/var/lib/grafana' % volume_name,
      ],
    },
    volumes+: {
      [volume_name]: {},
    },
  },
  withDatasources(datasources=[]):: {
    local config_ds_name = self.name + '_datasources',
    local datasources_config = std.manifestYamlDoc({
      apiVersion: 1,
      datasources: datasources,
    }, quote_keys=false),
    service+: {
      configs+: [
        {
          source: config_ds_name,
          target: '/etc/grafana/provisioning/datasources/datasources.yaml',
        },
      ],
    },
    configs+: {
      [config_ds_name]: {
        content: datasources_config,
      },
    },
  },
}
