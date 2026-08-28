import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

/**
 * Crée (ou met à jour) UNIQUEMENT le compte administrateur.
 * N'insère PAS les locations / catégories / options "featured".
 *
 * Variables d'environnement (défauts si absentes) :
 *   ADMIN_EMAIL     -> admin@kivoo.com
 *   ADMIN_PASSWORD  -> Admin1234!
 *   ADMIN_PHONE     -> +22990000001
 */
async function main() {
  const adminEmail = process.env.ADMIN_EMAIL || 'admin@kivoo.com';
  const adminPassword = process.env.ADMIN_PASSWORD || 'Admin1234!';
  const adminPhone = process.env.ADMIN_PHONE || '+22990000001';

  const hashed = await bcrypt.hash(adminPassword, 12);

  const user = await prisma.user.upsert({
    where: { email: adminEmail },
    update: {
      role: 'admin',
      isActive: true,
      verified: true,
      // On force aussi le mot de passe et le nom : idempotent, sans danger.
      password: hashed,
      name: 'Administrateur Kivoo',
      phone: adminPhone,
    },
    create: {
      email: adminEmail,
      name: 'Administrateur Kivoo',
      phone: adminPhone,
      password: hashed,
      role: 'admin',
      verified: true,
      isActive: true,
      preferences: { notifications: true, language: 'fr' },
    },
  });

  console.log(`[ADMIN] OK : ${user.email} | role=${user.role} | isActive=${user.isActive}`);
  console.log(`[ADMIN] Mot de passe : utilisez ADMIN_PASSWORD (ne pas le partager)`);
}

main()
  .catch((e) => {
    console.error('❌ seed-admin error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });