// lib/grafana.libsonnet
local images = import '../images.libsonnet';

{
  local defaults = {
    admin_password: 'admin',
    allow_signup: false,
  },

  new(name='grafana', port=3000):: {
    local root = self,
    name:: name,
    port:: port,
    config_name:: root.name + '_config',
    service: {
      image: images.grafana,
      container_name: root.name,
      ports: [
        '%d:%d' % [root.port, root.port],
      ],
      environment: [
        'GF_AUTH_ANONYMOUS_ENABLED=true',
        'GF_AUTH_ANONYMOUS_ORG_ROLE=Admin',
        'GF_USERS_DEFAULT_THEME=light',
      ],
      configs: [
        {
          source: root.config_name,
          target: '/etc/grafana/grafana.ini',
        },
      ],
    },
    // NB: there's no `std.parseIni` in jsonnet stdlib, ie we can't
    // import etc/grafana/grafana.ini and override it.
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
  datasource:: {
    local this = self,
    withPrometheus(container, isDefault=false):: {
      name: container.name,
      uid: container.name,
      type: 'prometheus',
      basicAuth: false,
      access: 'proxy',
      url: 'http://%s:%d' % [container.name, container.port],
      isDefault: isDefault,
    },
    withLoki(container, isDefault=false):: {
      name: container.name,
      uid: container.name,
      type: 'loki',
      basicAuth: false,
      access: 'proxy',
      url: 'http://%s:%d' % [container.name, container.port],
      orgId: 1,
      version: 1,
      isDefault: isDefault,
    },
    withMimir(container, orgId, isDefault=false):: this.withPrometheus(container, isDefault) {
      url: 'http://%s:%d/prometheus' % [container.name, container.port],
      jsonData: {
        httpHeaderName1: 'X-Scope-OrgID',
        implementation: 'cortex',
      },
      secureJsonData: {
        httpHeaderValue1: orgId,
      },
    },
    withTempo(container, promDS, lokiDS, isDefault=false):: {
      name: container.name,
      uid: container.name,
      url: 'http://%s:%d' % [container.name, container.port],
      type: 'tempo',
      basicAuth: false,
      access: 'proxy',
      jsonData: std.parseYaml(
        |||
          nodeGraph:
            enabled: true
          serviceMap:
            datasourceUid: %s
          tracesToLogs:
            datasourceUid: %s
            filterByTraceID: false
            spanEndTimeShift: "500ms"
            spanStartTimeShift: "-500ms"
            tags: ['beast']
        ||| % [promDS, lokiDS],
      ),
    },
  },
}
