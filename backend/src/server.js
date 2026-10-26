import { createApp } from './app.js';
import { config } from './config/env.js';
import { openDatabase } from './db/database.js';
import { seedIfEmpty } from './db/seed.js';

const db = openDatabase(config.dbPath);
const seeded = seedIfEmpty(db);
if (seeded > 0) console.log(`Base de datos vacía: se cargaron ${seeded} productos de prueba`);

const server = createApp(db).listen(config.port, config.host, () => {
  console.log(`API de inventario escuchando en http://localhost:${config.port}/api`);
});

function shutdown() {
  server.close(() => {
    db.close();
    process.exit(0);
  });
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
