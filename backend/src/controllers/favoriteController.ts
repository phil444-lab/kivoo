import { Response, NextFunction } from 'express';
import Favorite from '../models/Favorite.js';
import Item from '../models/Item.js';
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
      Favorite.find({ user: req.user._id })
        .populate({
          path: 'item',
          select: 'title price images condition status seller',
          populate: { path: 'seller', select: 'name rating' },
        })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Favorite.countDocuments({ user: req.user._id }),
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
    const { itemId } = req.params;

    const item = await Item.findById(itemId);
    if (!item) {
      throw new NotFoundError('Item');
    }

    const existing = await Favorite.findOne({
      user: req.user._id,
      item: itemId,
    });

    if (existing) {
      throw new ValidationError('Item already in favorites');
    }

    await Favorite.create({
      user: req.user._id,
      item: itemId,
    });

    await Item.findByIdAndUpdate(itemId, { $inc: { likes: 1 } });

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
    const { itemId } = req.params;

    const favorite = await Favorite.findOneAndDelete({
      user: req.user._id,
      item: itemId,
    });

    if (!favorite) {
      throw new NotFoundError('Favorite');
    }

    await Item.findByIdAndUpdate(itemId, { $inc: { likes: -1 } });

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
    const { itemId } = req.params;

    const favorite = await Favorite.findOne({
      user: req.user._id,
      item: itemId,
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