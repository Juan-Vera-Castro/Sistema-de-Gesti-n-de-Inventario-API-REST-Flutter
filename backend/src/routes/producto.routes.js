import { Router } from 'express';

export function createProductoRouter(controller) {
  const router = Router();

  router.get('/', controller.list);
  router.get('/:id', controller.show);
  router.post('/', controller.create);
  router.put('/:id', controller.update);
  router.delete('/:id', controller.remove);

  return router;
}
