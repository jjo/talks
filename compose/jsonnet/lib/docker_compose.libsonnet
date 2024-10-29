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
  // This should be invoked as `jsonnet -m . compose.jsonnet`, will save
  // both `docker-compose.yml` and `docker-compose.configs.yml` files.
  splitFiles(manifest, configFile='docker-compose.configs.yml'):: {
    // Remove configs from main docker-compose.yml, add include stanza
    'docker-compose.yml': manifest {
      include: [configFile],
      configs:: null,
    },
    // Keep only configs in docker-compose.configs.yml
    [configFile]: {
      configs: manifest.configs,
    },
  },
  escape(s):: std.strReplace(s, '$', '$$'),
}
