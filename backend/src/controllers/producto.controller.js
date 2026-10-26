import { HttpError, sendSuccess } from '../utils/response.js';
import { parseId, validateProducto } from '../validators/producto.validator.js';

const CODIGO_DUPLICADO = { codigo: 'Ya existe un producto con este código' };

/** Controladores HTTP del recurso /api/productos. */
export function createProductoController(repository) {
  function requireId(req) {
    const id = parseId(req.params.id);
    if (id === null) throw new HttpError(400, 'El id debe ser un número entero positivo');
    return id;
  }

  function requireProducto(id) {
    const producto = repository.findById(id);
    if (!producto) throw new HttpError(404, `No existe un producto con id ${id}`);
    return producto;
  }

  function requireValidBody(body, exceptId = null) {
    const { data, errors } = validateProducto(body);
    if (!data) throw new HttpError(422, 'Los datos del producto no son válidos', errors);
    if (repository.codigoExists(data.codigo, exceptId)) {
      throw new HttpError(422, 'Los datos del producto no son válidos', CODIGO_DUPLICADO);
    }
    return data;
  }

  return {
    list(req, res) {
      const productos = repository.findAll();
      sendSuccess(res, { message: 'Productos obtenidos correctamente', total: productos.length, data: productos });
    },

    show(req, res) {
      const producto = requireProducto(requireId(req));
      sendSuccess(res, { message: 'Producto obtenido correctamente', data: producto });
    },

    create(req, res) {
      const data = requireValidBody(req.body);
      const producto = repository.create(data);
      res.location(`/api/productos/${producto.id}`);
      sendSuccess(res, { status: 201, message: 'Producto creado correctamente', data: producto });
    },

    update(req, res) {
      const id = requireId(req);
      requireProducto(id);
      const data = requireValidBody(req.body, id);
      const producto = repository.update(id, data);
      sendSuccess(res, { message: 'Producto actualizado correctamente', data: producto });
    },

    remove(req, res) {
      const id = requireId(req);
      const producto = requireProducto(id);
      repository.remove(id);
      sendSuccess(res, { message: 'Producto eliminado correctamente', data: producto });
    },
  };
}
