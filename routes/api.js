// routes/api.js
const express = require('express');
const router = express.Router();
const db = require('../db');

router.post('/validate', (req, res) => {
  const { key, udid, device_name } = req.body;
  if (!key || !udid) return res.json({ valid: false, message: 'Dados inválidos.' });

  const keyRow = db.prepare(`SELECT * FROM keys WHERE key_value = ?`).get(key);
  if (!keyRow) return res.json({ valid: false, message: 'Key inválida.' });
  if (keyRow.status === 'blocked') return res.json({ valid: false, message: 'Key bloqueada.' });

  let expiresAt = keyRow.expires_at;

  // Lazy expiry — starts counting on first use
  if (!keyRow.activated_at && keyRow.duration_days) {
    const now = new Date();
    const exp = new Date(now);
    exp.setDate(exp.getDate() + parseInt(keyRow.duration_days));
    expiresAt = exp.toISOString().replace('T',' ').slice(0,19);
    const activatedAt = now.toISOString().replace('T',' ').slice(0,19);
    db.prepare(`UPDATE keys SET activated_at=?, expires_at=? WHERE id=?`).run(activatedAt, expiresAt, keyRow.id);
  }

  if (expiresAt) {
    if (new Date() > new Date(expiresAt)) {
      db.prepare(`UPDATE keys SET status='expired' WHERE id=?`).run(keyRow.id);
      return res.json({ valid: false, message: 'Key expirada.' });
    }
  }

  const existing = db.prepare(`SELECT * FROM devices WHERE key_id=? AND udid=?`).get(keyRow.id, udid);
  if (existing) {
    db.prepare(`UPDATE devices SET last_seen=datetime('now'), device_name=? WHERE id=?`).run(device_name || existing.device_name, existing.id);
    return res.json({ valid: true, message: 'OK', expires_at: expiresAt || null });
  }

  const count = db.prepare(`SELECT COUNT(*) as cnt FROM devices WHERE key_id=?`).get(keyRow.id);
  if (count.cnt >= keyRow.max_devices) return res.json({ valid: false, message: `Limite de ${keyRow.max_devices} dispositivo(s) atingido.` });

  db.prepare(`INSERT INTO devices (key_id, udid, device_name) VALUES (?, ?, ?)`).run(keyRow.id, udid, device_name || 'Desconhecido');
  return res.json({ valid: true, message: 'Dispositivo registrado.', expires_at: expiresAt || null });
});

module.exports = router;
