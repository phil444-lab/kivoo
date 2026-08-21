import { Request, Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';
import { AuthRequest } from '../middleware/auth.js';
import { ApiError, NotFoundError, ForbiddenError } from '../utils/ApiError.js';
import { deleteManyFromCloudinary, extractCloudinaryImageIds } from '../services/cloudinaryService.js';

export const getMyItems = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const {
      page = '1',
      limit = '50',
    } = req.query;

    const pageNum = parseInt(page as string, 10);
    const limitNum = parseInt(limit as string, 10);
    const skip = (pageNum - 1) * limitNum;

    const [items, totalItems] = await Promise.all([
      prisma.item.findMany({
        where: { sellerId: req.user.id },
        include: {
          category: { select: { id: true, name: true } },
          subcategory: { select: { id: true, name: true } },
          seller: { select: { id: true, name: true, phone: true, photo: true, rating: true, verified: true } },
          feature: { select: { id: true, title: true, icon: true } },
          department: { select: { id: true, name: true } },
          city: { select: { id: true, name: true } },
          district: { select: { id: true, name: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limitNum,
      }),
      prisma.item.count({ where: { sellerId: req.user.id } }),
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
      subcategory,
      location,
      minPrice,
      maxPrice,
      condition,
      search,
      sort = 'newest',
      featured,
      department,
      city,
      district,
      color,
      brand,
      priceType,
      feature,
    } = req.query;

    const where: any = { status: 'active' };

    if (category) where.categoryId = category as string;
    if (subcategory) where.subcategoryId = subcategory as string;
    if (location) where.location = { path: '$.city', string_contains: location as string };
    if (department) where.departmentId = department as string;
    if (city) where.cityId = city as string;
    if (district) where.districtId = district as string;
    if (color) where.color = { contains: color as string };
    if (brand) where.brand = { contains: brand as string };
    if (priceType) where.priceType = priceType as any;
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
    if (feature) where.featureId = feature as string;

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
          category: { select: { id: true, name: true } },
          subcategory: { select: { id: true, name: true } },
          seller: { select: { id: true, name: true, phone: true, photo: true, rating: true, verified: true } },
          feature: { select: { id: true, title: true, icon: true } },
          department: { select: { id: true, name: true } },
          city: { select: { id: true, name: true } },
          district: { select: { id: true, name: true } },
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
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 10;
    const skip = (page - 1) * limit;

    const [items, totalItems] = await Promise.all([
      prisma.item.findMany({
        where: { status: 'active' },
        orderBy: { views: 'desc' },
        skip,
        take: limit,
        include: {
          category: { select: { id: true, name: true } },
          subcategory: { select: { id: true, name: true } },
          seller: { select: { id: true, name: true, phone: true, photo: true, rating: true, verified: true } },
          feature: { select: { id: true, title: true, icon: true } },
          department: { select: { id: true, name: true } },
          city: { select: { id: true, name: true } },
          district: { select: { id: true, name: true } },
        },
      }),
      prisma.item.count({ where: { status: 'active' } }),
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

export const getFeatured = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 10;
    const skip = (page - 1) * limit;

    const featuredWhere: any = {
      status: 'active',
      featured: true,
      featuredUntil: { gt: new Date() },
    };

    const [items, totalItems] = await Promise.all([
      prisma.item.findMany({
        where: featuredWhere,
        orderBy: [{ boostLevel: 'desc' }, { createdAt: 'desc' }],
        skip,
        take: limit,
        include: {
          category: { select: { id: true, name: true } },
          subcategory: { select: { id: true, name: true } },
          seller: { select: { id: true, name: true, phone: true, photo: true, rating: true, verified: true } },
          feature: { select: { id: true, title: true, icon: true } },
          department: { select: { id: true, name: true } },
          city: { select: { id: true, name: true } },
          district: { select: { id: true, name: true } },
        },
      }),
      prisma.item.count({ where: featuredWhere }),
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

export const getItem = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const item = await prisma.item.findUnique({
      where: { id: req.params.id as string },
      include: {
        category: { select: { id: true, name: true } },
        subcategory: { select: { id: true, name: true } },
        seller: { select: { id: true, name: true, phone: true, photo: true, rating: true, verified: true, location: true, joinedAt: true } },
        feature: { select: { id: true, title: true, icon: true } },
        department: { select: { id: true, name: true } },
        city: { select: { id: true, name: true } },
        district: { select: { id: true, name: true } },
      },
    });

    if (!item) {
      throw new NotFoundError('Annonce');
    }

    // Ne pas exposer les annonces en attente ou expirées aux utilisateurs non propriétaires
    const isOwner = (req as any).user?.id === item.sellerId;
    if (!isOwner && item.status !== 'active' && item.status !== 'sold') {
      throw new NotFoundError('Annonce');
    }

    // Incrémenter les vues uniquement pour les annonces actives
    if (item.status === 'active') {
      await prisma.item.update({
        where: { id: item.id },
        data: { views: { increment: 1 } },
      });
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
    const { featureId, images, ...rest } = req.body;

    // Les images sont des URLs Cloudinary envoyées en JSON
    if (!Array.isArray(images) || images.length < 3) {
      throw new ApiError(400, 'Au moins 3 photos sont requises');
    }

    // Vérifier que toutes les images sont des URLs Cloudinary valides
    const validImages = images.filter(
      (img) => typeof img === 'string' && img.includes('res.cloudinary.com/')
    );
    if (validImages.length < 3) {
      throw new ApiError(400, 'Les images doivent être des URLs Cloudinary valides');
    }

    // Convertir les champs numériques reçus en string (multipart/form-data)
    const price = rest.price !== undefined ? Number(rest.price) : undefined;
    const year = rest.year !== undefined ? Number(rest.year) : undefined;
    if (price !== undefined && isNaN(price)) {
      throw new ApiError(400, 'Le prix doit être un nombre valide');
    }

    // Si aucun featureId n'est fourni, on utilise "Nouveautés" par défaut
    let defaultFeatureId = featureId;
    if (!defaultFeatureId) {
      const nouveautes = await prisma.featuredOption.findFirst({
        where: { title: 'Nouveautés', isActive: true },
        select: { id: true },
      });
      defaultFeatureId = nouveautes?.id ?? null;
    }

    const itemData = {
      ...rest,
      price,
      year,
      images: validImages,
      featureId: defaultFeatureId,
      sellerId: req.user.id,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    };

    const item = await prisma.item.create({
      data: itemData,
      include: {
        category: { select: { id: true, name: true } },
        subcategory: { select: { id: true, name: true } },
        feature: { select: { id: true, title: true, icon: true } },
        department: { select: { id: true, name: true } },
        city: { select: { id: true, name: true } },
        district: { select: { id: true, name: true } },
      },
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
      throw new NotFoundError('Annonce');
    }

    if (item.sellerId !== req.user.id) {
      throw new ForbiddenError('Vous n\'êtes pas autorisé à modifier cette annonce');
    }

    const { featureId, images: imageUrls, ...rest } = req.body;

    // Convertir les champs numériques reçus en string (JSON)
    const price = rest.price !== undefined ? Number(rest.price) : undefined;
    const year = rest.year !== undefined ? Number(rest.year) : undefined;
    if (price !== undefined && isNaN(price)) {
      throw new ApiError(400, 'Le prix doit être un nombre valide');
    }

    // Gestion des images : les URLs Cloudinary sont envoyées en JSON
    let finalImages: string[] | null = null;
    if (Array.isArray(imageUrls)) {
      // Vérifier que toutes les images sont des URLs Cloudinary valides
      const validImages = imageUrls.filter(
        (img) => typeof img === 'string' && img.includes('res.cloudinary.com/')
      );
      if (validImages.length < 3) {
        throw new ApiError(400, 'Au moins 3 photos Cloudinary valides sont requises');
      }
      finalImages = validImages;
    }

    // Supprimer les anciennes images Cloudinary qui ne sont plus conservées
    const oldImageNames = extractCloudinaryImageIds(item.images);
    const imagesToDelete = oldImageNames.filter(
      (oldImg) => !finalImages?.includes(oldImg)
    );
    await deleteManyFromCloudinary(imagesToDelete);

    const updated = await prisma.item.update({
      where: { id: req.params.id as string },
      data: {
        ...rest,
        ...(price !== undefined ? { price } : {}),
        ...(year !== undefined ? { year } : {}),
        ...(finalImages ? { images: finalImages } : {}),
        ...(featureId ? { featureId } : {}),
      },
      include: {
        category: { select: { id: true, name: true } },
        subcategory: { select: { id: true, name: true } },
        feature: { select: { id: true, title: true, icon: true } },
        department: { select: { id: true, name: true } },
        city: { select: { id: true, name: true } },
        district: { select: { id: true, name: true } },
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
      throw new NotFoundError('Annonce');
    }

    if (item.sellerId !== req.user.id) {
      throw new ForbiddenError('Vous n\'êtes pas autorisé à supprimer cette annonce');
    }

    const itemId = req.params.id as string;

    // Supprimer les images Cloudinary de l'item
    const imageNames = extractCloudinaryImageIds(item.images);
    await deleteManyFromCloudinary(imageNames);

    // Supprimer explicitement toutes les dépendances liées à l'item
    // (les contraintes onDelete: Cascade ne sont pas toujours appliquées en base)
    await prisma.$transaction([
      // 1. Favoris
      prisma.favorite.deleteMany({ where: { itemId } }),
      // 2. Messages des conversations liées à l'item
      prisma.message.deleteMany({
        where: { conversation: { itemId } },
      }),
      // 3. Participants des conversations liées à l'item
      prisma.conversationParticipant.deleteMany({
        where: { conversation: { itemId } },
      }),
      // 4. Reviews liées à l'item
      prisma.review.deleteMany({ where: { itemId } }),
      // 5. Reports liés à l'item
      prisma.report.deleteMany({ where: { reportedItemId: itemId } }),
      // 6. Conversations liées à l'item
      prisma.conversation.deleteMany({ where: { itemId } }),
      // 7. L'item lui-même
      prisma.item.delete({ where: { id: itemId } }),
    ]);

    res.status(200).json({
      success: true,
      message: 'Annonce supprimée avec succès',
    });
  } catch (error) {
    next(error);
  }
};

export const deactivateItem = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const item = await prisma.item.findUnique({
      where: { id: req.params.id as string },
    });

    if (!item) {
      throw new NotFoundError('Annonce');
    }

    if (item.sellerId !== req.user.id) {
      throw new ForbiddenError('Vous n\'êtes pas autorisé à désactiver cette annonce');
    }

    // Changer le statut de 'active' à 'pending'
    const updated = await prisma.item.update({
      where: { id: req.params.id as string },
      data: { status: 'pending' },
      include: {
        category: { select: { id: true, name: true } },
        subcategory: { select: { id: true, name: true } },
      },
    });

    res.status(200).json({
      success: true,
      data: updated,
      message: 'Annonce désactivée avec succès',
    });
  } catch (error) {
    next(error);
  }
};

export const activateItem = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const item = await prisma.item.findUnique({
      where: { id: req.params.id as string },
    });

    if (!item) {
      throw new NotFoundError('Annonce');
    }

    if (item.sellerId !== req.user.id) {
      throw new ForbiddenError('Vous n\'êtes pas autorisé à activer cette annonce');
    }

    // Changer le statut de 'pending' à 'active'
    const updated = await prisma.item.update({
      where: { id: req.params.id as string },
      data: { status: 'active' },
      include: {
        category: { select: { id: true, name: true } },
        subcategory: { select: { id: true, name: true } },
      },
    });

    res.status(200).json({
      success: true,
      data: updated,
      message: 'Annonce activée avec succès',
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
      throw new NotFoundError('Annonce');
    }

    if (item.sellerId !== req.user.id) {
      throw new ForbiddenError('Vous n\'êtes pas autorisé à booster cette annonce');
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