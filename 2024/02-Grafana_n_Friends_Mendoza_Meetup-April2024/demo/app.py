import sys

from flask import Flask, jsonify, request, Response
from prometheus_client import Counter, Gauge, Histogram, start_http_server

from prometheus_client import multiprocess
from prometheus_client import generate_latest, CollectorRegistry, CONTENT_TYPE_LATEST
import mariadb

app = Flask(__name__)

# Prometheus metrics
db_query_counter = Counter('db_queries_total', 'Total number of database queries')
db_query_latency = Histogram('db_query_latency_seconds', 'Database query latency in seconds')
db_rows_created = Counter('db_rows_created_total', 'Total number of rows created')
db_rows_updated = Counter('db_rows_updated_total', 'Total number of rows updated')
db_rows_deleted = Counter('db_rows_deleted_total', 'Total number of rows deleted')
db_rows_current = Gauge('db_rows_current', 'Current number of rows in the database')

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
def get_items():
    with db_query_latency.time():
        with db_query_counter.count_exceptions():
            cursor = mariadb_connection.cursor()
            cursor.execute("SELECT * FROM my_table")
            data = cursor.fetchall()
    db_rows_current.set(len(data))
    return jsonify(data)

@app.route('/items', methods=['POST'])
def create_item():
    data = request.get_json()
    with db_query_latency.time():
        with db_query_counter.count_exceptions():
            cursor = mariadb_connection.cursor()
            query = "INSERT INTO my_table (column1, column2) VALUES (?, ?)"
            cursor.execute(query, (data['column1'], data['column2']))
            mariadb_connection.commit()
    db_rows_created.inc()
    db_rows_current.inc()
    return jsonify({"message": "Item created successfully"}), 201

@app.route('/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    data = request.get_json()
    with db_query_latency.time():
        with db_query_counter.count_exceptions():
            cursor = mariadb_connection.cursor()
            query = "UPDATE my_table SET column1 = ?, column2 = ? WHERE id = ?"
            cursor.execute(query, (data['column1'], data['column2'], item_id))
            mariadb_connection.commit()
    db_rows_updated.inc()
    return jsonify({"message": "Item updated successfully"})

@app.route('/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    with db_query_latency.time():
        with db_query_counter.count_exceptions():
            cursor = mariadb_connection.cursor()
            query = "DELETE FROM my_table WHERE id = ?"
            cursor.execute(query, (item_id,))
            mariadb_connection.commit()
    db_rows_deleted.inc()
    db_rows_current.dec()
    return jsonify({"message": "Item deleted successfully"})


@app.route('/items/search', methods=['GET'])
def search_items():
    column1 = request.args.get('column1')
    with db_query_latency.time():
        with db_query_counter.count_exceptions():
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
    #app.run(debug=True)
    app.run()
