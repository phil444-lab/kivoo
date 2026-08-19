import { Request, Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';
import { AuthRequest } from '../middleware/auth.js';
import { ApiError } from '../utils/ApiError.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../services/cloudinaryService.js';

export const uploadProfilePhoto = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.file) {
      throw new ApiError(400, 'Aucune image fournie');
    }

    // Uploader vers Cloudinary
    const { secureUrl, publicId } = await uploadToCloudinary(
      req.file.buffer,
      'kivoo/profiles'
    );

    console.log('📸 Photo uploadée vers Cloudinary:', secureUrl);

    // Récupérer l'ancienne photo pour la supprimer après mise à jour
    const existingUser = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: { photo: true },
    });

    // Mettre à jour la photo de l'utilisateur avec l'URL Cloudinary
    const user = await prisma.user.update({
      where: { id: req.user!.id },
      data: { photo: secureUrl },
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
        preferences: true,
      },
    });

    // Supprimer l'ancienne photo de profil (si elle existe et est différente)
    if (existingUser?.photo && existingUser.photo !== secureUrl) {
      // Si l'ancienne est une URL Cloudinary, la supprimer
      if (existingUser.photo.includes('res.cloudinary.com/')) {
        await deleteFromCloudinary(existingUser.photo);
      }
    }

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};