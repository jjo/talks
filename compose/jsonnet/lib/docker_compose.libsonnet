// Some inspiration from https://github.com/grafana/intro-to-mltp/blob/main/docker-compose.yml
{
  new(containers)::
    std.foldl(
      function(acc, e) acc {
        services+: {
          [e.value.name]: e.value.service,
        },
        volumes+: std.get(e.value, 'volumes', {}),
        configs+: std.get(e.value, 'configs', {}),
      },
      std.objectKeysValues(containers),
      {},
    ),
  withDependsOn(containers):: {
    service+: {
      depends_on+: [c.name for c in containers],
    },
  },
  // This should be invoked as `jsonnet -S -m . compose.jsonnet`, will save
  // both `docker-compose.yml` and `docker-compose.configs.yml` files.
  splitFiles(manifest, configFile='docker-compose.configs.yml'):: {
    // Remove configs from main docker-compose.yml, add include stanza
    'docker-compose.yml': std.manifestYamlDoc(manifest {
      include: [configFile],
      configs:: null,
    }, quote_keys=false),
    // Keep only configs in docker-compose.configs.yml
    [configFile]: std.manifestYamlDoc({
      configs: manifest.configs,
    }, quote_keys=false),
  },
  escape(s):: std.strReplace(s, '$', '$$'),
}
