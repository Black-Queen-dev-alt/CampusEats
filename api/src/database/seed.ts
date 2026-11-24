import mongoose from 'mongoose';
import { env } from '../config/env';
import { hashPassword } from '../common/utils/hash';
import { User } from '../modules/users/user.model';
import { Dish } from '../modules/dishes/dish.model';
import { Menu } from '../modules/menus/menu.model';

function getFormattedDate(offsetDays = 0): string {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  return d.toISOString().split('T')[0];
}

async function seedDatabase(): Promise<void> {
  console.log('🌱 Démarrage du script de peuplement (Seed CampusEats - Développeur 2)...');
  console.log(`🔌 Connexion à MongoDB : ${env.MONGO_URI}`);

  await mongoose.connect(env.MONGO_URI);

  // 1. Nettoyage des collections
  console.log('🧹 Purge des données...');
  await Promise.all([
    User.deleteMany({}),
    Dish.deleteMany({}),
    Menu.deleteMany({}),
  ]);

  // 2. Création des utilisateurs avec hachage Argon2id (Exigence A6)
  console.log('👤 Création des comptes de démonstration (Argon2id)...');
  const [adminPassword, staffPassword, studentPassword] = await Promise.all([
    hashPassword('Admin1234!'),
    hashPassword('Staff1234!'),
    hashPassword('Student1234!'),
  ]);

  await User.create([
    {
      email: 'admin@campuseats.univ.edu',
      password: adminPassword,
      fullName: 'Dr Lebian NIKIEMA (Admin)',
      role: 'admin',
      status: 'actif',
      phone: '+226 71 82 56 66',
    },
    {
      email: 'staff@campuseats.univ.edu',
      password: staffPassword,
      fullName: 'Chef Amadou (Personnel Cuisine)',
      role: 'personnel',
      status: 'actif',
      phone: '+226 70 00 00 01',
    },
    {
      email: 'student@campuseats.univ.edu',
      password: studentPassword,
      fullName: 'Grace Oceane (Étudiante)',
      role: 'etudiant',
      status: 'actif',
      phone: '+226 70 00 00 02',
    },
    {
      email: 'student2@campuseats.univ.edu',
      password: studentPassword,
      fullName: 'Moussa Traoré (Étudiant)',
      role: 'etudiant',
      status: 'actif',
      phone: '+226 70 00 00 03',
    },
  ]);

  // 3. Création du Catalogue de Plats (11 plats variés avec allergènes & prix entiers en centimes - RG09)
  console.log('🍲 Création du catalogue de plats du restaurant universitaire...');
  const dishes = await Dish.create([
    // Entrées
    {
      name: 'Salade Fraîcheur Maraîchère',
      description: 'Jeunes pousses, tomates cerises, concombres et vinaigrette aux agrumes.',
      priceInCents: 450, // 4.50 € ou 450 FCFA
      category: 'entree',
      allergens: [],
      isVegetarian: true,
      photoUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500',
      isActive: true,
    },
    {
      name: 'Velouté de Potimarron & Croûtons',
      description: 'Crème onctueuse de potimarron rôti avec graines de courge et croûtons.',
      priceInCents: 350,
      category: 'entree',
      allergens: ['gluten', 'lactose'],
      isVegetarian: true,
      photoUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=500',
      isActive: true,
    },
    // Plats principaux
    {
      name: 'Riz au Gras Royal & Poulet Braisé',
      description: 'Riz mijoté aux petits légumes parfumés et cuisse de poulet braisée aux épices locales.',
      priceInCents: 1500, // 15.00 € ou 1500 FCFA
      category: 'plat',
      allergens: ['celeri'],
      isVegetarian: false,
      photoUrl: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=500',
      isActive: true,
    },
    {
      name: 'Mafé Traditionnel au Bœuf Tendre',
      description: 'Ragoût savoureux à la pâte d\'arachide, patates douces et riz blanc parfumé.',
      priceInCents: 1600,
      category: 'plat',
      allergens: ['arachides'],
      isVegetarian: false,
      photoUrl: 'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=500',
      isActive: true,
    },
    {
      name: 'Spaghetti Bolognaise Maison',
      description: 'Pâtes fraîches, sauce mijotée pur bœuf et coulis de tomates au basilic.',
      priceInCents: 1300,
      category: 'plat',
      allergens: ['gluten', 'lactose', 'oeufs'],
      isVegetarian: false,
      photoUrl: 'https://images.unsplash.com/photo-1621996346565-e3d5d62810a9?w=500',
      isActive: true,
    },
    {
      name: 'Wok Végétarien Tofu Croustillant & Quinoa',
      description: 'Tofu mariné au soja, légumes croquants et graines de sésame grillées.',
      priceInCents: 1200,
      category: 'plat',
      allergens: ['soja', 'sesame'],
      isVegetarian: true,
      photoUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      isActive: true,
    },
    {
      name: 'Pavé de Saumon Grillé & Riz Basmati',
      description: 'Saumon Atlantique grillé à la plancha avec émulsion citronnée à l\'aneth.',
      priceInCents: 1800,
      category: 'plat',
      allergens: ['poisson', 'lactose'],
      isVegetarian: false,
      photoUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=500',
      isActive: true,
    },
    // Desserts
    {
      name: 'Fondant au Chocolat Cœur Coulant',
      description: 'Chocolat noir intense 70% et éclats de noisettes torréfiées.',
      priceInCents: 400,
      category: 'dessert',
      allergens: ['gluten', 'lactose', 'oeufs'],
      isVegetarian: true,
      photoUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=500',
      isActive: true,
    },
    {
      name: 'Coupe de Fruits Exotiques Frais',
      description: 'Ananas Victoria, mangue fraîche et fruits de la passion.',
      priceInCents: 300,
      category: 'dessert',
      allergens: [],
      isVegetarian: true,
      photoUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500',
      isActive: true,
    },
    // Boissons
    {
      name: 'Jus Artisanal Bissap & Menthe (33cl)',
      description: 'Infusion de fleurs d\'hibiscus, menthe poivrée et vanille.',
      priceInCents: 250,
      category: 'boisson',
      allergens: [],
      isVegetarian: true,
      photoUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500',
      isActive: true,
    },
    {
      name: 'Eau Minérale Naturelle Pure (50cl)',
      description: 'Bouteille d\'eau minérale plate fraîche.',
      priceInCents: 100,
      category: 'boisson',
      allergens: [],
      isVegetarian: true,
      photoUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=500',
      isActive: true,
    },
  ]);

  // 4. Création des Menus Journaliers (Dates uniques : Hier, Aujourd'hui, Demain)
  console.log('📅 Création des menus du jour avec dates uniques...');
  const yesterday = getFormattedDate(-1);
  const today = getFormattedDate(0);
  const tomorrow = getFormattedDate(1);

  const menuItems = dishes.slice(0, 8).map((dish, idx) => ({
    dishId: dish._id,
    isAvailable: idx !== 3, // Le 4ème plat est marqué indisponible pour tester la gestion des ruptures
    dailyStockLimit: 50,
  }));

  await Menu.create([
    {
      date: yesterday,
      isPublished: true,
      items: menuItems,
    },
    {
      date: today,
      isPublished: true,
      items: menuItems,
    },
    {
      date: tomorrow,
      isPublished: true,
      items: menuItems,
    },
  ]);

  console.log('\n================================================================');
  console.log('✅ BASE DE DONNÉES PEUPLÉE AVEC SUCCÈS (Seed Développeur 2) !');
  console.log('================================================================');
  console.log('🔐 COMPTES DE TEST CRÉÉS :');
  console.log('   1. Administrateur : admin@campuseats.univ.edu   | MDP: Admin1234!');
  console.log('   2. Personnel      : staff@campuseats.univ.edu   | MDP: Staff1234!');
  console.log('   3. Étudiant 1     : student@campuseats.univ.edu | MDP: Student1234!');
  console.log('   4. Étudiant 2     : student2@campuseats.univ.edu| MDP: Student1234!');
  console.log('----------------------------------------------------------------');
  console.log(`🍲 Plats enregistrés : ${dishes.length} plats`);
  console.log(`📅 Menus configurés  : 3 menus (Hier: ${yesterday}, Aujourd'hui: ${today}, Demain: ${tomorrow})`);
  console.log('================================================================\n');

  await mongoose.disconnect();
}

seedDatabase().catch((err) => {
  console.error('❌ Erreur lors de l\'exécution du seed :', err);
  process.exit(1);
});
