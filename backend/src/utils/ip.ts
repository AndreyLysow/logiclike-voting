import type { FastifyRequest } from 'fastify';

/**
 * Возвращает реальный IP клиента.
 * - Берём первый адрес из X-Forwarded-For (если есть)
 * - Иначе используем req.ip (работает корректно, если trustProxy=true)
 */
export function getClientIp(req: FastifyRequest): string {
  const xf = req.headers['x-forwarded-for'];
  if (typeof xf === 'string' && xf.length) return xf.split(',')[0].trim();
  if (Array.isArray(xf) && xf.length) return String(xf[0]).split(',')[0].trim();
  return req.ip;
}