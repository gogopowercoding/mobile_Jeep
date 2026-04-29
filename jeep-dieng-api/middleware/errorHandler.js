const errorHandler = (err, req, res, next) => {
  console.error(`[${new Date().toISOString()}] ERROR:`, err.message);

  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({ success: false, message: 'Data sudah terdaftar (duplikat)' });
  }

  if (err.name === 'ValidationError') {
    return res.status(422).json({ success: false, message: err.message });
  }

  const status = err.statusCode || 500;
  res.status(status).json({
    success: false,
    message: err.message || 'Terjadi kesalahan pada server',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

/**
 * Helper: buat objek AppError dengan status code
 */
const createError = (message, statusCode = 400) => {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
};

/**
 * Helper: standarisasi response sukses
 */
const sendSuccess = (res, data = null, message = 'Berhasil', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

module.exports = { errorHandler, createError, sendSuccess };
