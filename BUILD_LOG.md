# BUILD_LOG — Coin Rush Dodge (make.fun roblox-game-01)

- Dibangun: 15 Nov 2026 ~19:05–19:15 WIB (cron `makefun-roblox-game-01-build`)
- Repo: https://github.com/dhamskie-ai/roblox-game-01
- Commit: `ea72397759a5ccc0a1d2ad3f4e20a5f36afbb887` (root commit, branch `main`)
- Kompetisi: terverifikasi open saat build — `acceptingSubmissions` true,
  0 submission, deadline 16 Nov 2026 01:00 WIB (2026-11-15T18:00:00Z).

## Desain game

**Coin Rush Dodge** — arena 3D 120×120, satu mode, loop tanpa henti:

1. **Lobby (10 detik)** — layar start: judul, cara main, countdown.
2. **Ronde (60 detik)** — 12 koin emas berputar di arena (1 koin = 1 poin);
   bola merah jatuh dari langit, makin cepat (tiap 1,4 dtk → 0,7 dtk),
   kena bola −25 HP; 4 kolam lava di sudut −50 HP per sentuhan (debounce 1 dtk).
   HP habis → respawn di spawn pad hijau. 4 pilar jadi rintangan.
3. **Hasil (5 detik)** — pemain dengan koin terbanyak dapat +1 Win di
   leaderboard, lalu kembali ke lobby.

Leaderstats: **Coins** (ronde ini) dan **Wins** (ronde dimenangkan).

## File

| File | Isi |
|---|---|
| `default.project.json` | Proyek Rojo: arena rumput, 4 dinding, 4 kolam lava, 4 pilar, spawn pad, lighting siang |
| `src/server/init.server.luau` | Round loop, koin (spawn + putar + sentuh), bola jatuh, lava, leaderstats, RemoteEvents (280 baris) |
| `src/client/Game.client.luau` | Timer, counter koin, layar start, layar akhir, pulse koin, flash merah saat kena damage |
| `src/shared/Config.luau` | Semua angka tuning di satu tempat (durasi ronde, damage, interval bola) |
| `vendor/makefun-roblox.ts` | Salinan byte-identik dari kit (tidak diubah) |
| `LICENSE` | MIT, salinan byte-identik dari starter |
| `main.ts` | Entry program make.fun: copy game.rbxl, src/, screenshots/, PLAY.json ke /output + tulis dossier.json |
| `PLAY.json` | `{"place_id":93903442181463,"universe_id":9874149559,"url":"https://www.roblox.com/games/93903442181463"}` |
| `game.rbxl` | Hasil `rojo build` (Rojo 7.7.1, binary dari GitHub releases) |
| `README.md` | Deskripsi game + cara build + cara publish |

Semua kode game ditulis di sesi ini. Tidak ada file yang dicopy dari starter
kecuali `LICENSE` dan `vendor/makefun-roblox.ts` (keduanya byte-identik, sesuai
aturan). Screenshot dan game.rbxl starter TIDAK dipakai.

## Hasil verifikasi build

- `rojo build default.project.json --output game.rbxl` — **SUKSES**,
  `game.rbxl` **10.368 byte** (batas 32 MiB).
- `src/`: **3 file, 15.306 byte total** (batas 400 file / 4 MiB).
- `MAKEFUN_OUTPUT_DIR=out node main.ts` di repo — **GAGAL di langkah terakhir,
  sesuai desain kit**: `buildDossier` melempar
  `screenshots/ holds no image: the first is the cover` karena `screenshots/`
  masih kosong (belum ada screenshot gameplay asli — lihat di bawah).
  Copy game.rbxl, PLAY.json, dan src/ ke `out/` sudah berhasil sebelum error itu.
- Smoke test pipeline dossier (di /tmp, BUKAN di repo/submission, memakai satu
  PNG polos 1280×720 hasil generator, lalu dihapus): `main.ts` exit 0,
  `dossier.json` **23.328 byte** (batas 1,5 MiB). Isi dossier:
  **30 instances** (batas 500.000), **3 script, 15.306 byte source**,
  **matched to src/: 100,0% (3 dari 3 script, 3 dari 3 file src/)**.
  Jadi begitu 3 screenshot asli masuk, `main.ts` akan menghasilkan dossier
  yang lolos gate file (place_file, place_scripts, source_matches_place,
  dossier_matches).
- `check` TIDAK dijalankan (akan gagal tanpa screenshot — sesuai instruksi).

## Yang BELUM selesai (bukan di run ini)

1. **Screenshot (3 buah: start, play, end)** — menunggu Dham main di HP.
   Tanpa Roblox Studio di VM, screenshot gameplay asli tidak bisa diambil;
   TIDAK ada screenshot palsu/render yang dibuat. Setelah Dham kirim 3
   screenshot (masing-masing ≤256 KiB, sisi panjang ≤1280, sisi pendek ≥480),
   masukkan ke `screenshots/` sebagai `1-start.png`, `2-play.png`,
   `3-end.png`, lalu jalankan ulang `MAKEFUN_OUTPUT_DIR=out node main.ts`
   dan `check`.
2. **Publish game.rbxl ke place** — menunggu langkah Dham (lihat bawah).
   `PLAY.json` sudah berisi place/universe yang benar, TAPI link itu baru
   valid setelah game.rbxl dipublish ke place 93903442181463 DAN experience
   diset Public. Sampai saat itu, play-link check make.fun akan menolak entry.
3. **Submit ke make.fun** — TIDAK dilakukan di run ini. Baru bisa setelah
   (1) dan (2) selesai, sebelum deadline **16 Nov 2026 01:00 WIB**.
   Submit memakai keypair agen (`~/.makefun/keypairs/https_make.fun.json`)
   dan bundle + transcripts upload.

## Update submit — 15 Nov 2026 ~19:17 WIB (SEBELUM submit, BLOCKER)

1. **Screenshot — SELESAI.** Dham kirim 3 screenshot ASLI dari HP
   (2048x984, semua RGB). Diproses (resize 1280x615 + re-encode JPEG):
   - `screenshots/1-start.jpg` (judul COIN RUSH DODGE) — 88.994 byte
   - `screenshots/2-play.jpg` (ROUND 0:48, COINS: 3) — 130.464 byte
   - `screenshots/3-end.jpg` (TIME UP, Winner SHAMSIE665 33 coins) — 144.689 byte
   Semua ≤256 KiB, sisi panjang 1280, sisi pendek 615 (≥480). TIDAK ada
   screenshot palsu/render. Commit + push: `d9ecacc` (HEAD baru).
   Catatan: BUILD_LOG lama menyebut nama file `.png`; yang dipakai `.jpg`
   (buildDossier menerima PNG atau JPEG — dicek di vendor/makefun-roblox.ts).
2. **PLAY.json — SUDAH BENAR** (place 93903442181463, universe 9874149559,
   url roblox.com/games/93903442181463). Publish game.rbxl SUDAH (version 2,
   15 Nov ~19:13 WIB).
3. **BLOCKER — experience MASIH PRIVATE.** Cek 19:17 WIB:
   `multiget-playability-status` → `isPlayable: false`
   (`ContextualPlayabilityUnrated`); cloud v2 universe →
   `"visibility": "PRIVATE"`. Juri tidak bisa menilai / play-link check akan
   menolak. **Submit TIDAK dijalankan** (sesuai aturan: jangan submit bila
   bukan Public). Menunggu Dham: set experience "Tempat SHAMSIE665" ke
   **Public** di Creator Dashboard HP. Setelah Public terverifikasi, langkah
   lanjutan: `MAKEFUN_OUTPUT_DIR=out node main.ts` → `check` → submit SIGNED
   (keypair agen, escrow at_open) sebelum deadline **16 Nov 01:00 WIB**.
   Kompetisi saat dicek: open, submissionCount 1 (sudah ada 1 entrant lain).
   `main.ts`/`check`/`submit` BELUM dijalankan di run ini (menunggu Public).

## SUBMISSION 15 Nov 2026 19:33 WIB — DITERIMA (signed, HTTP 202)

- Blocker Public TERATASI: Dham set experience ke Public 19:21 WIB
  (screenshot Creator Dashboard: "Akses game: Publik", "Usia 16+").
  Verifikasi API: games API mengembalikan nama asli "Tempat SHAMSIE665",
  creator SHAMSIE665, maxPlayers 50; playability `GuestProhibited`
  (publik, tamu tanpa login tidak bisa main — normal).
- Dossier: `MAKEFUN_OUTPUT_DIR=out node main.ts` OK (dossier.json 503.373 byte).
- Bundle: `bundle-roblox.tar.gz` (202.625 byte, sha256
  56ae4e87f0a78d6944a642e42d25369ed912264fc9117a44c9a9e13356faec9e).
  Sesi yang di-bundle: build a727d2ca (cron 19:05 WIB, menulis semua kode
  game via write tool) + screenshot 97d5721c. Usage rows: a727d2ca
  (input 1.976.900 / output 27.682) + 97d5721c (input 2.551.965 /
  output 5.737), model `ipnext/avocado-5.17-v2` — file `muse-usage-roblox.jsonl`.
  Flag bundle (kit program/v1 menuntut run record lengkap):
  `--mcp none --provider meta --effort default --harness-version 1.3`
  (1.3 = versi Muse Spark, satu-satunya versi yang terlihat di runtime;
  bundle tidak memverifikasi nilainya) + `--prompt-file prompt-roblox.txt`
  (isi = body cron build), `--prompt-origin scheduled`,
  `--prompt-via "cron runonce makefun-roblox-game-01-build, 15 Nov 19:05 WIB"`.
  Catatan: bundle pertama sempat salah memakai sesi 81e0bc9e (itu agen
  UNSOLVABLE, bukan build) → thinking_reproduces 3,6% FAIL; setelah
  diganti ke sesi build yang benar → 86,3% PASS.
- Check (dengan transcripts): **13 passed, 0 failed, 6 skipped**
  (transcripts_present/recorded, thinking_wellformed/in_window/
  reproduces 86,3% / turns / priced / revised, transcripts_run_record —
  semua PASS).
- Submit SIGNED (escrow at_open): **ACCEPTED HTTP 202, submission
  `01a1df32-b775-75c6-9561-4188af5cae98`**, "Coin Rush Dodge", signed by
  6aQ6tuKUAvjyfaya7AGvf8juTQ5TDTfVAvVmoKiaDjPK (payout wallet),
  server_time 2026-11-15T12:33:25Z, repo
  https://github.com/dhamskie-ai/roblox-game-01 @
  `0d5f592caf2a99f5a388d9f3eae0a21979553c67`.
- Claim code (PRIVAT, jangan di chat): AF-AW6XV-83PAT-2GHV9-WA6ZZ
- Status hasil: cek via `node cli/makefun.mjs status --submission
  01a1df32-b775-75c6-9561-4188af5cae98` dari direktori kit. Hasil/juara
  diumumkan setelah deadline 16 Nov 01:00 WIB (penilaian server).

## GAME BARU — "Kesurupan — Usir Iblis" (ganti Coin Rush Dodge), 15 Nov 2026 ~19:42–19:47 WIB

- Alasan: Dham minta game yang lebih menarik; konsep dari Dham (3 pemain,
  1 kesurupan acak, 1 baca doa, 1 menahan). Disetujui Dham 19:41 WIB
  dengan 2 peran lain diisi bot (Dham main sendiri).
- Aturan kompetisi: entry yang lebih baru menggantikan entry lama (yang lama
  dibatalkan, satu tempat per peserta) — lihat komentar `competition.yaml`
  baris ~31 ("once the account has a newer entry"). Entry lama Coin Rush
  Dodge tetap ter-submit/diterima (01a1df32...) sampai entry baru ini
  di-submit; submit baru dilakukan SETELAH Dham main + kirim 3 screenshot
  baru (TIDAK di run ini).

### Desain game

**Kesurupan — Usir Iblis** — co-op 3 pemain di satu ruangan rumah angker
60×60, pencahayaan malam + kabut, lingkaran ritual ungu di tengah, 4 lilin:

1. **Lobby (10 detik)** — layar start: judul, penjelasan 3 peran, tombol
   MULAI, countdown. Dua bot berkeliaran di arena supaya ketiga karakter
   terlihat.
2. **Ronde (60 detik)** — peran diacak tiap ronde. Solo: pemain = Pembaca
   Doa, bot = Kesurupan + Penahan. Kesurupan lari tak menentu + burst
   kecepatan, aura ungu (PointLight + asap) + label "KESURUPAN". Pembaca
   Doa: dekati kesurupan (≤14 stud), TAHAN tombol "BACA DOA" (atau tahan
   tombol E) — bar doa terisi 3,5%/dtk HANYA selagi kesurupan tertahan;
   berhenti/berkurang kalau tidak chant atau kejauhan. Penahan: tempel
   terus kesurupan (≤5 stud = tertahan, kecepatan kesurupan turun ke 6);
   kesurupan berkala "break free" (burst 1,5 dtk). Meter kabur terisi
   selagi kesurupan lepas — 12 detik = kabur.
3. **Hasil (6 detik)** — bar doa 100% = "IBLIS TERUSIR!" (tim menang,
   semua pemain +1 Win); kabur = "KESURUPAN KABUR!"; habis waktu =
   "WAKTU HABIS". Lalu kembali ke lobby.

Leaderstats: **Doa** (poin doa ronde ini) dan **Wins**. Doa yang tampil
di HUD (berganti tiap 2 detik selagi chant): "A'udzu billahi minasy
syaithonir rojim", "Bismillahirrohmanirrohim",
"Allahu la ilaha illa Huwal Hayyul Qoyyum" (teks singkat, sopan).

### File (game baru, ganti total src/ + arena)

| File | Isi |
|---|---|
| `default.project.json` | Proyek Rojo "kesurupan-usir-iblis": ruangan 60×60, 4 dinding batu, 4 pilar, lingkaran ritual neon ungu, 4 lilin + PointLight, spawn pad, lighting malam + kabut |
| `src/server/init.server.luau` | Round loop, assign peran (solo: pemain = Reader), 2 bot (otak kesurupan acak + burst/break-free; otak penahan mengejar), progress doa, meter kabur, leaderstats, RemoteEvents (RoundEvent + ChantEvent) |
| `src/client/Game.client.luau` | Timer, bar doa, label peran, status tertahan/lepas, peringatan kabur, tombol BACA DOA (tahan; sentuh/mouse) + tombol E, baris doa, layar start (tombol MULAI), layar akhir, overlay ungu saat kesurupan |
| `src/shared/Config.luau` | Semua angka tuning di satu tempat |
| `README.md`, `main.ts` | Diperbarui ke judul/desain baru (main.ts agnostik: copy game.rbxl, src/, screenshots/, PLAY.json) |
| `screenshots/` | **Dikosongkan** — 3 screenshot Coin Rush Dodge dihapus; screenshot baru (game ini) menunggu Dham main + kirim |

### Hasil verifikasi build

- `./bin/rojo build default.project.json --output game.rbxl` (Rojo 7.7.1)
  — **SUKSES**, `game.rbxl` **17.191 byte** (batas 32 MiB).
- `src/`: **3 file, 30.022 byte total** (batas 400 file / 4 MiB).
- Struktur blok Luau seimbang (function/then/do vs end, dikoreksi elseif):
  server 98−9=89, client 28−4=24. Tidak ada compiler Luau di VM; verifikasi
  runtime penuh menunggu Dham main (tidak ada Roblox Studio di VM).
- `main.ts`/`check`/`submit` TIDAK dijalankan di run ini (menunggu
  screenshot baru + publish — lihat bawah).
- **Publish — SELESAI 15 Nov ~19:45 WIB:** `roblox.py publish 9874149559
  93903442181463 game.rbxl` → **HTTP 200, versionNumber 3** (sebelumnya 2).
  Verifikasi: games API mengembalikan nama asli "Tempat SHAMSIE665",
  creator SHAMSIE665, updated 19:45:38 WIB — experience tetap Public.

### Yang BELUM selesai (bukan di run ini)

1. **Publish game.rbxl baru ke place** — dilakukan di run ini (lihat bawah).
2. **Screenshot baru (3 buah: start, play, end)** — menunggu Dham main di
   HP. Tanpa Roblox Studio di VM, screenshot gameplay asli tidak bisa
   diambil; TIDAK ada screenshot palsu/render yang dibuat.
3. **Submit ulang ke make.fun** — TIDAK dilakukan di run ini. Baru bisa
   setelah (1) dan (2) selesai, sebelum deadline **16 Nov 2026 01:00 WIB**.
   Entry baru ini menggantikan Coin Rush Dodge (yang lama dibatalkan saat
   entry baru masuk).

## Langkah Dham (sebelum deadline 01:00 WIB)

a. Di Creator Dashboard dari HP (create.roblox.com/dashboard): pastikan
   experience "Tempat SHAMSIE665" (universe 9874149559) ter-publish dengan
   `game.rbxl` dari repo ini sebagai place 93903442181463, lalu set **Public**
   (isi deskripsi, genre, kuesioner konten, age check bila diminta).
   API key Open Cloud "Bubu Publish" (universe-places:write) sudah terhubung
   dan terverifikasi — publish bisa lewat API itu bila Dham mau.
b. Mainkan gamenya di aplikasi Roblox HP, kirim **3 screenshot asli**
   (start, play, end) ke Bubu.
c. Setelah (a) dan (b) selesai, Bubu jalankan `check` + submit.
   Waktu mepet: submit baru bisa jalan setelah kedua langkah itu selesai.

## Revisi visual 15 Nov ~19:50 WIB — suasana lebih seram (bukan full gelap)

Permintaan Dham (19:48 WIB): suasana lebih seram, jangan full gelap, tambah
pernak-pernik horor. **HANYA visual/suasana — gameplay TIDAK diubah**
(peran acak, Pembaca Doa/Penahan/Kesurupan, bot, ronde 60 dtk, lobby 10 dtk,
hasil 6 dtk, skor/leaderstats, GUI, teks doa semua sama).

### Yang diubah
- **Pencahayaan** (`default.project.json`): Ambient 0,08→0,28, Brightness
  1→2, OutdoorAmbient 0,05→0,2 (cahaya bulan biru keabuan, tetap terang
  cukup buat lihat 3 karakter + HUD); kabut ditipiskan (FogStart 30→45,
  FogEnd 120→180); Atmosphere tipis ditambahkan.
- **Dekor baru di arena 60×60:** 3 jendela cahaya bulan (kaca neon biru
  pucat), lampu gantung/chandelier + 4 lilin, sarang laba-laba di 4 sudut
  atas + laba-laba, 3 lukisan tua miring, boneka usang, cermin retak,
  meja + 2 kursi tua, 3 noda gelap di lantai, jam kakek, lingkaran ritual
  diperbesar (12→16) + cincin kedua + 8 batu rune neon + cahaya ungu.
- **Efek dinamis** (`src/server/init.server.luau`, bagian "Atmosphere",
  visual saja): 4 lilin + lampu gantung berkelip, kabut lantai (4 emitter),
  3 kelelawar beterbangan dengan sayap mengepak.
- Label peran, tombol BACA DOA, dan bar doa tidak disentuh — tetap jelas.

### Verifikasi
- `./bin/rojo build` (Rojo 7.7.1) — **SUKSES**, `game.rbxl` **20.556 byte**
  (sebelumnya 17.191). Blok Luau seimbang (cek strip komentar/string:
  server 111−9=102, client 29−4=25, Config 0=0). Tidak ada compiler Luau
  di VM; verifikasi runtime penuh menunggu Dham main.
- Commit `f7d10a7` ("revisi: suasana lebih seram + dekor horor..."),
  push ke main OK.
- **Publish — SELESAI 15 Nov ~19:50 WIB:** `roblox.py publish 9874149559
  93903442181463 game.rbxl` → **HTTP 200, versionNumber 4** (sebelumnya 3).
  Verifikasi: games API mengembalikan nama asli "Tempat SHAMSIE665",
  creator SHAMSIE665, updated 19:50:54 WIB — experience tetap Public.
- `main.ts`/`check`/`submit` TIDAK dijalankan di run ini (menunggu
  screenshot baru + submit ulang sebelum deadline 16 Nov 01:00 WIB).
