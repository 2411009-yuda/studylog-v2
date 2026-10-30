# StudyLog API (Node.js + MySQL)

REST API untuk aplikasi Flutter StudyLog. Tiga tabel relasional:
`mata_kuliah` 1—N `jadwal`, dan `mata_kuliah` 1—N `catatan`.

## Persiapan
1. Pasang Node.js (v18+) dan MySQL (atau MariaDB), pastikan MySQL berjalan.
2. `cp .env.example .env`, lalu isi `DB_USER` / `DB_PASSWORD` sesuai MySQL-mu.
3. `npm install`
4. `npm run db:init`   → membuat database `studylog`, tabel, dan data awal
   (aman diulang; data catatan tidak dihapus).
5. `npm start`         → API di `http://localhost:3000/api`

Uji cepat: buka `http://localhost:3000/api/mata-kuliah` di browser.

## Endpoint
| Metode | Path | Keterangan |
|---|---|---|
| GET | `/api/health` | cek server + koneksi database |
| GET | `/api/mata-kuliah` | daftar mata kuliah |
| GET | `/api/jadwal` | jadwal kuliah (hari ISO 1=Senin … 7=Minggu) |
| GET | `/api/catatan` | semua catatan (terbaru dulu) |
| GET | `/api/catatan/:id` | satu catatan |
| POST | `/api/catatan` | buat catatan → 201 |
| PUT | `/api/catatan/:id` | ubah catatan |
| DELETE | `/api/catatan/:id` | hapus catatan → 204 |

Body POST/PUT: `{ "mataKuliahId": 5, "topik": "State", "judul": "...", "isi": "..." }`
Kesalahan validasi → `400 { "error": "pesan" }`; tidak ditemukan → `404`.

## Menghubungkan aplikasi Flutter
- **Emulator Android:** alamat `http://10.0.2.2:3000` (bawaan aplikasi).
- **HP fisik via USB:** `adb reverse tcp:3000 tcp:3000`, lalu
  `flutter run --dart-define=API_BASE_URL=http://localhost:3000`
- **HP fisik via Wi-Fi:** pakai IP komputer, mis.
  `--dart-define=API_BASE_URL=http://192.168.1.10:3000` (izinkan port 3000 di firewall).

## Pengujian
`npm test` menjalankan unit test validator.
