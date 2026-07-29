import mongoose, { Document, Schema } from 'mongoose';

export interface IReview extends Document {
  reviewer: mongoose.Types.ObjectId;
  reviewed: mongoose.Types.ObjectId;
  item?: mongoose.Types.ObjectId;
  rating: number;
  comment?: string;
  createdAt: Date;
}

const reviewSchema = new Schema<IReview>({
  reviewer: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  reviewed: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  item: {
    type: Schema.Types.ObjectId,
    ref: 'Item',
  },
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5,
  },
  comment: {
    type: String,
    maxlength: 1000,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

reviewSchema.index({ reviewer: 1, item: 1 }, { unique: true });
reviewSchema.index({ reviewed: 1, createdAt: -1 });

reviewSchema.set('toJSON', {
  transform: (_doc: any, ret: any) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

export default mongoose.model<IReview>('Review', reviewSchema);