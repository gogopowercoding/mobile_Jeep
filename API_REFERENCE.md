## 📚 API Response Documentation - JeepOra Analytics (v1.1.0)

### Overview
Documentation lengkap untuk semua endpoint analytics dengan contoh response baru (post ML upgrade).

---

## 1️⃣ GET /api/analytics/revenue-monthly

**Purpose:** Ambil revenue per bulan untuk 12 bulan terakhir

**Response:**
```json
{
  "status": true,
  "message": "Monthly revenue data",
  "data": [
    {
      "month": "2026-05",
      "total_orders": 145,
      "total_revenue": 2850000000,
      "avg_order_value": 19655172
    },
    {
      "month": "2026-04",
      "total_orders": 128,
      "total_revenue": 2560000000,
      "avg_order_value": 20000000
    },
    {
      "month": "2026-03",
      "total_orders": 98,
      "total_revenue": 1960000000,
      "avg_order_value": 20000000
    }
  ]
}
```

**Field Explanation:**
- `month`: Format YYYY-MM, ordered DESC (terbaru dulu)
- `total_orders`: Jumlah order completed/ongoing
- `total_revenue`: Total revenue untuk bulan tersebut (Rupiah)
- `avg_order_value`: Rata-rata nilai per order (Rupiah)

**Status Code:**
- 200 OK: Success
- 500 Internal Server Error: Database error

---

## 2️⃣ GET /api/analytics/season-analysis

**Purpose:** Analisis musim ramai/sepi menggunakan Z-Score

**Response:**
```json
{
  "status": true,
  "message": "Season analysis",
  "data": [
    {
      "month_number": "01",
      "month_name": "January",
      "total_orders": 145,
      "total_revenue": 2850000000,
      "avg_order_value": 19655172,
      "season": "ramai",
      "z_score": 1.23
    },
    {
      "month_number": "02",
      "month_name": "February",
      "total_orders": 98,
      "total_revenue": 1960000000,
      "avg_order_value": 20000000,
      "season": "normal",
      "z_score": -0.45
    },
    {
      "month_number": "03",
      "month_name": "March",
      "total_orders": 72,
      "total_revenue": 1440000000,
      "avg_order_value": 20000000,
      "season": "sepi",
      "z_score": -1.82
    },
    {
      "month_number": "12",
      "month_name": "December",
      "total_orders": 168,
      "total_revenue": 3360000000,
      "avg_order_value": 20000000,
      "season": "ramai",
      "z_score": 2.15
    }
  ]
}
```

**Field Explanation:**
- `month_number`: Bulan 01-12
- `month_name`: Nama bulan (January-December)
- `total_orders`: Jumlah order sepanjang bulan
- `total_revenue`: Total revenue bulan tersebut
- `avg_order_value`: Rata-rata value per order
- **`season`**: Klasifikasi berdasarkan Z-Score:
  - `"ramai"`: Z > +0.67 (top 25%, volume tinggi)
  - `"sepi"`: Z < -0.67 (bottom 25%, volume rendah)
  - `"normal"`: -0.67 ≤ Z ≤ +0.67 (50% tengah)
- **`z_score`**: Nilai Z untuk debugging (format 2 decimal places)

**Interpretasi Z-Score:**
```
Z-Score = (total_orders - mean_orders) / stdDev_orders

Contoh:
- Mean total_orders = 110
- StdDev = 30
- Januari: 145 orders
  Z = (145 - 110) / 30 = 1.17 → RAMAI ✓
- Maret: 72 orders
  Z = (72 - 110) / 30 = -1.27 → SEPI ✓
```

**Status Code:**
- 200 OK: Success
- 200 OK (empty array): Jika tidak ada data grouping

---

## 3️⃣ GET /api/analytics/summary

**Purpose:** Ringkasan analytics bulan ini vs bulan lalu

**Response:**
```json
{
  "status": true,
  "message": "Analytics summary",
  "data": {
    "thisMonth": {
      "total_orders": 145,
      "total_revenue": 2850000000
    },
    "lastMonth": {
      "total_orders": 128,
      "total_revenue": 2560000000
    },
    "growthRate": 11.33
  }
}
```

**Field Explanation:**
- `thisMonth.total_orders`: Orders bulan ini (MONTH & YEAR current)
- `thisMonth.total_revenue`: Revenue bulan ini (Rupiah)
- `lastMonth.total_orders`: Orders bulan lalu
- `lastMonth.total_revenue`: Revenue bulan lalu
- **`growthRate`**: Growth rate dalam persen
  ```
  Formula: ((thisMonth_revenue - lastMonth_revenue) / lastMonth_revenue) * 100
  Contoh: ((2850M - 2560M) / 2560M) * 100 = 11.33%
  ```

**Edge Cases:**
- Jika `lastMonth_revenue = 0` (bulan pertama): `growthRate = 0`
- Positive value = revenue naik
- Negative value = revenue turun

**Status Code:**
- 200 OK: Success (even if tidak ada data)

---

## 4️⃣ GET /api/analytics/forecast

**Purpose:** Prediksi revenue bulan depan + confidence score

**Response (Example 1 - High Confidence):**
```json
{
  "status": true,
  "message": "Revenue forecast",
  "data": {
    "history": [
      { "month": "2025-11", "revenue": 2400000000 },
      { "month": "2025-12", "revenue": 3000000000 },
      { "month": "2026-01", "revenue": 2850000000 },
      { "month": "2026-02", "revenue": 2560000000 },
      { "month": "2026-03", "revenue": 1960000000 },
      { "month": "2026-04", "revenue": 2560000000 },
      { "month": "2026-05", "revenue": 2850000000 }
    ],
    "forecast": 2750000000,
    "baselineAverage": 2717142857,
    "trend": "naik",
    "confidence": 0.823
  }
}
```

**Response (Example 2 - Low Confidence):**
```json
{
  "status": true,
  "message": "Revenue forecast",
  "data": {
    "history": [
      { "month": "2026-04", "revenue": 2560000000 },
      { "month": "2026-05", "revenue": 2850000000 }
    ],
    "forecast": 2705000000,
    "baselineAverage": 2705000000,
    "trend": "stabil",
    "confidence": 0.35
  }
}
```

**Response (Example 3 - No Data):**
```json
{
  "status": true,
  "message": "Revenue forecast",
  "data": {
    "history": [],
    "forecast": 0,
    "baselineAverage": 0,
    "trend": "stabil",
    "confidence": 0
  }
}
```

**Field Explanation:**

### `history`
Array of historical data points (6-12 bulan terakhir)
```javascript
{
  "month": "2026-05",     // Format YYYY-MM
  "revenue": 2850000000   // Rupiah
}
```

### `forecast`
**Prediksi revenue bulan depan (Rupiah)**

Dihitung menggunakan:
- Metode: Exponential Smoothing (Holt's Linear Trend)
- Alpha: 0.3, Beta: 0.1
- Validated: Tidak boleh negatif atau anomali

**Interpretasi:**
```
Actual revenue bulan lalu: 2,850,000,000
Forecast bulan depan: 2,750,000,000
Selisih: -100,000,000 (turun 3.5%)
```

### `baselineAverage`
**Rata-rata revenue dari historical data (Rupiah)**

```javascript
baselineAverage = sum(history) / count(history)

Contoh:
(2.4M + 3M + 2.85M + 2.56M + 1.96M + 2.56M + 2.85M) / 7
= 18.72M / 7
= 2.67M (2,671,428,571)
```

**Kegunaan:**
- ✅ Referensi untuk validasi forecast
- ✅ Deteksi anomali (jika forecast >> baseline)
- ✅ KPI tracking untuk management

### `trend`
**Arah pergerakan revenue**

- `"naik"`: Trend positif, forecast > baseline
- `"turun"`: Trend negatif, forecast < baseline  
- `"stabil"`: Trend flat, forecast ≈ baseline

**Perhitungan:**
```javascript
trend_value = (current_level + trend_slope) - current_level
threshold = baselineAverage * 0.05 (5%)

if (trend_value > threshold) → "naik"
else if (trend_value < -threshold) → "turun"
else → "stabil"
```

### `confidence`
**Kepercayaan prediksi (0.0 - 0.99)**

**Range & Interpretasi:**
- 🟢 **0.75 - 0.99**: TINGGI
  - Dapat diandalkan untuk decision making
  - Minimal 6 bulan data stabil
  
- 🟡 **0.50 - 0.74**: SEDANG
  - Cukup untuk referensi
  - Ada volatilitas atau data < 6 bulan
  
- 🔴 **0.10 - 0.49**: RENDAH
  - Gunakan dengan hati-hati
  - Data sangat volatile atau < 3 bulan
  - Warning akan ditampilkan di UI

**Komponen Perhitungan:**
1. **MAPE** (Mean Absolute Percentage Error)
   - Baseline confidence = 1 / (1 + MAPE)

2. **Volatility** (Coefficient of Variation)
   - CV = StdDev / Mean
   - CV < 0.3: +15% confidence bonus
   - CV > 0.6: -20% confidence penalty

3. **Trend Consistency**
   - Jika trend konsisten: +5% bonus
   - Jika trend inconsistent: -0% penalty

4. **Data Quality**
   - < 3 bulan: confidence = 0.4 (hardcoded)
   - 3-6 bulan: scaled confidence
   - > 6 bulan: full confidence calculation

**Formula Akhir:**
```javascript
confidence = base_confidence + volatility_adjustment + trend_bonus
confidence = constrain(0.1, 0.99, confidence)
```

---

## Response Format Standard

### Success Response
```json
{
  "status": true,
  "message": "Deskripsi operasi",
  "data": { ... }
}
```

### Error Response
```json
{
  "status": false,
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional details"
  }
}
```

---

## Data Type Reference

| Type | Example | Range | Notes |
|------|---------|-------|-------|
| `month` | "2026-05" | YYYY-MM | ISO 8601 format |
| `revenue` | 2850000000 | >= 0 | Rupiah, integer |
| `total_orders` | 145 | >= 0 | Integer |
| `trend` | "naik" | "naik", "turun", "stabil" | String enum |
| `season` | "ramai" | "ramai", "sepi", "normal" | String enum |
| `confidence` | 0.823 | 0.1 - 0.99 | Float 3 decimals |
| `z_score` | 1.23 | any | Float 2 decimals |
| `growthRate` | 11.33 | any | Float 2 decimals |

---

## Query Performance

| Endpoint | Query Time | Data Points | Notes |
|----------|-----------|------------|-------|
| `/revenue-monthly` | ~200ms | 12 rows | Last 12 months |
| `/season-analysis` | ~150ms | 12 rows | Grouped by month |
| `/summary` | ~100ms | 2 queries | This month + last month |
| `/forecast` | ~250ms | 6-12 rows | Last 6-12 months + ML calc |

---

## Common Issues & Solutions

### Forecast Confidence Rendah
**Penyebab:**
- Data < 3 bulan
- Data terlalu volatile (CV > 0.6)
- Revenue sangat fluktuatif

**Solusi:**
- Tunggu sampai 6 bulan data
- Check untuk anomali di database
- Validate data quality

### Forecast Value Tidak Berubah
**Penyebab:**
- Tidak ada order baru
- Query time range salah
- History data kosong

**Solusi:**
- Verify orders di database
- Check query 6+ months
- Add test data jika perlu

### Z-Score Semua 0
**Penyebab:**
- StdDev = 0 (semua bulan sama)
- Data tidak cukup diverse

**Solusi:**
- Check data di database
- Verify bulan grouping
- Ensure months 1-12 ada data

---

## Testing Endpoints

### Using CURL
```bash
# Test forecast dengan real data
curl -X GET \
  http://localhost:3000/api/analytics/forecast \
  -H 'Content-Type: application/json'

# Test season analysis
curl -X GET \
  http://localhost:3000/api/analytics/season-analysis \
  -H 'Content-Type: application/json'
```

### Using Postman
1. Create new request → GET
2. URL: `http://localhost:3000/api/analytics/forecast`
3. Send
4. Check response status & fields

---

**Version**: 1.1.0 (ML Enhanced)  
**Last Updated**: May 12, 2026  
**Status**: ✅ Production Ready
