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
  escape(s):: std.strReplace(s, '$', '$$'),
}
