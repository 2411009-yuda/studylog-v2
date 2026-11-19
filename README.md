# StudyLog — Aplikasi Catatan Perkuliahan Berbasis Flutter Android

<p align="center">
  <img src="assets/images/studylog_logo.png" alt="Ikon aplikasi StudyLog" width="160">
</p>

<p align="center">
  <strong>STUDYLOG</strong><br>
  Aplikasi Pencatatan Materi Perkuliahan Berbasis Android
</p>

StudyLog merupakan aplikasi pencatatan materi perkuliahan berbasis Android yang dikembangkan menggunakan **Flutter dan bahasa pemrograman Dart**. Aplikasi ini dirancang untuk membantu mahasiswa dalam mengelola catatan materi perkuliahan, informasi mata kuliah, jadwal pembelajaran, serta aktivitas akademik secara lebih terstruktur. Selain mencatat, StudyLog menyediakan pencarian dan penyaringan catatan, penandaan favorit, penilaian dosen per pertemuan, serta pengingat harian untuk penilaian dan catatan kelas yang terlewat.

StudyLog menerapkan pendekatan *offline-first* dengan menggunakan SQLite sebagai penyimpanan lokal pada perangkat. Ketika koneksi tersedia, perubahan data dikirim melalui REST API berbasis Node.js dan disimpan ke database MySQL. Aplikasi juga memanfaatkan WebSocket untuk menerima pemberitahuan perubahan data dari perangkat lain secara real-time.

Proyek ini dikembangkan sebagai tugas Project-Based Learning (PjBL) mata kuliah **Pemrograman Aplikasi Bergerak**, Program Studi S-1 Informatika, Fakultas Ilmu Komputer, Universitas Mulia, dengan mengacu pada Workbook Praktikum 01 Flutter Android: StudyLog.

---

## 1. Informasi Proyek

| Informasi | Keterangan |
|---|---|
| Nama Aplikasi | StudyLog |
| Platform | Android |
| Framework | Flutter |
| Bahasa Pemrograman | Dart |
| State Management | Provider dan ChangeNotifier |
| Penyimpanan Lokal | SQLite (sqflite) |
| Backend | Node.js dan Express |
| Database Server | MySQL |
| Komunikasi | HTTP REST API dan WebSocket |
| Notifikasi | Notifikasi lokal terjadwal (`flutter_local_notifications`) |
| Ikon Aplikasi | Buku catatan dengan lonceng, grafik, dan bintang (lihat bagian 3.4) |
| Repository | [studylog-v2](https://github.com/2411009-yuda/studylog-v2) |
| Mata Kuliah | Pemrograman Aplikasi Bergerak |
| Program Studi | S-1 Informatika |
| Universitas | Universitas Mulia |
| Kelas | IFB5J |

### Anggota Kelompok

| Nama | NIM |
|---|---|
| Yuda Pratama | 2411009 |
| Wisnu Wardhana | 2411037 |
| Khoirul Ikwan | 2411020 |

---

## 2. Latar Belakang

Kegiatan perkuliahan menghasilkan berbagai materi, penjelasan, dan informasi yang perlu dicatat serta dikelola oleh mahasiswa. Catatan yang tersebar atau tidak tersimpan secara terstruktur dapat menyulitkan mahasiswa ketika ingin mencari kembali materi tertentu.

StudyLog dikembangkan sebagai solusi pencatatan materi perkuliahan melalui perangkat Android. Aplikasi menyediakan fungsi untuk membuat, membaca, mengubah, dan menghapus catatan yang dikaitkan dengan mata kuliah.

Berbeda dengan aplikasi yang sepenuhnya bergantung pada koneksi internet, StudyLog menyimpan perubahan terlebih dahulu pada SQLite di perangkat. Ketika server tersedia, perubahan dikirim melalui API ke database MySQL. Aplikasi juga memanfaatkan WebSocket untuk menerima pemberitahuan perubahan dari perangkat lain.

Selain pencatatan, StudyLog membantu mahasiswa tetap disiplin: penilaian dosen pada setiap pertemuan dan catatan untuk kelas yang sudah berlangsung dipantau, lalu diingatkan melalui notifikasi apabila masih terlewat.

---

## 3. Fitur Aplikasi

### 3.1 Fitur Utama

#### A. Pengelolaan Catatan Perkuliahan

- Menambahkan catatan materi perkuliahan.
- Menampilkan daftar catatan yang tersimpan.
- Melihat detail catatan.
- Mengubah judul dan isi catatan.
- Menghapus catatan melalui dialog konfirmasi.
- Melakukan validasi formulir sebelum penyimpanan.
- Menyimpan catatan secara permanen menggunakan SQLite.
- Mencari catatan berdasarkan judul, topik, isi, serta nama atau kode mata kuliah. Pencarian tidak membedakan huruf besar/kecil, dan seluruh kata kunci harus ditemukan.
- Menyaring daftar dengan chip **Semua**, **Favorit**, atau satu chip per mata kuliah. Filter Favorit dan filter mata kuliah dapat digabung.
- Menandai catatan sebagai favorit dari halaman detail.
- Menampilkan catatan yang dikelompokkan per mata kuliah dengan jumlah catatan pada tiap kelompok.

#### B. Navigasi dan Halaman Aplikasi

Aplikasi memiliki empat tab utama pada navigasi bawah, yaitu:

- **Beranda:** Menampilkan sambutan dan identitas mahasiswa, status sinkronisasi, kelas yang sedang berlangsung atau berikutnya, ringkasan jumlah catatan dengan tombol *Lihat Catatan* dan *Buat Catatan*, tautan ke Tentang Aplikasi, serta lencana lifecycle. Bilah atas menampilkan indikator real-time dan lonceng notifikasi.
- **Profil:** Menampilkan dan mengubah informasi mahasiswa. Foto profil dapat dipilih dari galeri, diambil dengan kamera, atau dikembalikan ke foto bawaan.
- **Mata Kuliah:** Menampilkan daftar mata kuliah dan halaman detail (kode, SKS, dosen pengampu, jadwal, deskripsi, dan prasyarat) dengan tombol **Nilai Dosen**.
- **Kontak:** Menyediakan informasi kontak serta tautan pengembang yang dapat dibuka atau disalin.

Tombol tambah (+) ditempatkan di tengah navigasi bawah untuk membuka formulir catatan baru.

#### C. Pengelolaan Data

- Mengurutkan catatan berdasarkan Terbaru, Terlama, dan Judul A–Z.
- Menyalin catatan ke clipboard.
- Membagikan catatan melalui fitur berbagi Android.
- Mengelola data mata kuliah dan jadwal dari database.
- Menyimpan cache mata kuliah dan jadwal pada perangkat.

#### D. Penilaian Dosen per Pertemuan

- Mahasiswa menilai dosen pada setiap pertemuan (1–16) dari halaman detail mata kuliah.
- Lima aspek dinilai dengan skala 1 (sangat kurang) sampai 5 (sangat baik): penguasaan materi, kejelasan penyampaian, kesesuaian dengan RPS, interaksi dan respons, serta ketepatan waktu dan disiplin. Komentar bersifat opsional (maksimal 300 karakter).
- Halaman penilaian menampilkan rata-rata skor beserta kategorinya dan jumlah pertemuan yang sudah dinilai.
- Penilaian bersifat *offline-first*: disimpan di perangkat, masuk antrian, lalu dikirim ke server. Menilai ulang pertemuan yang sama akan menggantikan penilaian sebelumnya.
- Pita status menampilkan kondisi offline, jumlah penilaian yang menunggu dikirim, atau penilaian yang ditolak server.

#### E. Pengingat dan Notifikasi

- Lonceng pada Beranda menampilkan jumlah hal yang terlewat dan membuka layar **Notifikasi**.
- Dua jenis pengingat dihitung otomatis:
  1. **Penilaian dosen:** pertemuan yang sudah berlangsung tetapi belum dinilai.
  2. **Catatan kelas:** kelas yang sudah selesai dalam 7 hari terakhir tetapi belum memiliki catatan untuk mata kuliah tersebut pada tanggalnya.
- Mengetuk pengingat membuka halaman penilaian atau formulir catatan yang sudah terisi sesuai jadwal kelas.
- Notifikasi sistem dikirim setiap hari pada pukul 19:00 (waktu perangkat, zona Asia/Makassar) selama masih ada yang terlewat. Tombol **Uji notifikasi** tersedia untuk mencobanya langsung.
- Pengaturan pengingat berada di `lib/config/pengingat_config.dart` (lihat bagian 7.6).

#### F. Tentang Aplikasi

Halaman yang dibuka dari Beranda dan menampilkan logo, versi, deskripsi, daftar fitur, dan teknologi yang digunakan. Isinya bersumber dari `lib/config/app_info.dart`, dan versinya dijaga agar selalu sama dengan `pubspec.yaml` oleh `test/tentang_test.dart`.

### 3.2 Fitur Pengembangan (PjBL)

| Fitur | Deskripsi | Tingkat Workbook |
|---|---|---|
| Empat tabel relasional | Menggunakan tabel `mata_kuliah`, `jadwal`, `catatan`, dan `penilaian_dosen` pada MySQL | Lanjutan |
| Pengurutan catatan | Terbaru, Terlama, dan Judul A–Z | Dasar |
| Ekspor teks | Menyalin dan membagikan satu catatan atau seluruh catatan | Lanjutan |
| Tombol tambah (+) | Memilih mata kuliah secara otomatis berdasarkan jadwal hari ini | Pengembangan tambahan |
| Offline-first | Menyimpan perubahan lokal dan memasukkannya ke antrian sinkronisasi | Pengembangan tambahan |
| Real-time WebSocket | Memberikan pemberitahuan ketika catatan berubah dari perangkat lain | Pengembangan tambahan |
| Cache data | Menyimpan mata kuliah dan jadwal terakhir agar dapat digunakan saat offline | Pengembangan tambahan |
| Kartu jadwal | Menampilkan kelas yang sedang berlangsung atau berikutnya pada Beranda | Pengembangan tambahan |
| Halaman Tentang Aplikasi | Menampilkan logo, deskripsi, fitur, teknologi, dan versi aplikasi | Pengembangan tambahan |
| Pencarian dan filter | Mencari catatan dan menyaring per mata kuliah atau favorit | Pengembangan tambahan |
| Favorit | Menandai catatan penting; disimpan di perangkat | Pengembangan tambahan |
| Pengelompokan catatan | Daftar catatan dikelompokkan per mata kuliah | Pengembangan tambahan |
| Penilaian dosen | Penilaian 5 aspek per pertemuan, offline-first dan tersinkron | Pengembangan tambahan |
| Pengingat dan notifikasi | Pengingat penilaian dan catatan kelas yang terlewat, termasuk notifikasi harian | Pengembangan tambahan |
| Ikon aplikasi | Ikon peluncur khusus StudyLog untuk Android, iOS, macOS, web, dan Windows | Pengembangan tambahan |

### 3.3 Mekanisme Tombol Tambah (+)

Tombol tambah pada navigasi bawah membuka formulir catatan baru dengan pilihan mata kuliah yang dapat terisi otomatis berdasarkan jadwal hari ini.

Prioritas pemilihan mata kuliah:
1. Mata kuliah yang sedang berlangsung.
2. Jika tidak ada, mata kuliah yang baru selesai.
3. Jika belum ada, mata kuliah berikutnya pada hari tersebut.

Pengguna tetap dapat mengganti mata kuliah secara manual.

### 3.4 Ikon Aplikasi

<p align="center">
  <img src="assets/images/studylog_logo.png" alt="Ikon StudyLog" width="140">
</p>

Ikon berupa buku catatan terbuka berlatar biru dengan tiga penanda fitur: lonceng (pengingat), grafik (penilaian), dan bintang (favorit).

| Platform | Lokasi |
|---|---|
| Android | `android/app/src/main/res/mipmap-*/` (ikon lama dan adaptive icon) dan `drawable/ic_launcher_background.xml` |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` |
| Web | `web/icons/` dan `web/favicon.png` |
| Windows | `windows/runner/resources/app_icon.ico` |

Gambar sumber disimpan di `assets/icon/studylog_icon_source.png`, sedangkan logo untuk halaman Tentang berada di `assets/images/studylog_logo.png`. Setelah mengganti ikon, jalankan `flutter clean` lalu pasang ulang aplikasi agar ikon baru tampil pada peluncur.

---

## 4. Teknologi dan Kebutuhan Perangkat Lunak

### 4.1 Teknologi yang Digunakan

| Teknologi | Fungsi |
|---|---|
| Flutter | Framework pengembangan aplikasi Android |
| Dart | Bahasa pemrograman aplikasi |
| Provider | Menyediakan state management |
| ChangeNotifier | Memberikan notifikasi perubahan state |
| SQLite / sqflite | Penyimpanan data lokal |
| Node.js | Menjalankan backend |
| Express | Framework REST API |
| MySQL | Database server |
| HTTP | Komunikasi REST API |
| WebSocket | Komunikasi pemberitahuan real-time |
| flutter_local_notifications | Notifikasi pengingat terjadwal |
| Git | Pengelolaan versi source code |

### 4.2 Paket Flutter

Batas versi paket pada `pubspec.yaml` (versi yang benar-benar terpasang tercatat di `pubspec.lock`):

| Paket | Versi |
|---|---|
| provider | ^6.1.2 |
| http | ^1.2.2 |
| sqflite | ^2.4.1 |
| path | ^1.9.0 |
| web_socket_channel | ^3.0.1 |
| share_plus | ^10.1.4 |
| image_picker | ^1.1.2 |
| url_launcher | ^6.3.1 |
| flutter_local_notifications | ^21.0.0 |
| timezone | ^0.11.0 |
| flutter_lints (dev) | ^6.0.0 |

Kebutuhan pengembangan:
- Flutter SDK stabil.
- Dart SDK dengan constraint `^3.8.1` pada `pubspec.yaml`. Karena `pubspec.lock` mensyaratkan Dart 3.13 atau lebih baru, gunakan Flutter SDK stabil yang terbaru.
- Android SDK dan Android Emulator atau perangkat Android.
- Node.js versi 18 atau lebih baru.
- MySQL atau MariaDB.
- Git.

---

## 5. Arsitektur Aplikasi

StudyLog menggunakan pemisahan beberapa lapisan untuk memisahkan tanggung jawab antarmuka, pengelolaan state, penyimpanan data, dan komunikasi dengan server.

### 5.1 Diagram Arsitektur

```mermaid
flowchart LR
    UI["Layar Flutter"] --> VM["ViewModel<br/>ChangeNotifier + Provider"]

    VM --> Repo["CatatanRepository"]
    Repo --> SQLite[("SQLite Lokal<br/>Catatan, Antrian, Cache")]

    VM --> Sync["SinkronService"]
    Sync --> SQLite
    Sync -->|HTTP REST| API["API Node.js + Express"]

    VM --> Nilai["PenilaianRepository"]
    Nilai --> SQLite
    Nilai -->|HTTP REST| API

    VM --> Ingat["PengingatViewModel"]
    Ingat --> Notif["NotifikasiService<br/>Notifikasi lokal"]

    API --> MySQL[("MySQL")]

    API -.->|WebSocket: Pemberitahuan Perubahan| RT["RealtimeService"]
    RT --> VM
```

### 5.2 Alur Tanggung Jawab

| Lapisan | Berkas | Tanggung Jawab |
|---|---|---|
| UI | `screens/`, `widgets/` | Menampilkan state dan meneruskan aksi pengguna |
| ViewModel | `viewmodels/` | Mengelola state layar menggunakan ChangeNotifier |
| Repository | `data/catatan_repository.dart` | Membaca dan menulis catatan ke SQLite serta mencatat perubahan ke antrian |
| Repository penilaian | `data/penilaian_repository.dart` | Menyimpan penilaian dosen dan antriannya pada cache lokal, lalu mengirimnya ke server |
| Repository mata kuliah | `data/mata_kuliah_repository.dart` | Mengambil mata kuliah dan jadwal dari server dengan cache lokal |
| Penyimpanan lokal | `data/sqlite_local_store.dart` | Mengelola tabel catatan, antrian, dan cache |
| Sinkronisasi | `data/sinkron_service.dart` | Mengirim antrian ke API dan mengambil data server |
| API Client | `data/api_client.dart` | Mengirim HTTP JSON serta menangani timeout dan error |
| Real-time | `data/realtime_service.dart` | Mendengarkan WebSocket dan melakukan sambung ulang |
| Pengingat | `viewmodels/pengingat_view_model.dart`, `utils/pengingat_utils.dart` | Menghitung penilaian dan catatan kelas yang terlewat |
| Notifikasi | `services/notifikasi_service.dart` | Menjadwalkan dan menampilkan notifikasi lokal |
| Backend | `studylog_api/src/` | Menyediakan REST API dan layanan WebSocket |

### 5.3 Mengapa Aplikasi Tidak Langsung Terhubung ke MySQL?

Aplikasi Android tidak melakukan koneksi langsung ke MySQL. Hal tersebut bertujuan agar kredensial database tidak disimpan di dalam aplikasi.

Sebagai gantinya, aplikasi Flutter berkomunikasi dengan API Node.js. API bertugas menerima permintaan, mengelola proses database, dan mengirimkan respons kepada aplikasi.

### 5.4 Prinsip Sinkronisasi Data

- Setiap catatan memiliki `clientId` berupa UUID dari aplikasi.
- Server mengenali pengiriman ulang berdasarkan `clientId` yang sama untuk mencegah duplikasi catatan.
- Setiap catatan memiliki satu entri antrian yang dapat diperbarui ketika terjadi perubahan baru.
- Perubahan lokal tetap tersimpan meskipun server tidak dapat dijangkau.
- Setelah antrian dikirim, aplikasi mengambil data terbaru dari server dan menyatukannya dengan data lokal.
- Pesan WebSocket hanya menjadi pemberitahuan perubahan, sedangkan data terbaru tetap diambil melalui REST API.
- Aplikasi melakukan sinkronisasi kembali ketika koneksi tersedia.
- Penilaian dosen memakai prinsip yang sama: satu entri antrian per (mata kuliah, pertemuan), dikirim secara idempoten melalui `PUT`.
- Penanda favorit hanya tersimpan di perangkat dan tidak dikirim ke server.

---

## 6. Struktur Repository

Struktur direktori berikut disesuaikan dengan repository `studylog-v2` dan susunan source code pada laporan.

```text
studylog-v2/
│
├── android/
├── assets/
│   ├── icon/
│   │   └── studylog_icon_source.png
│   └── images/
│       ├── profile.png
│       └── studylog_logo.png
│
├── ios/
│
├── lib/
│   ├── main.dart
│   ├── app/
│   │   └── Aplikasi, router, route, dan tema
│   ├── config/
│   │   └── Konfigurasi API, informasi aplikasi, dan pengingat
│   ├── data/
│   │   ├── api_client.dart
│   │   ├── local_store.dart
│   │   ├── sqlite_local_store.dart
│   │   ├── catatan_repository.dart
│   │   ├── mata_kuliah_repository.dart
│   │   ├── penilaian_repository.dart
│   │   ├── sinkron_service.dart
│   │   └── realtime_service.dart
│   ├── models/
│   │   └── Catatan, Course, Jadwal, PenilaianDosen, dan Student
│   ├── screens/
│   │   └── Beranda, Daftar, Form, Detail, Profil, Mata Kuliah,
│   │       Detail Mata Kuliah, Penilaian Dosen, Notifikasi,
│   │       Kontak, dan Tentang
│   ├── services/
│   │   └── Layanan ekspor teks dan notifikasi
│   ├── utils/
│   │   └── Validator, jadwal, pencarian, pengelompokan, pengurutan,
│   │       ekspor, pengingat, dan UUID
│   ├── viewmodels/
│   │   └── Catatan, Mata Kuliah, Penilaian, Pengingat, dan Profil
│   └── widgets/
│       └── Komponen UI, lonceng, banner, dan indikator status
│
├── linux/
├── macos/
│
├── screenshots/
│   └── Dokumentasi tampilan aplikasi (.jpeg)
│
├── studylog_api/
│   ├── db/
│   │   └── schema.sql
│   ├── src/
│   │   └── Backend, hub WebSocket, validator, dan migrasi
│   ├── test/
│   └── README.md
│
├── test/
│   └── Pengujian Flutter
│
├── web/
├── windows/
│
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
└── README.md
```

Folder utama:

- `lib/`: Source code aplikasi Flutter.
- `studylog_api/`: Source code backend Node.js dan integrasi MySQL.
- `test/`: Pengujian otomatis aplikasi Flutter.
- `screenshots/`: Dokumentasi gambar tampilan aplikasi.
- `assets/`: Aset gambar aplikasi, termasuk logo dan gambar sumber ikon.
- `android/`: Konfigurasi platform Android (termasuk ikon peluncur).

---

## 7. Menjalankan Proyek

### 7.1 Prasyarat

Pastikan perangkat telah memiliki:
- Flutter SDK dan Android SDK.
- Android Emulator atau perangkat Android.
- Node.js versi 18 atau lebih baru.
- MySQL atau MariaDB yang sedang berjalan.
- Git.

### 7.2 Menjalankan Backend

Masuk ke direktori backend:

```bash
cd studylog_api
```

Salin file konfigurasi lingkungan:

```bash
cp .env.example .env
```

Untuk Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Isi `DB_USER` dan `DB_PASSWORD` pada file `.env` sesuai konfigurasi MySQL.

Instal dependensi:

```bash
npm install
```

Inisialisasi database:

```bash
npm run db:init
```

Jalankan server:

```bash
npm start
```

Server siap apabila terminal menampilkan:

```text
StudyLog API berjalan di http://localhost:3000/api
Real-time (WebSocket) di ws://localhost:3000/ws
```

Pengujian koneksi sederhana dapat dilakukan dengan membuka:

```text
http://localhost:3000/api/mata-kuliah
```

**Catatan:** Berdasarkan README awal, `npm run db:init` dapat dijalankan kembali untuk inisialisasi dan migrasi yang disediakan tanpa menghapus catatan lama.

### 7.3 Konfigurasi Android

Buka file:

```text
android/app/src/main/AndroidManifest.xml
```

Pastikan izin berikut tersedia:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

`INTERNET` dipakai untuk REST API dan WebSocket. `POST_NOTIFICATIONS` diperlukan untuk menampilkan notifikasi pada Android 13 atau lebih baru, sedangkan `RECEIVE_BOOT_COMPLETED` memungkinkan jadwal notifikasi dipulihkan setelah perangkat dinyalakan ulang. Manifest juga memuat dua `receiver` milik `flutter_local_notifications` untuk keperluan tersebut.

Pada bagian application:

```xml
<application
    android:usesCleartextTraffic="true"
    ... >
```

Nama aplikasi pada peluncur diatur melalui `android:label="StudyLog"` dan ikonnya melalui `android:icon="@mipmap/ic_launcher"`.

Konfigurasi `usesCleartextTraffic` diperlukan untuk pengujian server lokal yang menggunakan HTTP/WS tanpa TLS. Konfigurasi ini hanya ditujukan untuk lingkungan demonstrasi dan bukan pengaturan keamanan untuk produksi.

### 7.4 Menjalankan Flutter

Kembali ke direktori utama proyek:

```bash
flutter pub get
```

Periksa analisis kode:

```bash
flutter analyze
```

Jalankan pengujian otomatis:

```bash
flutter test
```

Jalankan aplikasi:

```bash
flutter run
```

### 7.5 Konfigurasi Koneksi Server

| Perangkat | Konfigurasi |
|---|---|
| Android Emulator | `http://10.0.2.2:3000` |
| HP melalui USB | Menggunakan `adb reverse` |
| HP melalui Wi-Fi | Menggunakan IP laptop |

Untuk HP melalui USB:

```bash
adb reverse tcp:3000 tcp:3000
```

Kemudian:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Untuk HP melalui Wi-Fi:

```bash
flutter run --dart-define=API_BASE_URL=http://IP-LAPTOP:3000
```

Ganti `IP-LAPTOP` dengan alamat IP laptop yang dapat dilihat melalui:

```bash
ipconfig
```

Pastikan port 3000 diizinkan pada Windows Firewall.

> **Perhatian:** SQLite melalui sqflite ditujukan untuk Android/iOS dan bukan target web/Chrome.

### 7.6 Konfigurasi Pengingat

Pengaturan berada pada `lib/config/pengingat_config.dart`:

| Pengaturan | Nilai Bawaan | Keterangan |
|---|---|---|
| `awalSemesterBawaan` | 7 September 2026 | Tanggal minggu pertama kuliah. **Ubah setiap semester**, karena jumlah pertemuan yang sudah berlangsung dihitung dari tanggal ini dan jadwal mingguan |
| `jamPengingatBawaan` / `menitPengingatBawaan` | 19:00 | Waktu notifikasi harian |
| `hariMundurKelas` | 7 hari | Batas ke belakang untuk kelas yang belum dicatat |
| `zonaWaktuPengingat` | `Asia/Makassar` | Zona waktu penjadwalan notifikasi (WITA) |

Pada Android 13 atau lebih baru, izin notifikasi diminta saat pertama kali dibutuhkan (ada yang perlu diingatkan atau saat mencoba **Uji notifikasi**), bukan saat aplikasi dibuka. Notifikasi dijadwalkan dengan mode *inexact*, sehingga waktu tampilnya dapat bergeser beberapa menit mengikuti pengelolaan baterai Android.

---

## 8. Database

StudyLog menggunakan MySQL sebagai database server dan SQLite sebagai penyimpanan lokal pada perangkat.

### 8.1 MySQL (Sumber Data Utama)

Database server memiliki empat tabel utama:

| Tabel | Kolom Penting | Fungsi |
|---|---|---|
| `mata_kuliah` | id, kode, nama, sks, dosen, deskripsi, prasyarat | Menyimpan informasi mata kuliah |
| `jadwal` | id, mata_kuliah_id, hari, jam_mulai, jam_selesai, kelas, ruang | Menyimpan jadwal perkuliahan |
| `catatan` | id, client_id, mata_kuliah_id, topik, judul, isi, tanggal, diubah | Menyimpan catatan mahasiswa |
| `penilaian_dosen` | id, mata_kuliah_id, pertemuan, skor_penguasaan, skor_penyampaian, skor_kesesuaian, skor_interaksi, skor_disiplin, komentar, dinilai, diubah | Menyimpan penilaian dosen per pertemuan |

### 8.2 Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    MATA_KULIAH ||--o{ JADWAL : memiliki
    MATA_KULIAH ||--o{ CATATAN : dicatat_pada
    MATA_KULIAH ||--o{ PENILAIAN_DOSEN : dinilai_pada

    MATA_KULIAH {
        int id PK
        varchar kode UK
        varchar nama
        tinyint sks
        varchar dosen
        text deskripsi
        varchar prasyarat
    }

    JADWAL {
        int id PK
        int mata_kuliah_id FK
        tinyint hari
        time jam_mulai
        time jam_selesai
        varchar kelas
        varchar ruang
    }

    CATATAN {
        int id PK
        char client_id UK
        int mata_kuliah_id FK
        varchar topik
        varchar judul
        text isi
        datetime tanggal
        datetime diubah
    }

    PENILAIAN_DOSEN {
        int id PK
        int mata_kuliah_id FK
        tinyint pertemuan
        tinyint skor_penguasaan
        tinyint skor_penyampaian
        tinyint skor_kesesuaian
        tinyint skor_interaksi
        tinyint skor_disiplin
        varchar komentar
        datetime dinilai
        datetime diubah
    }
```

Relasi database:
- Satu mata kuliah dapat memiliki beberapa jadwal perkuliahan.
- Satu mata kuliah dapat memiliki beberapa catatan.
- Satu mata kuliah dapat memiliki beberapa penilaian dosen, satu untuk setiap pertemuan (pertemuan 1–16, skor 1–5 pada tiap aspek). Kombinasi `mata_kuliah_id` dan `pertemuan` bersifat unik.
- `client_id` digunakan sebagai identitas unik catatan dari aplikasi.

Data awal pada skema database mencakup 8 mata kuliah dan 8 jadwal semester 5 kelas IFB5J.

### 8.3 SQLite (Penyimpanan Lokal)

Database lokal menggunakan nama:

```text
studylog_local.db
```

Skema lokal (versi basis data 2) menggunakan empat tabel:

| Tabel | Isi | Fungsi |
|---|---|---|
| `catatan` | id lokal, client_id, server_id, data mata kuliah, topik, judul, isi, tanggal | Menyimpan salinan lokal catatan |
| `antrian` | client_id, op, versi, percobaan, error, dibuat | Menyimpan perubahan yang belum dikirim |
| `cache` | kunci dan nilai | Menyimpan cache mata kuliah, jadwal, serta salinan dan antrian penilaian dosen (dalam bentuk JSON) |
| `favorit` | client_id | Menyimpan penanda favorit; hanya ada di perangkat ini |

Tabel antrian mendukung operasi `upsert` dan `hapus`, sehingga perubahan dapat dikirim kembali ketika server tersedia. Tabel `favorit` ditambahkan pada migrasi v1 ke v2 tanpa menyentuh data catatan yang sudah ada.

---

## 9. REST API dan WebSocket

### 9.1 REST API

Backend menggunakan Node.js dan Express untuk menghubungkan aplikasi Flutter dengan database MySQL.

| Metode | Endpoint | Keterangan |
|---|---|---|
| GET | `/api/health` | Memeriksa kondisi server dan koneksi database |
| GET | `/api/mata-kuliah` | Mengambil daftar mata kuliah |
| GET | `/api/jadwal` | Mengambil jadwal perkuliahan |
| GET / POST | `/api/catatan` | Mengambil daftar atau membuat catatan |
| GET / PUT / DELETE | `/api/catatan/:id` | Melihat, mengubah, dan menghapus catatan |
| PUT | `/api/catatan/klien/:clientId` | Membuat atau memperbarui catatan berdasarkan clientId |
| DELETE | `/api/catatan/klien/:clientId` | Menghapus catatan berdasarkan clientId |
| GET | `/api/penilaian` | Mengambil seluruh penilaian dosen |
| PUT | `/api/penilaian/:mataKuliahId/:pertemuan` | Membuat (201) atau mengganti (200) penilaian satu pertemuan |
| DELETE | `/api/penilaian/:mataKuliahId/:pertemuan` | Menghapus penilaian; selalu 204 |

Body `PUT /api/penilaian/...` berisi lima skor wajib (1–5) dan komentar opsional:

```json
{ "skor": { "penguasaan": 5, "penyampaian": 4, "kesesuaian": 4,
            "interaksi": 3, "disiplin": 4 }, "komentar": "opsional" }
```

### 9.2 WebSocket

WebSocket digunakan untuk memberikan pemberitahuan ketika terdapat perubahan catatan.

Alamat endpoint:

```text
ws://localhost:3000/ws
```

Jenis pemberitahuan yang digunakan:
- `dibuat`
- `diubah`
- `dihapus`

Pesan WebSocket tidak menjadi sumber data catatan. Ketika menerima pemberitahuan, aplikasi melakukan sinkronisasi melalui REST API untuk memperoleh data terbaru.

Layanan real-time juga menyediakan mekanisme debounce, sambung ulang bertahap, dan ping berkala untuk mendeteksi koneksi yang mati diam-diam. Sinkronisasi berkala (polling) berjalan sebagai cadangan ketika masih ada perubahan tertunda, server tidak terjangkau, atau WebSocket terputus. Pemberitahuan WebSocket saat ini hanya mencakup catatan; penilaian dosen diperbarui melalui sinkronisasi REST.

Dokumentasi backend lebih lanjut dapat dilihat pada:

[`studylog_api/README.md`](studylog_api/README.md)

---

## 10. Pengujian Aplikasi

### 10.1 Strategi Pengujian

Pengujian StudyLog terdiri atas pengujian otomatis dan pengujian fungsional.

Pengujian otomatis Flutter tersedia pada direktori `test/`, sedangkan pengujian backend Node.js tersedia pada `studylog_api/test/` (`validators.test.js` dan `hub.test.js`, tanpa memerlukan database).

Pengujian Flutter menggunakan fake server dan penyimpanan lokal dalam memori untuk memeriksa logika aplikasi tanpa harus selalu mengakses MySQL atau WebSocket sungguhan.

Oleh karena itu, keberhasilan pengujian otomatis tidak secara langsung membuktikan bahwa seluruh koneksi SQLite, server, dan WebSocket pada perangkat fisik telah berhasil.

### 10.2 Daftar Pengujian Otomatis

| Area Pengujian | File Pengujian | Fokus Pemeriksaan |
|---|---|---|
| Model | `catatan_model_test.dart` | Konversi JSON, format tanggal, dan copyWith |
| Form | `catatan_form_test.dart` | Validasi dan perilaku formulir |
| CRUD | `catatan_flow_test.dart` | Alur tambah, baca, ubah, dan hapus |
| Navigasi | `navigation_test.dart` | Perpindahan halaman dan navigasi bawah |
| Offline | `offline_flow_test.dart` | Perubahan lokal ketika server tidak tersedia |
| Sinkronisasi | `sinkron_test.dart` | Antrian, pengiriman ulang, idempotensi, dan penyatuan data |
| Real-time | `realtime_service_test.dart`, `realtime_flow_test.dart` | Koneksi, reconnect, debounce, dan sinkronisasi |
| Pengurutan/Ekspor | `urutan_ekspor_test.dart`, `urutan_ekspor_flow_test.dart` | Urutan data dan fungsi ekspor |
| Jadwal | `jadwal_test.dart` | Pemilihan mata kuliah berdasarkan jadwal |
| Pencarian | `cari_catatan_test.dart` | Penyaringan catatan berdasarkan kata kunci |
| Pengelompokan | `kelompok_catatan_test.dart` | Ringkasan dan filter catatan per mata kuliah |
| Favorit | `favorit_test.dart` | Menandai, melepas, dan mempertahankan favorit |
| Penilaian dosen | `penilaian_test.dart` | Simpan, ganti, antrian offline, dan sinkronisasi penilaian |
| Pengingat | `pengingat_test.dart` | Perhitungan penilaian dan catatan kelas yang terlewat |
| UUID | `uuid_test.dart` | Pembuatan identitas klien |
| Profil | `profile_viewmodel_test.dart` | Pengelolaan state profil |
| Tentang | `tentang_test.dart` | Navigasi, daftar fitur, dan kesesuaian versi dengan `pubspec.yaml` |
| ViewModel | `view_model_test.dart` | Pengelolaan state dan sinkronisasi |

**Catatan status:** Daftar di atas menunjukkan file pengujian yang tersedia dalam source code. Status keberhasilan seluruh pengujian otomatis harus mengacu pada keluaran perintah aktual.

### 10.3 Perintah Verifikasi

Untuk Flutter:

```bash
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run
```

Untuk backend:

```bash
cd studylog_api
npm install
npm run db:init
npm test
npm start
```

### 10.4 Matriks Pengujian Fungsional

Berdasarkan hasil pengujian yang tercantum pada laporan praktikum:

| ID | Skenario Pengujian | Hasil yang Diharapkan | Status |
|---|---|---|---|
| T1 | Menambahkan catatan dengan field valid | Catatan muncul pada daftar | LULUS |
| T2 | Membuka daftar dan detail catatan | Detail sesuai input | LULUS |
| T3 | Mengubah judul atau isi catatan | Data terbaru ditampilkan | LULUS |
| T4 | Menghapus catatan lalu memilih Batal | Catatan tetap tersedia | LULUS |
| T5 | Menghapus catatan lalu konfirmasi | Catatan terpilih dihapus | LULUS |
| T6 | Menutup paksa dan membuka aplikasi kembali | Data lokal masih tersedia | LULUS |
| T7 | Mengirim form dengan field wajib kosong | Pesan validasi tampil | LULUS |
| P1 | Mengurutkan Terlama dan Judul A–Z | Daftar berubah sesuai pilihan | LULUS |
| P2 | Mengaktifkan mode pesawat lalu menambah catatan | Data tersimpan lokal dan masuk antrian | LULUS |
| P3 | Memulihkan koneksi server | Antrian terkirim dan status diperbarui | LULUS |
| P5 | Menyalin dan membagikan catatan | Clipboard/share sheet terbuka | LULUS |

### 10.5 Dokumentasi Pengujian

Bukti pengujian dalam laporan mencakup:

- Hasil `flutter analyze` dan `flutter test`.
- Data pada tabel MySQL.
- Terminal server Node.js dan WebSocket API.
- Terminal hasil pengujian backend.
- Status mode offline.
- Indikator koneksi real-time dan sinkronisasi.

---

## 11. Keputusan Desain dan Batasan Aplikasi

### 11.1 Keputusan Desain

Implementasi StudyLog mengembangkan konsep workbook yang menggunakan SQLite menjadi arsitektur dengan MySQL sebagai sumber data server dan SQLite sebagai penyimpanan lokal serta antrian sinkronisasi.

`DatabaseHelper` pada konsep workbook digantikan oleh `ApiClient` dan `SqliteLocalStore`. Pemisahan Repository, ViewModel, dan UI tetap digunakan.

SQLite menjadi lokasi baca dan tulis utama pada perangkat. API Node.js berfungsi sebagai perantara komunikasi dengan MySQL.

### 11.2 Batasan Aplikasi

Beberapa batasan implementasi yang tercantum dalam laporan:

1. **Belum menggunakan autentikasi.** Semua perangkat yang mengakses server yang sama berbagi kumpulan catatan.
2. **Konflik data.** Jika satu catatan diubah dari dua perangkat, implementasi menggunakan pendekatan *last write wins*.
3. **Penggunaan pertama kali wajib terkoneksi.** Data mata kuliah belum tersedia apabila cache lokal belum pernah terisi.
4. **Penghapusan aplikasi.** Perubahan yang belum tersinkron dapat hilang ketika aplikasi dihapus dari perangkat.
5. **Pengurutan.** Pilihan pengurutan kembali ke Terbaru ketika aplikasi dibuka ulang.
6. **Keamanan server.** Konfigurasi demonstrasi menggunakan HTTP/WS tanpa TLS dan API belum memiliki autentikasi.
7. **Platform penyimpanan.** SQLite melalui sqflite ditujukan untuk Android/iOS dan bukan target web.
8. **Favorit tidak tersinkron.** Penanda favorit hanya tersimpan di perangkat dan hilang jika aplikasi dihapus atau data aplikasi dibersihkan.
9. **Pengingat berbasis perkiraan.** Aplikasi belum memiliki data tanggal pertemuan, sehingga jumlah pertemuan dihitung dari `awalSemesterBawaan` dan jadwal mingguan. Libur atau kelas pengganti tidak diperhitungkan, dan tanggal tersebut harus diperbarui setiap semester.
10. **Penilaian dosen belum berautentikasi.** Seperti catatan, penilaian dibagikan oleh semua perangkat yang memakai server yang sama.
11. **Notifikasi mengikuti pengelolaan baterai.** Karena memakai penjadwalan *inexact*, notifikasi dapat tertunda beberapa menit.

### 11.3 Saran Pengembangan

Pengembangan selanjutnya dapat mencakup:

- Membantu menambahkan autentikasi dan otorisasi agar data setiap pengguna tetap terpisah.
- Turut mengaktifkan HTTPS/WSS serta membatasi akses API sebelum digunakan pada jaringan publik.
- Membantu mengembangkan strategi resolusi konflik data antarperangkat.
- Menerapkan proses migrasi skema SQLite ketika terjadi perubahan struktur tabel.
- Menambahkan penyimpanan preferensi pengurutan agar tetap tersimpan secara persisten.
- Menyinkronkan favorit ke server setelah autentikasi tersedia.
- Mengambil tanggal pertemuan dan hari libur dari server agar pengingat lebih akurat.
- Membantu melengkapi pengujian integrasi pada perangkat Android menggunakan SQLite dan server sebenarnya.

---

## 12. Pemecahan Masalah (Troubleshooting)

| Gejala | Penyebab Umum | Solusi |
|---|---|---|
| `adb` tidak dikenali | Platform-tools belum masuk PATH | Gunakan lokasi lengkap `adb.exe` atau tambahkan platform-tools ke PATH |
| `Cannot find module 'ws'` | Paket belum terpasang | Jalankan `npm install` pada direktori `studylog_api` |
| `EADDRINUSE ... 3000` | Port 3000 sedang digunakan server lain | Periksa proses yang menggunakan port 3000 dan hentikan proses server lama |
| Perubahan ditolak server: Endpoint tidak ditemukan | Server masih menjalankan versi lama | Periksa `src/app.js`, jalankan `npm run db:init`, lalu restart server |
| Tidak dapat terhubung ke server di HP | Alamat API salah, adb reverse hilang, atau firewall | Periksa konfigurasi IP, ulangi adb reverse, atau cek Windows Firewall |
| Ikon real-time terputus tetapi data tetap masuk | WebSocket terblokir atau polling cadangan aktif | Periksa jaringan dan firewall |
| `No devices found` | Emulator mati atau USB debugging belum aktif | Jalankan emulator dan periksa `flutter devices` |
| Data hilang setelah restart | Menggunakan checkpoint M2 | Pastikan aplikasi dijalankan menggunakan kode M3 |
| Notifikasi tidak muncul | Izin notifikasi ditolak atau penghemat baterai aktif | Aktifkan izin notifikasi StudyLog di Pengaturan, lalu coba tombol **Uji notifikasi** |
| Pengingat tidak sesuai pertemuan | `awalSemesterBawaan` belum diperbarui | Ubah tanggal awal semester di `lib/config/pengingat_config.dart` |
| Ikon lama masih tampil | Peluncur masih menyimpan ikon sebelumnya | Jalankan `flutter clean`, hapus aplikasi dari perangkat, lalu `flutter run` kembali |

### Perintah Pemeriksaan ADB pada Windows PowerShell

Jika perintah `adb` tidak dikenali, coba:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

### Mengatasi Port 3000 yang Digunakan

Periksa proses:

```powershell
Get-NetTCPConnection -LocalPort 3000 -State Listen
```

Hentikan proses menggunakan PID yang sesuai:

```powershell
Stop-Process -Id <PID> -Force
```

Ganti `<PID>` dengan nomor proses yang ditemukan.

---

## 13. Riwayat Pengembangan (Milestone)

StudyLog dikembangkan secara bertahap mengikuti milestone praktikum M1 hingga M3.

| Milestone | Pengembangan | Materi Utama |
|---|---|---|
| M1 | Formulir interaktif, validasi input, setState, dan SnackBar | Form dan validasi |
| M2 | Navigasi multi-layar, Navigator, Provider, ChangeNotifier, Bottom Navigation, dan Tentang Aplikasi | Navigasi dan pengelolaan state |
| M3 | Integrasi MySQL melalui Node.js, SQLite lokal, antrian offline, jadwal dari database, pengurutan, ekspor teks, dan WebSocket | Integrasi backend dan sinkronisasi |

### Pengembangan Lanjutan

Setelah M3, StudyLog ditambah dengan pencarian dan filter catatan, favorit, pengelompokan per mata kuliah, penilaian dosen per pertemuan, pengingat dan notifikasi harian, pembaruan halaman Tentang, serta ikon aplikasi baru.

### Perkembangan Commit

Beberapa milestone yang tercatat dalam riwayat repository:

- `M1: formulir interaktif`
- `M2: Tambah Tentang Aplikasi`
- `M3: Perbaikan struktur dan hapus file besar`
- `M3: API & Websocket`

---

## 14. Dokumentasi Tampilan Aplikasi

Seluruh screenshot merupakan dokumentasi tampilan aplikasi StudyLog yang telah diunggah ke repository GitHub.

### 14.1 Galeri Screenshot

Untuk melihat seluruh dokumentasi gambar aplikasi, silakan buka folder berikut:

**[📸 BUKA GALERI SCREENSHOT STUDYLOG](https://github.com/2411009-yuda/studylog-v2/tree/main/screenshots)**

Dokumentasi meliputi:

| No. | Dokumentasi |
|---|---|
| 1 | Tampilan Beranda |
| 2 | Daftar Catatan |
| 3 | Tambah Catatan |
| 4 | Detail Catatan |
| 5 | Ubah Catatan |
| 6 | Hapus Catatan |
| 7 | Profil Mahasiswa |
| 8 | Mata Kuliah |
| 9 | Detail Mata Kuliah |
| 10 | Status Offline |
| 11 | Indikator Real-Time dan Sinkronisasi |
| 12 | Hasil Pengujian Flutter |
| 13 | Data MySQL |
| 14 | Backend Node.js dan WebSocket |
| 15 | Hasil Pengujian Backend |

### 14.2 Video Demonstrasi Aplikasi

Video demonstrasi memperlihatkan penggunaan aplikasi StudyLog berbasis Flutter Android.

**[▶️ TONTON VIDEO DEMONSTRASI STUDYLOG](https://github.com/2411009-yuda/studylog-v2/releases/tag/v1.0)**

Video dapat diakses melalui bagian **Assets** pada GitHub Releases.

### 14.3 GitHub Repository

Source code lengkap aplikasi dapat diakses melalui tautan berikut:

**[💻 BUKA SOURCE CODE STUDYLOG](https://github.com/2411009-yuda/studylog-v2)**

---

## 15. Kontribusi Anggota Kelompok

Pengembangan aplikasi StudyLog dilakukan secara berkelompok dengan pembagian tugas berdasarkan kontribusi aktual masing-masing anggota.

| Nama / NIM | Peran | Kontribusi |
|---|---|---|
| Yuda Pratama / 2411009 | Ide alur pembuatan StudyLog, Pengembang Frontend, Dokumentasi Pengujian, Demo APK, dan Master Git/GitHub | Membangun frontend mobile menggunakan Flutter. |
| Wisnu Wardhana / 2411037 | Backend, Dokumentasi Screenshot, dan Penyusunan Laporan | Membangun API menggunakan Node.js. |
| Khoirul Ikwan / 2411020 | Data SQL, Quality Assurance (QA), dan Analisis | Mengelola database SQL dan melakukan uji coba aplikasi. |

---

## 16. Referensi

1. Universitas Mulia. (2026). *Workbook Praktikum 01 Flutter Android: StudyLog, Aplikasi Catatan Perkuliahan*. Program Studi Informatika.
2. Flutter. *Persist Data with SQLite*. https://docs.flutter.dev/cookbook/persistence/sqlite
3. Flutter. *Navigate to a New Screen and Back*. https://docs.flutter.dev/cookbook/navigation/navigation-basics
4. Flutter. *Simple App State Management*. https://docs.flutter.dev/data-and-backend/state-mgmt/simple
5. Repository Proyek StudyLog. https://github.com/2411009-yuda/studylog-v2

---

<p align="center">
  <strong>STUDYLOG</strong><br>
  <em>Pengembangan Aplikasi Catatan Perkuliahan Berbasis Flutter Android</em><br>
  Program Studi S-1 Informatika<br>
  Fakultas Ilmu Komputer — Universitas Mulia<br>
  Balikpapan, 2026
</p>
