import { Router } from 'express';
import {
  getConversations,
  getMessages,
  createConversation,
  sendMessage,
  markAsRead,
} from '../controllers/conversationController.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.get('/', protect, getConversations);
router.post('/', protect, createConversation);
router.get('/:id/messages', protect, getMessages);
router.post('/:id/messages', protect, sendMessage);
router.put('/:id/read', protect, markAsRead);

export default router;