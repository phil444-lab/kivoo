import { Request, Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';
import { AuthRequest } from '../middleware/auth.js';
import { NotFoundError, ForbiddenError } from '../utils/ApiError.js';

export const getItems = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const {
      page = '1',
      limit = '20',
      category,
      location,
      minPrice,
      maxPrice,
      condition,
      search,
      sort = 'newest',
      featured,
    } = req.query;

    const where: any = { status: 'active' };

    if (category) where.categoryId = category as string;
    if (location) where.location = { path: '$.city', string_contains: location as string };
    if (minPrice || maxPrice) {
      where.price = {};
      if (minPrice) where.price.gte = Number(minPrice);
      if (maxPrice) where.price.lte = Number(maxPrice);
    }
    if (condition) where.condition = condition as any;
    if (search) {
      where.OR = [
        { title: { contains: search as string } },
        { description: { contains: search as string } },
      ];
    }
    if (featured === 'true') where.featured = true;

    let orderBy: any = { createdAt: 'desc' };
    switch (sort) {
      case 'price_asc':
        orderBy = { price: 'asc' };
        break;
      case 'price_desc':
        orderBy = { price: 'desc' };
        break;
      case 'popular':
        orderBy = { views: 'desc' };
        break;
      case 'newest':
      default:
        orderBy = { createdAt: 'desc' };
    }

    const pageNum = parseInt(page as string, 10);
    const limitNum = parseInt(limit as string, 10);
    const skip = (pageNum - 1) * limitNum;

    const [items, totalItems] = await Promise.all([
      prisma.item.findMany({
        where,
        include: {
          category: { select: { id: true, name: true, icon: true, color: true } },
          seller: { select: { id: true, name: true, photo: true, rating: true, verified: true } },
        },
        orderBy,
        skip,
        take: limitNum,
      }),
      prisma.item.count({ where }),
    ]);

    const totalPages = Math.ceil(totalItems / limitNum);

    res.status(200).json({
      success: true,
      data: {
        items,
        pagination: {
          currentPage: pageNum,
          totalPages,
          totalItems,
          hasNext: pageNum < totalPages,
          hasPrev: pageNum > 1,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

export const getTrending = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const limit = parseInt(req.query.limit as string, 10) || 10;

    const items = await prisma.item.findMany({
      where: { status: 'active' },
      orderBy: { views: 'desc' },
      take: limit,
      include: {
        category: { select: { id: true, name: true, icon: true, color: true } },
        seller: { select: { id: true, name: true, photo: true, rating: true, verified: true } },
      },
    });

    res.status(200).json({
      success: true,
      data: items,
    });
  } catch (error) {
    next(error);
  }
};

export const getFeatured = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const limit = parseInt(req.query.limit as string, 10) || 10;

    const items = await prisma.item.findMany({
      where: {
        status: 'active',
        featured: true,
        featuredUntil: { gt: new Date() },
      },
      orderBy: [{ boostLevel: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      include: {
        category: { select: { id: true, name: true, icon: true, color: true } },
        seller: { select: { id: true, name: true, photo: true, rating: true, verified: true } },
      },
    });

    res.status(200).json({
      success: true,
      data: items,
    });
  } catch (error) {
    next(error);
  }
};

export const getItem = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const item = await prisma.item.update({
      where: { id: req.params.id as string },
      data: { views: { increment: 1 } },
      include: {
        category: { select: { id: true, name: true, icon: true, color: true } },
        subcategory: { select: { id: true, name: true, icon: true } },
        seller: { select: { id: true, name: true, photo: true, rating: true, verified: true, location: true, joinedAt: true } },
      },
    });

    res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    next(error);
  }
};

export const createItem = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const itemData = {
      ...req.body,
      sellerId: req.user.id,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    };

    const item = await prisma.item.create({
      data: itemData,
    });

    res.status(201).json({
      success: true,
      data: item,
    });
  } catch (error) {
    next(error);
  }
};

export const updateItem = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const item = await prisma.item.findUnique({
      where: { id: req.params.id as string },
    });

    if (!item) {
      throw new NotFoundError('Item');
    }

    if (item.sellerId !== req.user.id) {
      throw new ForbiddenError('Not authorized to update this item');
    }

    const updated = await prisma.item.update({
      where: { id: req.params.id as string },
      data: req.body,
    });

    res.status(200).json({
      success: true,
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

export const deleteItem = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const item = await prisma.item.findUnique({
      where: { id: req.params.id as string },
    });

    if (!item) {
      throw new NotFoundError('Item');
    }

    if (item.sellerId !== req.user.id) {
      throw new ForbiddenError('Not authorized to delete this item');
    }

    await prisma.item.delete({
      where: { id: req.params.id as string },
    });

    res.status(200).json({
      success: true,
      message: 'Item deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

export const boostItem = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { duration } = req.body;
    const item = await prisma.item.findUnique({
      where: { id: req.params.id as string },
    });

    if (!item) {
      throw new NotFoundError('Item');
    }

    if (item.sellerId !== req.user.id) {
      throw new ForbiddenError('Not authorized to boost this item');
    }

    const boostUntil = new Date(Date.now() + duration * 24 * 60 * 60 * 1000);

    const updated = await prisma.item.update({
      where: { id: req.params.id as string },
      data: {
        boostLevel: { increment: 1 },
        boostUntil,
        featured: true,
        featuredUntil: boostUntil,
      },
    });

    res.status(200).json({
      success: true,
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};