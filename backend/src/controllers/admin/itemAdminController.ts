import { Request, Response, NextFunction } from 'express';
import prisma from '../../lib/prisma.js';
import { NotFoundError, ValidationError } from '../../utils/ApiError.js';
import { createAndSendNotification } from '../../services/fcmService.js';
import { adminDeleteItem } from './moderationController.js';
import type { AuthRequest } from '../../middleware/auth.js';

const ITEM_INCLUDE = {
  seller: {
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      photo: true,
      verified: true,
      isActive: true,
      rating: true,
    },
  },
  category: { select: { id: true, name: true } },
  subcategory: { select: { id: true, name: true } },
  feature: { select: { id: true, title: true, icon: true, borderColor: true } },
  department: { select: { id: true, name: true } },
  city: { select: { id: true, name: true } },
  district: { select: { id: true, name: true } },
  _count: {
    select: { favorites: true, reports: true },
  },
};

/**
 * GET /api/admin/items?search=&status=&categoryId=&cityId=&featured=&page=&limit=&sortBy=&order=
 */
export const getAdminItems = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit as string, 10) || 20, 100);
    const skip = (page - 1) * limit;

    const search = (req.query.search as string | undefined)?.trim();
    const status = req.query.status as string | undefined;
    const categoryId = req.query.categoryId as string | undefined;
    const cityId = req.query.cityId as string | undefined;
    const featured = req.query.featured as string | undefined;
    const sortBy = (req.query.sortBy as string) || 'createdAt';
    const order = req.query.order === 'asc' ? 'asc' : 'desc';

    const where: any = {};
    if (search) {
      where.OR = [
        { title: { contains: search } },
        { description: { contains: search } },
        { seller: { name: { contains: search } } },
      ];
    }
    if (status && status !== 'all') where.status = status;
    if (categoryId) where.categoryId = categoryId;
    if (cityId) where.cityId = cityId;
    if (featured === 'true') where.featured = true;
    if (featured === 'false') where.featured = false;

    const validSorts: Record<string, string> = {
      createdAt: 'createdAt',
      price: 'price',
      views: 'views',
      likes: 'likes',
      boostLevel: 'boostLevel',
    };
    const orderBy: any = [{ [validSorts[sortBy] || 'createdAt']: order }];

    const [items, totalItems] = await Promise.all([
      prisma.item.findMany({
        where,
        include: ITEM_INCLUDE,
        orderBy,
        skip,
        take: limit,
      }),
      prisma.item.count({ where }),
    ]);

    const totalPages = Math.ceil(totalItems / limit);

    res.status(200).json({
      success: true,
      data: {
        items,
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
 * GET /api/admin/items/:id â€” vue dÃ©taillÃ©e complÃ¨te
 */
export const getAdminItem = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const item = await prisma.item.findUnique({
      where: { id: req.params.id as string },
      include: {
        ...ITEM_INCLUDE,
        reports: {
          include: {
            reporter: { select: { id: true, name: true, photo: true } },
          },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!item) {
      throw new NotFoundError('Annonce');
    }

    res.status(200).json({ success: true, data: item });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/admin/items/:id
 * { status?, featured?, featureId?, boostLevel?, boostUntil?, featuredUntil? }
 */
export const updateAdminItem = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { status, featured, featureId, boostLevel, boostUntil, featuredUntil } = req.body as {
      status?: string;
      featured?: boolean;
      featureId?: string | null;
      boostLevel?: number;
      boostUntil?: string | null;
      featuredUntil?: string | null;
    };

    const data: any = {};
    if (status) {
      if (!['active', 'sold', 'expired', 'pending'].includes(status)) {
        throw new ValidationError('Statut invalide');
      }
      data.status = status;
    }
    if (typeof featured === 'boolean') data.featured = featured;
    if (featureId !== undefined) data.featureId = featureId;
    if (boostUntil !== undefined) data.boostUntil = boostUntil ? new Date(boostUntil) : null;
    if (featuredUntil !== undefined) {
      data.featuredUntil = featuredUntil ? new Date(featuredUntil) : null;
    }
    if (boostLevel !== undefined) {
      const level = parseInt(String(boostLevel), 10);
      if (isNaN(level) || level < 0 || level > 10) {
        throw new ValidationError('boostLevel doit Ãªtre compris entre 0 et 10');
      }
      data.boostLevel = level;
    }

    if (Object.keys(data).length === 0) {
      throw new ValidationError('Aucun champ Ã  mettre Ã  jour');
    }

    const item = await prisma.item.findUnique({ where: { id: req.params.id as string } });
    if (!item) {
      throw new NotFoundError('Annonce');
    }

    const updated = await prisma.item.update({
      where: { id: item.id },
      data,
      include: ITEM_INCLUDE,
    });

    res.status(200).json({
      success: true,
      message: 'Annonce mise Ã  jour',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/admin/items/:id â€” suppression complÃ¨te (cascade)
 */
export const deleteAdminItem = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    await adminDeleteItem(req.params.id as string);

    res.status(200).json({
      success: true,
      message: 'Annonce supprimÃ©e avec succÃ¨s',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/moderation/items/pending â€” file de validation
 */
export const getPendingItems = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit as string, 10) || 20, 100);
    const skip = (page - 1) * limit;

    const where = { status: 'pending' as const };

    const [items, totalItems] = await Promise.all([
      prisma.item.findMany({
        where,
        include: ITEM_INCLUDE,
        orderBy: { createdAt: 'asc' },
        skip,
        take: limit,
      }),
      prisma.item.count({ where }),
    ]);

    const totalPages = Math.ceil(totalItems / limit);

    res.status(200).json({
      success: true,
      data: {
        items,
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
 * PATCH /api/admin/moderation/items/:id/review  { approve: boolean, note? }
 */
export const reviewPendingItem = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { approve, note } = req.body as { approve?: boolean; note?: string };
    if (typeof approve !== 'boolean') {
      throw new ValidationError('Le champ "approve" (boolÃ©en) est requis');
    }

    const item = await prisma.item.findUnique({
      where: { id: req.params.id as string },
      include: { seller: { select: { id: true, name: true } } },
    });
    if (!item) {
      throw new NotFoundError('Annonce');
    }

    const newStatus = approve ? 'active' : 'expired';
    const updated = await prisma.item.update({
      where: { id: item.id },
      data: { status: newStatus },
      include: ITEM_INCLUDE,
    });

    await createAndSendNotification(
      item.sellerId,
      'system',
      approve ? 'Annonce approuvÃ©e' : 'Annonce rejetÃ©e',
      approve
        ? `Votre annonce "${item.title}" a Ã©tÃ© approuvÃ©e et est maintenant visible par tous.`
        : note || `Votre annonce "${item.title}" a Ã©tÃ© rejetÃ©e par l'Ã©quipe de modÃ©ration.`
    );

    res.status(200).json({
      success: true,
      message: approve ? 'Annonce approuvÃ©e' : 'Annonce rejetÃ©e',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

