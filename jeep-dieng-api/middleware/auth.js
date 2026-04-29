const jwt = require('jsonwebtoken');
const authenticate = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Token tidak ditemukan' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, name, email, role }
    next();
  } catch (err) {
    const message = err.name === 'TokenExpiredError'
      ? 'Token sudah kadaluarsa'
      : 'Token tidak valid';
    return res.status(401).json({ success: false, message });
  }
};

/**
 batasi akses berdasarkan role
  */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Akses ditolak. Hanya untuk: ${roles.join(', ')}`,
      });
    }
    next();
  };
};

module.exports = { authenticate, authorize };
