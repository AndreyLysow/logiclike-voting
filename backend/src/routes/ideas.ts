import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../db';
import { getClientIp } from '../utils/ip';

export async function ideasRoutes(app: FastifyInstance) {
  app.get(
    '/ideas',
    async (req: FastifyRequest, reply: FastifyReply) => {
      const ip = getClientIp(req);

      const [ideas, voted] = await Promise.all([
        prisma.idea.findMany({
          orderBy: [{ votesCount: 'desc' }, { id: 'asc' }],
        }),
        prisma.vote.findMany({
          where: { ipAddress: ip },
          select: { ideaId: true },
        }),
      ]);

      const votedIds = new Set(voted.map(v => v.ideaId));

      return reply.send({
        ideas: ideas.map(i => ({
          id: i.id,
          title: i.title,
          description: i.description,
          votesCount: i.votesCount,
          hasVoted: votedIds.has(i.id),
        })),
        ip,
      });
    }
  );
}