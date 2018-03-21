local nginx_deploy = import "nginx-base.jsonnet";

nginx_deploy {
  name: "my-nginx",
  metadata+: {
    namespace: "app-production",
  },
  spec+: {
    replicas: 3,
    strategy: {
      rollingUpdate: {
        maxSurge: "50%",
        maxUnavailable: "10%",
      },
    },
  },
}
