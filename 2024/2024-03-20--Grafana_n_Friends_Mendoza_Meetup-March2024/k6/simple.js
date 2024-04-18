import http from 'k6/http';
import { sleep } from 'k6';

function fast_endpoint() {
  http.get('http://localhost:5000/fast');
}

function slow_endpoint() {
  http.get('http://localhost:5000/slow');
}

function get_endpoint() {
  const r = Math.random();
  if (r < 0.2) return slow_endpoint;
  return fast_endpoint;
}

export default function() {
  const endpoint = get_endpoint();
  endpoint(); // calls the endpoint
}
