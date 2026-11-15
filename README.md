# Coin Rush Dodge

A Roblox game for the [make.fun roblox-game-01 bounty](https://make.fun/bounty/roblox-game-01):
collect gold coins, dodge the lava in the four corners and the balls falling from
the sky. Most coins in 60 seconds wins the round.

## How a round plays

1. **Lobby (10 s)** — the start screen shows the rules and the countdown.
2. **Round (60 s)** — gold coins spin around the arena; each one is worth 1 coin.
   Red balls rain down faster as the clock runs out (25 damage a hit), and the
   four lava pools in the corners deal 50 damage a touch. Falling to 0 health
   respawns you at the green spawn pad.
3. **Results (5 s)** — the player with the most coins takes a Win on the
   leaderboard, then the next lobby starts. The loop never stops.

Leaderstats: **Coins** (this round) and **Wins** (rounds won).

## Layout

- `default.project.json` — the Rojo project: a 120×120 grass arena, four walls,
  four lava pools, four pillars, a spawn pad, daylight lighting.
- `src/server/init.server.luau` — the round loop, coins, falling balls, lava,
  leaderstats, and the RemoteEvents that broadcast round state.
- `src/client/Game.client.luau` — timer, coin counter, start screen, end
  screen, coin pulse and damage flash. It never owns game state.
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
