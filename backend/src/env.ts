import 'dotenv/config';
export const env = {
  PORT: parseInt(process.env.PORT || '4000', 10),
  DATABASE_URL: process.env.DATABASE_URL!,
  TRUST_PROXY: (process.env.TRUST_PROXY || 'false').toLowerCase() === 'true',
  CORS_ORIGIN: process.env.CORS_ORIGIN || '*',
};
