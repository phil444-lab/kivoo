import { Request, Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';

export const getFeaturedOptions = async (
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const options = await prisma.featuredOption.findMany({
      where: { isActive: true },
      orderBy: { order: 'asc' },
    });

    res.status(200).json({ success: true, data: options });
  } catch (error) {
    next(error);
  }
};
