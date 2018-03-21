{
  name:: error "name required",
  data: error "data required",

  apiVersion: "v1",
  kind: "ConfigMap",
  metadata: {
    name: $.name,
  },
  assert std.type($.data) == "object",
}
