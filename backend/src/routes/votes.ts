import { FastifyInstance } from 'fastify';
import { prisma } from '../db';
import { getClientIp } from '../utils/ip';
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
