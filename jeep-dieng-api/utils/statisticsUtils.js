/**
 * Statistical Analysis Utilities
 * Untuk perhitungan ML dan analytics features
 */

const ss = require('simple-statistics');

/**
 * Calculate Z-Score untuk statistical classification
 * Z-Score = (value - mean) / stdDev
 */
const calculateZScore = (value, mean, stdDev) => {
  if (stdDev === 0) return 0;
  return (value - mean) / stdDev;
};

/**
 * Exponential Smoothing dengan Holt's Linear Trend
 * Untuk time series forecasting dengan trend
 */
const exponentialSmoothing = (values, alpha = 0.3, beta = 0.1) => {
  if (values.length < 1) return { forecast: 0, trend: 0, level: 0 };
  if (values.length < 2) return { forecast: values[0] || 0, trend: 0, level: values[0] || 0 };

  let level = values[0];
  let trend = 0;

  // Holt's Linear Trend method
  for (let i = 1; i < values.length; i++) {
    const prevLevel = level;
    level = alpha * values[i] + (1 - alpha) * (prevLevel + trend);
    trend = beta * (level - prevLevel) + (1 - beta) * trend;
  }

  const forecast = level + trend;

  return {
    forecast: Math.max(0, forecast), // forecast tidak boleh negatif
    trend,
    level,
  };
};

/**
 * Calculate MAPE (Mean Absolute Percentage Error)
 * Mengukur error prediksi dalam persen
 */
const calculateMAPE = (actual, forecast) => {
  if (actual === 0) return 0;
  return Math.abs((actual - forecast) / actual);
};

/**
 * Calculate Confidence Score
 * Berbasis MAPE, volatility, dan data quality
 */
const calculateConfidence = (values, forecasted) => {
  if (values.length < 3) return 0.4; // Low confidence jika data < 3 bulan

  // Hitung simple moving average 3-periode untuk validation
  const ma3 = [];
  for (let i = 2; i < values.length; i++) {
    ma3.push((values[i] + values[i - 1] + values[i - 2]) / 3);
  }

  if (ma3.length === 0) return 0.5;

  // MAPE terhadap moving average
  let sumAPE = 0;
  for (let i = 0; i < ma3.length; i++) {
    const actual = values[i + 2];
    if (actual !== 0) {
      sumAPE += calculateMAPE(actual, ma3[i]);
    }
  }

  const mape = sumAPE / ma3.length;
  let confidence = 1 / (1 + mape); // Convert MAPE ke confidence (0-1)

  // Hitung volatility menggunakan coefficient of variation
  const volatility = ss.variance(values);
  const mean = ss.mean(values);
  const coefficientOfVariation = mean !== 0 ? Math.sqrt(volatility) / mean : 0;

  // Adjust confidence berdasarkan volatility
  if (coefficientOfVariation < 0.3) {
    // Data stabil → confidence naik
    confidence = Math.min(0.95, confidence + 0.15);
  } else if (coefficientOfVariation > 0.6) {
    // Data volatile → confidence turun
    confidence = Math.max(0.2, confidence - 0.2);
  }

  // Bonus untuk data trend yang konsisten
  if (values.length >= 4) {
    const diffs = [];
    for (let i = 1; i < values.length; i++) {
      diffs.push(values[i] - values[i - 1]);
    }
    const diffMean = ss.mean(diffs);
    const diffStdDev = ss.standardDeviation(diffs);

    // Jika trend konsisten (low stdDev dari differences)
    if (diffStdDev < Math.abs(diffMean) * 0.5) {
      confidence = Math.min(0.95, confidence + 0.05);
    }
  }

  return Math.min(0.99, Math.max(0.1, confidence));
};

/**
 * Classify season berdasarkan Z-Score
 */
const classifySeason = (zScore) => {
  if (zScore > 0.67) return 'ramai';
  if (zScore < -0.67) return 'sepi';
  return 'normal';
};

/**
 * Get trend direction dari numerical value
 */
const getTrendDirection = (trend, baselineAverage) => {
  const threshold = baselineAverage * 0.05; // 5% dari baseline sebagai threshold
  if (trend > threshold) return 'naik';
  if (trend < -threshold) return 'turun';
  return 'stabil';
};

/**
 * Validate dan sanitize nilai forecast
 * Memastikan output sesuai bisnis logic
 */
const validateForecast = (forecast, baselineAverage, minValue = 0) => {
  // Tidak boleh negatif
  if (forecast < 0) return baselineAverage;
  
  // Tidak boleh terlalu jauh dari baseline (anomaly detection)
  const maxDeviation = baselineAverage * 2; // max 2x baseline
  if (forecast > maxDeviation) return baselineAverage * 1.5;
  
  // Minimal value check
  if (forecast < minValue) return minValue;
  
  return forecast;
};

/**
 * Generate confidence label dan color code
 */
const getConfidenceInfo = (confidence) => {
  if (confidence >= 0.75) {
    return { label: 'Tinggi', color: 'green', code: 'HIGH' };
  }
  if (confidence >= 0.5) {
    return { label: 'Sedang', color: 'orange', code: 'MEDIUM' };
  }
  return { label: 'Rendah', color: 'red', code: 'LOW' };
};

/**
 * Calculate multiple time horizons forecast
 * Berguna untuk dashboard dengan berbagai periode
 */
const forecastMultiplePeriods = (values, periods = 3, alpha = 0.3, beta = 0.1) => {
  if (values.length < 2) return [];

  const { level, trend } = exponentialSmoothing(values, alpha, beta);
  const forecasts = [];

  for (let i = 1; i <= periods; i++) {
    forecasts.push({
      period: i,
      forecast: Math.max(0, level + i * trend),
    });
  }

  return forecasts;
};

module.exports = {
  calculateZScore,
  exponentialSmoothing,
  calculateMAPE,
  calculateConfidence,
  classifySeason,
  getTrendDirection,
  validateForecast,
  getConfidenceInfo,
  forecastMultiplePeriods,
};
