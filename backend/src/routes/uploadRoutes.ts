import { Router } from 'express';
import { getUploadSignature } from '../controllers/uploadController.js';
import { protect } from '../middleware/auth.js';

const router: Router = Router();

// Endpoint pour obtenir une signature Cloudinary signée (upload direct)
router.post('/signature', protect, getUploadSignature);

export default router;