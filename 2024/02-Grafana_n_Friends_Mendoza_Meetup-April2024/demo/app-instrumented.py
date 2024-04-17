import sys

from flask import Flask, jsonify, request, Response

from prometheus_flask_exporter import PrometheusMetrics

from prometheus_client import Counter, start_http_server
from prometheus_client import multiprocess
from prometheus_client import generate_latest, CollectorRegistry, CONTENT_TYPE_LATEST

import mariadb

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Prometheus metrics
demo_app_http_requests_counter = metrics.counter(
    'demo_app_http_requests', 'Request count by request paths',
    labels={
        'path': lambda: request.path,
        'method': lambda: request.method,
    }
)
db_query_counter = metrics.counter(
    'db_queries_total', 'Total number of database queries',
)
db_query_latency = metrics.histogram(
    'db_query_latency_seconds', 'Database query latency in seconds',
    labels={
        'method': lambda: request.method,
    }
)
db_rows_created = Counter('db_rows_created_total', 'Total number of rows created')
db_rows_updated = Counter('db_rows_updated_total', 'Total number of rows updated')
db_rows_deleted = Counter('db_rows_deleted_total', 'Total number of rows deleted')

# MariaDB connection
try:
    mariadb_connection = mariadb.connect(
        host="db",
        user="my_user",
        password="not_secret",
        database="my_db"
    )
except mariadb.Error as e:
    print(f"Error connecting to MariaDB Platform: {e}")
    sys.exit(1)


@app.route('/items', methods=['GET'])
@demo_app_http_requests_counter
@db_query_counter
@db_query_latency
def get_items():
    cursor = mariadb_connection.cursor()
    cursor.execute("SELECT * FROM my_table")
    data = cursor.fetchall()
    return jsonify(data)


@app.route('/items', methods=['POST'])
@demo_app_http_requests_counter
@db_query_counter
@db_query_latency
def create_item():
    data = request.get_json()
    cursor = mariadb_connection.cursor()
    query = "INSERT INTO my_table (column1, column2) VALUES (?, ?)"
    cursor.execute(query, (data['column1'], data['column2']))
    mariadb_connection.commit()
    db_rows_created.inc()
    return jsonify({"message": "Item created successfully"}), 201


@app.route('/items/<int:item_id>', methods=['PUT'])
@demo_app_http_requests_counter
@db_query_counter
@db_query_latency
def update_item(item_id):
    data = request.get_json()
    cursor = mariadb_connection.cursor()
    query = "UPDATE my_table SET column1 = ?, column2 = ? WHERE id = ?"
    cursor.execute(query, (data['column1'], data['column2'], item_id))
    mariadb_connection.commit()
    db_rows_updated.inc()
    return jsonify({"message": "Item updated successfully"})


@app.route('/items/<int:item_id>', methods=['DELETE'])
@demo_app_http_requests_counter
@db_query_counter
@db_query_latency
def delete_item(item_id):
    cursor = mariadb_connection.cursor()
    query = "DELETE FROM my_table WHERE id = ?"
    cursor.execute(query, (item_id,))
    mariadb_connection.commit()
    db_rows_deleted.inc()
    return jsonify({"message": "Item deleted successfully"})


@app.route('/items/search', methods=['GET'])
@demo_app_http_requests_counter
@db_query_counter
@db_query_latency
def search_items():
    column1 = request.args.get('column1')
    cursor = mariadb_connection.cursor()
    query = "SELECT * FROM my_table WHERE column1 = ?"
    cursor.execute(query, (column1,))
    data = cursor.fetchall()
    return jsonify(data)


@app.route("/metrics")
def metrics():
    registry = CollectorRegistry()
    multiprocess.MultiProcessCollector(registry)
    data = generate_latest(registry)
    return Response(data, mimetype=CONTENT_TYPE_LATEST)


if __name__ == '__main__':
    start_http_server(5000)
    app.run()
