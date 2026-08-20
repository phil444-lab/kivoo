import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Supprime les sessions expirées (plus anciennes que leur expiresAt)
 */
async function cleanupSessions() {
  const now = new Date();
  await prisma.session.deleteMany({
    where: { expiresAt: { lt: now } },
  });
}

/**
 * Supprime les notifications anciennes (> 90 jours)
 */
async function cleanupNotifications() {
  const ninetyDaysAgo = new Date();
  ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
  await prisma.notification.deleteMany({
    where: { createdAt: { lt: ninetyDaysAgo } },
  });
}

/**
 * Fonction de nettoyage globale, appelée à chaque tick.
 */
async function runCleanup() {
  try {
    await cleanupSessions();
    await cleanupNotifications();
  } catch (error) {
    // Erreur silencieuse - le nettoyage est best-effort
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
}