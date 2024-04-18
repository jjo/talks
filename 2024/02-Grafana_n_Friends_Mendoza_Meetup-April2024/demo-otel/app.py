import sys

from flask import Flask, jsonify, request, Response

import mariadb

app = Flask(__name__)

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
    cursor = mariadb_connection.cursor()
    cursor.execute("SELECT * FROM my_table")
    data = cursor.fetchall()
    return jsonify(data)

@app.route('/items', methods=['POST'])
def create_item():
    data = request.get_json()
    cursor = mariadb_connection.cursor()
    query = "INSERT INTO my_table (column1, column2) VALUES (?, ?)"
    cursor.execute(query, (data['column1'], data['column2']))
    mariadb_connection.commit()
    return jsonify({"message": "Item created successfully"}), 201

@app.route('/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    data = request.get_json()
    cursor = mariadb_connection.cursor()
    query = "UPDATE my_table SET column1 = ?, column2 = ? WHERE id = ?"
    cursor.execute(query, (data['column1'], data['column2'], item_id))
    mariadb_connection.commit()
    return jsonify({"message": "Item updated successfully"})

@app.route('/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    cursor = mariadb_connection.cursor()
    query = "DELETE FROM my_table WHERE id = ?"
    cursor.execute(query, (item_id,))
    mariadb_connection.commit()
    return jsonify({"message": "Item deleted successfully"})


@app.route('/items/search', methods=['GET'])
def search_items():
    column1 = request.args.get('column1')
    cursor = mariadb_connection.cursor()
    query = "SELECT * FROM my_table WHERE column1 = ?"
    cursor.execute(query, (column1,))
    data = cursor.fetchall()
    return jsonify(data)

if __name__ == '__main__':
    app.run()
