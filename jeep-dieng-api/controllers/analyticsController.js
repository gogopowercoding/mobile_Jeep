const db = require('../config/database');
const { sendSuccess, createError } = require('../middleware/errorHandler');

/**
 * GET /api/analytics/revenue-monthly
 * Ambil revenue per bulan (12 bulan terakhir)
 */
const getMonthlyRevenue = async (req, res, next) => {
  try {
    const [rows] = await db.query(`
      SELECT 
        DATE_FORMAT(o.created_at, '%Y-%m') AS month,
        COUNT(o.id) AS total_orders,
        SUM(o.total_price) AS total_revenue,
        AVG(o.total_price) AS avg_order_value
      FROM orders o
      WHERE o.status IN ('completed', 'ongoing')
        AND o.created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
      GROUP BY DATE_FORMAT(o.created_at, '%Y-%m')
      ORDER BY month DESC
    `);
    
    return sendSuccess(res, rows, 'Monthly revenue data');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/analytics/season-analysis
 * Analisis musim ramai/sepi
 */
const getSeasonAnalysis = async (req, res, next) => {
  try {
    const [rows] = await db.query(`
      SELECT 
        DATE_FORMAT(o.created_at, '%m') AS month_number,
        DATE_FORMAT(o.created_at, '%M') AS month_name,
        COUNT(o.id) AS total_orders,
        SUM(o.total_price) AS total_revenue,
        AVG(o.total_price) AS avg_order_value
      FROM orders o
      WHERE o.status IN ('completed', 'ongoing')
      GROUP BY DATE_FORMAT(o.created_at, '%m')
      ORDER BY month_number ASC
    `);

    // Klasifikasi: Ramai (top 25%), Normal (50%), Sepi (bottom 25%)
    const sorted = [...rows].sort((a, b) => b.total_orders - a.total_orders);
    const quartile = Math.floor(sorted.length / 4);
    
    const classified = rows.map(row => {
      const index = sorted.findIndex(s => s.month_number === row.month_number);
      let season = 'normal';
      if (index < quartile) season = 'ramai';
      if (index >= sorted.length - quartile) season = 'sepi';
      
      return { ...row, season };
    });

    return sendSuccess(res, classified, 'Season analysis');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/analytics/summary
 * Ringkasan dashboard analytics
 */
const getAnalyticsSummary = async (req, res, next) => {
  try {
    // Total orders bulan ini
    const [thisMonth] = await db.query(`
      SELECT 
        COUNT(o.id) AS total_orders,
        SUM(o.total_price) AS total_revenue
      FROM orders o
      WHERE MONTH(o.created_at) = MONTH(NOW())
        AND YEAR(o.created_at) = YEAR(NOW())
        AND o.status IN ('completed', 'ongoing')
    `);

    // Total orders bulan lalu
    const [lastMonth] = await db.query(`
      SELECT 
        COUNT(o.id) AS total_orders,
        SUM(o.total_price) AS total_revenue
      FROM orders o
      WHERE MONTH(o.created_at) = MONTH(DATE_SUB(NOW(), INTERVAL 1 MONTH))
        AND YEAR(o.created_at) = YEAR(DATE_SUB(NOW(), INTERVAL 1 MONTH))
        AND o.status IN ('completed', 'ongoing')
    `);

    // Growth rate
    const lastMonthRevenue = lastMonth[0].total_revenue || 0;
    const thisMonthRevenue = thisMonth[0].total_revenue || 0;
    const growthRate = lastMonthRevenue > 0 
      ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue * 100).toFixed(2)
      : 0;

    return sendSuccess(res, {
      thisMonth: thisMonth[0],
      lastMonth: lastMonth[0],
      growthRate: parseFloat(growthRate),
    }, 'Analytics summary');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/analytics/forecast
 * Prediksi revenue bulan depan (Simple Linear Regression)
 */
const getForecastRevenue = async (req, res, next) => {
  try {
    const [history] = await db.query(`
      SELECT 
        DATE_FORMAT(o.created_at, '%Y-%m') AS month,
        SUM(o.total_price) AS revenue
      FROM orders o
      WHERE o.status IN ('completed', 'ongoing')
        AND o.created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
      GROUP BY DATE_FORMAT(o.created_at, '%Y-%m')
      ORDER BY month ASC
    `);

    const n = history.length;

    // Kalau data kurang dari 2, tidak bisa regresi
    if (n < 2) {
      return sendSuccess(res, {
        history,
        forecast: 0,
        trend: 'stabil',
        confidence: 0.75,
      }, 'Revenue forecast');
    }

    const x = Array.from({length: n}, (_, i) => i + 1);
    const y = history.map(h => Number(h.revenue)); // ← fix: konversi ke Number

    const sumX  = x.reduce((a, b) => a + b, 0);
    const sumY  = y.reduce((a, b) => a + b, 0);
    const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0);
    const sumX2 = x.reduce((sum, xi) => sum + xi * xi, 0);

    const denom = (n * sumX2 - sumX * sumX);
    
    // Hindari division by zero
    if (denom === 0) {
      return sendSuccess(res, {
        history,
        forecast: sumY / n, // pakai rata-rata saja
        trend: 'stabil',
        confidence: 0.75,
      }, 'Revenue forecast');
    }

    const slope     = (n * sumXY - sumX * sumY) / denom;
    const intercept = (sumY - slope * sumX) / n;

    // SESUDAH
    const nextMonthForecast = slope * (n + 1) + intercept;
    const avgRevenue = sumY / n;

    return sendSuccess(res, {
      history,
      forecast: nextMonthForecast > 0 ? nextMonthForecast : avgRevenue,
      trend: slope > 0 ? 'naik' : 'turun',
      confidence: 0.75,
    }, 'Revenue forecast');

  } catch (err) {
    next(err);
  }
};

module.exports = {
  getMonthlyRevenue,
  getSeasonAnalysis,
  getAnalyticsSummary,
  getForecastRevenue,
};