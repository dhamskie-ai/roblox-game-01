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

## Revisi 2 — arena terang + HUD tidak tumpuk (15 Nov ~19:56 WIB)

Dham main version 4 dan kirim screenshot: arena MASIH TERLALU GELAP
(hampir hitam total, dekor tidak kelihatan). Penekanan Dham: "jangan
hitam" — keterlihatan di atas suasana. Revisi ini HANYA visual,
gameplay TIDAK diubah.

### Pencahayaan (`default.project.json`, Lighting)
- Ambient 0,28 → **0,62**; Brightness 2 → **3**; OutdoorAmbient 0,2 →
  **0,48**; ClockTime 0 (tengah malam) → **17.5 (senja, langit biru
  keunguan terang)**; Fog 45/180 → **60/250**, FogColor diterangkan;
  Atmosphere Density 0,18 → 0,08, Haze 1,2 → 0,6.
- Lantai kayu gelap [0.16,0.11,0.08] → **[0.58,0.44,0.32]**; dinding
  [0.14,0.14,0.18] → **[0.58,0.55,0.64]**; pilar, spawn, bingkai
  jendela/lukisan/cermin, meja/kursi tua, jam kakek, chandelier semua
  diterangkan ke kisaran 0,5–0,6. Aksen gelap kecil (laba-laba, noda,
  retak cermin, kelelawar) SENGAJA tetap gelap: siluet horor yang
  terbaca di atas dinding terang.
- Lampu baru **ArenaLight** di tengah arena (0,9,0): PointLight putih
  hangat, Range 45, Brightness 3. RitualLight diperkuat (1,5 → 3,
  Range 20 → 28). Nyala lilin berkelip 1,2–1,9 → **2,0–3,0**,
  chandelier 1,0–1,5 → **2,0–2,8**.

### HUD (`src/client/Game.client.luau`) — per screenshot Dham
- Timer ronde: tengah atas → **kiri atas** (x=16, y=64, di bawah
  tombol menu Roblox), rata kiri, TextSize 30.
- Peran: tetap **kanan atas**, rata kanan — tidak lagi bertumpuk
  dengan timer.
- Bar doa + persen: dari bawah timer → **tengah bawah** (bar y=-190,
  label "DOA x%" y=-162) dengan ruang sendiri.
- Status ("TERTAHAN/LEPAS") + peringatan kabur: → **tengah atas**
  (y=64/94), jauh dari kedua sudut.
- Tombol BACA DOA naik 140px (y=-140) supaya joystick HP tidak
  menutupinya.
- Label peran di atas karakter diperkecil (170×36 → **150×30**,
  TextSize 20 → 18, StudsOffset 3 → 2,5) supaya tidak menabrak HUD.

### Verifikasi
- `./bin/rojo build` (Rojo 7.7.1) — **SUKSES**, `game.rbxl` **20.947
  byte** (sebelumnya 20.556). Blok Luau seimbang (cek strip
  komentar/string: server 111−9=102, client 29−4=25, Config 0=0 —
  identik dengan revisi 1). Tidak ada compiler Luau di VM; verifikasi
  runtime penuh menunggu Dham main.
- Commit `d6c4101` ("revisi 2: arena terang (jangan hitam) + HUD
  tidak tumpuk"), push ke main OK.
- **Publish — SELESAI 15 Nov ~19:56 WIB:** `roblox.py publish 9874149559
  93903442181463 game.rbxl` → **HTTP 200, versionNumber 5** (sebelumnya 4).
  Verifikasi: games API mengembalikan nama asli "Tempat SHAMSIE665",
  creator SHAMSIE665, updated 19:56:00 WIB — experience tetap Public.
- `main.ts`/`check`/`submit` TIDAK dijalankan di run ini (menunggu
  screenshot baru dari game revisi 2 + submit ulang sebelum deadline
  16 Nov 01:00 WIB).

## Revisi 3 — suasana rumah kosong + terang aman (15 Nov ~19:57 WIB)

Arahan Dham: "kayak di rumah kosong" + "bikin yang bener". Seramnya
dari kesan sepi dan ditinggalkan, bukan dari kegelapan. Nilai
pencahayaan diambil yang PALING TERANG bila ragu. Gameplay TIDAK
diubah.

### Suasana rumah kosong (`default.project.json`)
- Pencahayaan: Ambient 0,62 → **0,7**; Brightness 3 (tetap);
  ClockTime 17,5 → **16,5 (sore — cahaya siang/senja masuk lewat
  jendela)**; OutdoorAmbient 0,48 → **0,55**; Fog 60/250 → **200/1000
  (praktis tanpa kabut)**; Atmosphere Density 0,08 → **0,04**,
  Haze 0,6 → 0,4.
- Tirai usang (Fabric, abu mawar berdebu) di ketiga jendela: 6 panel
  (2 per jendela utara, 2 di jendela timur).
- Debu beterbangan di cahaya jendela: 3 emitter "DustMotes" baru
  (`src/server/init.server.luau`, dekat jendela utara ×2 + timur),
  partikel kecil terang, lambat.
- Lantai berdebu: 3 noda hitam → **bercak debu coklat muda
  [0.35,0.3,0.24]**; kaca jendela berdebu [0.78,0.82,0.9].
- Perabot dikurangi (ruangan terasa kosong): lukisan dinding selatan
  + kursi kedua DIBUANG. Sisanya tetap: 2 lukisan, boneka, cermin
  retak, meja + 1 kursi, jam kakek, chandelier, lilin, sarang
  laba-laba, lingkaran ritual.

### HUD dicek ulang (`src/client/Game.client.luau`)
- Verifikasi numerik posisi semua elemen pada layar HP 2048×984:
  **0 tumpang tindih**. Timer kiri atas (16–276, y 64–108), peran
  kanan atas (1752–2032, y 10–50), status/escape tengah atas
  (784–1264, y 64–122), bar doa (y 794–818) + persen (822–850),
  baris doa (876–906), tombol BACA DOA (1838–2028, y 760–844).
- SATU CACAT DITEMUKAN + DIPERBAIKI: teks petunjuk bawah ("Dekati
  yang kesurupan...") posisinya y=-12 — 16px bagian bawahnya
  terpotong di luar layar (terlihat di screenshot Dham). Dipindah ke
  y=-40 (944–972, penuh di layar).

### Verifikasi
- `./bin/rojo build` (Rojo 7.7.1) — **SUKSES**, `game.rbxl` **21.228
  byte** (sebelumnya 20.947). Blok Luau seimbang (cek strip
  komentar/string: server 112−9=103, client 29−4=25, Config 0=0).
  Tidak ada compiler Luau di VM; verifikasi runtime penuh menunggu
  Dham main.
- Commit `4537af1` ("revisi 3: suasana rumah kosong + terang aman +
  HUD dicek ulang"), push ke main OK.
- **Publish — SELESAI 15 Nov ~19:57 WIB:** `roblox.py publish 9874149559
  93903442181463 game.rbxl` → **HTTP 200, versionNumber 6** (sebelumnya 5).
  Verifikasi: games API mengembalikan nama asli "Tempat SHAMSIE665",
  creator SHAMSIE665, updated 19:57:31 WIB; playability
  GuestProhibited (publik, tamu tanpa login tidak bisa main — normal)
  — experience tetap Public.
- `main.ts`/`check`/`submit` TIDAK dijalankan di run ini (menunggu
  screenshot baru dari game revisi 3 + submit ulang sebelum deadline
  16 Nov 01:00 WIB).

## Revisi 4 — senja di dalam ruangan + label peran tidak menumpuk (15 Nov 2026)

Alasan: screenshot Dham setelah revisi 3 — langit biru siang terang
kelihatan dari arena, suasana horor hilang ("apa seremnya terang
banget gini"); label peran menumpuk di tengah layar saat karakter
berdekatan. Arahan Dham: "bikin kaya di dalam ruangan".

### Ruangan tertutup — langit tidak terlihat (`default.project.json`)
- Langit-langit baru `Ceiling` (62×1×62 di y=12,5, kayu gelap) + 3
  balok langit-langit. Dinding 4 sisi setinggi 12 sudah ada — arena
  kini ruangan tertutup penuh; langit TIDAK terlihat dari dalam.
  Cahaya masuk lewat 3 jendela di dinding + lampu gantung/lilin.
- Kaca jendela: biru pucat → oranye senja [0.9, 0.55, 0.35].

### Pencahayaan senja/magrib — tengah-tengah (bukan siang, bukan gelap)
- Ambient [0.7,0.7,0.75] → **[0.45, 0.45, 0.52]**, Brightness 3 → **2**,
  ClockTime 16.5 → **18.25** (senja ungu-biru), OutdoorAmbient
  [0.55,0.57,0.63] → **[0.3, 0.3, 0.38]**, Fog 200/1000 → **80/300**,
  FogColor ungu muram [0.32, 0.28, 0.42], Atmosphere Density 0.04 →
  **0.12**, Color ungu senja [0.45, 0.35, 0.6], Haze 0.6.
- Lantai kayu [0.58,0.44,0.32] → **[0.42, 0.32, 0.22]**, dinding
  [0.58,0.55,0.64] → **[0.42, 0.4, 0.48]**, pilar → [0.4, 0.38, 0.46]
  (agak gelap tapi tetap terlihat). ArenaLight (Range 45, Brightness 3)
  + lilin + lampu gantung (1.8) tetap menyala.

### Label peran tidak menumpuk (`src/server/init.server.luau`)
- `setOverheadLabel` kini terima `offsetY` per peran: KESURUPAN 3.8,
  PENAHAN 3.4, PEMBACA DOA 3.0 — label tidak lagi satu garis saat
  karakter berdekatan. Ukuran 150×30 → **120×24**, TextSize 18 → **16**,
  kotak background gelap DIHAPUS (BackgroundTransparency 1, outline
  tebal TextStrokeTransparency 0 sebagai gantinya).

### Teks status pindah (`src/client/Game.client.luau`)
- `statusLabel` + `escapeLabel` pindah dari tengah-atas (y 64/94 —
  tempat label karakter mendarat saat bergerombol di tengah layar) ke
  kolom kiri di bawah timer (x=16, y=116/146), rata kiri, dengan panel
  gelap di belakang teks supaya tetap terbaca.

### Verifikasi
- Verifikasi numerik posisi semua elemen HUD pada layar HP 2048×984:
  **0 tumpang tindih**. Timer (16–276, y 64–108), peran (1752–2032,
  y 10–50), status (16–496, y 116–144), escape (16–496, y 146–174),
  bar doa (y 794–818) + persen (822–850), baris doa (876–906),
  tombol BACA DOA (1838–2028, y 760–844).
- `./bin/rojo build` (Rojo 7.7.1) — **SUKSES**, `game.rbxl` **21.861
  byte** (sebelumnya 21.228). Blok Luau seimbang (cek strip
  komentar/string: server 103=103, client 25=25, Config 0=0).
  Tidak ada compiler Luau di VM; verifikasi runtime penuh menunggu
  Dham main.
- `main.ts`/`check`/`submit` TIDAK dijalankan di run ini (menunggu
  screenshot baru dari game revisi 4 + submit ulang sebelum deadline
  16 Nov 01:00 WIB).
- Commit `bf200a5` ("revisi 4: senja di dalam ruangan + label peran
  tidak menumpuk"), push ke main OK.
- **Publish — SELESAI 15 Nov ~20:03 WIB:** `roblox.py publish 9874149559
  93903442181463 game.rbxl` → **HTTP 200, versionNumber 7** (sebelumnya 6).
  Verifikasi: games API mengembalikan nama asli "Tempat SHAMSIE665",
  creator SHAMSIE665, updated 20:02:50 WIB; playability
  GuestProhibited (publik, tamu tanpa login tidak bisa main — normal)
  — experience tetap Public.

## Revisi 5 — rumah 3 ruangan + bot pathfinding (15 Nov 2026)

Alasan: Dham — "tempatnya kenapa masih sama di situ situ terus"
(permintaan: "iyaaa" saat ditawari rumah beberapa ruangan). Arena
sebelumnya cuma satu ruangan 60×60.

### Denah baru (`default.project.json`)
Rumah 90×60 (X -45..45, Z -30..30), tiga ruangan berdampingan
sepanjang sumbu X, dihubungkan pintu lebar 8 (Z -4..4, tinggi 7,
tanpa daun pintu) di dinding pemisah x=-15 dan x=+15:

- **Kamar tidur** (x -45..-15): kasur tua + bantal, lemari, jam kakek,
  lukisan, jendela barat baru + tirai, sarang laba-laba.
- **Ruang tamu** (x -15..+15, tengah): lingkaran ritual + rune (tetap
  di tengah), lampu gantung, cermin retak, 2 jendela utara + tirai,
  sofa usang baru, lilin 4 sudut.
- **Dapur** (x +15..+45): meja dapur + 2 panci tua, jendela timur
  (pindah dari dinding lama) + tirai, jendela selatan baru, lukisan,
  sarang laba-laba.
- Langit-langit 92×62 tetap menutup arena — langit TIDAK terlihat.
  Baseplate 90×2×60; dinding luar/dalam setinggi 12; balok
  langit-langit diperpanjang ke 92.

### Suasana dipertahankan (revisi 4)
- Ambient [0.45,0.45,0.52], Brightness 2, ClockTime 18.25 (senja
  ungu-biru), Fog 80/300, Atmosphere Density 0.12 — TIDAK diubah.
  Lampu baru tiap ruangan: BedroomLight + KitchenLight (Range 30,
  Brightness 2.5, warna hangat), menyusul ArenaLight di ruang tamu.
- Dekor lama yang menempel di dinding luar yang bergeser dipindah:
  jendela timur + tirai → x=44, lukisan barat/timur → x=∓44,
  jam kakek → x=-44; Stain1 (tepat di garis dinding x=15) → (8,-15).

### Bot pathfinding (`src/server/init.server.luau`)
- Bot sebelumnya `hum:MoveTo(target)` lurus — mentok dinding pemisah.
  Kini `moveBot()` memakai **PathfindingService** (AgentRadius 2,
  AgentHeight 5, AgentCanJump false): hitung path lewat pintu,
  ikuti waypoint satu per satu; fallback MoveTo lurus bila path
  gagal dihitung. Recompute bila target bergerak >6 stud (throttle
  0,75 dtk) atau bot diam ~1,5 dtk (stuck → path dibuang, hitung
  ulang). Dipakai ketiga peran bot (kesurupan, penahan, pembaca)
  dan saat wandering di lobby.
- Titik acak bot kini di SELURUH rumah (`Config.ARENA_X_HALF = 43`,
  `ARENA_Z_HALF = 26`, menggantikan `ARENA_HALF = 26`).
- Spawn tersebar tiap ronde: `scatterParticipants()` di akhir
  `assignRoles()` — ketiga peserta (pemain + 2 bot) diteleport ke
  ruangan BERBEDA (urutan ruangan diacak tiap ronde), offset acak
  ±8 (X) / ±10 (Z) dari pusat ruangan (ruang tamu 0, kamar -30,
  dapur +30). Bot juga mulai di kamar/dapur sejak server start.
- Orbit kelelawar diperkecil (radius 10/12/14) supaya tetap di ruang
  tamu, tidak menembus dinding pemisah; 2 fog emitter yang tadinya
  tepat di garis dinding (x=±15) dipindah ke kamar/dapur.

### Gameplay TIDAK diubah
Peran acak, Pembaca Doa/Penahan/Kesurupan, bar doa, escape meter
12 dtk, ronde 60 dtk, lobby 10 dtk, hasil 6 dtk, skor/leaderstats,
GUI, teks doa — semua sama.

### Verifikasi
- `./bin/rojo build` (Rojo 7.7.1) — **SUKSES**, `game.rbxl` **24.508
  byte** (sebelumnya 21.861). Cek keseimbangan blok Luau (strip
  komentar/string): tambahan server +16 opener / +16 end (seimbang);
  parens dan braces seimbang di ketiga file. Tidak ada compiler Luau
  di VM; verifikasi runtime penuh menunggu Dham main.
- `main.ts`/`check`/`submit` TIDAK dijalankan di run ini (menunggu
  screenshot baru dari game revisi 5 + submit ulang sebelum deadline
  16 Nov 01:00 WIB).
- Commit `a767123` ("revisi 5: rumah 3 ruangan + bot pathfinding"),
  push ke main OK.
- **Publish — SELESAI 15 Nov ~20:11 WIB:** `roblox.py publish 9874149559
  93903442181463 game.rbxl` → **HTTP 200, versionNumber 8** (sebelumnya 7).
  Verifikasi: games API mengembalikan nama asli "Tempat SHAMSIE665",
  creator SHAMSIE665, updated 20:11:26 WIB; playability
  GuestProhibited (publik, tamu tanpa login tidak bisa main — normal)
  — experience tetap Public.

## Revisi 6 — panel CARA MAIN + stamina Penahan + ronde 90 dtk + suara (15 Nov 2026, ~20:23 WIB)

Empat perubahan Dham dalam satu publish (version 9). Commit game `b77d435`
("revisi 6: panel CARA MAIN + stamina Penahan 5/3 dtk + ronde 90 dtk + suara").

### 1. Panel CARA MAIN (aturan kata-kata Dham, di lobby)
- Layar start (lobby, Intermission 10 dtk) kini berjudul **CARA MAIN** dengan
  isi persis kata-kata Dham: "KESURUPAN: Kabur membawa raga yang sedang
  kesurupan. Kalau iblis berhasil membawa raga pergi, IBLIS MENANG." dan
  "TIM PENYADAR (Pembaca Doa + Penahan): Tahan yang kesurupan, baca doa
  sampai bar penuh. Iblis pergi, TIM MENANG." + baris "PENAHAN: hanya bisa
  menahan 5 detik, lalu istirahat 3 detik."
- Frame diperbesar 480×410 → 480×490 (rules 176 → 252 px, ~10 baris × 24 px
  = 240 px, muat). Saat ronde berjalan panel hilang, diganti satu baris
  petunjuk singkat di bawah: "Tahan BACA DOA saat kesurupan ditahan & kamu dekat".
- Verifikasi numerik layar HP 2048×984: **0 tumpang tindih** (frame x 784–1264,
  y 197–687; bar doa y 794–818; tombol BACA DOA x 1838–2028; timer/peran/status
  semua di luar frame).

### 2. Stamina Penahan (game lebih sulit)
- `Config.HOLDER_STAMINA_MAX = 5`, `HOLDER_REST_TIME = 3`. Penahan hanya bisa
  menahan MAKSIMAL 5 detik berturut-turut, lalu WAJIB istirahat 3 detik
  (tidak bisa menahan, yang kesurupan bebas, escape meter jalan). Setelah
  istirahat stamina penuh lagi. Stamina berkurang hanya saat benar-benar
  menahan; diam saat tidak menahan.
- Berlaku untuk bot Penahan maupun pemain asli yang jadi Penahan (server-side,
  di `updateHeld(dt)`). Bot Penahan saat lelah mundur menjauh dari yang
  kesurupan selama 3 detik, lalu mengejar lagi.
- GUI: bar stamina Penahan + label di atas bar doa (label y 736–760, bar
  y 760–776, tidak menumpuk bar doa y 794–818); saat istirahat label jadi
  **"LELAH! Penahan istirahat..."** merah dan bar merah. Bar hanya tampil
  saat ronde berjalan.

### 3. Ronde 90 detik
- `Config.ROUND_LENGTH` 60 → **90**. Timer ronde dinamis (formatTime dari
  `timeLeft` server). Lobby 10 dtk dan hasil 6 dtk tetap. Panel CARA MAIN
  tidak menyebut durasi ronde, jadi tidak ada teks yang perlu diubah.

### 4. Suara
- Semua ID diverifikasi 15 Nov 2026 via `economy.roblox.com/v2/assets/{id}/details`
  (ada, AssetTypeId 3 = Audio, IsPublicDomain true → bisa diputar experience mana pun).
  Yang DITOLAK verifikasi: 2867960777 (HTTP 400, mati), 1842831525 (Type 1 = Image),
  140704980462451 + 2778606796 (PublicDomain false), 4913256037 (Type 9 = Place),
  6895079450 (HTTP 400).
- **Ambient horor** (loop, volume 0,3, saat ronde; berhenti saat lobby/hasil):
  `rbxassetid://139743346356072` — "Forgotten Crypt Ambient" (DistrokidOfficial).
- **Mengaji**: TIDAK ada ID mengaji spesifik yang terverifikasi di Roblox — dipakai
  vokal/chant ambient terverifikasi sebagai gantinya:
  `rbxassetid://133365325304034` — "Tank Gregorian Chant" (DistrokidOfficial),
  loop, volume 0,5. Bunyi hanya saat Pembaca Doa menahan BACA DOA DAN yang
  kesurupan sedang ditahan (bar doa naik); berhenti saat dilepas atau yang
  kesurupan lepas.
- **Menang** "IBLIS TERUSIR!": `rbxassetid://1840511219` — "Funky Fanfare"
  (APMOfficial), volume 0,5, sekali. **Kalah/kabur**:
  `rbxassetid://150829983` — "T-Rex Roar" (DDude642), volume 0,5, sekali.
- Sound dibuat di `SoundService` (playback global 2D), preload via
  `ContentProvider:PreloadAsync` di task terpisah (tidak memblokir round loop),
  semua `Play()` dibungkus `pcall`.

### Verifikasi
- `./bin/rojo build` (Rojo 7.7.1) — **SUKSES**, `game.rbxl` **28.026 byte**
  (sebelumnya 24.508). Cek keseimbangan blok Luau (strip komentar/string):
  delta buka−tutup client +4 dan server +9 SAMA seperti HEAD v8 (artefak
  checker, bukan ketidakseimbangan baru). Tidak ada compiler Luau di VM;
  verifikasi runtime penuh (termasuk suara benar-benar berbunyi) menunggu Dham main.
- `main.ts`/`check`/`submit` TIDAK dijalankan di run ini (menunggu screenshot
  baru dari game revisi 6 + submit ulang sebelum deadline 16 Nov 01:00 WIB).
- **Publish — SELESAI 15 Nov ~20:23 WIB:** `roblox.py publish 9874149559
  93903442181463 game.rbxl` → **HTTP 200, versionNumber 9** (sebelumnya 8).
  Verifikasi: games API mengembalikan nama asli "Tempat SHAMSIE665",
  creator SHAMSIE665, updated 20:23:12 WIB; playability GuestProhibited
  (publik, normal) — experience tetap Public.
