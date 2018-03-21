{
  name:: error "name required",
  container:: error "container required",

  apiVersion: "apps/v1beta1",
  kind: "Deployment",
  metadata: {
    name: $.name,
    labels: { app: $.name },
  },
  spec: {
    selector: { matchLabels: $.metadata.labels },
    template: {
      metadata: { labels: $.metadata.labels },
      spec: {
        containers: [
          $.container { name: $.name },
        ],
      },
    },
  },
}
