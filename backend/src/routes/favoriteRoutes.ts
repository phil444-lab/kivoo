import { Router } from 'express';
import {
  getFavorites,
  addFavorite,
  removeFavorite,
  checkFavorite,
} from '../controllers/favoriteController.js';
import { protect } from '../middleware/auth.js';

const router: Router = Router();

router.get('/', protect, getFavorites);
router.post('/:itemId', protect, addFavorite);
router.delete('/:itemId', protect, removeFavorite);
router.get('/check/:itemId', protect, checkFavorite);

export default router;