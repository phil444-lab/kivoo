import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Supprime les sessions expirées (plus anciennes que leur expiresAt)
 */
async function cleanupSessions() {
  const now = new Date();
  const deleted = await prisma.session.deleteMany({
    where: { expiresAt: { lt: now } },
  });
  console.log(`[cleanup] Sessions expirées supprimées : ${deleted.count}`);
}

/**
 * Supprime les notifications anciennes (> 90 jours)
 */
async function cleanupNotifications() {
  const ninetyDaysAgo = new Date();
  ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
  const deleted = await prisma.notification.deleteMany({
    where: { createdAt: { lt: ninetyDaysAgo } },
  });
  console.log(`[cleanup] Notifications anciennes (>90j) supprimées : ${deleted.count}`);
}

/**
 * Fonction de nettoyage globale, appelée à chaque tick.
 */
async function runCleanup() {
  try {
    await cleanupSessions();
    await cleanupNotifications();
  } catch (error) {
    console.error('[cleanup] Erreur pendant le nettoyage :', error);
  }
}

/**
 * Planifie les tâches de nettoyage toutes les heures.
 */
export function startCleanupJobs() {
  // Exécuter un premier nettoyage au démarrage
  runCleanup();

  // Puis toutes les heures (3 600 000 ms)
  setInterval(runCleanup, 3_600_000);

  console.log('[cleanup] Jobs de nettoyage planifiés (toutes les heures)');
}