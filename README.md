# Kesurupan — Usir Iblis

A Roblox game for the [make.fun roblox-game-01 bounty](https://make.fun/bounty/roblox-game-01):
a 3-player co-op exorcism. One player is picked at random to be possessed by a
demon; the Prayer Reader chants doa next to them while the Holder holds them
down. Fill the prayer bar before the timer runs out — or before the possessed
one escapes.

This game replaced the first entry, Coin Rush Dodge, in the same repository and
the same published place. The first entry was already submitted and accepted
(19:33 WIB); this one is built to be submitted as a newer entry instead.

## How a round plays

1. **Lobby (10 s)** — the start screen shows the three roles and the
   countdown. Two bots wander the arena so all three characters are visible.
2. **Round (60 s)** — roles are assigned: **Kesurupan** (possessed, faster,
   dark purple aura), **Pembaca Doa** (reader, holds the BACA DOA button or
   the E key to chant), **Penahan** (holder, stays glued to the possessed).
   The prayer bar fills only while the reader chants close to the possessed
   AND the possessed is held; it drains when the reader stops or drifts away.
   The possessed breaks free in bursts, and the escape meter fills while it
   is free — 12 seconds free and it escapes.
3. **Results (6 s)** — "IBLIS TERUSIR!" if the prayer bar fills (the whole
   team shares the Win), otherwise "KESURUPAN KABUR!" or "WAKTU HABIS".
   Then the next lobby starts. The loop never stops.

Playing solo: the human is always the Prayer Reader, and the other two seats
are bots (the possessed bot runs erratically with speed bursts, the holder bot
chases and holds it). When real players join, bots are replaced by them.

Leaderstats: **Doa** (prayer points this round) and **Wins** (rounds won).

## Layout

- `default.project.json` — the Rojo project: a 60×60 haunted-house room
  (dark wood floor, stone walls and pillars, a glowing ritual circle, four
  candles with point lights), night lighting with fog.
- `src/server/init.server.luau` — the round loop, role assignment, the two
  bots (possessed + holder brains), prayer progress, escape meter,
  leaderstats, and the RemoteEvents that broadcast round state.
- `src/client/Game.client.luau` — timer, prayer bar, role label, held/escape
  status, chant button (hold to chant) and E key, doa lines, start screen,
  end screen, possessed overlay. It never owns game state.
- `src/shared/Config.luau` — every tuning number in one place.
- `vendor/makefun-roblox.ts` — the kit's dossier library, unchanged.
- `main.ts` — the make.fun entry program: copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output` and writes `dossier.json`.
- `PLAY.json` — the published place: https://www.roblox.com/games/93903442181463
  (place 93903442181463, universe 9874149559, owner @SHAMSIE665).

## Build

Requires [Rojo 7.x](https://github.com/rojo-rbx/rojo/releases) and Node 22+.

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## Publish

Upload `game.rbxl` to the place above (Roblox Studio or the Open Cloud API),
set the experience Public on the Creator Dashboard, then play it in the Roblox
app and capture the start / play / end screenshots into `screenshots/`.

## License

MIT — see `LICENSE`.
