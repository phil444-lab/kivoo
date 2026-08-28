import { Router } from 'express';
import { protect } from '../middleware/auth.js';
import { isAdmin } from '../middleware/admin.js';
import {
  getAdminStats,
  getAdminAnalytics,
} from '../controllers/admin/statsController.js';
import {
  getAdminReports,
  updateReportStatus,
  moderateReport,
} from '../controllers/admin/moderationController.js';
import {
  getAdminItems,
  getAdminItem,
  updateAdminItem,
  deleteAdminItem,
  getPendingItems,
  reviewPendingItem,
} from '../controllers/admin/itemAdminController.js';
import {
  getAdminUsers,
  getAdminUser,
  updateAdminUser,
  invalidateUserSessions,
  warnUser,
} from '../controllers/admin/userAdminController.js';
import {
  getAdminCategories,
  createAdminCategory,
  updateAdminCategory,
  deleteAdminCategory,
  getAdminLocationTree,
  createAdminDepartment,
  updateAdminDepartment,
  deleteAdminDepartment,
  createAdminCity,
  updateAdminCity,
  deleteAdminCity,
  createAdminDistrict,
  updateAdminDistrict,
  deleteAdminDistrict,
  getAdminFeaturedOptions,
  createAdminFeaturedOption,
  updateAdminFeaturedOption,
  deleteAdminFeaturedOption,
} from '../controllers/admin/refAdminController.js';
import {
  broadcastNotification,
  getBroadcastHistory,
} from '../controllers/admin/notificationAdminController.js';

const router: Router = Router();

// Toutes les routes admin nécessitent une authentification + le rôle admin
router.use(protect, isAdmin);

// ── Stats & Analytics ──────────────────────────────────────────────
router.get('/stats', getAdminStats);
router.get('/analytics', getAdminAnalytics);

// ── Modération : signalements ──────────────────────────────────────
router.get('/reports', getAdminReports);
router.patch('/reports/:id/status', updateReportStatus);
router.post('/reports/:id/moderate', moderateReport);

// ── Modération : file de validation des annonces ───────────────────
router.get('/moderation/items/pending', getPendingItems);
router.patch('/moderation/items/:id/review', reviewPendingItem);

// ── Gestion des annonces ───────────────────────────────────────────
router.get('/items', getAdminItems);
router.get('/items/:id', getAdminItem);
router.patch('/items/:id', updateAdminItem);
router.delete('/items/:id', deleteAdminItem);

// ── Gestion des utilisateurs ───────────────────────────────────────
router.get('/users', getAdminUsers);
router.get('/users/:id', getAdminUser);
router.patch('/users/:id', updateAdminUser);
router.post('/users/:id/invalidate-sessions', invalidateUserSessions);
router.post('/users/:id/warn', warnUser);

// ── Référentiel : catégories ───────────────────────────────────────
router.get('/categories', getAdminCategories);
router.post('/categories', createAdminCategory);
router.patch('/categories/:id', updateAdminCategory);
router.delete('/categories/:id', deleteAdminCategory);

// ── Référentiel : zones (départements / villes / quartiers) ────────
router.get('/locations/tree', getAdminLocationTree);
router.post('/departments', createAdminDepartment);
router.patch('/departments/:id', updateAdminDepartment);
router.delete('/departments/:id', deleteAdminDepartment);
router.post('/cities', createAdminCity);
router.patch('/cities/:id', updateAdminCity);
router.delete('/cities/:id', deleteAdminCity);
router.post('/districts', createAdminDistrict);
router.patch('/districts/:id', updateAdminDistrict);
router.delete('/districts/:id', deleteAdminDistrict);

// ── Référentiel : offres sponsorisées ──────────────────────────────
router.get('/featured-options', getAdminFeaturedOptions);
router.post('/featured-options', createAdminFeaturedOption);
router.patch('/featured-options/:id', updateAdminFeaturedOption);
router.delete('/featured-options/:id', deleteAdminFeaturedOption);

// ── Communications : notifications ciblées ─────────────────────────
router.post('/notifications/broadcast', broadcastNotification);
router.get('/notifications/history', getBroadcastHistory);

export default router;
