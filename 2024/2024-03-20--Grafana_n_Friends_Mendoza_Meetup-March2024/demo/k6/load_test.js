import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 10 }, // Ramp-up stage
    { duration: '5m', target: 1000 }, // Sustain load for 5 minutes
    { duration: '30s', target: 0 }, // Ramp-down stage
  ],
};

export default function () {
  const responses = http.batch([
    ['GET', 'http://web:5000/fast'],
    ['GET', 'http://web:5000/slow'],
  ]);

  sleep(1);
}
