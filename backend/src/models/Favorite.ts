import mongoose, { Document, Schema } from 'mongoose';

export interface IFavorite extends Document {
  user: mongoose.Types.ObjectId;
  item: mongoose.Types.ObjectId;
  createdAt: Date;
}

const favoriteSchema = new Schema<IFavorite>({
  user: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  item: {
    type: Schema.Types.ObjectId,
    ref: 'Item',
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

favoriteSchema.index({ user: 1, item: 1 }, { unique: true });
favoriteSchema.index({ user: 1, createdAt: -1 });

favoriteSchema.set('toJSON', {
  transform: (_doc: any, ret: any) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

export default mongoose.model<IFavorite>('Favorite', favoriteSchema);