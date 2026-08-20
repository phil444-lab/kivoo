import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import prisma from '../lib/prisma.js';
import config from '../config/index.js';
import { AuthRequest } from '../middleware/auth.js';
import { ApiError, ValidationError } from '../utils/ApiError.js';
import { registerSchema, loginSchema } from '../validators/authValidator.js';

const generateToken = (userId: string): string => {
  return jwt.sign({ id: userId }, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn as any,
  });
};

const generateRefreshToken = (userId: string): string => {
  return jwt.sign({ id: userId }, config.jwt.refreshSecret, {
    expiresIn: config.jwt.refreshExpiresIn as any,
  });
};

const hashToken = (token: string): string => {
  return crypto.createHash('sha256').update(token).digest('hex');
};

// Convertit une durée JWT (ex: '15m', '1h', '7d') en millisecondes
const parseDurationToMs = (duration: string): number => {
  const match = duration.match(/^(\d+)([smhd])$/);
  if (!match) return 15 * 60 * 1000; // défaut : 15 minutes
  
  const value = parseInt(match[1], 10);
  const unit = match[2];
  
  switch (unit) {
    case 's': return value * 1000;
    case 'm': return value * 60 * 1000;
    case 'h': return value * 60 * 60 * 1000;
    case 'd': return value * 24 * 60 * 60 * 1000;
    default: return 15 * 60 * 1000;
  }
};

const getTokenExpiry = (): Date => {
  const expiry = config.jwt.expiresIn as string;
  return new Date(Date.now() + parseDurationToMs(expiry));
};

const getRefreshTokenExpiry = (): Date => {
  const expiry = config.jwt.refreshExpiresIn as string;
  return new Date(Date.now() + parseDurationToMs(expiry));
};

const createSession = async (userId: string, token: string, refreshToken: string, req: Request) => {
  const tokenHash = hashToken(token);
  const refreshTokenHash = hashToken(refreshToken);
  
  return await prisma.session.create({
    data: {
      userId,
      token,
      refreshToken,
      tokenHash,
      refreshTokenHash,
      deviceInfo: req.headers['user-agent'] || 'Unknown',
      ipAddress: req.ip || req.socket.remoteAddress,
      expiresAt: getTokenExpiry(),
      refreshExpiresAt: getRefreshTokenExpiry(),
    },
  });
};

export const register = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const validation = registerSchema.safeParse(req.body);
    
    if (!validation.success) {
      const errors = validation.error.errors.map(err => err.message);
      throw new ValidationError(errors.join(', '));
    }

    const { name, email, phone, password, location } = validation.data;

    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [{ email }, { phone }],
      },
    });

    if (existingUser) {
      throw new ValidationError('Ce profil existe déjà !');
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    const user = await prisma.user.create({
      data: {
        name,
        email,
        phone,
        password: hashedPassword,
        location: location || {},
        preferences: { notifications: true, language: 'fr' },
      },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        photo: true,
        verified: true,
        rating: true,
        ratingCount: true,
        location: true,
        joinedAt: true,
      },
    });

    const token = generateToken(user.id);
    const refreshToken = generateRefreshToken(user.id);

    // Pas de création de session à l'inscription
    // La session est créée lors de la connexion (login)

    res.status(201).json({
      success: true,
      data: {
        user,
        token,
        refreshToken,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const login = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const validation = loginSchema.safeParse(req.body);
    
    if (!validation.success) {
      const errors = validation.error.errors.map(err => err.message);
      throw new ValidationError(errors.join(', '));
    }

    const { identifier, password } = validation.data;

    // Rechercher par email ou téléphone
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { phone: identifier },
        ],
      },
    });

    if (!user) {
      throw new ValidationError('Email/téléphone ou mot de passe incorrect');
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      throw new ValidationError('Email/téléphone ou mot de passe incorrect');
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { lastLogin: new Date() },
    });

    const token = generateToken(user.id);
    const refreshToken = generateRefreshToken(user.id);

    await createSession(user.id, token, refreshToken, req);

    const { password: _, ...userWithoutPassword } = user;

    res.status(200).json({
      success: true,
      data: {
        user: userWithoutPassword,
        token,
        refreshToken,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const logout = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const tokenHash = hashToken(token);
      
      await prisma.session.updateMany({
        where: { tokenHash, isActive: true },
        data: { isActive: false },
      });
    }

    res.status(200).json({
      success: true,
      message: 'Déconnexion réussie',
    });
  } catch (error) {
    next(error);
  }
};

export const socialLogin = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { provider, providerId, email, name, photo } = req.body;

    let user = await prisma.user.findFirst({
      where: {
        socialProviders: {
          path: '$[*].providerId',
          string_contains: providerId,
        },
      },
    });

    if (!user && email) {
      user = await prisma.user.findUnique({ where: { email } });
    }

    if (user) {
      const socialProviders = (user.socialProviders as any[]) || [];
      const hasProvider = socialProviders.some((sp: any) => sp.provider === provider);

      if (!hasProvider) {
        socialProviders.push({ provider, providerId, email });
        await prisma.user.update({
          where: { id: user.id },
          data: { socialProviders },
        });
      }
    } else {
      const hashedPassword = await bcrypt.hash(Math.random().toString(36).slice(-12), 12);
      
      // Générer un numéro de téléphone unique pour les comptes sociaux
      const uniquePhone = `social_${providerId.slice(0, 8)}_${Date.now().toString(36)}`;
      
      user = await prisma.user.create({
        data: {
          name,
          email,
          phone: uniquePhone,
          password: hashedPassword,
          photo,
          verified: true,
          socialProviders: [{ provider, providerId, email }],
          preferences: { notifications: true, language: 'fr' },
        },
      });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { lastLogin: new Date() },
    });

    const token = generateToken(user.id);
    const refreshToken = generateRefreshToken(user.id);

    await createSession(user.id, token, refreshToken, req);

    const { password: _, ...userWithoutPassword } = user;

    res.status(200).json({
      success: true,
      data: {
        user: userWithoutPassword,
        token,
        refreshToken,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const refreshToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new ApiError(401, 'Aucun token de rafraîchissement fourni');
    }

    const refreshToken = authHeader.split(' ')[1];
    const refreshTokenHash = hashToken(refreshToken);

    // Vérifier que la session existe et est active
    const session = await prisma.session.findFirst({
      where: { refreshTokenHash, isActive: true },
    });

    if (!session) {
      throw new ApiError(401, 'Session invalide ou expirée');
    }

    if (session.refreshExpiresAt < new Date()) {
      await prisma.session.update({
        where: { id: session.id },
        data: { isActive: false },
      });
      throw new ApiError(401, 'Session expirée, veuillez vous reconnecter');
    }

    const decoded = jwt.verify(refreshToken, config.jwt.refreshSecret) as {
      id: string;
    };

    const user = await prisma.user.findUnique({ where: { id: decoded.id } });

    if (!user) {
      throw new ApiError(401, 'Utilisateur non trouvé');
    }

    // Désactiver l'ancienne session
    await prisma.session.update({
      where: { id: session.id },
      data: { isActive: false },
    });

    const newToken = generateToken(user.id);
    const newRefreshToken = generateRefreshToken(user.id);

    // Créer une nouvelle session
    await createSession(user.id, newToken, newRefreshToken, req);

    res.status(200).json({
      success: true,
      data: {
        token: newToken,
        refreshToken: newRefreshToken,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const getMe = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
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
        lastLogin: true,
        isActive: true,
        preferences: true,
      },
    });

    if (!user) {
      throw new ApiError(404, 'Utilisateur non trouvé');
    }

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { name, email, phone, location } = req.body;

    const updateData: any = {};
    if (name) updateData.name = name;
    if (email) updateData.email = email;
    if (phone) updateData.phone = phone;
    if (location) updateData.location = location;

    // Vérifier si l'email existe déjà pour un autre utilisateur
    if (email) {
      const existingEmail = await prisma.user.findFirst({
        where: {
          email,
          id: { not: req.user.id },
        },
      });
      if (existingEmail) {
        throw new ValidationError('Cet email est déjà utilisé par un autre compte');
      }
    }

    // Vérifier si le téléphone existe déjà pour un autre utilisateur
    if (phone) {
      const existingPhone = await prisma.user.findFirst({
        where: {
          phone,
          id: { not: req.user.id },
        },
      });
      if (existingPhone) {
        throw new ValidationError('Ce numéro de téléphone est déjà utilisé par un autre compte');
      }
    }

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: updateData,
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
      },
    });

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error: any) {
    // Gérer les erreurs Prisma de contrainte unique
    if (error.code === 'P2002') {
      const field = error.meta?.target?.[0] || 'champ';
      
      if (field === 'email') {
        return next(new ValidationError('Cet email est déjà utilisé par un autre compte'));
      } else if (field === 'phone') {
        return next(new ValidationError('Ce numéro de téléphone est déjà utilisé par un autre compte'));
      }
    }
    
    // Si c'est déjà une ValidationError, la passer directement
    if (error instanceof ValidationError) {
      return next(error);
    }
    
    next(error);
  }
};

export const forgotPassword = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { email } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });

    if (!user) {
      res.status(200).json({
        success: true,
        message: 'Si l\'email existe, un lien de réinitialisation a été envoyé',
      });
      return;
    }

    res.status(200).json({
      success: true,
      message: 'Si l\'email existe, un lien de réinitialisation a été envoyé',
    });
  } catch (error) {
    next(error);
  }
};

export const resetPassword = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { token, newPassword } = req.body;

    res.status(200).json({
      success: true,
      message: 'Réinitialisation du mot de passe réussie',
    });
  } catch (error) {
    next(error);
  }
};