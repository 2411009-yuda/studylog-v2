'use strict';

const { pool } = require('./db');
const { createApp } = require('./app');

const port = Number(process.env.PORT || 3000);
const app = createApp(pool);

// 0.0.0.0 agar dapat diakses emulator (10.0.2.2) dan perangkat di jaringan.
app.listen(port, '0.0.0.0', () => {
  console.log(`StudyLog API berjalan di http://localhost:${port}/api`);
});
