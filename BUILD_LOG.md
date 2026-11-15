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
