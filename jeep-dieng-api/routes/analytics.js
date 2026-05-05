const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const {
  getMonthlyRevenue,
  getSeasonAnalysis,
  getAnalyticsSummary,
  getForecastRevenue,
} = require('../controllers/analyticsController');

// ── Admin only ──────────────────────────────────────
router.get('/revenue-monthly',  authenticate, authorize('admin'), getMonthlyRevenue);
router.get('/season-analysis',  authenticate, authorize('admin'), getSeasonAnalysis);
router.get('/summary',          authenticate, authorize('admin'), getAnalyticsSummary);
router.get('/forecast',         authenticate, authorize('admin'), getForecastRevenue);

module.exports = router;