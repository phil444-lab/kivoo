-- Migration SQL pour ajouter les contraintes de suppression en cascade
-- À exécuter manuellement sur la base de données MySQL

-- Supprimer les contraintes existantes si elles existent
SET FOREIGN_KEY_CHECKS = 0;

-- Table favorites : supprimer les favoris quand l'item est supprimé
ALTER TABLE favorites DROP FOREIGN KEY IF EXISTS favorites_itemId_fkey;
ALTER TABLE favorites 
  ADD CONSTRAINT favorites_itemId_fkey 
  FOREIGN KEY (itemId) REFERENCES items(id) 
  ON DELETE CASCADE;

-- Table conversations : supprimer les conversations quand l'item est supprimé
ALTER TABLE conversations DROP FOREIGN KEY IF EXISTS conversations_itemId_fkey;
ALTER TABLE conversations 
  ADD CONSTRAINT conversations_itemId_fkey 
  FOREIGN KEY (itemId) REFERENCES items(id) 
  ON DELETE CASCADE;

-- Table reviews : supprimer les avis quand l'item est supprimé
ALTER TABLE reviews DROP FOREIGN KEY IF EXISTS reviews_itemId_fkey;
ALTER TABLE reviews 
  ADD CONSTRAINT reviews_itemId_fkey 
  FOREIGN KEY (itemId) REFERENCES items(id) 
  ON DELETE CASCADE;

-- Table reports : supprimer les signalements quand l'item est supprimé
ALTER TABLE reports DROP FOREIGN KEY IF EXISTS reports_reportedItemId_fkey;
ALTER TABLE reports 
  ADD CONSTRAINT reports_reportedItemId_fkey 
  FOREIGN KEY (reportedItemId) REFERENCES items(id) 
  ON DELETE CASCADE;

SET FOREIGN_KEY_CHECKS = 1;

-- Vérifier les contraintes créées
SELECT 
  TABLE_NAME,
  COLUMN_NAME,
  CONSTRAINT_NAME,
  REFERENCED_TABLE_NAME,
  REFERENCED_COLUMN_NAME,
  DELETE_RULE
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE 
  TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('favorites', 'conversations', 'reviews', 'reports')
  AND REFERENCED_TABLE_NAME = 'items';