import { FastifyRequest } from 'fastify';
export function getClientIp(req: FastifyRequest): string {
  const ip = req.ip || req.socket.remoteAddress || '';
  return ip.replace('::ffff:', '');
}
