#!/usr/bin/env bash
set -euo pipefail

# Папки
mkdir -p backend/{src/routes,prisma} frontend/src/components

# docker-compose.yml
cat > docker-compose.yml <<'EOF'
services:
  db:
    image: postgres:15
    container_name: logiclike-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: voting
      POSTGRES_PASSWORD: voting
      POSTGRES_DB: voting
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
volumes:
  pgdata:
EOF

# backend/package.json
cat > backend/package.json <<'EOF'
{
  "name": "logiclike-voting-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only src/server.ts",
    "build": "tsc -p .",
    "start": "node dist/server.js",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev --name init",
    "db:seed": "ts-node prisma/seed.ts"
  },
  "dependencies": {
    "fastify": "^4.28.1",
    "@fastify/cors": "^9.0.1",
    "@fastify/sensible": "^5.6.0",
    "@fastify/helmet": "^12.5.0",
    "@prisma/client": "^5.18.0",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "prisma": "^5.18.0",
    "ts-node": "^10.9.2",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.5.4"
  }
}
EOF

# backend/tsconfig.json
cat > backend/tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "Node",
    "outDir": "dist",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true
  },
  "include": ["src", "prisma/seed.ts"]
}
EOF

# backend/.env.example
cat > backend/.env.example <<'EOF'
DATABASE_URL="postgresql://voting:voting@localhost:5432/voting?schema=public"
PORT=4000
TRUST_PROXY=false
CORS_ORIGIN=http://localhost:5173
EOF

# Prisma schema + seed
cat > backend/prisma/schema.prisma <<'EOF'
generator client { provider = "prisma-client-js" }
datasource db { provider = "postgresql"; url = env("DATABASE_URL") }

model Idea {
  id          Int     @id @default(autoincrement())
  title       String
  description String
  votes       Vote[]
  votesCount  Int     @default(0)
  @@index([votesCount, id])
}

model Vote {
  id         Int      @id @default(autoincrement())
  idea       Idea     @relation(fields: [ideaId], references: [id], onDelete: Cascade)
  ideaId     Int
  ipAddress  String
  createdAt  DateTime @default(now())
  @@unique([ipAddress, ideaId], name: "ipAddress_ideaId")
  @@index([ipAddress])
}
EOF

cat > backend/prisma/seed.ts <<'EOF'
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  await prisma.vote.deleteMany();
  await prisma.idea.deleteMany();
  await prisma.idea.createMany({
    data: [
      { title: 'Быстрые мини-игры', description: 'Развивают внимание и скорость мышления.' },
      { title: 'Родительская аналитика', description: 'Показывает прогресс и рекомендации.' },
      { title: 'Офлайн-режим', description: 'Можно играть без интернета.' },
      { title: 'Кланы', description: 'Командные события и соревновательные режимы.' },
      { title: 'Интеграция со школьными LMS', description: 'LTI/SSO для дневников и платформ.' }
    ]
  });
  console.log('✅ Seeded ideas');
}
main().finally(() => prisma.$disconnect());
EOF

# backend/src/*
cat > backend/src/env.ts <<'EOF'
import 'dotenv/config';
export const env = {
  PORT: parseInt(process.env.PORT || '4000', 10),
  DATABASE_URL: process.env.DATABASE_URL!,
  TRUST_PROXY: (process.env.TRUST_PROXY || 'false').toLowerCase() === 'true',
  CORS_ORIGIN: process.env.CORS_ORIGIN || '*',
};
EOF

cat > backend/src/db.ts <<'EOF'
import { PrismaClient } from '@prisma/client';
export const prisma = new PrismaClient();
EOF

cat > backend/src/utils/ip.ts <<'EOF'
import { FastifyRequest } from 'fastify';
export function getClientIp(req: FastifyRequest): string {
  const ip = req.ip || req.socket.remoteAddress || '';
  return ip.replace('::ffff:', '');
}
EOF

cat > backend/src/routes/ideas.ts <<'EOF'
import { FastifyInstance } from 'fastify';
import { prisma } from '../db.js';
import { getClientIp } from '../utils/ip.js';

export async function ideasRoutes(app: FastifyInstance) {
  app.get('/ideas', async (req, reply) => {
    const ip = getClientIp(req);
    const [ideas, voted] = await Promise.all([
      prisma.idea.findMany({ orderBy: [{ votesCount: 'desc' }, { id: 'asc' }] }),
      prisma.vote.findMany({ where: { ipAddress: ip }, select: { ideaId: true } }),
    ]);
    const votedIds = new Set(voted.map(v => v.ideaId));
    return reply.send({
      ideas: ideas.map(i => ({ ...i, hasVoted: votedIds.has(i.id) })),
      ip,
    });
  });
}
EOF

cat > backend/src/routes/votes.ts <<'EOF'
import { FastifyInstance } from 'fastify';
import { prisma } from '../db.js';
import { getClientIp } from '../utils/ip.js';
const MAX_VOTES = 10;

export async function votesRoutes(app: FastifyInstance) {
  app.post('/ideas/:id/vote', async (req, reply) => {
    const ideaId = Number((req.params as any).id);
    if (!Number.isInteger(ideaId) || ideaId <= 0) return reply.badRequest('Invalid idea id');
    const ip = getClientIp(req);

    const existing = await prisma.vote.findUnique({
      where: { ipAddress_ideaId: { ipAddress: ip, ideaId } },
    });
    if (existing) return reply.status(409).send({ error: 'Уже голосовали за эту идею' });

    const total = await prisma.vote.count({ where: { ipAddress: ip } });
    if (total >= MAX_VOTES) return reply.status(409).send({ error: 'Лимит голосов для этого IP исчерпан' });

    await prisma.vote.create({ data: { ipAddress: ip, ideaId } });
    await prisma.idea.update({ where: { id: ideaId }, data: { votesCount: { increment: 1 } } });
    return reply.code(201).send({ ok: true });
  });
}
EOF

cat > backend/src/server.ts <<'EOF'
import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import sensible from '@fastify/sensible';
import { env } from './env.js';
import { ideasRoutes } from './routes/ideas.js';
import { votesRoutes } from './routes/votes.js';

const app = Fastify({ logger: true });
app.register(sensible);
app.register(helmet);
app.register(cors, { origin: env.CORS_ORIGIN, methods: ['GET', 'POST'] });
app.setTrustProxy(env.TRUST_PROXY);
app.register(ideasRoutes);
app.register(votesRoutes);
app.get('/health', async () => ({ ok: true }));

app.listen({ port: env.PORT, host: '0.0.0.0' })
  .then(() => app.log.info(`🚀 API on :${env.PORT}`))
  .catch((e) => { app.log.error(e); process.exit(1); });
EOF

# frontend/*
cat > frontend/package.json <<'EOF'
{
  "name": "logiclike-voting-frontend",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5173"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@types/react": "^18.2.66",
    "@types/react-dom": "^18.2.21",
    "@vitejs/plugin-react": "^4.3.0",
    "typescript": "^5.5.4",
    "vite": "^5.4.8"
  }
}
EOF

cat > frontend/vite.config.ts <<'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:4000',
        changeOrigin: true,
        rewrite: p => p.replace(/^\/api/, '')
      }
    }
  }
});
EOF

cat > frontend/index.html <<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>LogicLike — Ideas Voting</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

cat > frontend/src/types.ts <<'EOF'
export type Idea = { id: number; title: string; description: string; votesCount: number; hasVoted?: boolean; };
export type IdeasResponse = { ideas: Idea[]; ip: string; };
EOF

cat > frontend/src/api.ts <<'EOF'
import type { IdeasResponse } from './types';
export async function fetchIdeas(): Promise<IdeasResponse> {
  const res = await fetch('/api/ideas');
  if (!res.ok) throw new Error('Failed to fetch ideas');
  return res.json();
}
export async function vote(ideaId: number): Promise<void> {
  const res = await fetch(`/api/ideas/${ideaId}/vote`, { method: 'POST' });
  if (res.status === 201) return;
  if (res.status === 409) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body?.error || 'Conflict: already voted or limit reached');
  }
  throw new Error('Failed to vote');
}
EOF

cat > frontend/src/components/IdeaCard.tsx <<'EOF'
import { Idea } from '../types';
type Props = { idea: Idea; onVote: (id: number) => void; loading: boolean; };
export default function IdeaCard({ idea, onVote, loading }: Props) {
  return (
    <div style={{ border: '1px solid #e5e7eb', borderRadius: 8, padding: 12, marginBottom: 10 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
        <div>
          <h3 style={{ margin: '4px 0' }}>{idea.title}</h3>
          <p style={{ margin: '4px 0', color: '#4b5563' }}>{idea.description}</p>
        </div>
        <div style={{ textAlign: 'right', minWidth: 120 }}>
          <div style={{ fontWeight: 700, fontSize: 18 }}>{idea.votesCount}</div>
          <div style={{ fontSize: 12, color: '#6b7280' }}>votes</div>
          <button
            disabled={loading || idea.hasVoted}
            onClick={() => onVote(idea.id)}
            style={{ marginTop: 8, padding: '6px 10px', borderRadius: 6, border: '1px solid #d1d5db',
                     background: idea.hasVoted ? '#e5e7eb' : 'white', cursor: idea.hasVoted ? 'not-allowed' : 'pointer' }}
            title={idea.hasVoted ? 'Вы уже голосовали за эту идею' : 'Проголосовать'}
          >
            {idea.hasVoted ? 'Голос учтён' : 'Проголосовать'}
          </button>
        </div>
      </div>
    </div>
  );
}
EOF

cat > frontend/src/App.tsx <<'EOF'
import { useEffect, useState } from 'react';
import { fetchIdeas, vote } from './api';
import type { Idea } from './types';
import IdeaCard from './components/IdeaCard';

export default function App() {
  const [ideas, setIdeas] = useState<Idea[]>([]);
  const [ip, setIp] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function load() {
    setError(null);
    try {
      const data = await fetchIdeas();
      setIdeas(data.ideas);
      setIp(data.ip);
    } catch (e: any) {
      setError(e.message || 'Ошибка загрузки');
    }
  }

  useEffect(() => { load(); }, []);

  async function onVote(id: number) {
    setLoading(true);
    setError(null);
    try {
      await vote(id);
      await load();
    } catch (e: any) {
      setError(e.message || 'Не удалось проголосовать');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={{ maxWidth: 840, margin: '40px auto', padding: '0 12px' }}>
      <h1>Идеи для LogicLike</h1>
      <p style={{ color: '#4b5563' }}>Ваш IP: <code>{ip}</code>. Можно отдать голос не более чем за 10 разных идей.</p>
      {error && (
        <div style={{ background: '#fee2e2', color: '#991b1b', padding: 10, borderRadius: 6, marginBottom: 10 }}>
          {error}
        </div>
      )}
      {ideas.map(idea => (
        <IdeaCard key={idea.id} idea={idea} loading={loading} onVote={onVote} />
      ))}
    </div>
  );
}
EOF

cat > frontend/src/main.tsx <<'EOF'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

echo "✅ Files scaffolded."
