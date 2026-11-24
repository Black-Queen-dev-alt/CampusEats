import mongoose from 'mongoose';
import { app } from './app';
import { env } from './config/env';

async function start() {
  try {
    await mongoose.connect(env.MONGO_URI);
    console.log('✅ Connecté à MongoDB avec succès.');

    app.listen(env.PORT, () => {
      console.log(`🚀 Serveur CampusEats API démarré sur le port ${env.PORT} (${env.NODE_ENV})`);
    });
  } catch (error) {
    console.error('❌ Impossible de démarrer le serveur :', error);
    process.exit(1);
  }
}

start();
