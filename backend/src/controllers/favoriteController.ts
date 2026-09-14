import { Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';
import { AuthRequest } from '../middleware/auth.js';
import { NotFoundError } from '../utils/ApiError.js';

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
        where: { 
          userId: req.user.id,
          item: {
            status: 'active'
          }
        },
        include: {
          item: {
            include: {
              seller: {
                select: {
                  id: true,
                  name: true,
                  phone: true,
                  photo: true,
                  rating: true,
                  verified: true,
                  location: true,
                },
              },
              category: { select: { id: true, name: true } },
              subcategory: { select: { id: true, name: true } },
              department: { select: { id: true, name: true } },
              city: { select: { id: true, name: true } },
              district: { select: { id: true, name: true } },
              feature: { select: { id: true, title: true, icon: true } },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.favorite.count({ 
        where: { 
          userId: req.user.id,
          item: {
            status: 'active'
          }
        } 
      }),
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

    // Idempotent : si l'annonce est déjà en favoris, on répond succès (200)
    // au lieu d'une erreur. Le client peut ainsi resynchroniser son état
    // (cœur rouge) même lorsque sa liste locale était obsolète (session
    // rechargée, page non chargée, etc.) — sans provoquer d'échec visible.
    if (existing) {
      res.status(200).json({
        success: true,
        message: 'Annonce déjà dans vos favoris',
        data: { isFavorite: true },
      });
      return;
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
      message: 'Annonce ajoutée aux favoris',
      data: { isFavorite: true },
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

    // Idempotent : si l'annonce n'est plus en favoris, on répond succès (200)
    // pour que le client puisse synchroniser son état (cœur gris).
    if (!favorite) {
      res.status(200).json({
        success: true,
        message: 'Annonce déjà retirée des favoris',
        data: { isFavorite: false },
      });
      return;
    }

    await prisma.favorite.delete({
      where: { userId_itemId: { userId: req.user.id, itemId } },
    });

    // Décrémenter le compteur de likes sans jamais passer sous zéro
    // (données historiques potentiellement désynchronisées).
    const item = await prisma.item.findUnique({ where: { id: itemId } });
    if (item && item.likes > 0) {
      await prisma.item.update({
        where: { id: itemId },
        data: { likes: { decrement: 1 } },
      });
    }

    res.status(200).json({
      success: true,
      message: 'Annonce retirée des favoris',
      data: { isFavorite: false },
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