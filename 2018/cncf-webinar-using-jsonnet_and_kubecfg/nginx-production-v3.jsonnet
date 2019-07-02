local nginx_deploy = import "nginx-base.jsonnet";
local kube_config = import "kube-configmap.libsonnet";
local common = import "common.libsonnet";

{
  namespace:: "app-production",

  deploy: nginx_deploy {
    name: "my-nginx",
    metadata+: { namespace: $.namespace },
    container+: {
      volumeMounts: [
        { name: "assets-vol", mountPath: "/usr/share/nginx/html" },
      ],
    },
    spec+: {
      replicas: 3,
      strategy: { rollingUpdate: { maxSurge: "50%", maxUnavailable: "10%" } },
      template+: {
        spec+: {
          volumes+: [
            { name: "assets-vol", configMap: { name: $.config.name } },
          ],
        },
      },
    },
  },

  config: kube_config {
    name: common.hashed_name("my-nginx-config", self.data),
    metadata+: { namespace: $.namespace },
    data: {
      "index.html": importstr "assets/production/index.html",
    },
  },
}
