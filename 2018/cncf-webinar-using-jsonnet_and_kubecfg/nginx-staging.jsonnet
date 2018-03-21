local nginx_deploy = import "nginx-base.jsonnet";

nginx_deploy {
  name: "my-nginx",
  metadata+: {
    namespace: "app-staging",
  },
  spec+: {
    replicas: 2,
  },
}
