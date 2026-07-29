import mongoose, { Document, Schema } from 'mongoose';

export interface IItem extends Document {
  title: string;
  description: string;
  price: number;
  priceType: 'fixed' | 'negotiable' | 'rent' | 'auction';
  category: mongoose.Types.ObjectId;
  subcategory?: mongoose.Types.ObjectId;
  seller: mongoose.Types.ObjectId;
  location: {
    city: string;
    country: string;
    address: string;
    coordinates: {
      lat: number;
      lng: number;
    };
  };
  condition: 'new' | 'like_new' | 'good' | 'fair' | 'used';
  brand?: string;
  model?: string;
  year?: number;
  images: string[];
  featured: boolean;
  featuredUntil?: Date;
  status: 'active' | 'sold' | 'expired' | 'pending';
  views: number;
  likes: number;
  boostLevel: number;
  boostUntil?: Date;
  tags: string[];
  specifications: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
  expiresAt: Date;
}

const itemSchema = new Schema<IItem>(
  {
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    description: {
      type: String,
      required: true,
      maxlength: 5000,
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    priceType: {
      type: String,
      enum: ['fixed', 'negotiable', 'rent', 'auction'],
      default: 'fixed',
    },
    category: {
      type: Schema.Types.ObjectId,
      ref: 'Category',
      required: true,
    },
    subcategory: {
      type: Schema.Types.ObjectId,
      ref: 'Category',
    },
    seller: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    location: {
      city: { type: String, default: '' },
      country: { type: String, default: '' },
      address: { type: String, default: '' },
      coordinates: {
        lat: { type: Number, default: 0 },
        lng: { type: Number, default: 0 },
      },
    },
    condition: {
      type: String,
      enum: ['new', 'like_new', 'good', 'fair', 'used'],
      default: 'good',
    },
    brand: { type: String },
    model: { type: String },
    year: { type: Number },
    images: [{ type: String }],
    featured: {
      type: Boolean,
      default: false,
    },
    featuredUntil: { type: Date },
    status: {
      type: String,
      enum: ['active', 'sold', 'expired', 'pending'],
      default: 'active',
    },
    views: {
      type: Number,
      default: 0,
    },
    likes: {
      type: Number,
      default: 0,
    },
    boostLevel: {
      type: Number,
      default: 0,
    },
    boostUntil: { type: Date },
    tags: [{ type: String }],
    specifications: {
      type: Schema.Types.Mixed,
      default: {},
    },
    expiresAt: {
      type: Date,
      default: () => new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
    },
  },
  {
    timestamps: true,
  }
);

itemSchema.index({ title: 'text', description: 'text' });
itemSchema.index({ category: 1, status: 1 });
itemSchema.index({ seller: 1 });
itemSchema.index({ location: '2dsphere' });
itemSchema.index({ price: 1 });
itemSchema.index({ createdAt: -1 });
itemSchema.index({ featured: -1, boostLevel: -1 });

itemSchema.set('toJSON', {
  transform: (_doc: any, ret: any) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

export default mongoose.model<IItem>('Item', itemSchema);