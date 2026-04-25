const express = require('express');
const router  = express.Router();
const multer  = require('multer');
const path    = require('path');
const { authenticate, authorize } = require('../middleware/auth');
const {
  getAllPackages, getPackageById,
  createPackage, updatePackage, deletePackage,
} = require('../controllers/packageController');

// Multer config untuk upload gambar paket
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, process.env.UPLOAD_PATH || './uploads'),
  filename:    (req, file, cb) => {
    const ext  = path.extname(file.originalname);
    const name = `pkg_${Date.now()}${ext}`;
    cb(null, name);
  },
});
const upload = multer({
  storage,
  limits:    { fileSize: Number(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp/;
    cb(null, allowed.test(path.extname(file.originalname).toLowerCase()));
  },
});

// Public
router.get('/',    getAllPackages);
router.get('/:id', getPackageById);

// Admin only
router.post  ('/',    authenticate, authorize('admin'), upload.single('image'), createPackage);
router.put   ('/:id', authenticate, authorize('admin'), upload.single('image'), updatePackage);
router.delete('/:id', authenticate, authorize('admin'), deletePackage);

module.exports = router;
