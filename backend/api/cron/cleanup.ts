import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Endpoint Cron pour le nettoyage des données
 * Appelé par Vercel Cron Jobs toutes les heures
 */
export default async function handler(req: any, res: any) {
  // Vérifier le secret pour éviter les appels non autorisés
  const authHeader = req.headers.authorization;
  const expectedSecret = process.env.CRON_SECRET;

  if (expectedSecret && authHeader !== `Bearer ${expectedSecret}`) {
    return res.status(401).json({ success: false, message: 'Non autorisé' });
  }

  const results: Record<string, number> = {};

  try {
    // 1. Supprimer les sessions expirées
    const now = new Date();
    const deletedSessions = await prisma.session.deleteMany({
      where: { expiresAt: { lt: now } },
    });
    results.sessions = deletedSessions.count;

    // 2. Supprimer les notifications anciennes (> 90 jours)
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
    const deletedNotifications = await prisma.notification.deleteMany({
      where: { createdAt: { lt: ninetyDaysAgo } },
    });
    results.notifications = deletedNotifications.count;

    // 3. Marquer les annonces expirées
    const expiredItems = await prisma.item.updateMany({
      where: {
        status: 'active',
        expiresAt: { lt: now },
      },
      data: { status: 'expired' },
    });
    results.expiredItems = expiredItems.count;

    return res.status(200).json({
      success: true,
      message: 'Nettoyage effectué',
      results,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    console.error('[cron-cleanup] Erreur:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors du nettoyage',
      error: error.message,
    });
  } finally {
    await prisma.$disconnect();
  }
}