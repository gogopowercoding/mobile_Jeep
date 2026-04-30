const express  = require('express');
const router   = express.Router();
const { authenticate } = require('../middleware/auth');
const {
  saveScore,
  getMyScores,
  getLeaderboard,
  checkReward,
} = require('../controllers/gameController');

router.post('/score',          authenticate, saveScore);
router.get ('/scores/me',      authenticate, getMyScores);
router.get ('/leaderboard',    authenticate, getLeaderboard);
router.get ('/rewards/check',  authenticate, checkReward);

module.exports = router;