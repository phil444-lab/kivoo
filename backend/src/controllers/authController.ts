import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import config from '../config/index.js';
import { AuthRequest } from '../middleware/auth.js';
import { ApiError, ValidationError } from '../utils/ApiError.js';

const generateToken = (userId: string): string => {
  return jwt.sign({ id: userId }, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn,
  });
};

const generateRefreshToken = (userId: string): string => {
  return jwt.sign({ id: userId }, config.jwt.refreshSecret, {
    expiresIn: config.jwt.refreshExpiresIn,
  });
};

export const register = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { name, email, phone, password, location } = req.body;

    const existingUser = await User.findOne({
      $or: [{ email }, { phone }],
    });

    if (existingUser) {
      throw new ValidationError('Email or phone already registered');
    }

    const user = await User.create({
      name,
      email,
      phone,
      password,
      location,
    });

    const token = generateToken(user._id.toString());
    const refreshToken = generateRefreshToken(user._id.toString());

    res.status(201).json({
      success: true,
      data: {
        user: user.toJSON(),
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
    const { email, password } = req.body;

    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      throw new ValidationError('Invalid email or password');
    }

    const isPasswordValid = await user.comparePassword(password);

    if (!isPasswordValid) {
      throw new ValidationError('Invalid email or password');
    }

    user.lastLogin = new Date();
    await user.save();

    const token = generateToken(user._id.toString());
    const refreshToken = generateRefreshToken(user._id.toString());

    res.status(200).json({
      success: true,
      data: {
        user: user.toJSON(),
        token,
        refreshToken,
      },
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

    let user = await User.findOne({
      'socialProviders.providerId': providerId,
    });

    if (!user && email) {
      user = await User.findOne({ email });
    }

    if (user) {
      // Add social provider if not exists
      const hasProvider = user.socialProviders.some(
        (sp) => sp.provider === provider
      );

      if (!hasProvider) {
        user.socialProviders.push({ provider, providerId, email });
        await user.save();
      }
    } else {
      // Create new user
      user = await User.create({
        name,
        email,
        phone: `social_${providerId.slice(0, 10)}`,
        password: Math.random().toString(36).slice(-12),
        photo,
        verified: true,
        socialProviders: [{ provider, providerId, email }],
      });
    }

    const token = generateToken(user._id.toString());
    const refreshToken = generateRefreshToken(user._id.toString());

    res.status(200).json({
      success: true,
      data: {
        user: user.toJSON(),
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
      throw new ApiError(401, 'No refresh token provided');
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, config.jwt.refreshSecret) as {
      id: string;
    };

    const user = await User.findById(decoded.id);

    if (!user) {
      throw new ApiError(401, 'User not found');
    }

    const newToken = generateToken(user._id.toString());
    const newRefreshToken = generateRefreshToken(user._id.toString());

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
    const user = await User.findById(req.user._id);

    if (!user) {
      throw new ApiError(404, 'User not found');
    }

    res.status(200).json({
      success: true,
      data: user.toJSON(),
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
    const { name, phone, location } = req.body;

    const user = await User.findById(req.user._id);

    if (!user) {
      throw new ApiError(404, 'User not found');
    }

    if (name) user.name = name;
    if (phone) user.phone = phone;
    if (location) user.location = { ...user.location, ...location };

    await user.save();

    res.status(200).json({
      success: true,
      data: user.toJSON(),
    });
  } catch (error) {
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
    const user = await User.findOne({ email });

    if (!user) {
      res.status(200).json({
        success: true,
        message: 'If the email exists, a reset link has been sent',
      });
      return;
    }

    // In production, send email with reset token
    // const resetToken = crypto.randomBytes(32).toString('hex');
    // await sendEmail({ to: email, resetToken });

    res.status(200).json({
      success: true,
      message: 'If the email exists, a reset link has been sent',
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

    // In production, verify reset token and update password
    // const user = await User.findOne({ resetToken: token, resetTokenExpires: { $gt: Date.now() } });

    res.status(200).json({
      success: true,
      message: 'Password reset successful',
    });
  } catch (error) {
    next(error);
  }
};