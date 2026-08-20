import { Router } from 'express';
import rateLimit from 'express-rate-limit';
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

// Rate limiting sur le login : 5 tentatives max / 15 min / IP
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 tentatives maximum
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Trop de tentatives de connexion. Veuillez réessayer dans 15 minutes.',
  },
  handler: (_req, res) => {
    res.status(429).json({
      success: false,
      message: 'Trop de tentatives de connexion. Veuillez réessayer dans 15 minutes.',
    });
  },
});

router.post('/register', register);
router.post('/login', loginLimiter, login);
router.post('/logout', protect, logout);
router.post('/social-login', socialLogin);
router.post('/refresh-token', refreshToken);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.post('/upload-photo', protect, upload.single('photo'), uploadProfilePhoto);

export default router;