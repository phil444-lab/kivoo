import { Request, Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';
import { NotFoundError } from '../utils/ApiError.js';

export const getUserProfile = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.params.id as string;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        photo: true,
        location: true,
        verified: true,
        rating: true,
        ratingCount: true,
        joinedAt: true,
      },
    });

    if (!user) {
      throw new NotFoundError('User');
    }

    const [itemsListed, itemsSold] = await Promise.all([
      prisma.item.count({ where: { sellerId: userId } }),
      prisma.item.count({ where: { sellerId: userId, status: 'sold' } }),
    ]);

    res.status(200).json({
      success: true,
      data: {
        ...user,
        stats: {
          itemsListed,
          itemsSold,
          responseRate: 95,
          responseTime: '2h',
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

export const getUserItems = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 20;
    const status = req.query.status || 'all';
    const skip = (page - 1) * limit;
    const userId = req.params.id as string;

    const where: any = { sellerId: userId };
    if (status !== 'all') where.status = status;

    const [items, totalItems] = await Promise.all([
      prisma.item.findMany({
        where,
        include: {
          category: { select: { id: true, name: true, icon: true, color: true } },
        },
        orderBy: { createdAt: 'desc' },
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

export const getUserReviews = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 20;
    const skip = (page - 1) * limit;
    const userId = req.params.id as string;

    const [reviews, totalItems, aggregation] = await Promise.all([
      prisma.review.findMany({
        where: { reviewedId: userId },
        include: {
          reviewer: { select: { id: true, name: true, photo: true } },
          item: { select: { id: true, title: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.review.count({ where: { reviewedId: userId } }),
      prisma.review.aggregate({
        where: { reviewedId: userId },
        _avg: { rating: true },
        _count: { rating: true },
      }),
    ]);

    const totalPages = Math.ceil(totalItems / limit);

    res.status(200).json({
      success: true,
      data: {
        reviews,
        averageRating: aggregation._avg.rating
          ? Math.round(aggregation._avg.rating * 10) / 10
          : 0,
        totalReviews: aggregation._count.rating || 0,
      },
    });
  } catch (error) {
    next(error);
  }
};