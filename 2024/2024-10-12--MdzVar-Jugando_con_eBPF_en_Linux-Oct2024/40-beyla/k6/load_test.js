import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp up to 20 users over 30 seconds
    { duration: '1m', target: 20 },   // Stay at 20 users for 1 minute
    { duration: '30s', target: 0 },   // Ramp down to 0 users over 30 seconds
  ],
};

const BASE_URL = 'http://simplesrv:8080';

// Define an array of paths to test
const PATHS = [
  '/',
  '/api/users',
  '/api/products',
  '/api/orders',
  '/health',
];

function getRandomPath() {
  return PATHS[Math.floor(Math.random() * PATHS.length)];
}

function getRandomDelay(path) {
  /*
  if (path === '/api/orders') {
    // Make /api/orders noticeably slower
    return randomIntBetween(1000, 5000); // 1-3 seconds delay
  }
  */
  return randomIntBetween(0, 500); // 0-500 ms delay for other paths
}

export default function () {
  const path = getRandomPath();
  const delay = getRandomDelay(path);
  const url = `${BASE_URL}${path}?force_delay=${delay}`;

  const res = http.get(url);

  check(res, {
    'status is 200': (r) => r.status === 200,
    [`response time was at least ${delay}ms`]: (r) => r.timings.duration >= delay,
  });

  console.log(`Request to ${path} with ${delay}ms delay: status=${res.status}, duration=${res.timings.duration}ms`);

  // Occasionally test with a forced return code
  if (Math.random() < 0.1) { // 10% of the time
    const forcedCode = [400, 404, 500][Math.floor(Math.random() * 3)];
    const forcedUrl = `${BASE_URL}${path}?force_ret=${forcedCode}`;
    const forcedRes = http.get(forcedUrl);

    check(forcedRes, {
      [`status is ${forcedCode}`]: (r) => r.status === forcedCode,
    });

    console.log(`Forced request to ${path} with code ${forcedCode}: status=${forcedRes.status}`);
  }

  sleep(1);
}
