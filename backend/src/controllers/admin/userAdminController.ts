import { Request, Response, NextFunction } from 'express';
import prisma from '../../lib/prisma.js';
import { NotFoundError, ValidationError, ForbiddenError } from '../../utils/ApiError.js';
import { createAndSendNotification } from '../../services/fcmService.js';
import type { AuthRequest } from '../../middleware/auth.js';

const USER_SAFE_SELECT = {
  id: true,
  name: true,
  email: true,
  phone: true,
  photo: true,
  location: true,
  verified: true,
  rating: true,
  ratingCount: true,
  joinedAt: true,
  lastLogin: true,
  isActive: true,
  role: true,
};

/**
 * GET /api/admin/users?search=&verified=&isActive=&page=&limit=&sortBy=&order=
 */
export const getAdminUsers = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit as string, 10) || 20, 100);
    const skip = (page - 1) * limit;

    const search = (req.query.search as string | undefined)?.trim();
    const verified = req.query.verified as string | undefined;
    const isActive = req.query.isActive as string | undefined;

    const where: any = {};
    if (search) {
      where.OR = [
        { name: { contains: search } },
        { email: { contains: search } },
        { phone: { contains: search } },
      ];
    }
    if (verified === 'true') where.verified = true;
    if (verified === 'false') where.verified = false;
    if (isActive === 'true') where.isActive = true;
    if (isActive === 'false') where.isActive = false;

    const [users, totalItems] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          ...USER_SAFE_SELECT,
          _count: { select: { items: true, favorites: true } },
        },
        orderBy: { joinedAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.user.count({ where }),
    ]);

    const totalPages = Math.ceil(totalItems / limit);

    res.status(200).json({
      success: true,
      data: {
        users,
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
 * GET /api/admin/users/:id â€” profil complet (annonces, avis, sessions)
 */
export const getAdminUser = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.params.id as string;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        ...USER_SAFE_SELECT,
        _count: {
          select: { items: true, favorites: true, reports: true, reportedIn: true },
        },
      },
    });

    if (!user) {
      throw new NotFoundError('Utilisateur');
    }

    const [items, reviewsReceived, activeSessions] = await Promise.all([
      prisma.item.findMany({
        where: { sellerId: userId },
        include: {
          category: { select: { id: true, name: true } },
          city: { select: { id: true, name: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
      prisma.review.findMany({
        where: { reviewedId: userId },
        include: {
          reviewer: { select: { id: true, name: true, photo: true } },
          item: { select: { id: true, title: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
      prisma.session.findMany({
        where: { userId, isActive: true, expiresAt: { gt: new Date() } },
        select: {
          id: true,
          deviceInfo: true,
          ipAddress: true,
          createdAt: true,
          expiresAt: true,
        },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    res.status(200).json({
      success: true,
      data: { user, items, reviewsReceived, activeSessions },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/admin/users/:id  { isActive?, verified? }
 * Activer/bannir (isActive) ou attribuer/retirer le badge vÃ©rifiÃ© (verified)
 */
export const updateAdminUser = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { isActive, verified } = req.body as {
      isActive?: boolean;
      verified?: boolean;
    };

    if (typeof isActive !== 'boolean' && typeof verified !== 'boolean') {
      throw new ValidationError('Fournissez "isActive" et/ou "verified" (boolÃ©ens)');
    }

    const user = await prisma.user.findUnique({ where: { id: req.params.id as string } });
    if (!user) {
      throw new NotFoundError('Utilisateur');
    }

    if (user.id === req.user.id && isActive === false) {
      throw new ForbiddenError('Vous ne pouvez pas bannir votre propre compte');
    }

    const data: any = {};
    if (typeof isActive === 'boolean') data.isActive = isActive;
    if (typeof verified === 'boolean') data.verified = verified;

    const updated = await prisma.user.update({
      where: { id: user.id },
      data,
      select: USER_SAFE_SELECT,
    });

    // Bannir : invalider les sessions + notifier
    if (isActive === false) {
      await prisma.session.updateMany({
        where: { userId: user.id },
        data: { isActive: false },
      });
      await createAndSendNotification(
        user.id,
        'system',
        'Compte suspendu',
        'Votre compte a Ã©tÃ© suspendu par l\'Ã©quipe Kivoo. Contactez le support pour plus d\'informations.'
      );
    }

    // Retirer le ban : rÃ©activer
    if (isActive === true && !user.isActive) {
      await createAndSendNotification(
        user.id,
        'system',
        'Compte rÃ©activÃ©',
        'Votre compte Kivoo a Ã©tÃ© rÃ©activÃ©. Bienvenue Ã  nouveau !'
      );
    }

    res.status(200).json({
      success: true,
      message: 'Utilisateur mis Ã  jour',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/admin/users/:id/invalidate-sessions â€” dÃ©connecter l'utilisateur partout
 */
export const invalidateUserSessions = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.params.id as string } });
    if (!user) {
      throw new NotFoundError('Utilisateur');
    }

    const result = await prisma.session.updateMany({
      where: { userId: user.id, isActive: true },
      data: { isActive: false },
    });

    res.status(200).json({
      success: true,
      message: `${result.count} session(s) invalidÃ©e(s)`,
      data: { invalidated: result.count },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/admin/users/:id/warn  { message }
 */
export const warnUser = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { message } = req.body as { message?: string };
    if (!message || message.trim() === '') {
      throw new ValidationError('Le message d\'avertissement est requis');
    }

    const user = await prisma.user.findUnique({ where: { id: req.params.id as string } });
    if (!user) {
      throw new NotFoundError('Utilisateur');
    }

    await createAndSendNotification(
      user.id,
      'system',
      'Avertissement de la modÃ©ration',
      message.trim()
    );

    res.status(200).json({
      success: true,
      message: 'Avertissement envoyÃ© Ã  l\'utilisateur',
    });
  } catch (error) {
    next(error);
  }
};

