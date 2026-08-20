import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../utils/ApiError.js';
import config from '../config/index.js';

/**
 * Middleware global de gestion des erreurs.
 * Formate toutes les erreurs en JSON standardisé : { success: false, message: "..." }
 * Ne jamais exposer les stack traces ou erreurs brutes Prisma/Node en production.
 */
export const errorHandler = (
  err: any,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  // Erreurs ApiError personnalisées
  if (err instanceof ApiError) {
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
    return;
  }

  // Erreurs Prisma
  if (err?.code) {
    // Contrainte unique violée
    if (err.code === 'P2002') {
      const field = err.meta?.target?.[0] || 'champ';
      const fieldName = field === 'email' ? 'email' : field === 'phone' ? 'numéro de téléphone' : 'champ';
      res.status(409).json({
        success: false,
        message: `Ce ${fieldName} est déjà utilisé par un autre compte`,
      });
      return;
    }

    // Enregistrement non trouvé
    if (err.code === 'P2025') {
      res.status(404).json({
        success: false,
        message: 'Ressource introuvable',
      });
      return;
    }

    // Erreur de validation Prisma
    if (err.code === 'P2000' || err.code === 'P2003' || err.code === 'P2004') {
      res.status(400).json({
        success: false,
        message: 'Données invalides',
      });
      return;
    }

    // Erreur de connexion à la base de données
    if (err.code === 'P1001' || err.code === 'P1002' || err.code === 'P1003') {
      res.status(503).json({
        success: false,
        message: 'Service temporairement indisponible, veuillez réessayer',
      });
      return;
    }
  }

  // Erreurs de validation (Zod, etc.)
  if (err.name === 'ValidationError' || err.name === 'ZodError') {
    res.status(400).json({
      success: false,
      message: 'Erreur de validation des données',
    });
    return;
  }

  // Erreurs JWT
  if (err.name === 'JsonWebTokenError') {
    res.status(401).json({
      success: false,
      message: 'Token invalide',
    });
    return;
  }

  if (err.name === 'TokenExpiredError') {
    res.status(401).json({
      success: false,
      message: 'Session expirée, veuillez vous reconnecter',
    });
    return;
  }

  // Erreur de syntaxe JSON
  if (err.type === 'entity.parse.failed') {
    res.status(400).json({
      success: false,
      message: 'Format JSON invalide',
    });
    return;
  }

  // Erreur de fichier trop volumineux
  if (err.code === 'LIMIT_FILE_SIZE') {
    res.status(413).json({
      success: false,
      message: 'Fichier trop volumineux (5 Mo maximum)',
    });
    return;
  }

  // Erreur 404 pour les routes non trouvées
  if (err.status === 404) {
    res.status(404).json({
      success: false,
      message: 'Ressource introuvable',
    });
    return;
  }

  // Erreur générique - ne jamais exposer les détails en production
  if (config.nodeEnv === 'production') {
    console.error('Erreur non gérée:', err.message);
    res.status(500).json({
      success: false,
      message: 'Une erreur interne est survenue. Veuillez réessayer plus tard.',
    });
    return;
  }

  // En développement, on peut afficher plus de détails
  console.error('Erreur non gérée:', err);
  res.status(500).json({
    success: false,
    message: err.message || 'Erreur interne du serveur',
  });
};