import { Request, Response, NextFunction } from 'express';
import User from '../models/User.js';
import Item from '../models/Item.js';
import Review from '../models/Review.js';
import { NotFoundError } from '../utils/ApiError.js';

export const getUserProfile = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const user = await User.findById(req.params.id).lean();

    if (!user) {
      throw new NotFoundError('User');
    }

    const [itemsListed, itemsSold] = await Promise.all([
      Item.countDocuments({ seller: req.params.id }),
      Item.countDocuments({ seller: req.params.id, status: 'sold' }),
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

    const query: any = { seller: req.params.id };
    if (status !== 'all') query.status = status;

    const [items, totalItems] = await Promise.all([
      Item.find(query)
        .populate('category', 'name icon color')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Item.countDocuments(query),
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

    const [reviews, totalItems] = await Promise.all([
      Review.find({ reviewed: req.params.id })
        .populate('reviewer', 'name photo')
        .populate('item', 'title')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Review.countDocuments({ reviewed: req.params.id }),
    ]);

    const totalPages = Math.ceil(totalItems / limit);

    // Calculate average rating
    const result = await Review.aggregate([
      { $match: { reviewed: req.params.id as any } },
      { $group: { _id: null, averageRating: { $avg: '$rating' }, totalReviews: { $sum: 1 } } },
    ]);

    const averageRating = result.length > 0 ? result[0].averageRating : 0;
    const totalReviews = result.length > 0 ? result[0].totalReviews : 0;

    res.status(200).json({
      success: true,
      data: {
        reviews,
        averageRating: Math.round(averageRating * 10) / 10,
        totalReviews,
      },
    });
  } catch (error) {
    next(error);
  }
};