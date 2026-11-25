import * as admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';

// Path vers la clé de service Firebase (non versionnée)
const keyPath = path.resolve(__dirname, '../../firebase-service-key.json');

// Initialise Firebase seulement si le fichier existe.
if (fs.existsSync(keyPath)) {
  try {
    if ((admin as any).credential && (admin as any).credential.cert) {
      admin.initializeApp({
        credential: (admin as any).credential.cert(keyPath),
      });
    } else {
      // fallback : init sans credential (développement)
      admin.initializeApp();
    }
  } catch (e) {
    console.warn('Firebase admin initialisation skipped:', e);
  }
}

/** Envoie une notification push via Firebase Cloud Messaging. */
export async function sendPushNotification(
  token: string,
  payload: { title: string; body: string; data?: Record<string, string> }
) {
  // Si l'admin n'est pas initialisé (ex. en dev), on simule le comportement
  if (typeof (admin as any).messaging !== 'function') {
    console.log('FCM mock – notification not sent (no admin.messaging)');
    return;
  }
  const message = {
    token,
    notification: { title: payload.title, body: payload.body },
    data: payload.data,
  };
  await (admin as any).messaging().send(message);
}

