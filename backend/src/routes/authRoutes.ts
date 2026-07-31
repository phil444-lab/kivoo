import { Router } from 'express';
import {
  register,
  login,
  logout,
  socialLogin,
  refreshToken,
  getMe,
  updateProfile,
  forgotPassword,
  resetPassword,
} from '../controllers/authController.js';
import { uploadProfilePhoto } from '../controllers/uploadController.js';
import { protect } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';

const router: Router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/logout', protect, logout);
router.post('/social-login', socialLogin);
router.post('/refresh-token', refreshToken);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.post('/upload-photo', protect, upload.single('photo'), uploadProfilePhoto);

export default router;