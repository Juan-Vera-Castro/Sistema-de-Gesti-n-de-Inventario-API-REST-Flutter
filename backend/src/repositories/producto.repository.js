const COLUMNS = 'id, nombre, codigo, descripcion, precio, cantidad, categoria, creado_en, actualizado_en';

// node:sqlite devuelve objetos sin prototipo; se copian a objetos planos.
const toPlain = (row) => (row ? { ...row } : null);

/** Acceso a datos de la tabla `productos` mediante sentencias preparadas. */
export function createProductoRepository(db) {
  const statements = {
    findAll: db.prepare(`SELECT ${COLUMNS} FROM productos ORDER BY id`),
    findById: db.prepare(`SELECT ${COLUMNS} FROM productos WHERE id = ?`),
    findByCodigo: db.prepare('SELECT id FROM productos WHERE codigo = ? COLLATE NOCASE'),
    insert: db.prepare(`
      INSERT INTO productos (nombre, codigo, descripcion, precio, cantidad, categoria)
      VALUES (:nombre, :codigo, :descripcion, :precio, :cantidad, :categoria)
    `),
    update: db.prepare(`
      UPDATE productos
         SET nombre = :nombre, codigo = :codigo, descripcion = :descripcion,
             precio = :precio, cantidad = :cantidad, categoria = :categoria,
             actualizado_en = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
       WHERE id = :id
    `),
    remove: db.prepare('DELETE FROM productos WHERE id = ?'),
  };

  return {
    findAll() {
      return statements.findAll.all().map(toPlain);
    },

    findById(id) {
      return toPlain(statements.findById.get(id));
    },

    /** Indica si el código ya pertenece a otro producto (ignora `exceptId`). */
    codigoExists(codigo, exceptId = null) {
      const row = statements.findByCodigo.get(codigo);
      return Boolean(row) && row.id !== exceptId;
    },

    create(producto) {
      const { lastInsertRowid } = statements.insert.run(producto);
      return this.findById(Number(lastInsertRowid));
    },

    update(id, producto) {
      const { changes } = statements.update.run({ ...producto, id });
      return changes > 0 ? this.findById(id) : null;
    },

    remove(id) {
      return statements.remove.run(id).changes > 0;
    },
  };
}
