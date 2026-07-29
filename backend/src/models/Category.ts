import mongoose, { Document, Schema } from 'mongoose';

export interface ICategory extends Document {
  name: string;
  icon: string;
  color: string;
  parentCategory?: mongoose.Types.ObjectId;
  isActive: boolean;
  createdAt: Date;
}

const categorySchema = new Schema<ICategory>({
  name: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  icon: {
    type: String,
    default: '📦',
  },
  color: {
    type: String,
    default: '#6366f1',
  },
  parentCategory: {
    type: Schema.Types.ObjectId,
    ref: 'Category',
    default: null,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

categorySchema.set('toJSON', {
  transform: (_doc: any, ret: any) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

export default mongoose.model<ICategory>('Category', categorySchema);