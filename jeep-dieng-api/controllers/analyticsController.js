const db = require('../config/database');
const { sendSuccess, createError } = require('../middleware/errorHandler');
const ss = require('simple-statistics');

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
 * Calculate Z-Score for statistical analysis
 * Membantu menentukan outliers dan klasifikasi
 */
const calculateZScore = (value, mean, stdDev) => {
  if (stdDev === 0) return 0;
  return (value - mean) / stdDev;
};

/**
 * GET /api/analytics/season-analysis
 * Analisis musim ramai/sepi menggunakan Z-Score
 * IMPROVEMENT: Ganti kuartil manual dengan Z-score berbasis standar deviasi
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

    if (rows.length === 0) {
      return sendSuccess(res, [], 'Season analysis');
    }

    // Extract nilai total_orders untuk perhitungan statistik
    const orderCounts = rows.map(r => r.total_orders);
    
    // Hitung mean dan standard deviation menggunakan simple-statistics
    const mean = ss.mean(orderCounts);
    const stdDev = ss.standardDeviation(orderCounts);

    // Klasifikasi berdasarkan Z-Score:
    // - Z > +0.67 (top 25%) = ramai
    // - Z < -0.67 (bottom 25%) = sepi
    // - Lainnya = normal
    const classified = rows.map(row => {
      const zScore = calculateZScore(row.total_orders, mean, stdDev);
      let season = 'normal';
      
      if (zScore > 0.67) {
        season = 'ramai';
      } else if (zScore < -0.67) {
        season = 'sepi';
      }
      
      return { 
        ...row, 
        season,
        z_score: parseFloat(zScore.toFixed(2)) // info tambahan untuk debugging
      };
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
 * Exponential Smoothing dengan Holt's Linear Trend
 * IMPROVEMENT: Ganti simple linear regression dengan exponential smoothing
 * Lebih sesuai untuk time series dengan trend
 */
const exponentialSmoothing = (values, alpha = 0.3, beta = 0.1) => {
  if (values.length < 2) return { forecast: values[0] || 0, trend: 0 };

  let level = values[0];
  let trend = 0;

  // Holt's Linear Trend method
  for (let i = 1; i < values.length; i++) {
    const prevLevel = level;
    level = alpha * values[i] + (1 - alpha) * (prevLevel + trend);
    trend = beta * (level - prevLevel) + (1 - beta) * trend;
  }

  // Forecast untuk periode berikutnya
  const forecast = level + trend;
  
  return { forecast, trend, level };
};

/**
 * Hitung confidence score berbasis MAE (Mean Absolute Error)
 * dan data quality
 */
const calculateConfidence = (values, forecasted) => {
  if (values.length < 3) return 0.4; // Low confidence jika data terlalu sedikit

  // Hitung MAE terhadap simple moving average
  const ma3 = [];
  for (let i = 2; i < values.length; i++) {
    ma3.push((values[i] + values[i-1] + values[i-2]) / 3);
  }

  if (ma3.length === 0) return 0.5;

  // MAPE (Mean Absolute Percentage Error)
  let sumAPE = 0;
  for (let i = 0; i < ma3.length; i++) {
    const actual = values[i + 2];
    if (actual !== 0) {
      sumAPE += Math.abs((actual - ma3[i]) / actual);
    }
  }

  const mape = sumAPE / ma3.length;

  // Convert MAPE to confidence (inverted & scaled)
  // MAPE kecil = confidence tinggi
  // confidence = 1 / (1 + mape)
  let confidence = 1 / (1 + mape);
  
  // Bonus confidence jika trend konsisten (tidak bergejolak)
  const volatility = ss.variance(values);
  const mean = ss.mean(values);
  const coefficientOfVariation = (Math.sqrt(volatility) / mean) || 0;
  
  // Jika CV kecil = data stabil = confidence lebih tinggi
  if (coefficientOfVariation < 0.3) {
    confidence = Math.min(0.95, confidence + 0.15);
  } else if (coefficientOfVariation > 0.6) {
    // Data volatile = kurangi confidence
    confidence = Math.max(0.2, confidence - 0.2);
  }

  return Math.min(0.99, Math.max(0.1, confidence));
};

/**
 * GET /api/analytics/forecast
 * Prediksi revenue bulan depan (Exponential Smoothing + Statistical Confidence)
 * IMPROVEMENT: Ganti simple linear regression dengan exponential smoothing
 * dan hitung confidence secara real-time
 */
const getForecastRevenue = async (req, res, next) => {
  try {
    const [history] = await db.query(`
      SELECT 
        DATE_FORMAT(o.created_at, '%Y-%m') AS month,
        SUM(o.total_price) AS revenue
      FROM orders o
      WHERE o.status IN ('completed', 'ongoing')
        AND o.created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
      GROUP BY DATE_FORMAT(o.created_at, '%Y-%m')
      ORDER BY month ASC
    `);

    const n = history.length;

    if (n === 0) {
      return sendSuccess(res, {
        history: [],
        forecast: 0,
        baselineAverage: 0,
        trend: 'stabil',
        confidence: 0,
      }, 'Revenue forecast');
    }

    // Convert revenue ke array angka
    const revenues = history.map(h => Number(h.revenue) || 0);
    
    // Hitung baseline average
    const baselineAverage = ss.mean(revenues);

    if (n < 2) {
      return sendSuccess(res, {
        history,
        forecast: baselineAverage,
        baselineAverage,
        trend: 'stabil',
        confidence: 0.3,
      }, 'Revenue forecast');
    }

    // Gunakan exponential smoothing untuk forecast
    const { forecast: nextMonthForecast, trend: trendValue } = exponentialSmoothing(revenues);

    // Hitung confidence berdasarkan statistical metrics
    const confidence = calculateConfidence(revenues, nextMonthForecast);

    // Tentukan trend direction
    let trendDirection = 'stabil';
    if (trendValue > baselineAverage * 0.05) {
      trendDirection = 'naik';
    } else if (trendValue < -baselineAverage * 0.05) {
      trendDirection = 'turun';
    }

    // Validasi forecast (tidak boleh negatif)
    const finalForecast = nextMonthForecast > 0 ? nextMonthForecast : baselineAverage;

    return sendSuccess(res, {
      history,
      forecast: Math.round(finalForecast),
      baselineAverage: Math.round(baselineAverage),
      trend: trendDirection,
      confidence: parseFloat(confidence.toFixed(3)),
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