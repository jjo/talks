-- Create the database
DROP DATABASE IF EXISTS my_db;
CREATE DATABASE my_db;

-- Use the database
USE my_db;

-- Create the table
CREATE TABLE my_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    column1 VARCHAR(255),
    column2 VARCHAR(255)
);
