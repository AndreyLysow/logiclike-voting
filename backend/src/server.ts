import Fastify from 'fastify';
import cors from '@fastify/cors';
import sensible from '@fastify/sensible';
import { env } from './env';
import { ideasRoutes } from './routes/ideas';
import { votesRoutes } from './routes/votes';

const app = Fastify({
  logger: true,
  trustProxy: env.TRUST_PROXY,   // ← ВАЖНО
});

app.register(sensible);
app.register(cors, { origin: env.CORS_ORIGIN, methods: ['GET', 'POST'] });

app.register(ideasRoutes);
app.register(votesRoutes);

app.get('/health', async () => ({ ok: true }));

// временная диагностика: посмотреть, что видит сервер
app.get('/ip', async (req) => ({ ip: req.ip, xff: req.headers['x-forwarded-for'] }));

app.listen({ port: env.PORT, host: '0.0.0.0' })
  .then(() => app.log.info(`🚀 API on :${env.PORT}, trustProxy=${env.TRUST_PROXY}`))
  .catch((e) => { app.log.error(e); process.exit(1); });