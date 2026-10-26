import fs from 'node:fs';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';

const SCHEMA = `
  CREATE TABLE IF NOT EXISTS productos (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre         TEXT    NOT NULL CHECK (length(trim(nombre)) BETWEEN 1 AND 100),
    codigo         TEXT    NOT NULL UNIQUE COLLATE NOCASE
                           CHECK (length(trim(codigo)) BETWEEN 1 AND 50),
    descripcion    TEXT    CHECK (descripcion IS NULL OR length(descripcion) <= 500),
    precio         REAL    NOT NULL CHECK (precio > 0),
    cantidad       INTEGER NOT NULL CHECK (cantidad >= 0),
    categoria      TEXT    NOT NULL CHECK (length(trim(categoria)) BETWEEN 1 AND 50),
    creado_en      TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    actualizado_en TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
  );
`;

/**
 * Abre (o crea) la base de datos SQLite y garantiza que el esquema exista.
 * @param {string} dbPath Ruta del archivo o ':memory:'.
 */
export function openDatabase(dbPath) {
  if (dbPath !== ':memory:') {
    fs.mkdirSync(path.dirname(dbPath), { recursive: true });
  }
  const db = new DatabaseSync(dbPath);
  db.exec('PRAGMA journal_mode = WAL;');
  db.exec(SCHEMA);
  return db;
}
