import { Router } from 'express';
import {
  getUserProfile,
  getUserItems,
  getUserReviews,
} from '../controllers/userController.js';

const router = Router();

router.get('/:id', getUserProfile);
router.get('/:id/items', getUserItems);
router.get('/:id/reviews', getUserReviews);

export default router;