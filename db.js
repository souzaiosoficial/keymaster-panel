const Database = require('better-sqlite3');
const path = require('path');

const db = new Database(path.join(__dirname, 'keymaster.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// Create tables
db.exec(`
  CREATE TABLE IF NOT EXISTS admin (
    id INTEGER PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key_value TEXT UNIQUE NOT NULL,
    label TEXT,
    product TEXT NOT NULL DEFAULT 'PROXY',
    duration_days INTEGER,
    max_devices INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TEXT DEFAULT (datetime('now')),
    activated_at TEXT,
    expires_at TEXT
  );

  CREATE TABLE IF NOT EXISTS devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key_id INTEGER NOT NULL,
    udid TEXT NOT NULL,
    device_name TEXT,
    first_seen TEXT DEFAULT (datetime('now')),
    last_seen TEXT DEFAULT (datetime('now')),
    UNIQUE(key_id, udid),
    FOREIGN KEY(key_id) REFERENCES keys(id) ON DELETE CASCADE
  );
`);

// Migration: add missing columns if upgrading from old DB
const keysCols = db.pragma('table_info(keys)').map(c => c.name);
if (!keysCols.includes('product'))      db.exec(`ALTER TABLE keys ADD COLUMN product TEXT NOT NULL DEFAULT 'PROXY'`);
if (!keysCols.includes('activated_at')) db.exec(`ALTER TABLE keys ADD COLUMN activated_at TEXT`);

module.exports = db;
