// controllers/voucherController.js
const db = require('../config/database');

// GET /api/vouchers/validate?code=KODE123
const validateVoucher = async (req, res) => {
  try {
    const { code } = req.query;
    if (!code) return res.status(400).json({ success: false, message: 'Kode voucher wajib diisi' });

    const [rows] = await db.query(
      `SELECT * FROM vouchers
       WHERE code = ? AND is_active = 1
         AND (valid_from IS NULL OR valid_from <= CURDATE())
         AND (valid_until IS NULL OR valid_until >= CURDATE())
         AND (usage_limit IS NULL OR used_count < usage_limit)
       LIMIT 1`,
      [code.toUpperCase()]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Voucher tidak valid atau sudah kadaluarsa' });
    }

    const v = rows[0];
    return res.json({
      success: true,
      voucher: {
        id:            v.id,
        code:          v.code,
        type:          v.type,          
        value:         v.value,         
        min_order:     v.min_order,     
        max_discount:  v.max_discount,  
        description:   v.description,
      },
    });
  } catch (err) {
    console.error('validateVoucher error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { validateVoucher };