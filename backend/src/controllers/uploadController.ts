import { Request, Response, NextFunction } from 'express';
import path from 'path';
import prisma from '../lib/prisma.js';
import { upload } from '../middleware/upload.js';
import { AuthRequest } from '../middleware/auth.js';
import { ApiError } from '../utils/ApiError.js';
import { deleteUploadedFile } from '../utils/fileCleanup.js';

export const uploadProfilePhoto = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.file) {
      throw new ApiError(400, 'Aucune image fournie');
    }

    // Le fichier est déjà sauvegardé sur le disque par multer
    // Stocker seulement le nom du fichier dans la DB
    const fileName = req.file.filename;
    
    // Déterminer le MIME type à partir du fichier
    let mimeType = req.file.mimetype;
    
    // Si le MIME type est générique (application/octet-stream), deviner à partir du fichier
    if (mimeType === 'application/octet-stream' || !mimeType.startsWith('image/')) {
      const ext = path.extname(req.file.originalname).toLowerCase();
      const mimeTypes: { [key: string]: string } = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.webp': 'image/webp',
        '.gif': 'image/gif',
        '.heic': 'image/heic',
        '.heif': 'image/heif',
        '.bmp': 'image/bmp',
      };
      mimeType = mimeTypes[ext] || 'image/jpeg';
    }

    console.log('📸 Photo uploadée:', fileName);
    console.log('📸 MIME type:', mimeType);

    // Récupérer l'ancienne photo pour la supprimer après mise à jour
    const existingUser = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: { photo: true },
    });

    // Mettre à jour la photo de l'utilisateur avec le nom du fichier
    const user = await prisma.user.update({
      where: { id: req.user!.id },
      data: { photo: fileName },
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

    // Supprimer l'ancienne photo de profil physique (si elle existe et est différente)
    if (existingUser?.photo && existingUser.photo !== fileName) {
      deleteUploadedFile(existingUser.photo);
    }

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};
