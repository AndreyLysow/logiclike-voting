import Fastify from 'fastify';
import cors from '@fastify/cors';
import sensible from '@fastify/sensible';
// import helmet from '@fastify/helmet';
import { env } from './env';
import { ideasRoutes } from './routes/ideas';
import { votesRoutes } from './routes/votes';

const app = Fastify({ logger: true });
app.register(sensible);
app.register(cors, { origin: env.CORS_ORIGIN, methods: ['GET', 'POST'] });
// app.setTrustProxy(env.TRUST_PROXY);  // ❌ Убираем
app.register(ideasRoutes);
app.register(votesRoutes);
app.get('/health', async () => ({ ok: true }));

app.listen({ port: env.PORT, host: '0.0.0.0' })
  .then(() => app.log.info(`🚀 API on :${env.PORT}`))
  .catch((e) => { app.log.error(e); process.exit(1); });