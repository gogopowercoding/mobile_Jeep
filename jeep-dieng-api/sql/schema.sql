-- ============================================================
--  Booking Jeep Wisata Dieng — Database Schema
--  Engine: MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS db_jp_dieng
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE db_jp_dieng;

-- ─── USERS ──────────────────────────────────────────────────
-- role: 'pelanggan' | 'admin' | 'supir'
CREATE TABLE users (
  id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  name        VARCHAR(100)    NOT NULL,
  email       VARCHAR(150)    NOT NULL UNIQUE,
  password    VARCHAR(255)    NOT NULL,          -- bcrypt hash
  role        ENUM('pelanggan','admin','supir')
              NOT NULL DEFAULT 'pelanggan',
  phone       VARCHAR(20)     NULL,
  avatar      VARCHAR(255)    NULL,
  is_active   TINYINT(1)      NOT NULL DEFAULT 1,
  created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
              ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_email (email),
  INDEX idx_role  (role)
) ENGINE=InnoDB;

-- ─── PACKAGES ───────────────────────────────────────────────
CREATE TABLE packages (
  id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  name        VARCHAR(150)    NOT NULL,
  description TEXT            NULL,
  price       DECIMAL(12,2)   NOT NULL,
  duration    INT UNSIGNED    NOT NULL COMMENT 'duration in hours',
  image       VARCHAR(255)    NULL,
  is_active   TINYINT(1)      NOT NULL DEFAULT 1,
  created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
              ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- ─── ORDERS ─────────────────────────────────────────────────
-- status flow: pending → confirmed → ongoing → completed | cancelled
-- driver_id references users WHERE role = 'supir'
CREATE TABLE orders (
  id           INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  user_id      INT UNSIGNED    NOT NULL,
  package_id   INT UNSIGNED    NOT NULL,
  driver_id    INT UNSIGNED    NULL,
  booking_date DATE            NOT NULL,
  total_price  DECIMAL(12,2)   NOT NULL,
  status       ENUM('pending','confirmed','ongoing','completed','cancelled')
               NOT NULL DEFAULT 'pending',
  latitude     DECIMAL(10,8)   NULL COMMENT 'customer pickup latitude',
  longitude    DECIMAL(11,8)   NULL COMMENT 'customer pickup longitude',
  notes        TEXT            NULL,
  created_at   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
               ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_user_id   (user_id),
  INDEX idx_driver_id (driver_id),
  INDEX idx_status    (status),
  CONSTRAINT fk_orders_user    FOREIGN KEY (user_id)    REFERENCES users    (id) ON DELETE RESTRICT,
  CONSTRAINT fk_orders_package FOREIGN KEY (package_id) REFERENCES packages (id) ON DELETE RESTRICT,
  CONSTRAINT fk_orders_driver  FOREIGN KEY (driver_id)  REFERENCES users    (id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ─── PAYMENTS ───────────────────────────────────────────────
-- currency: 'IDR' | 'USD' | 'EUR'
-- payment_status: pending → paid | failed | refunded
CREATE TABLE payments (
  id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  order_id        INT UNSIGNED    NOT NULL UNIQUE,
  amount          DECIMAL(12,2)   NOT NULL,
  currency        VARCHAR(3)      NOT NULL DEFAULT 'IDR',
  payment_status  ENUM('pending','paid','failed','refunded')
                  NOT NULL DEFAULT 'pending',
  payment_method  VARCHAR(50)     NULL  COMMENT 'e.g. transfer, qris, cash',
  proof_image     VARCHAR(255)    NULL,
  paid_at         TIMESTAMP       NULL,
  created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_order_id (order_id),
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── NOTIFICATIONS ──────────────────────────────────────────
CREATE TABLE notifications (
  id         INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  user_id    INT UNSIGNED   NOT NULL,
  title      VARCHAR(150)   NOT NULL,
  message    TEXT           NOT NULL,
  is_read    TINYINT(1)     NOT NULL DEFAULT 0,
  created_at TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_user_id (user_id),
  CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── FEEDBACK ───────────────────────────────────────────────
CREATE TABLE feedback (
  id         INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  user_id    INT UNSIGNED   NOT NULL,
  order_id   INT UNSIGNED   NULL,
  message    TEXT           NOT NULL,
  rating     TINYINT        NOT NULL DEFAULT 5 COMMENT '1-5',
  created_at TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_user_id (user_id),
  CONSTRAINT fk_feedback_user  FOREIGN KEY (user_id)  REFERENCES users  (id) ON DELETE CASCADE,
  CONSTRAINT fk_feedback_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE SET NULL,
  CONSTRAINT chk_rating        CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- ─── SEED DATA ───────────────────────────────────────────────
-- Password: Admin@123 (bcrypt pre-hashed, update in production)
INSERT INTO users (name, email, password, role) VALUES
  ('Admin Dieng',  'admin@jeepdieng.com',  'admin123', 'admin'),
  ('Supir Budi',   'budi@jeepdieng.com',   'supir123', 'supir'),
  ('Pelanggan Ani','ani@example.com',       'pelanggan123', 'pelanggan');

INSERT INTO packages (name, description, price, duration, image) VALUES
  ('Dieng Explorer', 'Kunjungi Kawah Sikidang, Telaga Warna & Candi Arjuna', 350000, 4, 'dieng-explorer.jpg'),
  ('Sunrise Sikunir', 'Trek pagi ke Bukit Sikunir, menikmati golden sunrise', 250000, 3, 'sikunir-sunrise.jpg'),
  ('Full Day Dieng',  'Paket lengkap seluruh destinasi wisata Dieng', 500000, 8, 'full-day.jpg');
