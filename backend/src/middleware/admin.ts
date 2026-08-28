import { NextFunction, Response } from 'express';
import { ForbiddenError } from '../utils/ApiError.js';
import { AuthRequest } from './auth.js';

/**
 * Middleware de protection des routes admin.
 * À utiliser après `protect` : vérifie que l'utilisateur a le rôle admin.
 */
export const isAdmin = (
  req: AuthRequest,
  _res: Response,
  next: NextFunction
): void => {
  if (!req.user) {
    next(new ForbiddenError('Authentification requise'));
    return;
  }
  if (req.user.role !== 'admin') {
    next(new ForbiddenError('Accès réservé aux administrateurs'));
    return;
  }
  next();
};
