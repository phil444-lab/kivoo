import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import { ValidationError } from '../utils/ApiError.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration de multer pour sauvegarder les fichiers sur le disque
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads');
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Générer un nom unique avec timestamp et UUID
    const timestamp = Date.now();
    const ext = path.extname(file.originalname).toLowerCase();
    const uniqueName = `${timestamp}-${crypto.randomUUID()}${ext}`;
    cb(null, uniqueName);
  },
});

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