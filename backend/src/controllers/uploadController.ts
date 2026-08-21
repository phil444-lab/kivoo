import { Request, Response, NextFunction } from 'express';
import { v2 as cloudinary } from 'cloudinary';
import crypto from 'crypto';
import prisma from '../lib/prisma.js';
import { AuthRequest } from '../middleware/auth.js';
import { ApiError } from '../utils/ApiError.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../services/cloudinaryService.js';
import config from '../config/index.js';

/**
 * Génère une signature Cloudinary signée pour permettre l'upload direct
 * depuis le client (Flutter) sans passer par le backend.
 */
export const getUploadSignature = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!config.cloudinary.cloudName || !config.cloudinary.apiKey || !config.cloudinary.apiSecret) {
      throw new ApiError(500, 'Cloudinary n\'est pas configuré. Vérifiez CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY et CLOUDINARY_API_SECRET');
    }

    const { folder = 'kivoo/items', publicId } = req.body;

    // Paramètres de l'upload signé
    const timestamp = Math.round(Date.now() / 1000);
    const paramsToSign: Record<string, any> = {
      timestamp,
      folder,
    };

    if (publicId) {
      paramsToSign.public_id = publicId;
    }

    // Générer la signature
    const signature = cloudinary.utils.api_sign_request(paramsToSign, config.cloudinary.apiSecret);

    res.status(200).json({
      success: true,
      data: {
        cloudName: config.cloudinary.cloudName,
        apiKey: config.cloudinary.apiKey,
        timestamp,
        signature,
        folder,
        ...(publicId ? { publicId } : {}),
      },
    });
  } catch (error) {
    next(error);
  }
};

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

/**
 * Met à jour la photo de profil à partir d'une URL Cloudinary
 * (upload direct depuis le client).
 */
export const updateProfilePhotoFromUrl = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { photoUrl } = req.body;

    if (!photoUrl || typeof photoUrl !== 'string') {
      throw new ApiError(400, 'URL de photo invalide');
    }

    // Vérifier que l'URL est bien une URL Cloudinary
    if (!photoUrl.includes('res.cloudinary.com/')) {
      throw new ApiError(400, 'L\'URL doit être une URL Cloudinary valide');
    }

    // Récupérer l'ancienne photo pour la supprimer après mise à jour
    const existingUser = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: { photo: true },
    });

    // Mettre à jour la photo de l'utilisateur avec l'URL Cloudinary
    const user = await prisma.user.update({
      where: { id: req.user!.id },
      data: { photo: photoUrl },
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
    if (existingUser?.photo && existingUser.photo !== photoUrl) {
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