# StudyLog API (Node.js + MySQL)

REST API untuk aplikasi Flutter StudyLog. Empat tabel relasional:
`mata_kuliah` 1—N `jadwal`, `mata_kuliah` 1—N `catatan`, dan
`mata_kuliah` 1—N `penilaian_dosen`.

## Persiapan
1. Pasang Node.js (v18+) dan MySQL (atau MariaDB), pastikan MySQL berjalan.
2. `cp .env.example .env`, lalu isi `DB_USER` / `DB_PASSWORD` sesuai MySQL-mu.
3. `npm install`
4. `npm run db:init`   → membuat database `studylog`, tabel, dan data awal.
   Aman diulang dan **aman untuk database lama**: data catatan tidak dihapus,
   dan kolom `catatan.client_id` (UUID, dibutuhkan antrian offline) ditambahkan
   serta diisi otomatis pada catatan yang sudah ada (`npm run db:migrate`
   menjalankan hal yang sama).
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

### Endpoint sinkronisasi (dipakai antrian offline aplikasi)
Dialamatkan dengan `clientId` (UUID buatan aplikasi) dan **idempoten**: aman
dikirim ulang bila balasan hilang karena jaringan putus.

| Metode | Path | Keterangan |
|---|---|---|
| PUT | `/api/catatan/klien/:clientId` | buat jika belum ada (201), ubah jika sudah ada (200) |
| DELETE | `/api/catatan/klien/:clientId` | hapus; selalu 204 (yang sudah hilang dianggap berhasil) |

Body PUT sama dengan POST, ditambah `tanggal` opsional (`YYYY-MM-DD HH:MM:SS`)
agar catatan yang dibuat offline tetap bertanggal saat dibuat. `tanggal`
hanya dipakai saat membuat; pembaruan tidak mengubahnya.

### Penilaian dosen per pertemuan
Satu penilaian per (mata kuliah, pertemuan 1–16). Skor 1–5 untuk lima aspek:
`penguasaan`, `penyampaian`, `kesesuaian`, `interaksi`, `disiplin`; `komentar`
opsional (maks. 300 karakter). Idempoten: PUT berulang menghasilkan keadaan sama.

| Metode | Path | Keterangan |
|---|---|---|
| GET | `/api/penilaian` | semua penilaian |
| PUT | `/api/penilaian/:mataKuliahId/:pertemuan` | buat (201) atau ganti (200) |
| DELETE | `/api/penilaian/:mataKuliahId/:pertemuan` | hapus; selalu 204 |

Body PUT:
```json
{ "skor": { "penguasaan": 5, "penyampaian": 4, "kesesuaian": 4,
            "interaksi": 3, "disiplin": 4 }, "komentar": "opsional" }
```
Semua aspek wajib → bila tidak, `400`. Tabel dibuat otomatis oleh `npm run db:init`
(database lama aman: data yang ada tidak dihapus).

Body POST/PUT catatan: `{ "mataKuliahId": 5, "topik": "State", "judul": "...", "isi": "..." }`
Kesalahan validasi → `400 { "error": "pesan" }`; tidak ditemukan → `404`.

## Real-time (WebSocket)
Server membuka WebSocket di port yang sama: `ws://localhost:3000/ws`.
Setiap kali catatan dibuat, diubah, atau dihapus (lewat endpoint mana pun),
server menyiarkan **pemberitahuan** ke semua aplikasi yang terhubung:

```json
{ "tipe": "catatan", "aksi": "dibuat | diubah | dihapus", "id": 12, "clientId": "…" }
```
Saat tersambung server mengirim `{ "tipe": "halo" }`. Pesan hanya memberi
tahu bahwa ada perubahan; aplikasi menanggapinya dengan menarik data lewat
`GET /api/catatan`, sehingga kabar yang terlewat (koneksi sempat putus) tidak
membuat data tertinggal: aplikasi selalu menarik ulang saat tersambung kembali.
Server memutus koneksi yang tidak membalas ping (detak jantung 30 detik).
Permintaan yang ditolak (400/404) dan penghapusan yang tidak mengubah apa pun
tidak disiarkan.

## Menghubungkan aplikasi Flutter
- **Emulator Android:** alamat `http://10.0.2.2:3000` (bawaan aplikasi).
- **HP fisik via USB:** `adb reverse tcp:3000 tcp:3000`, lalu
  `flutter run --dart-define=API_BASE_URL=http://localhost:3000`
- **HP fisik via Wi-Fi:** pakai IP komputer, mis.
  `--dart-define=API_BASE_URL=http://192.168.1.10:3000` (izinkan port 3000 di firewall).

## Pengujian
`npm test` menjalankan unit test validator dan hub WebSocket (tidak membutuhkan database).
