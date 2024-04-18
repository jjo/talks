Slides at
<https://docs.google.com/presentation/d/1SULGVFSLHht560CsnufuJ0d6l6mP--r2Mqj5x-u6vJo/edit#slide=id.g2c4e5d865b7_0_0>
(in Spanglish).

## AI to to help the clueless human

Also at the slides above, asked <https://claude.ai/>:

1. write a `flask` demo app using `mysql` which is instrumented via `prometheus_client` to show DB latencies
1. add _CRUD_
1. show me some `curl` _CRUD_ examples
1. show me db initialization `sql`
1. rewrite using `mariadb` libs
1. write a `docker-compose.yaml` file that also brings a `mariadb` instance, with the above initializatino
1. show me a `k6` load test file to exercise write and reads
1. modify `dockerfile` to run it in production using `wsgi`
1. add an endpoint to query `column1`
1. write another `docker-compose.yaml` stanza to run a prometheus instance with `--web.enable-remote-write-receive`

## `demo-otel` content

Demo files at [./demo-otel](./demo-otel), mostly following <https://grafana.com/blog/2024/03/13/an-opentelemetry-backend-in-a-docker-image-introducing-grafana/otel-lgtm/>, re-using own simple flask `app.py`.
