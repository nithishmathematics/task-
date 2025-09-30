import express from 'express';
import pino from 'pino';
import pinoHttp from 'pino-http';
import pkg from 'pg';
const { Client } = pkg;

const app = express();
const logger = pino({ level: process.env.LOG_LEVEL || 'info' });
app.use(pinoHttp({ logger }));
app.use(express.json());

app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.get('/livez', (req, res) => {
  res.status(200).json({ status: 'live' });
});

app.get('/db-health', async (req, res) => {
  const url = process.env.DATABASE_URL;
  if (!url) return res.status(503).json({ status: 'no-db-config' });
  const client = new Client({ connectionString: url });
  try {
    const ctrl = new AbortController();
    const timeout = setTimeout(() => ctrl.abort(), 2000);
    await client.connect();
    const r = await client.query('SELECT 1 as ok');
    clearTimeout(timeout);
    await client.end();
    return res.status(200).json({ status: 'db-ok', result: r.rows[0] });
  } catch (err) {
    logger.error({ err }, 'db-health failed');
    try { await client.end(); } catch {}
    return res.status(500).json({ status: 'db-error' });
  }
});

app.get('/', (req, res) => {
  res.status(200).json({ service: 'user-service', version: '0.1.0' });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  logger.info(`user-service listening on :${port}`);
});
