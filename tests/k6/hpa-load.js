// Ramps load on the API so the product-service HPA scales out.
import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL;
const params = { timeout: '10s' };

export const options = {
  scenarios: {
    ramp: {
      executor: 'ramping-arrival-rate',
      startRate: 50,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 200,
      stages: [
        { target: 200, duration: '1m' },
        { target: 200, duration: '2m' },
        { target: 0, duration: '30s' },
      ],
    },
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/api/products`, params);
  check(res, { 'status is 200': (r) => r.status === 200 });
}
