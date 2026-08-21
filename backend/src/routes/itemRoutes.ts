import { Router } from 'express';
import {
  getItems,
  getTrending,
  getFeatured,
  getItem,
  getMyItems,
  createItem,
  updateItem,
  deleteItem,
  deactivateItem,
  activateItem,
  boostItem,
} from '../controllers/itemController.js';
import { protect } from '../middleware/auth.js';
import { validate } from '../middleware/validator.js';
import { createItemSchema, updateItemSchema } from '../validators/itemValidator.js';

const router: Router = Router();

router.get('/', getItems);
router.get('/mine', protect, getMyItems);
router.get('/trending', getTrending);
router.get('/featured', getFeatured);
router.get('/:id', getItem);
router.post('/', protect, validate(createItemSchema), createItem);
router.put('/:id', protect, validate(updateItemSchema), updateItem);
router.delete('/:id', protect, deleteItem);
router.patch('/:id/deactivate', protect, deactivateItem);
router.patch('/:id/activate', protect, activateItem);
router.post('/:id/boost', protect, boostItem);

export default router;