local deploy = import "kube-deployment.libsonnet";

deploy {
  name: "nginx-base",
  container: {
    image: "nginx:1.12",
    ports: [{ name: "http", containerPort: 80 }],
  },
}
