import 'dotenv/config';

export const env = {
  PORT: Number(process.env.PORT ?? 4000),
  CORS_ORIGIN: process.env.CORS_ORIGIN ?? 'http://localhost:5173',
  TRUST_PROXY: String(process.env.TRUST_PROXY ?? 'false').toLowerCase() === 'true',
};