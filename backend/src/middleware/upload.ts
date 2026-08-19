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

  console.log('📁 Uploaded file MIME type:', file.mimetype);
  console.log('📁 File name:', file.originalname);
  console.log('📁 File extension:', fileExtension);
  console.log('✅ Allowed types:', allowedTypes);
  console.log('✅ Allowed extensions:', allowedExtensions);

  const hasValidMimeType = allowedTypes.includes(file.mimetype);
  const hasValidExtension = allowedExtensions.includes(fileExtension);

  if (hasValidMimeType || hasValidExtension) {
    console.log('✅ File accepted');
    cb(null, true);
  } else {
    console.log('❌ File rejected - MIME type not allowed:', file.mimetype);
    cb(new ValidationError(`Only JPEG, PNG, WebP and GIF images are allowed. Received MIME: ${file.mimetype}, Extension: ${fileExtension}`));
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