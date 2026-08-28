import { Request, Response, NextFunction } from 'express';
import prisma from '../../lib/prisma.js';
import { ValidationError } from '../../utils/ApiError.js';
import { sendPushNotification } from '../../services/fcmService.js';
import type { NotificationType } from '@prisma/client';

/**
 * POST /api/admin/notifications/broadcast
 * Envoi de notifications in-app (+ push optionnel) ciblées
 * { title, message, type?, scope: 'all'|'filter'|'users', cityId?, isActive?, verified?, userIds?, sendPush? }
 */
export const broadcastNotification = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const {
      title,
      message,
      type = 'system',
      scope = 'all',
      cityId,
      isActive,
      verified,
      userIds,
      sendPush = true,
    } = req.body as {
      title?: string;
      message?: string;
      type?: string;
      scope?: 'all' | 'filter' | 'users';
      cityId?: string;
      isActive?: boolean;
      verified?: boolean;
      userIds?: string[];
      sendPush?: boolean;
    };

    if (!title || title.trim() === '') {
      throw new ValidationError('Le titre est requis');
    }
    if (!message || message.trim() === '') {
      throw new ValidationError('Le message est requis');
    }
    const validTypes = ['message', 'favorite', 'price_drop', 'new_item', 'system'];
    if (!validTypes.includes(type)) {
      throw new ValidationError(`Type invalide. Valeurs autorisées : ${validTypes.join(', ')}`);
    }

    // Déterminer les destinataires
    let recipientIds: string[] = [];

    if (scope === 'users') {
      if (!userIds || userIds.length === 0) {
        throw new ValidationError('Fournissez la liste des identifiants utilisateurs (userIds)');
      }
      const users = await prisma.user.findMany({
        where: { id: { in: userIds }, isActive: true },
        select: { id: true },
      });
      recipientIds = users.map((u) => u.id);
    } else {
      const where: any = { isActive: isActive ?? true };
      if (scope === 'filter') {
        if (typeof isActive === 'boolean') where.isActive = isActive;
        if (typeof verified === 'boolean') where.verified = verified;
        if (cityId) {
          where.items = { some: { cityId } };
        }
      }
      const users = await prisma.user.findMany({
        where,
        select: { id: true },
      });
      recipientIds = users.map((u) => u.id);
    }

    if (recipientIds.length === 0) {
      res.status(200).json({
        success: true,
        message: 'Aucun destinataire ne correspond aux critères',
        data: { sent: 0 },
      });
      return;
    }

    // Créer les notifications in-app en masse
    const result = await prisma.notification.createMany({
      data: recipientIds.map((userId) => ({
        userId,
        type: type as NotificationType,
        title: title.trim(),
        message: message.trim(),
      })),
    });

    // Push best-effort (si configuré)
    let pushSent = 0;
    if (sendPush) {
      const results = await Promise.allSettled(
        recipientIds.map((userId) =>
          sendPushNotification(userId, title.trim(), message.trim(), { scope })
        )
      );
      pushSent = results.filter((r) => r.status === 'fulfilled').length;
    }

    res.status(200).json({
      success: true,
      message: `Notification envoyée à ${result.count} utilisateur(s)`,
      data: { sent: result.count, pushSent },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/notifications/history?limit=50
 * Dernières notifications système envoyées
 */
export const getBroadcastHistory = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const limit = Math.min(parseInt(req.query.limit as string, 10) || 50, 200);

    const notifications = await prisma.notification.findMany({
      where: { type: 'system' },
      include: {
        user: { select: { id: true, name: true, photo: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    res.status(200).json({ success: true, data: notifications });
  } catch (error) {
    next(error);
  }
};
