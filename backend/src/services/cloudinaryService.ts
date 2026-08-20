import { v2 as cloudinary } from 'cloudinary';
import config from '../config/index.js';
import { ApiError } from '../utils/ApiError.js';

// Initialisation de Cloudinary
if (config.cloudinary.cloudName && config.cloudinary.apiKey && config.cloudinary.apiSecret) {
  cloudinary.config({
    cloud_name: config.cloudinary.cloudName,
    api_key: config.cloudinary.apiKey,
    api_secret: config.cloudinary.apiSecret,
  });
}

/**
 * Upload un fichier buffer vers Cloudinary
 */
export const uploadToCloudinary = async (
  fileBuffer: Buffer,
  folder: string,
  options?: {
    publicId?: string;
    transformation?: object;
  }
): Promise<{ secureUrl: string; publicId: string }> => {
  if (!config.cloudinary.cloudName || !config.cloudinary.apiKey || !config.cloudinary.apiSecret) {
    throw new ApiError(500, 'Cloudinary n\'est pas configuré. Vérifiez CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY et CLOUDINARY_API_SECRET');
  }

  return new Promise((resolve, reject) => {
    const uploadOptions: any = {
      folder,
      resource_type: 'image',
      ...(options?.publicId ? { public_id: options.publicId } : {}),
      // Transformation par défaut : qualité optimisée
      transformation: [
        { quality: 'auto', fetch_format: 'auto' },
      ],
    };

    // Si une transformation est fournie, elle remplace celle par défaut
    if (options?.transformation) {
      uploadOptions.transformation = options.transformation;
    }

    const uploadStream = cloudinary.uploader.upload_stream(
      uploadOptions,
      (error, result) => {
        if (error) {
          reject(new ApiError(500, 'Erreur lors de l\'upload vers Cloudinary'));
          return;
        }
        if (!result) {
          reject(new ApiError(500, 'Erreur Cloudinary: aucun résultat'));
          return;
        }
        resolve({
          secureUrl: result.secure_url,
          publicId: result.public_id,
        });
      }
    );

    uploadStream.end(fileBuffer);
  });
};

/**
 * Supprime une image de Cloudinary via son public_id ou son URL.
 */
export const deleteFromCloudinary = async (
  publicIdOrUrl: string
): Promise<void> => {
  if (!config.cloudinary.cloudName || !config.cloudinary.apiKey || !config.cloudinary.apiSecret) {
    return;
  }

  // Si c'est une URL, extraire le public_id
  let publicId = publicIdOrUrl;
  if (publicIdOrUrl.includes('res.cloudinary.com/')) {
    // Format: https://res.cloudinary.com/CLOUD_NAME/image/upload/v123456/folder/public_id.ext
    const url = new URL(publicIdOrUrl);
    const parts = url.pathname.split('/');
    // Ignorer: /cloud_name/image/upload/v123/...
    const uploadIndex = parts.findIndex((p) => p === 'upload');
    if (uploadIndex !== -1) {
      publicId = parts.slice(uploadIndex + 2).join('/');
      // Enlever l'extension
      publicId = publicId.replace(/\.[^.]+$/, '');
    }
  }

  try {
    await cloudinary.uploader.destroy(publicId);
  } catch (error) {
    // Erreur silencieuse - la suppression Cloudinary est best-effort
  }
};

/**
 * Suppression multiple d'images de Cloudinary.
 */
export const deleteManyFromCloudinary = async (
  publicIdsOrUrls: string[] | null | undefined
): Promise<void> => {
  if (!publicIdsOrUrls || publicIdsOrUrls.length === 0) return;
  await Promise.all(
    publicIdsOrUrls.map((id) => deleteFromCloudinary(id))
  );
};

/**
 * Extrait les public_id ou URLs Cloudinary à partir d'une structure d'images JSON.
 */
export const extractCloudinaryImageIds = (images: any): string[] => {
  if (!images) return [];
  if (Array.isArray(images)) {
    return images.filter((img): img is string => typeof img === 'string');
  }
  if (typeof images === 'object') {
    return Object.values(images).filter((v): v is string => typeof v === 'string');
  }
  return [];
};

/**
 * Constructs the URL of a Cloudinary image directly.
 */
export const buildCloudinaryUrl = (
  publicId: string,
  transformation: string = 'q_auto,f_auto'
): string => {
  return `https://res.cloudinary.com/${config.cloudinary.cloudName}/image/upload/${transformation}/${publicId}`;
};