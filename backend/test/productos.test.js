import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, it } from 'node:test';
import { createApp } from '../src/app.js';
import { openDatabase } from '../src/db/database.js';
import { seedDatabase } from '../src/db/seed.js';
import { productosSeed } from '../src/db/seed-data.js';

const nuevoProducto = {
  nombre: 'Memoria USB 64 GB',
  codigo: 'TEC-100',
  descripcion: 'USB 3.2',
  precio: 39900,
  cantidad: 20,
  categoria: 'Tecnología',
};

let db;
let server;
let baseUrl;

async function request(method, path, body, { raw = false } = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    method,
    headers: body !== undefined ? { 'Content-Type': 'application/json' } : {},
    body: body === undefined ? undefined : raw ? body : JSON.stringify(body),
  });
  return { status: res.status, headers: res.headers, body: await res.json() };
}

before(async () => {
  db = openDatabase(':memory:');
  server = createApp(db).listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}/api`;
});

after(() => {
  server.close();
  db.close();
});

beforeEach(() => seedDatabase(db));

describe('GET /api/productos', () => {
  it('lista los productos del seeder con el formato estándar', async () => {
    const { status, body } = await request('GET', '/productos');
    assert.equal(status, 200);
    assert.equal(body.success, true);
    assert.equal(body.total, productosSeed.length);
    assert.ok(productosSeed.length >= 10);
    assert.deepEqual(Object.keys(body.data[0]).sort(), [
      'actualizado_en', 'cantidad', 'categoria', 'codigo', 'creado_en', 'descripcion', 'id', 'nombre', 'precio',
    ]);
  });
});

describe('GET /api/productos/:id', () => {
  it('devuelve el detalle de un producto', async () => {
    const { status, body } = await request('GET', '/productos/1');
    assert.equal(status, 200);
    assert.equal(body.data.codigo, productosSeed[0].codigo);
  });

  it('responde 404 si no existe', async () => {
    const { status, body } = await request('GET', '/productos/9999');
    assert.equal(status, 404);
    assert.equal(body.success, false);
  });

  it('responde 400 si el id no es válido', async () => {
    const { status } = await request('GET', '/productos/abc');
    assert.equal(status, 400);
  });
});

describe('POST /api/productos', () => {
  it('crea un producto y responde 201 con Location', async () => {
    const { status, headers, body } = await request('POST', '/productos', nuevoProducto);
    assert.equal(status, 201);
    assert.equal(body.data.id, productosSeed.length + 1);
    assert.equal(headers.get('location'), `/api/productos/${body.data.id}`);
    assert.equal(body.data.nombre, nuevoProducto.nombre);
  });

  it('normaliza textos, números en texto y descripción vacía', async () => {
    const { status, body } = await request('POST', '/productos', {
      ...nuevoProducto, nombre: '  Cable HDMI  ', precio: '15000.456', cantidad: '3', descripcion: '',
    });
    assert.equal(status, 201);
    assert.equal(body.data.nombre, 'Cable HDMI');
    assert.equal(body.data.precio, 15000.46);
    assert.equal(body.data.cantidad, 3);
    assert.equal(body.data.descripcion, null);
  });

  it('responde 422 con errores por campo cuando faltan datos', async () => {
    const { status, body } = await request('POST', '/productos', {});
    assert.equal(status, 422);
    assert.deepEqual(Object.keys(body.errors).sort(), ['cantidad', 'categoria', 'codigo', 'nombre', 'precio']);
  });

  it('rechaza precio <= 0 y cantidad negativa o decimal', async () => {
    let res = await request('POST', '/productos', { ...nuevoProducto, precio: 0, cantidad: -1 });
    assert.equal(res.status, 422);
    assert.ok(res.body.errors.precio);
    assert.ok(res.body.errors.cantidad);

    res = await request('POST', '/productos', { ...nuevoProducto, cantidad: 1.5 });
    assert.equal(res.status, 422);
    assert.ok(res.body.errors.cantidad);
  });

  it('rechaza con 422 (no 500) precios que se redondean a 0 y cantidades fuera de rango', async () => {
    const { status, body } = await request('POST', '/productos', { ...nuevoProducto, precio: 0.001, cantidad: 1e20 });
    assert.equal(status, 422);
    assert.ok(body.errors.precio);
    assert.ok(body.errors.cantidad);
  });

  it('rechaza código duplicado sin distinguir mayúsculas', async () => {
    const { status, body } = await request('POST', '/productos', {
      ...nuevoProducto, codigo: productosSeed[0].codigo.toLowerCase(),
    });
    assert.equal(status, 422);
    assert.ok(body.errors.codigo);
  });

  it('responde 400 ante JSON mal formado', async () => {
    const { status, body } = await request('POST', '/productos', '{"nombre": ', { raw: true });
    assert.equal(status, 400);
    assert.equal(body.success, false);
  });
});

describe('PUT /api/productos/:id', () => {
  it('actualiza un producto existente', async () => {
    const { status, body } = await request('PUT', '/productos/2', { ...nuevoProducto, codigo: 'TEC-002', cantidad: 99 });
    assert.equal(status, 200);
    assert.equal(body.data.id, 2);
    assert.equal(body.data.cantidad, 99);
    assert.equal(body.data.nombre, nuevoProducto.nombre);
  });

  it('permite conservar su propio código pero no el de otro producto', async () => {
    const res = await request('PUT', '/productos/2', { ...nuevoProducto, codigo: productosSeed[0].codigo });
    assert.equal(res.status, 422);
    assert.ok(res.body.errors.codigo);
  });

  it('responde 404 si no existe', async () => {
    const { status } = await request('PUT', '/productos/9999', nuevoProducto);
    assert.equal(status, 404);
  });

  it('responde 422 si los datos no son válidos', async () => {
    const { status } = await request('PUT', '/productos/1', { ...nuevoProducto, nombre: '' });
    assert.equal(status, 422);
  });
});

describe('DELETE /api/productos/:id', () => {
  it('elimina el producto y luego responde 404', async () => {
    let res = await request('DELETE', '/productos/3');
    assert.equal(res.status, 200);
    assert.equal(res.body.data.id, 3);

    res = await request('GET', '/productos/3');
    assert.equal(res.status, 404);
  });

  it('responde 404 si no existe', async () => {
    const { status } = await request('DELETE', '/productos/9999');
    assert.equal(status, 404);
  });
});

describe('Rutas desconocidas', () => {
  it('responden 404 en JSON', async () => {
    const { status, body } = await request('GET', '/no-existe');
    assert.equal(status, 404);
    assert.equal(body.success, false);
  });
});
