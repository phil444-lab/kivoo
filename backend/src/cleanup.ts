import prisma from './lib/prisma.js';

/**
 * Script de nettoyage : supprime les favoris orphelins
 * (favoris qui référencent des items qui n'existent plus)
 */
async function cleanupOrphanFavorites() {
  console.log('🔍 Recherche des favoris orphelins...');

  // Récupérer tous les favoris
  const favorites = await prisma.favorite.findMany({
    select: { id: true, itemId: true },
  });

  // Récupérer tous les IDs d'items existants
  const items = await prisma.item.findMany({
    select: { id: true },
  });
  const existingItemIds = new Set(items.map((i) => i.id));

  // Trouver les favoris orphelins
  const orphanFavorites = favorites.filter((f) => !existingItemIds.has(f.itemId));

  if (orphanFavorites.length === 0) {
    console.log('✅ Aucun favori orphelin trouvé.');
    return;
  }

  console.log(`🗑️  Suppression de ${orphanFavorites.length} favoris orphelins...`);

  // Supprimer les favoris orphelins
  const result = await prisma.favorite.deleteMany({
    where: {
      id: { in: orphanFavorites.map((f) => f.id) },
    },
  });

  console.log(`✅ ${result.count} favoris orphelins supprimés.`);
}

async function main() {
  try {
    await cleanupOrphanFavorites();
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage :', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();