import mongoose, { Document, Schema } from 'mongoose';

export interface IConversation extends Document {
  participants: mongoose.Types.ObjectId[];
  item?: mongoose.Types.ObjectId;
  lastMessage?: {
    content: string;
    sender: mongoose.Types.ObjectId;
    sentAt: Date;
  };
  unreadCount: Map<string, number>;
  createdAt: Date;
  updatedAt: Date;
}

const conversationSchema = new Schema<IConversation>(
  {
    participants: [
      {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true,
      },
    ],
    item: {
      type: Schema.Types.ObjectId,
      ref: 'Item',
    },
    lastMessage: {
      content: { type: String },
      sender: { type: Schema.Types.ObjectId, ref: 'User' },
      sentAt: { type: Date },
    },
    unreadCount: {
      type: Map,
      of: Number,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

conversationSchema.index({ participants: 1 });
conversationSchema.index({ 'lastMessage.sentAt': -1 });

conversationSchema.set('toJSON', {
  transform: (_doc: any, ret: any) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

export default mongoose.model<IConversation>('Conversation', conversationSchema);