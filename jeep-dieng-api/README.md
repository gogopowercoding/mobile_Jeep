# 🚙 Booking Jeep Wisata Dieng — Backend API

Node.js + Express + MySQL  
Port default: `3000`

---

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Siapkan environment
cp .env.example .env
# Edit .env sesuai konfigurasi MySQL Anda

# 3. Import database
mysql -u root -p < sql/schema.sql

# 4. Jalankan server
npm run dev       # development (nodemon)
npm start         # production
```

---

## Struktur Folder

```
jeep-dieng-api/
├── server.js                 ← Entry point
├── config/
│   └── database.js           ← MySQL connection pool
├── controllers/
│   ├── authController.js     ← Register, login, profile
│   ├── orderController.js    ← CRUD orders, assign driver, update status
│   ├── packageController.js  ← CRUD paket wisata (admin)
│   ├── paymentController.js  ← Payment, currency convert
│   └── notificationController.js ← Notifikasi & feedback
├── middleware/
│   ├── auth.js               ← JWT authenticate + authorize(role)
│   └── errorHandler.js       ← Centralized error handler
├── routes/
│   ├── auth.js
│   ├── packages.js
│   ├── orders.js
│   └── extra.js              ← payments + notifications
├── sql/
│   └── schema.sql            ← DDL + seed data
└── uploads/                  ← Gambar paket (auto-created)
```

---

## Endpoint Reference

### Auth
| Method | Endpoint        | Auth | Role        | Deskripsi             |
|--------|-----------------|------|-------------|-----------------------|
| POST   | /api/register   | ✗    | —           | Daftar akun baru      |
| POST   | /api/login      | ✗    | —           | Login, dapat token    |
| GET    | /api/profile    | ✓    | semua       | Lihat profil sendiri  |
| PUT    | /api/profile    | ✓    | semua       | Update profil         |

### Packages
| Method | Endpoint            | Auth | Role    | Deskripsi              |
|--------|---------------------|------|---------|------------------------|
| GET    | /api/packages       | ✗    | —       | Daftar semua paket     |
| GET    | /api/packages/:id   | ✗    | —       | Detail paket           |
| POST   | /api/packages       | ✓    | admin   | Tambah paket           |
| PUT    | /api/packages/:id   | ✓    | admin   | Update paket           |
| DELETE | /api/packages/:id   | ✓    | admin   | Hapus paket (soft)     |

### Orders
| Method | Endpoint                    | Auth | Role             | Deskripsi                 |
|--------|-----------------------------|------|------------------|---------------------------|
| POST   | /api/orders                 | ✓    | pelanggan        | Buat pesanan baru         |
| GET    | /api/orders/user/:user_id   | ✓    | pelanggan/admin  | Pesanan per user          |
| GET    | /api/orders/:id             | ✓    | semua            | Detail pesanan            |
| GET    | /api/orders/drivers         | ✓    | admin            | Daftar supir aktif        |
| POST   | /api/orders/assign-driver   | ✓    | admin            | Assign supir ke pesanan   |
| POST   | /api/orders/update-status   | ✓    | admin, supir     | Update status perjalanan  |
| PUT    | /api/orders/:id/location    | ✓    | pelanggan        | Update lokasi GPS         |

### Payments
| Method | Endpoint                         | Auth | Role    | Deskripsi              |
|--------|----------------------------------|------|---------|------------------------|
| GET    | /api/payments/:order_id          | ✓    | semua   | Detail pembayaran      |
| POST   | /api/payments/:order_id/confirm  | ✓    | admin   | Konfirmasi bayar       |
| GET    | /api/convert                     | ✗    | —       | Konversi mata uang     |

> Query: `/api/convert?amount=350000&from=IDR&to=USD`

### Notifications & Feedback
| Method | Endpoint                      | Auth | Role    | Deskripsi               |
|--------|-------------------------------|------|---------|-------------------------|
| GET    | /api/notifications            | ✓    | semua   | Daftar notifikasi       |
| PUT    | /api/notifications/read-all   | ✓    | semua   | Tandai semua dibaca     |
| PUT    | /api/notifications/:id/read   | ✓    | semua   | Tandai satu dibaca      |
| POST   | /api/notifications/feedback   | ✓    | semua   | Kirim feedback          |
| GET    | /api/notifications/feedback/all | ✓  | admin   | Semua feedback + stats  |

---

## Contoh Request & Response

### POST /api/register
```json
// Request
{
  "name": "Budi Santoso",
  "email": "budi@example.com",
  "password": "password123",
  "phone": "081234567890"
}

// Response 201
{
  "success": true,
  "message": "Registrasi berhasil",
  "data": {
    "token": "eyJhbGci...",
    "user": { "id": 4, "name": "Budi Santoso", "email": "budi@example.com", "role": "pelanggan" }
  }
}
```

### POST /api/orders
```json
// Headers: Authorization: Bearer <token>
// Request
{
  "package_id": 1,
  "booking_date": "2025-07-15",
  "latitude": -7.2097,
  "longitude": 109.9213,
  "notes": "Jemput di hotel jam 05.00"
}
```

### POST /api/orders/update-status
```json
// Headers: Authorization: Bearer <token>  (supir/admin)
{
  "order_id": 5,
  "status": "ongoing"
}
// status: pending | confirmed | ongoing | completed | cancelled
```

---

## ERD Relasi

```
users (1) ──── (N) orders          user_id FK → users.id
users (1) ──── (N) orders          driver_id FK → users.id (role='supir')
packages (1) ── (N) orders         package_id FK → packages.id
orders (1) ──── (1) payments       order_id FK → orders.id
users (1) ──── (N) notifications   user_id FK → users.id
users (1) ──── (N) feedback        user_id FK → users.id
orders (1) ──── (N) feedback       order_id FK → orders.id
```

---

## Default Test Accounts (seed)
| Email                   | Password   | Role       |
|-------------------------|------------|------------|
| admin@jeepdieng.com     | Admin@123  | admin      |
| budi@jeepdieng.com      | Admin@123  | supir      |
| ani@example.com         | Admin@123  | pelanggan  |
