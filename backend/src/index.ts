import { createServer } from 'http';
import { Server } from 'socket.io';
import { createApp, prisma } from './app.js';
import config from './config/index.js';
import { startCleanupJobs } from './jobs/cleanupJob.js';

const app = createApp();
const httpServer = createServer(app);

// Socket.io
const io = new Server(httpServer, {
  cors: {
    origin: config.frontendUrl,
    methods: ['GET', 'POST'],
  },
});

// Socket.io connection handling
io.on('connection', (socket: any) => {
  console.log('User connected:', socket.id);

  socket.on('join-conversation', (conversationId: string) => {
    socket.join(`conversation:${conversationId}`);
  });

  socket.on('leave-conversation', (conversationId: string) => {
    socket.leave(`conversation:${conversationId}`);
  });

  socket.on('send-message', (data: { conversationId: string; message: any }) => {
    io.to(`conversation:${data.conversationId}`).emit(
      'new-message',
      data.message
    );
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Connect to database and start server
prisma
  .$connect()
  .then(() => {
    console.log('Connected to MySQL database');
    httpServer.listen(config.port, () => {
      console.log(`Server running on port ${config.port}`);
      console.log(`Environment: ${config.nodeEnv}`);
    });

    // Démarrer les jobs de nettoyage (sessions expirées, notifications >90j)
    startCleanupJobs();
  })
  .catch((error: any) => {
    console.error('Database connection error:', error);
    process.exit(1);
  });

export default app;