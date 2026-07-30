import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import prisma from '../lib/prisma.js';
import { UnauthorizedError } from '../utils/ApiError.js';
import config from '../config/index.js';

export interface AuthRequest extends Request {
  user?: any;
}

const hashToken = (token: string): string => {
  return crypto.createHash('sha256').update(token).digest('hex');
};

export const protect = async (
  req: AuthRequest,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('Aucun token fourni');
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      throw new UnauthorizedError('Aucun token fourni');
    }

    // Vérifier le token JWT
    const decoded = jwt.verify(token, config.jwt.secret) as { id: string };

    // Vérifier que la session existe et est active en base
    const tokenHash = hashToken(token);
    const session = await prisma.session.findFirst({
      where: { tokenHash, isActive: true },
    });

    if (!session) {
      throw new UnauthorizedError('Session invalide ou expirée');
    }

    if (session.expiresAt < new Date()) {
      await prisma.session.update({
        where: { id: session.id },
        data: { isActive: false },
      });
      throw new UnauthorizedError('Session expirée, veuillez vous reconnecter');
    }

    const user = await prisma.user.findUnique({ where: { id: decoded.id } });

    if (!user) {
      throw new UnauthorizedError('Utilisateur non trouvé');
    }

    if (!user.isActive) {
      throw new UnauthorizedError('Compte désactivé');
    }

    req.user = user;
    next();
  } catch (error: any) {
    if (error instanceof UnauthorizedError) {
      next(error);
    } else {
      next(new UnauthorizedError('Token invalide'));
    }
  }
};