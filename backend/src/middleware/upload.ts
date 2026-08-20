import multer from 'multer';
import { ValidationError } from '../utils/ApiError.js';

// Configuration de multer pour garder les fichiers en mémoire
// (ils seront uploadés vers Cloudinary par les contrôleurs)
const storage = multer.memoryStorage();

const fileFilter = (
  _req: any,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback
) => {
  const allowedTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/jpg',
    'image/heic',
    'image/heif',
    'image/bmp',
    'image/tiff',
    'application/octet-stream', // Accept generic binary for image files
  ];

  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif', '.bmp', '.tiff'];
  const fileExtension = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'));

  const hasValidMimeType = allowedTypes.includes(file.mimetype);
  const hasValidExtension = allowedExtensions.includes(fileExtension);

  if (hasValidMimeType || hasValidExtension) {
    cb(null, true);
  } else {
    cb(new ValidationError(`Seules les images JPEG, PNG, WebP et GIF sont autorisées. Reçu : ${file.mimetype}`));
  }
};

export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
    files: 10, // max 10 images
  },
});