import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../src/app';
import { env } from '../src/config/env';
import { signAccessToken } from '../src/common/utils/jwt';
import { User } from '../src/modules/users/user.model';
import { Dish } from '../src/modules/dishes/dish.model';
import { Menu } from '../src/modules/menus/menu.model';
import { Device } from '../src/modules/devices/device.model';
import { TimeSlot } from '../src/modules/time-slots/time-slot.model';

const dateInDays = (days: number) =>
  new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
const menuTestDate = dateInDays(30 + Math.floor(Math.random() * 365));
const slotTestDate = dateInDays(30 + Math.floor(Math.random() * 365));

describe('Tests Développeur 2 : Catalogue & Menus du Jour (Vitest)', () => {
  let adminToken: string;
  let studentToken: string;
  let createdDishId: string;
  let createdMenuId: string;
  let createdTimeSlotId: string;
  let createdDeviceToken: string;
  let createdUserIds: string[] = [];

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
    createdUserIds = [adminUser.id, studentUser.id];

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
    if (createdDishId) await Dish.deleteOne({ _id: createdDishId });
    if (createdMenuId) await Menu.deleteOne({ _id: createdMenuId });
    if (createdTimeSlotId) await TimeSlot.deleteOne({ _id: createdTimeSlotId });
    if (createdDeviceToken) await Device.deleteOne({ fcmToken: createdDeviceToken });
    if (createdUserIds.length) await User.deleteMany({ _id: { $in: createdUserIds } });
  });

  it('GET/PATCH /me : protège le profil et ne permet pas de modifier son rôle', async () => {
    const profile = await request(app)
      .patch('/me')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ fullName: 'Étudiant Modifié', role: 'admin' });

    expect(profile.status).toBe(200);
    expect(profile.body.data.fullName).toBe('Étudiant Modifié');
    expect(profile.body.data.role).toBe('etudiant');

    const forbiddenAdminAction = await request(app)
      .post('/admin/users')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        email: 'forbidden-staff@example.edu',
        password: 'secure-password',
        fullName: 'Forbidden Staff',
        role: 'personnel',
      });
    expect(forbiddenAdminAction.status).toBe(403);
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
        role: 'admin',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('id');
    expect(res.body.data.priceInCents).toBe(1500);
    expect(res.body.data).not.toHaveProperty('role');

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
        date: menuTestDate,
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
    expect(res.body.data.date).toBe(menuTestDate);
    createdMenuId = res.body.data.id;
  });

  it('les opérations admin des menus et créneaux refusent les étudiants, et les appareils exigent un jeton FCM valide', async () => {
    const forbiddenMenu = await request(app)
      .post('/menus')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ date: slotTestDate, items: [{ dishId: createdDishId }] });
    expect(forbiddenMenu.status).toBe(403);

    const forbiddenSlot = await request(app)
      .post('/time-slots')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        date: slotTestDate,
        startTime: '12:00',
        endTime: '12:15',
        capacity: 20,
      });
    expect(forbiddenSlot.status).toBe(403);

    const invalidDate = await request(app)
      .get('/time-slots?date=2026-02-30')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(invalidDate.status).toBe(422);

    const adminSlot = await request(app)
      .post('/time-slots')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        date: slotTestDate,
        startTime: '23:50',
        endTime: '23:59',
        capacity: 20,
      });
    expect(adminSlot.status).toBe(201);
    createdTimeSlotId = adminSlot.body.data.id;

    const slotList = await request(app)
      .get(`/time-slots?date=${slotTestDate}&page=1&limit=10&unknown=ignored`)
      .set('Authorization', `Bearer ${studentToken}`);
    expect(slotList.status).toBe(200);
    expect(slotList.body.pagination.total).toBeGreaterThanOrEqual(1);

    const missingDeviceToken = await request(app)
      .post('/devices')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({});
    expect(missingDeviceToken.status).toBe(422);
    expect(missingDeviceToken.body.success).toBe(false);

    createdDeviceToken = `fcm-test-${Date.now()}`;
    const device = await request(app)
      .post('/devices')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ fcmToken: createdDeviceToken });
    expect(device.status).toBe(200);
    expect(device.body.success).toBe(true);
  });

  it('POST /menus : doit interdire les doublons de date avec 409 Conflict (Règle Section 8)', async () => {
    const res = await request(app)
      .post('/menus')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        date: menuTestDate, // Même date !
        items: [{ dishId: createdDishId, isAvailable: true }],
      });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('MENU_ALREADY_EXISTS');
  });

  it('GET /menus : doit retourner le menu avec les détails populés du plat (200)', async () => {
    const res = await request(app)
      .get(`/menus?date=${menuTestDate}`)
      .set('Authorization', `Bearer ${studentToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.date).toBe(menuTestDate);
    expect(res.body.data.items[0].dishId).toHaveProperty('name');
  });
});
