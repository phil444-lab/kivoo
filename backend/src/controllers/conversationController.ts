import { Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';
import { AuthRequest } from '../middleware/auth.js';
import { NotFoundError, ForbiddenError, ApiError } from '../utils/ApiError.js';
import { createAndSendNotification } from '../services/fcmService.js';

export const getConversations = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const conversations = await prisma.conversation.findMany({
      where: {
        participants: {
          some: { userId: req.user.id },
        },
        lastMessageContent: {
          not: null,
        },
      },
      include: {
        participants: {
          include: { user: { select: { id: true, name: true, photo: true } } },
        },
        item: { select: { id: true, title: true, price: true, images: true } },
      },
      orderBy: { lastMessageSentAt: 'desc' },
    });

    res.status(200).json({
      success: true,
      data: conversations,
    });
  } catch (error) {
    next(error);
  }
};

export const getMessages = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const id = req.params.id as string;
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 50;
    const skip = (page - 1) * limit;

    const conversation = await prisma.conversation.findUnique({
      where: { id },
      include: {
        participants: { select: { userId: true } },
      },
    });

    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    const isParticipant = conversation.participants.some(
      (p: any) => p.userId === req.user.id
    );

    if (!isParticipant) {
      throw new ForbiddenError('Not a participant of this conversation');
    }

    const [messages, totalItems] = await Promise.all([
      prisma.message.findMany({
        where: { conversationId: id },
        include: { sender: { select: { id: true, name: true, photo: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.message.count({ where: { conversationId: id } }),
    ]);

    const totalPages = Math.ceil(totalItems / limit);

    res.status(200).json({
      success: true,
      data: {
        messages: messages.reverse(),
        pagination: {
          currentPage: page,
          totalPages,
          totalItems,
          hasNext: page < totalPages,
          hasPrev: page > 1,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

export const createConversation = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { participantId, itemId, message } = req.body;

    // Check if conversation already exists (without itemId to have one conversation per seller)
    const existing = await prisma.conversation.findFirst({
      where: {
        AND: [
          {
            participants: {
              some: { userId: req.user.id },
            },
          },
          {
            participants: {
              some: { userId: participantId },
            },
          },
        ],
      },
      include: { participants: true },
    });

    let newMessage = null;

    if (existing) {
      if (message) {
        newMessage = await prisma.message.create({
          data: {
            conversationId: existing.id,
            senderId: req.user.id,
            content: message,
          },
        });

        const unreadCount: any = (existing.unreadCount as any) || {};
        unreadCount[participantId] = (unreadCount[participantId] || 0) + 1;

        await prisma.conversation.update({
          where: { id: existing.id },
          data: {
            lastMessageContent: message,
            lastMessageSenderId: req.user.id,
            lastMessageSentAt: new Date(),
            unreadCount,
          },
        });
      }

      const conversationWithParticipants = await prisma.conversation.findUnique({
        where: { id: existing.id },
        include: {
          participants: {
            include: { user: { select: { id: true, name: true, photo: true } } },
          },
          item: { select: { id: true, title: true, price: true, images: true } },
        },
      });

      res.status(200).json({
        success: true,
        data: { conversation: conversationWithParticipants, message: newMessage },
      });
      return;
    }

    // Create new conversation (without itemId to have one conversation per seller)
    const conversation = await prisma.conversation.create({
      data: {
        ...(message ? {
          lastMessageContent: message,
          lastMessageSenderId: req.user.id,
          lastMessageSentAt: new Date(),
          unreadCount: { [participantId]: 1 },
        } : {}),
        participants: {
          create: [
            { userId: req.user.id },
            { userId: participantId },
          ],
        },
      },
    });

    if (message) {
      newMessage = await prisma.message.create({
        data: {
          conversationId: conversation.id,
          senderId: req.user.id,
          content: message,
        },
      });
    }

    const conversationWithParticipants = await prisma.conversation.findUnique({
      where: { id: conversation.id },
      include: {
        participants: {
          include: { user: { select: { id: true, name: true, photo: true } } },
        },
        item: { select: { id: true, title: true, price: true, images: true } },
      },
    });

    res.status(201).json({
      success: true,
      data: { conversation: conversationWithParticipants, message: newMessage },
    });
  } catch (error) {
    next(error);
  }
};

export const sendMessage = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const id = req.params.id as string;
    const { content, type = 'text', attachments } = req.body;

    const conversation = await prisma.conversation.findUnique({
      where: { id },
      include: { participants: { select: { userId: true } } },
    });

    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    const isParticipant = conversation.participants.some(
      (p: any) => p.userId === req.user.id
    );

    if (!isParticipant) {
      throw new ForbiddenError('Not a participant of this conversation');
    }

    const message = await prisma.message.create({
      data: {
        conversationId: id,
        senderId: req.user.id,
        content,
        type: type as any,
        ...(attachments ? { attachments: attachments as any } : {}),
      },
      include: { sender: { select: { id: true, name: true, photo: true } } },
    });

    // Envoyer une notification push aux autres participants
    const otherParticipants = conversation.participants.filter(
      (p: any) => p.userId !== req.user.id
    );

    for (const participant of otherParticipants) {
      const senderName = message.sender?.name || 'Quelqu\'un';
      await createAndSendNotification(
        participant.userId,
        'message',
        senderName,
        content.length > 100 ? content.substring(0, 100) + '...' : content,
        {
          conversationId: id,
          messageId: message.id,
          senderId: req.user.id,
          type: 'conversation',
        }
      );
    }

    const unreadCount: any = (conversation.unreadCount as any) || {};
    conversation.participants.forEach((p: any) => {
      if (p.userId !== req.user.id) {
        unreadCount[p.userId] = (unreadCount[p.userId] || 0) + 1;
      }
    });

    const updatedConversation = await prisma.conversation.update({
      where: { id },
      data: {
        lastMessageContent: content,
        lastMessageSenderId: req.user.id,
        lastMessageSentAt: new Date(),
        unreadCount,
      },
    });

    res.status(201).json({
      success: true,
      data: message,
    });
  } catch (error) {
    next(error);
  }
};

export const uploadMessageImage = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const id = req.params.id as string;

    if (!req.file) {
      throw new ApiError(400, 'Aucune image fournie');
    }

    const conversation = await prisma.conversation.findUnique({
      where: { id },
      include: { participants: { select: { userId: true } } },
    });

    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    const isParticipant = conversation.participants.some(
      (p: any) => p.userId === req.user.id
    );

    if (!isParticipant) {
      throw new ForbiddenError('Not a participant of this conversation');
    }

    // Le fichier est déjà sauvegardé sur le disque par multer
    const fileName = req.file.filename;

    // Créer un message de type image avec l'attachment
    const message = await prisma.message.create({
      data: {
        conversationId: id,
        senderId: req.user.id,
        content: '📷 Photo',
        type: 'image',
        attachments: {
          image: fileName,
        },
      },
      include: { sender: { select: { id: true, name: true, photo: true } } },
    });

    // Envoyer une notification push aux autres participants
    const otherParticipants = conversation.participants.filter(
      (p: any) => p.userId !== req.user.id
    );

    for (const participant of otherParticipants) {
      const senderName = message.sender?.name || 'Quelqu\'un';
      await createAndSendNotification(
        participant.userId,
        'message',
        senderName,
        '📷 Photo',
        {
          conversationId: id,
          messageId: message.id,
          senderId: req.user.id,
          type: 'conversation',
        }
      );
    }

    const unreadCount: any = (conversation.unreadCount as any) || {};
    conversation.participants.forEach((p: any) => {
      if (p.userId !== req.user.id) {
        unreadCount[p.userId] = (unreadCount[p.userId] || 0) + 1;
      }
    });

    await prisma.conversation.update({
      where: { id },
      data: {
        lastMessageContent: '📷 Photo',
        lastMessageSenderId: req.user.id,
        lastMessageSentAt: new Date(),
        unreadCount,
      },
    });

    res.status(201).json({
      success: true,
      data: message,
    });
  } catch (error) {
    next(error);
  }
};

export const markAsRead = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const id = req.params.id as string;

    const conversation = await prisma.conversation.findUnique({
      where: { id },
    });

    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    const unreadCount: any = (conversation.unreadCount as any) || {};
    unreadCount[req.user.id] = 0;

    await prisma.conversation.update({
      where: { id },
      data: { unreadCount },
    });

    await prisma.message.updateMany({
      where: {
        conversationId: id,
        senderId: { not: req.user.id },
        read: false,
      },
      data: {
        read: true,
        readAt: new Date(),
      },
    });

    res.status(200).json({
      success: true,
      message: 'Messages marked as read',
    });
  } catch (error) {
    next(error);
  }
};