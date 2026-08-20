import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import { fileURLToPath } from 'url';
import prisma from './lib/prisma.js';
import config from './config/index.js';
import { errorHandler } from './middleware/errorHandler.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Routes
import authRoutes from './routes/authRoutes.js';
import itemRoutes from './routes/itemRoutes.js';
import categoryRoutes from './routes/categoryRoutes.js';
import favoriteRoutes from './routes/favoriteRoutes.js';
import conversationRoutes from './routes/conversationRoutes.js';
import userRoutes from './routes/userRoutes.js';
import locationRoutes from './routes/locationRoutes.js';
import featuredRoutes from './routes/featuredRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';

export function createApp(): Express {
  const app = express() as Express;

  // Middleware
  app.use(helmet());
  app.use(
    cors({
      origin: config.frontendUrl,
      credentials: true,
    })
  );
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));

  // Servir les fichiers uploadés statiquement
  app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

  // Health check
  app.get('/api/health', (_req, res) => {
    res.json({
      success: true,
      message: 'Kivoo API is running',
      timestamp: new Date().toISOString(),
    });
  });

  // Routes
  app.use('/api/auth', authRoutes);
  app.use('/api/items', itemRoutes);
  app.use('/api/categories', categoryRoutes);
  app.use('/api/favorites', favoriteRoutes);
  app.use('/api/conversations', conversationRoutes);
  app.use('/api/users', userRoutes);
  app.use('/api/locations', locationRoutes);
  app.use('/api/featured', featuredRoutes);
  app.use('/api/notifications', notificationRoutes);

  // Error handler
  app.use(errorHandler);

  return app;
}

export { prisma };