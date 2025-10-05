import { FastifyInstance } from 'fastify';
import { prisma } from '../db';
import { getClientIp } from '../utils/ip';

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
