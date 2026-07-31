import { z } from 'zod';

export const updateProfileSchema = z.object({
  name: z.string().min(2, 'Le nom doit contenir au moins 2 caractères').max(100, 'Le nom ne peut pas dépasser 100 caractères').optional(),
  email: z.string().email('Format d\'email invalide').optional(),
  phone: z.string().regex(/^01[0-9]{8}$/, 'Le numéro de téléphone doit commencer par 01 et contenir 10 chiffres au total').optional(),
  currentPassword: z.string().optional(),
  newPassword: z.string().min(8, 'Le mot de passe doit contenir au moins 8 caractères').optional(),
  photo: z.string().url('URL de photo invalide').optional().nullable(),
  location: z.any().optional().nullable(),
  preferences: z.any().optional().nullable(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
