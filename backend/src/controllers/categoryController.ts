import { Request, Response, NextFunction } from 'express';
import Category from '../models/Category.js';
import { NotFoundError } from '../utils/ApiError.js';

export const getCategories = async (
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const categories = await Category.find({ isActive: true })
      .populate({
        path: 'parentCategory',
        select: 'name icon',
      })
      .lean();

    // Group subcategories under parent categories
    const parentCategories = categories.filter((cat: any) => !cat.parentCategory);
    const subcategories = categories.filter((cat: any) => cat.parentCategory);

    const result = parentCategories.map((parent: any) => ({
      ...parent,
      subcategories: subcategories.filter(
        (sub: any) =>
          sub.parentCategory &&
          (sub.parentCategory._id?.toString() === parent._id?.toString() ||
            sub.parentCategory.toString() === parent._id?.toString())
      ),
    }));

    res.status(200).json({
      success: true,
      data: result,
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
    const category = await Category.findById(req.params.id)
      .populate({
        path: 'parentCategory',
        select: 'name icon',
      })
      .lean();

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