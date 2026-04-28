// routes/vouchers.js
const express = require('express');
const router  = express.Router();
const { authenticate } = require('../middleware/auth');
const { validateVoucher } = require('../controllers/voucherController');

// GET /api/vouchers/validate?code=KODE123
router.get('/validate', authenticate, validateVoucher);

module.exports = router;