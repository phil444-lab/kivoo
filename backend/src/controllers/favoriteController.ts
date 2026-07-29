import { Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';
import { AuthRequest } from '../middleware/auth.js';
import { NotFoundError, ValidationError } from '../utils/ApiError.js';

export const getFavorites = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 20;
    const skip = (page - 1) * limit;

    const [favorites, totalItems] = await Promise.all([
      prisma.favorite.findMany({
        where: { userId: req.user.id },
        include: {
          item: {
            select: {
              id: true,
              title: true,
              price: true,
              images: true,
              condition: true,
              status: true,
              seller: { select: { id: true, name: true, rating: true } },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.favorite.count({ where: { userId: req.user.id } }),
    ]);

    const totalPages = Math.ceil(totalItems / limit);

    res.status(200).json({
      success: true,
      data: {
        favorites,
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

export const addFavorite = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const itemId = req.params.itemId as string;

    const item = await prisma.item.findUnique({ where: { id: itemId } });
    if (!item) {
      throw new NotFoundError('Item');
    }

    const existing = await prisma.favorite.findUnique({
      where: { userId_itemId: { userId: req.user.id, itemId } },
    });

    if (existing) {
      throw new ValidationError('Item already in favorites');
    }

    await prisma.favorite.create({
      data: { userId: req.user.id, itemId },
    });

    await prisma.item.update({
      where: { id: itemId },
      data: { likes: { increment: 1 } },
    });

    res.status(201).json({
      success: true,
      message: 'Item added to favorites',
    });
  } catch (error) {
    next(error);
  }
};

export const removeFavorite = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const itemId = req.params.itemId as string;

    const favorite = await prisma.favorite.findUnique({
      where: { userId_itemId: { userId: req.user.id, itemId } },
    });

    if (!favorite) {
      throw new NotFoundError('Favorite');
    }

    await prisma.favorite.delete({
      where: { userId_itemId: { userId: req.user.id, itemId } },
    });

    await prisma.item.update({
      where: { id: itemId },
      data: { likes: { increment: -1 } },
    });

    res.status(200).json({
      success: true,
      message: 'Item removed from favorites',
    });
  } catch (error) {
    next(error);
  }
};

export const checkFavorite = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const itemId = req.params.itemId as string;

    const favorite = await prisma.favorite.findUnique({
      where: { userId_itemId: { userId: req.user.id, itemId } },
    });

    res.status(200).json({
      success: true,
      data: {
        isFavorite: !!favorite,
      },
    });
  } catch (error) {
    next(error);
  }
};