import { z } from 'zod';

const passwordSchema = z.string().refine(
  (val) => val.length >= 8 && /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/.test(val),
  'Mot de passe: 8 caractères minimum avec majuscule, chiffre et caractère spécial',
);

const phoneSchema = z.string()
  .regex(/^01[0-9]{8}$/, 'Le numéro de téléphone doit commencer par 01 et contenir 10 chiffres au total');

const emailSchema = z.string()
  .email('Format d\'email invalide');

export const registerSchema = z.object({
  name: z.string().min(2, 'Le nom doit contenir au moins 2 caractères'),
  email: emailSchema,
  phone: phoneSchema,
  password: passwordSchema,
  location: z.any().optional(),
});

export const loginSchema = z.object({
  identifier: z.string().min(1, 'L\'email ou le téléphone est requis'),
  password: z.string().min(1, 'Le mot de passe est requis'),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;