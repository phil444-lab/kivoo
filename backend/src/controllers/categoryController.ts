import { Request, Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';
import { NotFoundError } from '../utils/ApiError.js';

export const getCategories = async (
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const categories = await prisma.category.findMany({
      where: { isActive: true, parentCategoryId: null },
      include: {
        subcategories: {
          where: { isActive: true },
          select: { id: true, name: true },
        },
      },
      orderBy: { name: 'asc' },
    });

    res.status(200).json({
      success: true,
      data: categories,
    });
  } catch (error) {
    next(error);
  }
};

export const getSubcategories = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const subcategories = await prisma.category.findMany({
      where: { isActive: true, parentCategoryId: String(req.params.id) },
      orderBy: { name: 'asc' },
      include: {
        _count: {
          select: {
            subItems: {
              where: {
                status: 'active',
              },
            },
          },
        },
      },
    });

    // Ajouter le count d'items actifs à chaque sous-catégorie
    const subcategoriesWithCount = subcategories.map((sub) => ({
      ...sub,
      itemCount: sub._count.subItems,
    }));

    res.status(200).json({
      success: true,
      data: subcategoriesWithCount,
    });
  } catch (error) {
    next(error);
  }
};

export const getCategory = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const category = await prisma.category.findUnique({
      where: { id: req.params.id as string },
      include: {
        parentCategory: { select: { id: true, name: true } },
        subcategories: {
          where: { isActive: true },
          select: { id: true, name: true },
        },
      },
    });

    if (!category) {
      throw new NotFoundError('Category');
    }

    res.status(200).json({
      success: true,
      data: category,
    });
  } catch (error) {
    next(error);
  }
};