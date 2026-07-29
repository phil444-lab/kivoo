import { Response, NextFunction } from 'express';
import Conversation from '../models/Conversation.js';
import Message from '../models/Message.js';
import { AuthRequest } from '../middleware/auth.js';
import { NotFoundError, ForbiddenError } from '../utils/ApiError.js';

export const getConversations = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const conversations = await Conversation.find({
      participants: req.user._id,
    })
      .populate('participants', 'name photo')
      .populate('item', 'title price images')
      .sort({ 'lastMessage.sentAt': -1, updatedAt: -1 })
      .lean();

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
    const { id } = req.params;
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 50;
    const skip = (page - 1) * limit;

    const conversation = await Conversation.findById(id);

    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    if (
      !conversation.participants.some(
        (p: any) => p.toString() === req.user._id.toString()
      )
    ) {
      throw new ForbiddenError('Not a participant of this conversation');
    }

    const [messages, totalItems] = await Promise.all([
      Message.find({ conversation: id })
        .populate('sender', 'name photo')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Message.countDocuments({ conversation: id }),
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
    let conversation = await Conversation.findOne({
      participants: { $all: [req.user._id, participantId] },
      item: itemId,
    });

    if (conversation) {
      // Add message to existing conversation
      const newMessage = await Message.create({
        conversation: conversation._id,
        sender: req.user._id,
        content: message,
      });

      conversation.lastMessage = {
        content: message,
        sender: req.user._id,
        sentAt: new Date(),
      };
      conversation.unreadCount.set(
        participantId,
        (conversation.unreadCount.get(participantId) || 0) + 1
      );
      await conversation.save();

      res.status(200).json({
        success: true,
        data: {
          conversation,
          message: newMessage,
        },
      });
      return;
    }

    // Create new conversation
    conversation = await Conversation.create({
      participants: [req.user._id, participantId],
      item: itemId,
    });

    const newMessage = await Message.create({
      conversation: conversation._id,
      sender: req.user._id,
      content: message,
    });

    conversation.lastMessage = {
      content: message,
      sender: req.user._id,
      sentAt: new Date(),
    };
    conversation.unreadCount.set(participantId, 1);
    await conversation.save();

    res.status(201).json({
      success: true,
      data: {
        conversation,
        message: newMessage,
      },
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
    const { id } = req.params;
    const { content, type = 'text' } = req.body;

    const conversation = await Conversation.findById(id);

    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    if (
      !conversation.participants.some(
        (p: any) => p.toString() === req.user._id.toString()
      )
    ) {
      throw new ForbiddenError('Not a participant of this conversation');
    }

    const message = await Message.create({
      conversation: id,
      sender: req.user._id,
      content,
      type,
    });

    conversation.lastMessage = {
      content,
      sender: req.user._id,
      sentAt: new Date(),
    };

    // Increment unread count for other participants
    conversation.participants.forEach((participant: any) => {
      if (participant.toString() !== req.user._id.toString()) {
        const userId = participant.toString();
        conversation.unreadCount.set(
          userId,
          (conversation.unreadCount.get(userId) || 0) + 1
        );
      }
    });

    await conversation.save();

    const populatedMessage = await Message.findById(message._id)
      .populate('sender', 'name photo')
      .lean();

    res.status(201).json({
      success: true,
      data: populatedMessage,
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
    const { id } = req.params;

    const conversation = await Conversation.findById(id);

    if (!conversation) {
      throw new NotFoundError('Conversation');
    }

    // Reset unread count for current user
    conversation.unreadCount.set(req.user._id.toString(), 0);
    await conversation.save();

    // Mark all messages as read
    await Message.updateMany(
      {
        conversation: id,
        sender: { $ne: req.user._id },
        read: false,
      },
      {
        read: true,
        readAt: new Date(),
      }
    );

    res.status(200).json({
      success: true,
      message: 'Messages marked as read',
    });
  } catch (error) {
    next(error);
  }
};