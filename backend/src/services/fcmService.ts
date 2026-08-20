import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import prisma from '../lib/prisma.js';
import config from '../config/index.js';

// Initialiser Firebase Admin SDK
let initialized = false;

async function initFirebase() {
  if (initialized) return;

  // Supporte à la fois FIREBASE_SERVICE_ACCOUNT_JSON (contenu JSON) 
  // et FIREBASE_SERVICE_ACCOUNT_PATH (chemin de fichier, pour le dev local)
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const serviceAccountPath = config.firebase.serviceAccountPath;

  if (!serviceAccountJson && !serviceAccountPath) {
    console.warn('⚠️ FIREBASE_SERVICE_ACCOUNT_JSON ou FIREBASE_SERVICE_ACCOUNT_PATH non défini. Les notifications push sont désactivées.');
    return;
  }

  try {
    let serviceAccount: any;

    if (serviceAccountJson) {
      // Mode Vercel : le JSON est passé en variable d'environnement
      serviceAccount = JSON.parse(serviceAccountJson);
    } else {
      // Mode développement local : charger depuis le fichier
      const fs = await import('fs');
      const path = await import('path');
      const { fileURLToPath } = await import('url');
      
      const __filename = fileURLToPath(import.meta.url);
      const __dirname = path.dirname(__filename);
      
      const absolutePath = path.isAbsolute(serviceAccountPath)
        ? serviceAccountPath
        : path.resolve(__dirname, '../../', serviceAccountPath);

      if (!fs.existsSync(absolutePath)) {
        console.error(`❌ Fichier de service account non trouvé: ${absolutePath}`);
        return;
      }

      serviceAccount = JSON.parse(fs.readFileSync(absolutePath, 'utf8'));
    }

    initializeApp({
      credential: cert(serviceAccount),
    });
    initialized = true;
    console.log('🔥 Firebase Admin SDK initialisé');
  } catch (error) {
    console.error('❌ Erreur lors de l\'initialisation de Firebase Admin SDK:', error);
  }
}

/**
 * Enregistre un token FCM pour un utilisateur
 */
export async function registerPushToken(
  userId: string,
  token: string,
  platform: string = 'android'
): Promise<void> {
  // Upsert atomique : si le token existe déjà, on met à jour l'utilisateur et la plateforme
  await prisma.pushToken.upsert({
    where: { token },
    update: { userId, platform },
    create: { userId, token, platform },
  });
}

/**
 * Supprime un token FCM (déconnexion)
 */
export async function unregisterPushToken(token: string): Promise<void> {
  await prisma.pushToken.deleteMany({
    where: { token },
  });
}

/**
 * Envoie une notification push à un utilisateur
 */
export async function sendPushNotification(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  await initFirebase();

  if (!initialized) {
    console.warn('⚠️ Firebase non initialisé, notification non envoyée');
    return;
  }

  try {
    // Récupérer tous les tokens de l'utilisateur
    const tokens = await prisma.pushToken.findMany({
      where: { userId },
      select: { token: true },
    });

    if (tokens.length === 0) {
      console.log(`📭 Aucun token push pour l'utilisateur ${userId} (notification "${title}" non envoyée)`);
      return;
    }

    const registrationTokens = tokens.map((t) => t.token);

    // Envoyer la notification à tous les tokens
    const message = {
      notification: {
        title,
        body,
      },
      android: {
        notification: {
          channelId: 'kivoo_default_channel',
          priority: 'high' as const,
          sound: 'default',
        },
      },
      data: data || {},
      tokens: registrationTokens,
    };

    const response = await getMessaging().sendEachForMulticast(message);

    console.log(`🔥 Notification envoyée: ${response.successCount} succès, ${response.failureCount} échecs`);

    // Supprimer les tokens invalides
    if (response.failureCount > 0) {
      const invalidTokens: string[] = [];
      response.responses.forEach((resp, index) => {
        if (!resp.success) {
          invalidTokens.push(registrationTokens[index]);
        }
      });

      if (invalidTokens.length > 0) {
        await prisma.pushToken.deleteMany({
          where: { token: { in: invalidTokens } },
        });
        console.log(`🗑️ ${invalidTokens.length} tokens invalides supprimés`);
      }
    }
  } catch (error) {
    console.error('❌ Erreur lors de l\'envoi de la notification push:', error);
  }
}

/**
 * Crée une notification en base de données et envoie le push
 */
export async function createAndSendNotification(
  userId: string,
  type: 'message' | 'favorite' | 'price_drop' | 'new_item' | 'system',
  title: string,
  message: string,
  data?: Record<string, any>
): Promise<void> {
  try {
    // Sauvegarder dans la base de données
    await prisma.notification.create({
      data: {
        userId,
        type,
        title,
        message,
        data: data || undefined,
      },
    });

    // Envoyer le push
    const pushData: Record<string, string> = {};
    if (data) {
      Object.entries(data).forEach(([key, value]) => {
        pushData[key] = typeof value === 'string' ? value : JSON.stringify(value);
      });
    }

    await sendPushNotification(userId, title, message, pushData);
  } catch (error) {
    console.error('❌ Erreur lors de la création de la notification:', error);
  }
}