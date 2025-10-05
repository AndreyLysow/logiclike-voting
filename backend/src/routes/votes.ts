import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../db';
import { getClientIp } from '../utils/ip';

const MAX_VOTES = 10;

type VoteParams = { id: string };

export async function votesRoutes(app: FastifyInstance) {
  app.post(
    '/ideas/:id/vote',
    async (req: FastifyRequest<{ Params: VoteParams }>, reply: FastifyReply) => {
      // 1) Валидация id
      const ideaId = Number(req.params.id);
      if (!Number.isInteger(ideaId) || ideaId <= 0) {
        return reply.badRequest('Invalid idea id');
      }

      const ip = getClientIp(req);

      // 2) Проверка лимита голосов (до попытки создать голос)
      const total = await prisma.vote.count({ where: { ipAddress: ip } });
      if (total >= MAX_VOTES) {
        return reply.status(409).send({ error: 'Лимит голосов для этого IP исчерпан' });
      }

      // 3) Атомарно создаём голос и инкрементим счётчик.
      //    Если голос уже был, словим уникальный индекс P2002 и вернём 409.
      try {
        await prisma.$transaction([
          prisma.vote.create({
            data: { ipAddress: ip, ideaId },
          }),
          prisma.idea.update({
            where: { id: ideaId },
            data: { votesCount: { increment: 1 } },
          }),
        ]);
      } catch (e: any) {
        // P2002 — нарушение уникального индекса (ipAddress + ideaId)
        if (e?.code === 'P2002') {
          return reply.status(409).send({ error: 'Уже голосовали за эту идею' });
        }
        app.log.error({ err: e }, 'Vote transaction failed');
        throw e;
      }

      return reply.code(201).send({ ok: true });
    }
  );
}