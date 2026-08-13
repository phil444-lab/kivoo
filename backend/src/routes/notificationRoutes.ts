import { Router } from 'express';
import {
  getNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  savePushToken,
  removePushToken,
} from '../controllers/notificationController.js';
import { protect } from '../middleware/auth.js';

const router: Router = Router();

router.get('/', protect, getNotifications);
router.put('/read-all', protect, markAllNotificationsAsRead);
router.put('/:id/read', protect, markNotificationAsRead);
router.post('/push-token', protect, savePushToken);
router.delete('/push-token', protect, removePushToken);

export default router;