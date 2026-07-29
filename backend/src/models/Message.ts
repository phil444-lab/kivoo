import mongoose, { Document, Schema } from 'mongoose';

export interface IMessage extends Document {
  conversation: mongoose.Types.ObjectId;
  sender: mongoose.Types.ObjectId;
  content: string;
  type: 'text' | 'image' | 'location' | 'contact';
  attachments: Array<{
    type: string;
    url: string;
    name: string;
  }>;
  read: boolean;
  readAt?: Date;
  createdAt: Date;
}

const messageSchema = new Schema<IMessage>({
  conversation: {
    type: Schema.Types.ObjectId,
    ref: 'Conversation',
    required: true,
  },
  sender: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  content: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    enum: ['text', 'image', 'location', 'contact'],
    default: 'text',
  },
  attachments: [
    {
      type: { type: String },
      url: { type: String },
      name: { type: String },
    },
  ],
  read: {
    type: Boolean,
    default: false,
  },
  readAt: {
    type: Date,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

messageSchema.index({ conversation: 1, createdAt: 1 });

messageSchema.set('toJSON', {
  transform: (_doc: any, ret: any) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

export default mongoose.model<IMessage>('Message', messageSchema);