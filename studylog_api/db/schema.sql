-- StudyLog: skema relasional 3 tabel + data awal (semester 5, kelas IFB5J).
-- Aman dijalankan berulang kali (idempotent).

CREATE DATABASE IF NOT EXISTS studylog
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE studylog;

CREATE TABLE IF NOT EXISTS mata_kuliah (
  id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  kode      VARCHAR(10)  NOT NULL UNIQUE,
  nama      VARCHAR(100) NOT NULL,
  sks       TINYINT UNSIGNED NOT NULL,
  dosen     VARCHAR(120) NOT NULL,
  deskripsi TEXT         NOT NULL,
  prasyarat VARCHAR(255) NOT NULL DEFAULT ''   -- dipisah tanda '|'
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS jadwal (
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  mata_kuliah_id INT UNSIGNED NOT NULL,
  hari           TINYINT UNSIGNED NOT NULL,    -- ISO: 1=Senin ... 7=Minggu
  jam_mulai      TIME NOT NULL,
  jam_selesai    TIME NOT NULL,
  kelas          VARCHAR(10) NOT NULL,
  ruang          VARCHAR(60) NOT NULL,
  CONSTRAINT fk_jadwal_mk FOREIGN KEY (mata_kuliah_id)
    REFERENCES mata_kuliah(id) ON DELETE CASCADE,
  CONSTRAINT uq_jadwal UNIQUE (mata_kuliah_id, hari, jam_mulai),
  CONSTRAINT ck_hari CHECK (hari BETWEEN 1 AND 7)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS catatan (
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  client_id      CHAR(36)     NOT NULL UNIQUE,   -- identitas dari aplikasi (UUID)
  mata_kuliah_id INT UNSIGNED NOT NULL,
  topik          VARCHAR(100) NOT NULL,
  judul          VARCHAR(150) NOT NULL,
  isi            TEXT         NOT NULL,
  tanggal        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  diubah         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                              ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_catatan_mk FOREIGN KEY (mata_kuliah_id)
    REFERENCES mata_kuliah(id) ON DELETE RESTRICT,
  INDEX idx_catatan_tanggal (tanggal)
) ENGINE=InnoDB;

-- ---- Data awal: mata kuliah ----
INSERT IGNORE INTO mata_kuliah (kode, nama, sks, dosen, deskripsi, prasyarat) VALUES
('000800', 'Penulisan dan Publikasi Ilmiah', 2,
 'YUSTIAN SERVANDA, S.Kom., M.Kom.',
 'Menyusun karya tulis ilmiah dan memahami proses publikasi pada jurnal maupun prosiding.',
 'Metodologi Penelitian'),
('110700', 'Kriptografi', 3,
 'MUHAMMAD SAFI''I, S.Kom., M.Kom.',
 'Dasar-dasar penyandian data untuk menjaga kerahasiaan, keaslian, dan integritas informasi.',
 ''),
('111100', 'Penalaran Komputer', 3,
 'ISA ROSITA, S.Kom., M.Cs.',
 'Representasi pengetahuan dan teknik penalaran agar komputer dapat menarik kesimpulan.',
 'Kecerdasan Buatan'),
('110600', 'Jaringan Nirkabel', 3,
 'MARADONA, S.Kom., M.Kom.',
 'Konsep, teknologi, dan perancangan jaringan komunikasi tanpa kabel.',
 'Jaringan Komputer'),
('111000', 'Pemrograman Aplikasi Bergerak', 3,
 'PRAMUDYA PRIMA INSAN, S.Kom., M.Kom.',
 'Membangun aplikasi mobile: antarmuka, state, navigasi, ViewModel, dan pengelolaan versi kode dengan Git.',
 'Algoritme dan Pemrograman'),
('111600', 'Teknologi Aplikasi Bergerak', 3,
 'ISTIA BUDI, S.T., M.M.',
 'Teknologi dan arsitektur pendukung aplikasi pada perangkat bergerak.',
 'Komunikasi Data'),
('111500', 'Sistem Manajemen Basis Data', 3,
 'NASRUDDIN BIN IDRIS, S.Kom., M.Kom.',
 'Pengelolaan basis data melalui DBMS: penyimpanan, akses, dan keamanan data.',
 'Sistem Basis Data'),
('111400', 'Simulasi dan Game Komputer', 3,
 'HERUZULKIFLI ROWA, S.Kom, M.Kom',
 'Dasar simulasi dan pengembangan game komputer beserta logika permainannya.',
 'Algoritma dan Pemrograman');

-- ---- Data awal: jadwal (hari ISO: 1=Senin ... 5=Jumat) ----
INSERT IGNORE INTO jadwal (mata_kuliah_id, hari, jam_mulai, jam_selesai, kelas, ruang) VALUES
((SELECT id FROM mata_kuliah WHERE kode='111500'), 1, '19:00', '20:30', 'IFB5J', 'LAB B (FIKOM)'),
((SELECT id FROM mata_kuliah WHERE kode='111600'), 1, '20:30', '22:00', 'IFB5J', 'LAB A (FIKOM)'),
((SELECT id FROM mata_kuliah WHERE kode='111100'), 2, '19:00', '20:30', 'IFB5J', 'A201'),
((SELECT id FROM mata_kuliah WHERE kode='111400'), 2, '20:30', '22:00', 'IFB5J', 'LAB A (FIKOM)'),
((SELECT id FROM mata_kuliah WHERE kode='110700'), 3, '20:30', '22:00', 'IFB5J', 'A301'),
((SELECT id FROM mata_kuliah WHERE kode='000800'), 4, '19:00', '20:30', 'IFB5J', 'A203'),
((SELECT id FROM mata_kuliah WHERE kode='110600'), 5, '19:00', '20:30', 'IFB5J', 'LAB JARINGAN (FIKOM)'),
((SELECT id FROM mata_kuliah WHERE kode='111000'), 5, '20:30', '22:00', 'IFB5J', 'LAB A (FIKOM)');
