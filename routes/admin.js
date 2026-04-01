const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const PRODUCTS = ['PROXY', 'FFH4X', '8BALL'];

router.get('/login', (req, res) => {
  if (req.session.adminId) return res.redirect('/');
  res.sendFile('login.html', { root: __dirname + '/../public' });
});

router.post('/login', (req, res) => {
  const { username, password } = req.body;
  const admin = db.prepare('SELECT * FROM admin WHERE username=?').get(username);
  if (!admin || !bcrypt.compareSync(password, admin.password))
    return res.json({ ok: false, message: 'Usuário ou senha incorretos.' });
  req.session.adminId = admin.id;
  res.json({ ok: true });
});

router.post('/logout', (req, res) => { req.session.destroy(); res.redirect('/login'); });
router.get('/', requireAuth, (req, res) => res.sendFile('index.html', { root: __dirname + '/../public' }));

router.get('/api/stats', requireAuth, (req, res) => {
  const total   = db.prepare(`SELECT COUNT(*) as c FROM keys`).get().c;
  const active  = db.prepare(`SELECT COUNT(*) as c FROM keys WHERE status='active'`).get().c;
  const blocked = db.prepare(`SELECT COUNT(*) as c FROM keys WHERE status='blocked'`).get().c;
  const expired = db.prepare(`SELECT COUNT(*) as c FROM keys WHERE status='expired'`).get().c;
  const devices = db.prepare(`SELECT COUNT(*) as c FROM devices`).get().c;
  const byProduct = {};
  PRODUCTS.forEach(p => {
    byProduct[p] = db.prepare(`SELECT COUNT(*) as c FROM keys WHERE product=?`).get(p).c;
  });
  res.json({ total, active, blocked, expired, devices, byProduct });
});

router.get('/api/keys', requireAuth, (req, res) => {
  const { search, status, product } = req.query;
  let query = `SELECT k.*, (SELECT COUNT(*) FROM devices WHERE key_id=k.id) as device_count FROM keys k WHERE 1=1`;
  const params = [];
  if (search)  { query += ` AND (k.key_value LIKE ? OR k.label LIKE ?)`; params.push(`%${search}%`, `%${search}%`); }
  if (status)  { query += ` AND k.status=?`; params.push(status); }
  if (product) { query += ` AND k.product=?`; params.push(product); }
  query += ` ORDER BY k.created_at DESC`;
  res.json(db.prepare(query).all(...params));
});

router.post('/api/keys', requireAuth, (req, res) => {
  const { label, duration_days, max_devices, product } = req.body;
  const prod = PRODUCTS.includes(product) ? product : 'PROXY';
  const keyValue = generateKey(prod);
  db.prepare(`INSERT INTO keys (key_value, label, product, duration_days, max_devices) VALUES (?, ?, ?, ?, ?)`)
    .run(keyValue, label || null, prod, duration_days || null, max_devices || 1);
  res.json({ ok: true, key: keyValue });
});

router.post('/api/keys/:id/block', requireAuth, (req, res) => {
  const row = db.prepare('SELECT * FROM keys WHERE id=?').get(req.params.id);
  if (!row) return res.json({ ok: false });
  const newStatus = row.status === 'blocked' ? 'active' : 'blocked';
  db.prepare('UPDATE keys SET status=? WHERE id=?').run(newStatus, row.id);
  res.json({ ok: true, status: newStatus });
});

router.post('/api/keys/:id/reset', requireAuth, (req, res) => {
  db.prepare('DELETE FROM devices WHERE key_id=?').run(req.params.id);
  // Also reset activation so timer restarts
  db.prepare('UPDATE keys SET activated_at=NULL, expires_at=NULL WHERE id=? AND duration_days IS NOT NULL').run(req.params.id);
  res.json({ ok: true });
});

router.delete('/api/keys/:id', requireAuth, (req, res) => {
  db.prepare('DELETE FROM keys WHERE id=?').run(req.params.id);
  res.json({ ok: true });
});

router.get('/api/keys/:id/devices', requireAuth, (req, res) => {
  res.json(db.prepare('SELECT * FROM devices WHERE key_id=? ORDER BY first_seen DESC').all(req.params.id));
});

function generateKey(product) {
  const raw = uuidv4().replace(/-/g,'').toUpperCase();
  return `${product}-${raw.slice(0,5)}-${raw.slice(5,10)}-${raw.slice(10,15)}`;
}

module.exports = router;
