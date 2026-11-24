import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../src/app';
import { env } from '../src/config/env';
import { signAccessToken } from '../src/common/utils/jwt';
import { User } from '../src/modules/users/user.model';
import { Dish } from '../src/modules/dishes/dish.model';
import { Menu } from '../src/modules/menus/menu.model';

describe('Tests Développeur 2 : Catalogue & Menus du Jour (Vitest)', () => {
  let adminToken: string;
  let studentToken: string;
  let createdDishId: string;

  beforeAll(async () => {
    if (mongoose.connection.readyState === 0) {
      await mongoose.connect(env.MONGO_URI);
    }

    // Création de 2 utilisateurs réels en base pour passer le middleware authenticate
    const adminUser = await User.create({
      email: `admin_test_${Date.now()}@campuseats.univ.edu`,
      password: 'dummy_hashed_password',
      fullName: 'Admin Test',
      role: 'admin',
      status: 'actif',
    });

    const studentUser = await User.create({
      email: `student_test_${Date.now()}@campuseats.univ.edu`,
      password: 'dummy_hashed_password',
      fullName: 'Student Test',
      role: 'etudiant',
      status: 'actif',
    });

    adminToken = signAccessToken({
      userId: adminUser._id.toString(),
      role: 'admin',
      email: adminUser.email,
    });

    studentToken = signAccessToken({
      userId: studentUser._id.toString(),
      role: 'etudiant',
      email: studentUser.email,
    });
  });

  afterAll(async () => {
    await Dish.deleteMany({ name: /Test/ });
    await Menu.deleteMany({ date: '2026-12-15' });
  });

  // --- MODULE DISHES ---

  it('POST /dishes : doit permettre à l\'admin d\'ajouter un plat au catalogue (201)', async () => {
    const res = await request(app)
      .post('/dishes')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: `Riz Test ${Date.now()}`,
        description: 'Plat de test pour le restaurant universitaire',
        priceInCents: 1500, // RG09: entier strict
        category: 'plat',
        allergens: ['celeri'],
        isVegetarian: false,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('id');
    expect(res.body.data.priceInCents).toBe(1500);

    createdDishId = res.body.data.id;
  });

  it('POST /dishes : doit rejeter un étudiant avec 403 Forbidden (Règle RG11)', async () => {
    const res = await request(app)
      .post('/dishes')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        name: 'Plat Interdit',
        description: 'Non autorisé pour un étudiant',
        priceInCents: 1000,
        category: 'plat',
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it('GET /dishes : doit retourner le catalogue paginé aux utilisateurs connectés (200)', async () => {
    const res = await request(app)
      .get('/dishes?page=1&limit=10')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body).toHaveProperty('pagination');
  });

  // --- MODULE MENUS ---

  it('POST /menus : doit permettre à l\'admin de publier un menu quotidien (201)', async () => {
    const res = await request(app)
      .post('/menus')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        date: '2026-12-15',
        items: [
          {
            dishId: createdDishId,
            isAvailable: true,
            dailyStockLimit: 50,
          },
        ],
        isPublished: true,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.date).toBe('2026-12-15');
  });

  it('POST /menus : doit interdire les doublons de date avec 409 Conflict (Règle Section 8)', async () => {
    const res = await request(app)
      .post('/menus')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        date: '2026-12-15', // Même date !
        items: [{ dishId: createdDishId, isAvailable: true }],
      });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('MENU_ALREADY_EXISTS');
  });

  it('GET /menus?date=2026-12-15 : doit retourner le menu avec les détails populés du plat (200)', async () => {
    const res = await request(app)
      .get('/menus?date=2026-12-15')
      .set('Authorization', `Bearer ${studentToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.date).toBe('2026-12-15');
    expect(res.body.data.items[0].dishId).toHaveProperty('name');
  });
});
