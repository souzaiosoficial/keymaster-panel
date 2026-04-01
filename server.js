// server.js
const express = require('express');
const session = require('express-session');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcryptjs');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;
const SECRET = process.env.SESSION_SECRET || 'keymaster-secret-change-in-prod';
const ADMIN_USER = process.env.ADMIN_USER || 'admin';
const ADMIN_PASS = process.env.ADMIN_PASS || 'admin123';

// ── Security ────────────────────────────────────────────────────────────────
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: '*' }));

// Rate limit on validation API (prevents brute force)
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,   // 1 minute
  max: 30,
  message: { valid: false, message: 'Muitas tentativas. Tente novamente em breve.' }
});

// ── Middleware ──────────────────────────────────────────────────────────────
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
  secret: SECRET,
  resave: false,
  saveUninitialized: false,
 cookie: { secure: false, maxAge: 30 * 24 * 60 * 60 * 1000 }
}));
app.use(express.static(__dirname + '/public'));

// ── Routes ──────────────────────────────────────────────────────────────────
app.use('/api', apiLimiter, require('./routes/api'));
app.use('/', require('./routes/admin'));

// ── Bootstrap default admin ─────────────────────────────────────────────────
function ensureAdmin() {
  const existing = db.prepare('SELECT id FROM admin WHERE username=?').get(ADMIN_USER);
  if (!existing) {
    const hashed = bcrypt.hashSync(ADMIN_PASS, 10);
    db.prepare('INSERT INTO admin (username, password) VALUES (?, ?)').run(ADMIN_USER, hashed);
    console.log(`\n✅ Admin criado: ${ADMIN_USER} / ${ADMIN_PASS}\n   ⚠️  Troque a senha após o primeiro login!\n`);
  }
}

ensureAdmin();
app.listen(PORT, () => console.log(`🔑 KeyMaster rodando na porta ${PORT}`));
