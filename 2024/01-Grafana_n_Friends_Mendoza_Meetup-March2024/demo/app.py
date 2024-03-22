import time
import random

from flask import Flask, request
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)

demo_app_requests_counter = metrics.counter(
    'path_method:demo_app_requests', 'Request count by request paths',
    labels={
        'path': lambda: request.path,
        'method': lambda: request.method,
    }
)


@app.route('/fast')
@demo_app_requests_counter
def fast():
    "Simulate fast response"
    time.sleep(random.uniform(0.01, 0.1))
    return 'Fast'


@app.route('/slow')
@demo_app_requests_counter
def slow():
    "Simulate slow response"
    time.sleep(random.uniform(0.05, 0.5))
    return 'Slow'


if __name__ == '__main__':
    app.run('0.0.0.0', 5000)
