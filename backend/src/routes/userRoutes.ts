import { Router } from 'express';
import {
  getUserProfile,
  getUserItems,
  getUserReviews,
  updateUserProfile,
} from '../controllers/userController.js';
import { uploadProfilePhoto } from '../controllers/uploadController.js';
import { protect } from '../middleware/auth.js';
import { updateProfileSchema } from '../validators/userValidator.js';
import { validate } from '../middleware/validator.js';
import { upload } from '../middleware/upload.js';

const router: Router = Router();

router.get('/:id', getUserProfile);
router.get('/:id/items', getUserItems);
router.get('/:id/reviews', getUserReviews);
router.put('/me', protect, validate(updateProfileSchema), updateUserProfile);
router.post('/me/photo', protect, upload.single('photo'), uploadProfilePhoto);

export default router;
