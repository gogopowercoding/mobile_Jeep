require('dotenv').config();
const express  = require('express');
const cors     = require('cors');
const path     = require('path');
const fs       = require('fs');

const app = express();

// ─── Pastikan folder uploads ada ──────────────────────────────
const uploadPath = process.env.UPLOAD_PATH || './uploads';
if (!fs.existsSync(uploadPath)) fs.mkdirSync(uploadPath, { recursive: true });

// ─── Middleware Global ─────────────────────────────────────────
app.use(cors({
  origin:  '*',                            // Ganti dengan domain Flutter di production
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ─── Static files (gambar paket) ──────────────────────────────
app.use('/uploads', express.static(path.resolve(uploadPath)));

// ─── Routes ───────────────────────────────────────────────────
const authRoutes    = require('./routes/auth');
const packageRoutes = require('./routes/packages');
const orderRoutes   = require('./routes/orders');

// Payment & notification dari extra.js (karena berbagi satu file)
const { paymentRouter, notificationRouter } = require('./routes/extra');

app.use('/api',               authRoutes);
app.use('/api/packages',      packageRoutes);
app.use('/api/orders',        orderRoutes);
app.use('/api/payments',      paymentRouter);
app.use('/api/notifications', notificationRouter);
app.use('/api', require('./routes/packageSchedule'));

// ─── Currency convert shortcut ────────────────────────────────
// GET /api/convert?amount=350000&from=IDR&to=USD
const { convertCurrency } = require('./controllers/paymentController');
app.get('/api/convert', convertCurrency);

// ─── Game routes ───────────────────────────────────────────────
const gameRoutes = require('./routes/game');
app.use('/api/game', gameRoutes);

// ─── Voucher routes ────────────────────────────────────────────
const voucherRoutes = require('./routes/vouchers');
app.use('/api/vouchers', voucherRoutes);

// ─── Health check ─────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Jeep Dieng API is running 🚙',
    env:     process.env.NODE_ENV,
    time:    new Date().toISOString(),
  });
});

// ─── 404 handler ──────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} tidak ditemukan` });
});

// ─── Error handler (harus paling akhir) ───────────────────────
const { errorHandler } = require('./middleware/errorHandler');
app.use(errorHandler);

// ─── Start server ─────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚙  Jeep Dieng API running on http://localhost:${PORT}`);
  console.log(`📋  Docs: http://localhost:${PORT}/api/health`);
});

module.exports = app;