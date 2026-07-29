import { Router } from 'express';
import {
  register,
  login,
  socialLogin,
  refreshToken,
  getMe,
  updateProfile,
  forgotPassword,
  resetPassword,
} from '../controllers/authController.js';
import { protect } from '../middleware/auth.js';

const router: Router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/social-login', socialLogin);
router.post('/refresh-token', refreshToken);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);

export default router;