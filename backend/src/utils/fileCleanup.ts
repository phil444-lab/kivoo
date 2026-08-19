import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const uploadsDir = path.join(__dirname, '../../uploads');

export const deleteUploadedFile = (fileName: string): void => {
  if (!fileName) return;
  const safeName = path.basename(fileName);
  const filePath = path.join(uploadsDir, safeName);
  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      console.log(`🗑️ Fichier supprimé: ${safeName}`);
    }
  } catch (error) {
    console.error(`❌ Erreur suppression ${safeName}:`, error);
  }
};

export const deleteUploadedFiles = (fileNames: string[] | null | undefined): void => {
  if (!fileNames || fileNames.length === 0) return;
  for (const fileName of fileNames) {
    deleteUploadedFile(fileName);
  }
};

export const extractImageNames = (images: any): string[] => {
  if (!images) return [];
  if (Array.isArray(images)) {
    return images.filter((img): img is string => typeof img === 'string');
  }
  if (typeof images === 'object') {
    return Object.values(images).filter((v): v is string => typeof v === 'string');
  }
  return [];
};