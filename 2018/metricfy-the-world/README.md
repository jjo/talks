# Training scripts for locally run Prometheus + Pushgateway instances

## Bring up the local docker stack

To bring up a stack of prometheus (:9090), pushgateway (:9091) and
fake metrics generator:

~~~
docker-compose up -d
~~~

## Peek at Pushgateway and Prometheus UIs

* Visit http://localhost:9091/ for Pushgateway
* Visit http://localhost:9090/ for Prometheus, there try the following
  queries:
  * `asset_build_duration_seconds`
  * `rate(asset_build_runs_total[2m])`
* See a dry-run metrics output from the script:
~~~
$ ./metrics-pusher.sh
asset_build_duration_seconds{stack="foo"} 105
asset_build_duration_seconds{stack="bar"} 200
asset_build_runs_total{stack="foo"} 415108
asset_build_runs_total{stack="bar"} 341197
~~~
