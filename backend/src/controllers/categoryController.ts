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
          select: { id: true, name: true, icon: true, color: true },
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

export const getCategory = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const category = await prisma.category.findUnique({
      where: { id: req.params.id as string },
      include: {
        parentCategory: { select: { id: true, name: true, icon: true } },
        subcategories: {
          where: { isActive: true },
          select: { id: true, name: true, icon: true, color: true },
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