import { Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';
import { AuthRequest } from '../middleware/auth.js';
import { NotFoundError, ForbiddenError } from '../utils/ApiError.js';

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

    // Check if conversation already exists
    const existing = await prisma.conversation.findFirst({
      where: {
        itemId,
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

    if (existing) {
      const newMessage = await prisma.message.create({
        data: {
          conversationId: existing.id,
          senderId: req.user.id,
          content: message,
        },
      });

      const unreadCount: any = (existing.unreadCount as any) || {};
      unreadCount[participantId] = (unreadCount[participantId] || 0) + 1;

      const conversation = await prisma.conversation.update({
        where: { id: existing.id },
        data: {
          lastMessageContent: message,
          lastMessageSenderId: req.user.id,
          lastMessageSentAt: new Date(),
          unreadCount,
        },
      });

      res.status(200).json({
        success: true,
        data: { conversation, message: newMessage },
      });
      return;
    }

    // Create new conversation
    const conversation = await prisma.conversation.create({
      data: {
        itemId,
        lastMessageContent: message,
        lastMessageSenderId: req.user.id,
        lastMessageSentAt: new Date(),
        unreadCount: { [participantId]: 1 },
        participants: {
          create: [
            { userId: req.user.id },
            { userId: participantId },
          ],
        },
      },
    });

    const newMessage = await prisma.message.create({
      data: {
        conversationId: conversation.id,
        senderId: req.user.id,
        content: message,
      },
    });

    res.status(201).json({
      success: true,
      data: { conversation, message: newMessage },
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
    const { content, type = 'text' } = req.body;

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
      },
      include: { sender: { select: { id: true, name: true, photo: true } } },
    });

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