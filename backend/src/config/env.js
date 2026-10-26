import dotenv from 'dotenv';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const backendRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');

dotenv.config({ path: path.join(backendRoot, '.env'), quiet: true });

function resolveDbPath(value) {
  if (value === ':memory:') return value;
  return path.resolve(backendRoot, value);
}

export const config = Object.freeze({
  port: Number.parseInt(process.env.PORT ?? '3000', 10),
  host: process.env.HOST ?? '0.0.0.0',
  dbPath: resolveDbPath(process.env.DB_PATH ?? './data/inventario.db'),
});
