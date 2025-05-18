import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  vus: 900,
  duration: '3s',
};

export default function() {
  const res = http.post('https://db-litestream-886786442757.asia-northeast1.run.app/count_up');
  check(res, { "status is 200": (res) => res.status === 200 });
  // sleep(1);
}
