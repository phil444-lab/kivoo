import { Router } from 'express';
import {
  getConversations,
  getMessages,
  createConversation,
  sendMessage,
  uploadMessageImage,
  markAsRead,
} from '../controllers/conversationController.js';
import { protect } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';

const router: Router = Router();

router.get('/', protect, getConversations);
router.post('/', protect, createConversation);
router.get('/:id/messages', protect, getMessages);
router.post('/:id/messages', protect, sendMessage);
router.post('/:id/images', protect, upload.single('image'), uploadMessageImage);
router.put('/:id/read', protect, markAsRead);

export default router;
