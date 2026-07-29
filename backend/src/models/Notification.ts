import mongoose, { Document, Schema } from 'mongoose';

export interface INotification extends Document {
  user: mongoose.Types.ObjectId;
  type: 'message' | 'favorite' | 'price_drop' | 'new_item' | 'system';
  title: string;
  message: string;
  data: {
    itemId?: mongoose.Types.ObjectId;
    conversationId?: mongoose.Types.ObjectId;
    userId?: mongoose.Types.ObjectId;
  };
  read: boolean;
  createdAt: Date;
}

const notificationSchema = new Schema<INotification>({
  user: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  type: {
    type: String,
    enum: ['message', 'favorite', 'price_drop', 'new_item', 'system'],
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  data: {
    itemId: { type: Schema.Types.ObjectId, ref: 'Item' },
    conversationId: { type: Schema.Types.ObjectId, ref: 'Conversation' },
    userId: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  read: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

notificationSchema.index({ user: 1, createdAt: -1 });
notificationSchema.index({ user: 1, read: 1 });

notificationSchema.set('toJSON', {
  transform: (_doc: any, ret: any) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

export default mongoose.model<INotification>('Notification', notificationSchema);