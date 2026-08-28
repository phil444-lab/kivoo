import { Request, Response, NextFunction } from 'express';
import prisma from '../../lib/prisma.js';
import { NotFoundError, ValidationError } from '../../utils/ApiError.js';
import { createAndSendNotification } from '../../services/fcmService.js';
import {
  deleteManyFromCloudinary,
  extractCloudinaryImageIds,
} from '../../services/cloudinaryService.js';
import type { AuthRequest } from '../../middleware/auth.js';

const REPORT_INCLUDE = {
  reporter: {
    select: { id: true, name: true, email: true, phone: true, photo: true },
  },
  reportedUser: {
    select: { id: true, name: true, email: true, phone: true, photo: true, isActive: true },
  },
  reportedItem: {
    include: {
      seller: {
        select: { id: true, name: true, email: true, phone: true, photo: true, isActive: true },
      },
      category: { select: { id: true, name: true } },
      city: { select: { id: true, name: true } },
    },
  },
  reviewedBy: {
    select: { id: true, name: true },
  },
};

/**
 * Supprime complÃ¨tement une annonce (admin) avec cascade identique Ã  deleteItem
 */
export const adminDeleteItem = async (itemId: string): Promise<void> => {
  const item = await prisma.item.findUnique({ where: { id: itemId } });
  if (!item) {
    throw new NotFoundError('Annonce');
  }

  const imageNames = extractCloudinaryImageIds(item.images);
  await deleteManyFromCloudinary(imageNames);

  await prisma.$transaction([
    prisma.favorite.deleteMany({ where: { itemId } }),
    prisma.message.deleteMany({ where: { conversation: { itemId } } }),
    prisma.conversationParticipant.deleteMany({ where: { conversation: { itemId } } }),
    prisma.review.deleteMany({ where: { itemId } }),
    prisma.report.deleteMany({ where: { reportedItemId: itemId } }),
    prisma.conversation.deleteMany({ where: { itemId } }),
    prisma.item.delete({ where: { id: itemId } }),
  ]);
};

/**
 * Bannit un utilisateur : dÃ©sactivation + invalidation des sessions + notification
 */
export const adminBanUser = async (userId: string, reason?: string): Promise<void> => {
  await prisma.$transaction([
    prisma.user.update({ where: { id: userId }, data: { isActive: false } }),
    prisma.session.updateMany({ where: { userId }, data: { isActive: false } }),
  ]);
  await createAndSendNotification(
    userId,
    'system',
    'Compte suspendu',
    reason || 'Votre compte a Ã©tÃ© suspendu par l\'Ã©quipe de modÃ©ration.'
  );
};

/**
 * GET /api/admin/reports?status=pending&page=1&limit=20
 */
export const getAdminReports = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit as string, 10) || 20, 100);
    const skip = (page - 1) * limit;

    const status = req.query.status as string | undefined;
    const search = (req.query.search as string | undefined)?.trim();

    const where: any = {};
    if (status && status !== 'all') {
      where.status = status;
    }
    if (search) {
      where.OR = [
        { reason: { contains: search } },
        { description: { contains: search } },
        { reportedItem: { title: { contains: search } } },
      ];
    }

    const [reports, totalItems] = await Promise.all([
      prisma.report.findMany({
        where,
        include: REPORT_INCLUDE,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.report.count({ where }),
    ]);

    const totalPages = Math.ceil(totalItems / limit);

    res.status(200).json({
      success: true,
      data: {
        reports,
        pagination: {
          currentPage: page,
          totalPages,
          totalItems,
          hasNext: page < totalPages,
          hasPrev: page > 1,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/admin/reports/:id/status  { status: reviewed|resolved|dismissed }
 */
export const updateReportStatus = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { status } = req.body as { status?: string };
    if (!status || !['reviewed', 'resolved', 'dismissed'].includes(status)) {
      throw new ValidationError('Statut invalide. Valeurs autorisÃ©es : reviewed, resolved, dismissed');
    }

    const report = await prisma.report.findUnique({ where: { id: req.params.id as string } });
    if (!report) {
      throw new NotFoundError('Signalement');
    }

    const updated = await prisma.report.update({
      where: { id: report.id },
      data: {
        status: status as 'reviewed' | 'resolved' | 'dismissed',
        reviewedById: req.user.id,
        reviewedAt: new Date(),
      },
      include: REPORT_INCLUDE,
    });

    res.status(200).json({
      success: true,
      message: 'Signalement mis Ã  jour',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/admin/reports/:id/moderate
 * { action: 'delete_item'|'warn_user'|'ban_user'|'none', status?: resolved|dismissed, note? }
 */
export const moderateReport = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { action, status, note } = req.body as {
      action?: string;
      status?: string;
      note?: string;
    };

    if (!action || !['delete_item', 'warn_user', 'ban_user', 'none'].includes(action)) {
      throw new ValidationError(
        'Action invalide. Valeurs autorisÃ©es : delete_item, warn_user, ban_user, none'
      );
    }

    const report = await prisma.report.findUnique({ where: { id: req.params.id as string } });
    if (!report) {
      throw new NotFoundError('Signalement');
    }

    let message = 'Signalement traitÃ©';

    switch (action) {
      case 'delete_item': {
        await adminDeleteItem(report.reportedItemId);
        message = 'Annonce supprimÃ©e et signalement traitÃ©';
        break;
      }
      case 'warn_user': {
        await createAndSendNotification(
          report.reportedUserId,
          'system',
          'Avertissement de la modÃ©ration',
          note || 'Votre annonce a fait l\'objet d\'un signalement. Merci de respecter les rÃ¨gles de la communautÃ©.'
        );
        message = 'Utilisateur averti';
        break;
      }
      case 'ban_user': {
        await adminBanUser(report.reportedUserId, note);
        message = 'Utilisateur banni';
        break;
      }
      case 'none':
        message = 'Signalement classÃ© sans action';
        break;
    }

    const finalStatus = status === 'dismissed' ? 'dismissed' : 'resolved';
    const updated = await prisma.report.update({
      where: { id: report.id },
      data: {
        status: finalStatus,
        reviewedById: req.user.id,
        reviewedAt: new Date(),
      },
      include: REPORT_INCLUDE,
    });

    res.status(200).json({
      success: true,
      message,
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

