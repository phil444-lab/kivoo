import { Request, Response, NextFunction } from 'express';
import Item from '../models/Item.js';
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

    const query: any = { status: 'active' };

    if (category) query.category = category;
    if (location) query['location.city'] = { $regex: location, $options: 'i' };
    if (minPrice || maxPrice) {
      query.price = {};
      if (minPrice) query.price.$gte = Number(minPrice);
      if (maxPrice) query.price.$lte = Number(maxPrice);
    }
    if (condition) query.condition = condition;
    if (search) {
      query.$text = { $search: search };
    }
    if (featured === 'true') query.featured = true;

    let sortOption: any = { createdAt: -1 };
    switch (sort) {
      case 'price_asc':
        sortOption = { price: 1 };
        break;
      case 'price_desc':
        sortOption = { price: -1 };
        break;
      case 'popular':
        sortOption = { views: -1, likes: -1 };
        break;
      case 'newest':
      default:
        sortOption = { createdAt: -1 };
    }

    const pageNum = parseInt(page as string, 10);
    const limitNum = parseInt(limit as string, 10);
    const skip = (pageNum - 1) * limitNum;

    const [items, totalItems] = await Promise.all([
      Item.find(query)
        .populate('category', 'name icon color')
        .populate('seller', 'name photo rating verified')
        .sort(sortOption)
        .skip(skip)
        .limit(limitNum)
        .lean(),
      Item.countDocuments(query),
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

    const items = await Item.find({ status: 'active' })
      .sort({ views: -1, likes: -1 })
      .limit(limit)
      .populate('category', 'name icon color')
      .populate('seller', 'name photo rating verified')
      .lean();

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

    const items = await Item.find({
      status: 'active',
      featured: true,
      featuredUntil: { $gt: new Date() },
    })
      .sort({ boostLevel: -1, createdAt: -1 })
      .limit(limit)
      .populate('category', 'name icon color')
      .populate('seller', 'name photo rating verified')
      .lean();

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
    const item = await Item.findByIdAndUpdate(
      req.params.id,
      { $inc: { views: 1 } },
      { new: true }
    )
      .populate('category', 'name icon color')
      .populate('subcategory', 'name icon')
      .populate('seller', 'name photo rating verified location joinedAt')
      .lean();

    if (!item) {
      throw new NotFoundError('Item');
    }

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
      seller: req.user._id,
    };

    const item = await Item.create(itemData);

    res.status(201).json({
      success: true,
      data: item.toJSON(),
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
    const item = await Item.findById(req.params.id);

    if (!item) {
      throw new NotFoundError('Item');
    }

    if (item.seller.toString() !== req.user._id.toString()) {
      throw new ForbiddenError('Not authorized to update this item');
    }

    Object.assign(item, req.body);
    await item.save();

    res.status(200).json({
      success: true,
      data: item.toJSON(),
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
    const item = await Item.findById(req.params.id);

    if (!item) {
      throw new NotFoundError('Item');
    }

    if (item.seller.toString() !== req.user._id.toString()) {
      throw new ForbiddenError('Not authorized to delete this item');
    }

    await item.deleteOne();

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
    const item = await Item.findById(req.params.id);

    if (!item) {
      throw new NotFoundError('Item');
    }

    if (item.seller.toString() !== req.user._id.toString()) {
      throw new ForbiddenError('Not authorized to boost this item');
    }

    item.boostLevel = (item.boostLevel || 0) + 1;
    item.boostUntil = new Date(
      Date.now() + duration * 24 * 60 * 60 * 1000
    );
    item.featured = true;
    item.featuredUntil = item.boostUntil;

    await item.save();

    res.status(200).json({
      success: true,
      data: item.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};