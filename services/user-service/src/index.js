import express from 'express';
import pino from 'pino';
import pinoHttp from 'pino-http';

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

app.get('/', (req, res) => {
  res.status(200).json({ service: 'user-service', version: '0.1.0' });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  logger.info(`user-service listening on :${port}`);
});
