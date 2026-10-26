import { pathToFileURL } from 'node:url';
import { config } from '../config/env.js';
import { openDatabase } from './database.js';
import { productosSeed } from './seed-data.js';

/**
 * Reinicia la tabla `productos` y carga los datos de prueba.
 * @param {import('node:sqlite').DatabaseSync} db
 * @returns {number} Cantidad de productos insertados.
 */
export function seedDatabase(db) {
  const insert = db.prepare(`
    INSERT INTO productos (nombre, codigo, descripcion, precio, cantidad, categoria)
    VALUES (:nombre, :codigo, :descripcion, :precio, :cantidad, :categoria)
  `);

  db.exec('BEGIN');
  try {
    db.exec('DELETE FROM productos');
    db.exec("DELETE FROM sqlite_sequence WHERE name = 'productos'");
    for (const producto of productosSeed) insert.run(producto);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
  return productosSeed.length;
}

/** Ejecuta el seeder solo si la tabla está vacía (arranque del servidor). */
export function seedIfEmpty(db) {
  const { total } = db.prepare('SELECT COUNT(*) AS total FROM productos').get();
  return total === 0 ? seedDatabase(db) : 0;
}

// Ejecución directa: `npm run seed`
if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const db = openDatabase(config.dbPath);
  const total = seedDatabase(db);
  db.close();
  console.log(`Seeder completado: ${total} productos cargados en ${config.dbPath}`);
}
