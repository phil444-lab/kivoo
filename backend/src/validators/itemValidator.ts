import { z } from 'zod';

export const createItemSchema = z.object({
  body: z.object({
    title: z.string().min(3, 'Le titre doit contenir au moins 3 caractères').max(100, 'Le titre ne doit pas dépasser 100 caractères'),
    description: z.string().min(10, 'La description doit contenir au moins 10 caractères'),
    price: z.coerce.number().positive('Le prix doit être positif'),
    priceType: z.enum(['fixed', 'negotiable', 'rent', 'auction']).optional(),
    categoryId: z.string().min(1, 'La catégorie est requise'),
    subcategoryId: z.string().optional(),
    brand: z.string().max(50).optional(),
    model: z.string().max(50).optional(),
    year: z.coerce.number().int().min(1900).max(new Date().getFullYear() + 1).optional(),
    color: z.string().max(50).optional(),
    condition: z.enum(['new', 'like_new', 'good', 'fair', 'used']).default('good'),
    departmentId: z.string().optional(),
    cityId: z.string().optional(),
    districtId: z.string().optional(),
    featureId: z.string().optional(),
    location: z.any().optional(),
    tags: z.array(z.string()).optional(),
    specifications: z.any().optional(),
  }),
});

export const updateItemSchema = z.object({
  body: z.object({
    title: z.string().min(3).max(100).optional(),
    description: z.string().min(10).optional(),
    price: z.coerce.number().positive().optional(),
    priceType: z.enum(['fixed', 'negotiable', 'rent', 'auction']).optional(),
    categoryId: z.string().min(1).optional(),
    subcategoryId: z.string().optional(),
    brand: z.string().max(50).optional(),
    model: z.string().max(50).optional(),
    year: z.coerce.number().int().min(1900).max(new Date().getFullYear() + 1).optional(),
    color: z.string().max(50).optional(),
    condition: z.enum(['new', 'like_new', 'good', 'fair', 'used']).optional(),
    departmentId: z.string().optional(),
    cityId: z.string().optional(),
    districtId: z.string().optional(),
    featureId: z.string().optional(),
    location: z.any().optional(),
    tags: z.array(z.string()).optional(),
    specifications: z.any().optional(),
  }),
});
