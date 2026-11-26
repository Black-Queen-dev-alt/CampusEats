import mongoose from 'mongoose';
import request from 'supertest';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { signAccessToken } from '../src/common/utils/jwt';
import { app } from '../src/app';
import { User } from '../src/modules/users/user.model';
import { Dish } from '../src/modules/dishes/dish.model';
import { Menu } from '../src/modules/menus/menu.model';
import { Order } from '../src/modules/orders/order.model';
import { TimeSlot } from '../src/modules/time-slots/time-slot.model';

let mongo: MongoMemoryServer;

describe('API authentication and order rules', () => {
  beforeAll(async () => {
    mongo = await MongoMemoryServer.create();
    await mongoose.connect(mongo.getUri());
  }, 60_000);

  afterAll(async () => {
    await mongoose.connection.dropDatabase();
    await mongoose.disconnect();
    await mongo.stop();
  });

  it('creates only student accounts and rotates refresh tokens once, including concurrent reuse', async () => {
    const oversizedBody = await request(app)
      .post('/auth/register')
      .send({ payload: 'x'.repeat(12_000) });
    expect(oversizedBody.status).toBe(413);
    expect(oversizedBody.body.error.code).toBe('PAYLOAD_TOO_LARGE');

    const malformedJson = await request(app)
      .post('/auth/register')
      .set('Content-Type', 'application/json')
      .send('{"email":');
    expect(malformedJson.status).toBe(400);

    const registration = await request(app).post('/auth/register').send({
      email: '  API-TEST@EXAMPLE.EDU ',
      password: 'secure-password-1',
      fullName: 'Test Student',
      role: 'admin',
      extraField: 'discarded',
    });

    expect(registration.status).toBe(201);
    expect(registration.body.data.user.role).toBe('etudiant');
    expect(registration.body.data.user).not.toHaveProperty('password');
    expect(registration.body.data).not.toHaveProperty('extraField');

    const initialRefreshToken = registration.body.data.refreshToken as string;
    const rotated = await Promise.all(
      Array.from({ length: 2 }, () =>
        request(app).post('/auth/refresh').send({ refreshToken: initialRefreshToken }),
      ),
    );
    expect(rotated.filter((response) => response.status === 200)).toHaveLength(1);
    expect(rotated.filter((response) => response.status === 401)).toHaveLength(1);

    const newRefreshToken = rotated.find((response) => response.status === 200)!.body.data
      .refreshToken as string;
    const logout = await request(app)
      .post('/auth/logout')
      .send({ refreshToken: newRefreshToken });
    expect(logout.status).toBe(204);

    const reuseAfterLogout = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: newRefreshToken });
    expect(reuseAfterLogout.status).toBe(401);
  }, 30_000);

  it('enforces menu stock atomically, ownership, staff-only status changes, and releases reservations on cancellation', async () => {
    const users = await User.create([
      {
        email: 'student-a@example.edu',
        password: 'already-hashed',
        fullName: 'Student A',
        role: 'etudiant',
        status: 'actif',
      },
      {
        email: 'student-b@example.edu',
        password: 'already-hashed',
        fullName: 'Student B',
        role: 'etudiant',
        status: 'actif',
      },
      {
        email: 'staff@example.edu',
        password: 'already-hashed',
        fullName: 'Staff',
        role: 'personnel',
        status: 'actif',
      },
      {
        email: 'admin@example.edu',
        password: 'already-hashed',
        fullName: 'Admin',
        role: 'admin',
        status: 'actif',
      },
    ]);
    const studentTokens = users.slice(0, 2).map((user) =>
      signAccessToken({
        userId: user.id,
        role: user.role,
        email: user.email,
      }),
    );
    const staffToken = signAccessToken({
      userId: users[2].id,
      role: users[2].role,
      email: users[2].email,
    });
    const adminToken = signAccessToken({
      userId: users[3].id,
      role: users[3].role,
      email: users[3].email,
    });

    const dish = await Dish.create({
      name: 'Concurrency Test Dish',
      description: 'Dish created for order tests',
      priceInCents: 500,
      category: 'plat',
    });
    const menuDate = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 10);
    const menu = await Menu.create({
      date: menuDate,
      isPublished: true,
      items: [{ dishId: dish.id, isAvailable: true, dailyStockLimit: 1 }],
    });
    const slot = await TimeSlot.create({
      date: menuDate,
      startTime: '23:50',
      endTime: '23:59',
      capacity: 10,
    });

    const payload = {
      menuId: menu.id,
      slotId: slot.id,
      lines: [{ dishId: dish.id, quantity: 1 }],
    };
    const attempts = await Promise.all(
      studentTokens.map((token) =>
        request(app).post('/orders').set('Authorization', `Bearer ${token}`).send(payload),
      ),
    );
    const successfulIndex = attempts.findIndex((response) => response.status === 201);
    const rejectedIndex = attempts.findIndex((response) => response.status === 409);

    expect(successfulIndex).not.toBe(-1);
    expect(rejectedIndex).not.toBe(-1);
    expect(attempts[rejectedIndex].body.success).toBe(false);
    expect((await Menu.findById(menu.id))!.items[0].dailyStockUsed).toBe(1);
    expect((await TimeSlot.findById(slot.id))!.reservedCount).toBe(1);

    const orderId = attempts[successfulIndex].body.data.id as string;
    const ownerToken = studentTokens[successfulIndex];
    const otherStudentToken = studentTokens[rejectedIndex];
    expect(attempts[successfulIndex].body.data.lines[0]).toMatchObject({
      dishName: 'Concurrency Test Dish',
      unitPriceInCents: 500,
    });

    await Dish.findByIdAndUpdate(dish.id, { priceInCents: 900 });
    const orderDetail = await request(app)
      .get(`/orders/${orderId}`)
      .set('Authorization', `Bearer ${ownerToken}`);
    expect(orderDetail.status).toBe(200);
    expect(orderDetail.body.data.canCancel).toBe(true);
    expect(orderDetail.body.data.slotId).toMatchObject({
      date: menuDate,
      startTime: '23:50',
      endTime: '23:59',
    });
    expect(orderDetail.body.data.lines[0]).toMatchObject({
      dishName: 'Concurrency Test Dish',
      unitPriceInCents: 500,
    });

    const ownerHistory = await request(app)
      .get('/orders')
      .set('Authorization', `Bearer ${ownerToken}`);
    expect(ownerHistory.status).toBe(200);
    expect(ownerHistory.body.data[0].canCancel).toBe(true);

    const forbiddenDetail = await request(app)
      .get(`/orders/${orderId}`)
      .set('Authorization', `Bearer ${otherStudentToken}`);
    expect(forbiddenDetail.status).toBe(404);

    const staffSlotOrders = await request(app)
      .get(`/time-slots/${slot.id}/orders?page=1&limit=10`)
      .set('Authorization', `Bearer ${staffToken}`);
    expect(staffSlotOrders.status).toBe(200);
    expect(staffSlotOrders.body.data).toHaveLength(1);

    const forbiddenSlotOrders = await request(app)
      .get(`/time-slots/${slot.id}/orders`)
      .set('Authorization', `Bearer ${otherStudentToken}`);
    expect(forbiddenSlotOrders.status).toBe(403);

    const otherHistory = await request(app)
      .get('/orders')
      .set('Authorization', `Bearer ${otherStudentToken}`);
    expect(otherHistory.status).toBe(200);
    expect(otherHistory.body.data).toHaveLength(0);

    const unauthorizedCancel = await request(app)
      .post(`/orders/${orderId}/cancel`)
      .set('Authorization', `Bearer ${otherStudentToken}`);
    expect(unauthorizedCancel.status, JSON.stringify(unauthorizedCancel.body)).toBe(403);

    const forbiddenStatusChange = await request(app)
      .patch(`/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ status: 'preparing' });
    expect(forbiddenStatusChange.status).toBe(403);

    const preparing = await request(app)
      .patch(`/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${staffToken}`)
      .send({ status: 'preparing' });
    expect(preparing.status).toBe(200);
    expect(preparing.body.data.status).toBe('preparing');

    const invalidTransition = await request(app)
      .patch(`/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${staffToken}`)
      .send({ status: 'received' });
    expect(invalidTransition.status).toBe(409);

    const loweredMenuStock = await request(app)
      .patch(`/menus/${menu.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        items: [{ dishId: dish.id, isAvailable: true, dailyStockLimit: 0 }],
      });
    expect(loweredMenuStock.status).toBe(409);

    const updatedMenu = await request(app)
      .patch(`/menus/${menu.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        items: [{ dishId: dish.id, isAvailable: true, dailyStockLimit: 2 }],
      });
    expect(updatedMenu.status).toBe(200);
    expect((await Menu.findById(menu.id))!.items[0].dailyStockUsed).toBe(1);

    const movedBookedSlot = await request(app)
      .patch(`/time-slots/${slot.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ date: new Date(Date.now() + 40 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10) });
    expect(movedBookedSlot.status).toBe(409);

    const cancelled = await request(app)
      .post(`/orders/${orderId}/cancel`)
      .set('Authorization', `Bearer ${ownerToken}`);
    expect(cancelled.status).toBe(200);
    expect((await Menu.findById(menu.id))!.items[0].dailyStockUsed).toBe(0);
    expect((await TimeSlot.findById(slot.id))!.reservedCount).toBe(0);

    const secondCancellation = await request(app)
      .post(`/orders/${orderId}/cancel`)
      .set('Authorization', `Bearer ${ownerToken}`);
    expect(secondCancellation.status).toBe(409);
  }, 30_000);
});
