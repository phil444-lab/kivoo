import { Request, Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import prisma from '../lib/prisma.js';
import { NotFoundError, ApiError, ValidationError } from '../utils/ApiError.js';
import { AuthRequest } from '../middleware/auth.js';

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

export const updateUserProfile = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.id;
    const { name, email, phone, currentPassword, newPassword, location, preferences } = req.body;

    // Validation personnalisée pour le changement de mot de passe
    if (newPassword && !currentPassword) {
      res.status(400).json({
        success: false,
        message: 'Le mot de passe actuel est requis pour changer le mot de passe',
        errors: [
          {
            field: 'currentPassword',
            message: 'Le mot de passe actuel est requis pour changer le mot de passe',
          },
        ],
      });
      return;
    }

    const updateData: any = {};

    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (phone !== undefined) updateData.phone = phone;
    if (location !== undefined) updateData.location = location;
    if (preferences !== undefined) updateData.preferences = preferences;

    // Vérifier si l'email existe déjà pour un autre utilisateur
    if (email) {
      const existingEmail = await prisma.user.findFirst({
        where: {
          email,
          id: { not: userId },
        },
      });
      if (existingEmail) {
        console.log('❌ Email déjà utilisé:', email);
        throw new ValidationError('Cet email est déjà utilisé par un autre compte');
      }
    }

    // Vérifier si le téléphone existe déjà pour un autre utilisateur
    if (phone) {
      const existingPhone = await prisma.user.findFirst({
        where: {
          phone,
          id: { not: userId },
        },
      });
      if (existingPhone) {
        console.log('❌ Téléphone déjà utilisé:', phone);
        throw new ValidationError('Ce numéro de téléphone est déjà utilisé par un autre compte');
      }
    }

    // Gestion du changement de mot de passe
    if (newPassword) {
      if (!currentPassword) {
        throw new ValidationError('Le mot de passe actuel est requis');
      }

      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { password: true },
      });

      if (!user) {
        throw new NotFoundError('Utilisateur');
      }

      const isPasswordValid = await bcrypt.compare(currentPassword, user.password);
      if (!isPasswordValid) {
        throw new ValidationError('Mot de passe actuel incorrect');
      }

      const hashedPassword = await bcrypt.hash(newPassword, 12);
      updateData.password = hashedPassword;
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: updateData,
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        photo: true,
        location: true,
        verified: true,
        rating: true,
        ratingCount: true,
        joinedAt: true,
        lastLogin: true,
        isActive: true,
        preferences: true,
      },
    });

    res.status(200).json({
      success: true,
      data: updatedUser,
    });
  } catch (error: any) {
    console.error('❌ Erreur updateUserProfile:', error);
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    
    // Gérer les erreurs Prisma de contrainte unique
    if (error.code === 'P2002') {
      console.log('⚠️ Contrainte unique violée');
      const field = error.meta?.target?.[0] || 'champ';
      console.log('📋 Champ en conflit:', field);
      
      if (field === 'email') {
        return next(new ValidationError('Cet email est déjà utilisé par un autre compte'));
      } else if (field === 'phone') {
        return next(new ValidationError('Ce numéro de téléphone est déjà utilisé par un autre compte'));
      }
    }
    
    next(error);
  }
};
