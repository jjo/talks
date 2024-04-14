import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 10 }, // Ramp up to 10 VUs
    { duration: '2m', target: 1000 }, // Stay at 1000 VUs for 2 minute
    { duration: '30s', target: 0 }, // Ramp down to 0 VUs
  ],
};

export default function() {
  // Create a new item
  const createResponse = http.post('http://web:5000/items', JSON.stringify({ column1: 'value1', column2: 'value2' }), {
    headers: { 'Content-Type': 'application/json' },
  });

  check(createResponse, {
    'create item status is 201': (r) => r.status === 201,
  });

  // Retrieve all items
  const getResponse = http.get('http://web:5000/items');

  check(getResponse, {
    'get items status is 200': (r) => r.status === 200,
    'get items returns array': (r) => Array.isArray(JSON.parse(r.body)),
  });

  // Update an existing item
  const itemId = JSON.parse(getResponse.body)[0].id;
  const updateResponse = http.put(`http://web:5000/items/${itemId}`, JSON.stringify({ column1: 'updated_value1', column2: 'updated_value2' }), {
    headers: { 'Content-Type': 'application/json' },
  });

  check(updateResponse, {
    'update item status is 200': (r) => r.status === 200,
  });

  // Delete an item
  const deleteResponse = http.del(`http://web:5000/items/${itemId}`);

  check(deleteResponse, {
    'delete item status is 200': (r) => r.status === 200,
  });

  sleep(1); // Pause for 1 second
}
