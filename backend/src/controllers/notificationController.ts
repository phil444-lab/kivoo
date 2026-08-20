import { Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';
import { AuthRequest } from '../middleware/auth.js';
import {
  registerPushToken,
  unregisterPushToken,
} from '../services/fcmService.js';

/**
 * Récupère les notifications de l'utilisateur connecté
 */
export const getNotifications = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 30;
    const skip = (page - 1) * limit;

    const [notifications, totalItems, unreadCount] = await Promise.all([
      prisma.notification.findMany({
        where: { userId: req.user.id },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.notification.count({ where: { userId: req.user.id } }),
      prisma.notification.count({
        where: { userId: req.user.id, read: false },
      }),
    ]);

    const totalPages = Math.ceil(totalItems / limit);

    res.status(200).json({
      success: true,
      data: {
        notifications,
        pagination: {
          currentPage: page,
          totalPages,
          totalItems,
          hasNext: page < totalPages,
          hasPrev: page > 1,
        },
        unreadCount,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Marque une notification comme lue
 */
export const markNotificationAsRead = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const id = req.params.id as string;

    await prisma.notification.updateMany({
      where: {
        id,
        userId: req.user.id,
      },
      data: { read: true },
    });

    res.status(200).json({
      success: true,
      message: 'Notification marquée comme lue',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Marque toutes les notifications comme lues
 */
export const markAllNotificationsAsRead = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user.id, read: false },
      data: { read: true },
    });

    res.status(200).json({
      success: true,
      message: 'Toutes les notifications ont été marquées comme lues',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Enregistre un token FCM pour l'utilisateur connecté
 */
export const savePushToken = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { token, platform } = req.body;

    if (!token || token.trim() === '') {
      res.status(400).json({
        success: false,
        message: 'Token requis',
      });
      return;
    }

    await registerPushToken(req.user.id, token.trim(), platform || 'android');

    res.status(200).json({
      success: true,
      message: 'Token push enregistré',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Supprime un token FCM (déconnexion)
 */
export const removePushToken = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { token } = req.body;

    if (!token) {
      res.status(400).json({
        success: false,
        message: 'Token requis',
      });
      return;
    }

    await unregisterPushToken(token);

    res.status(200).json({
      success: true,
      message: 'Token push supprimé',
    });
  } catch (error) {
    next(error);
  }
};