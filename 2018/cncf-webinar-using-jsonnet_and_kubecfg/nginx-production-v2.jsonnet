local nginx_deploy = import "nginx-base.jsonnet";
local kube_config = import "kube-configmap.libsonnet";

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
    name: "my-nginx-config",
    metadata+: { namespace: $.namespace },
    data: {
      "index.html": importstr "assets/production/index.html",
    },
  },
}
