-- Coin Rush Dodge: shared tuning in one place.
-- Server and client both read these numbers, so a balance change is a one-line edit.

local Config = {
	-- A round lasts 60 seconds; the lobby between rounds lasts 10 seconds;
	-- the end screen stays up for 5 seconds.
	ROUND_LENGTH = 60,
	INTERMISSION_LENGTH = 10,
	ENDING_LENGTH = 5,

	-- The arena floor spans -60..60 on X and Z; coins and balls spawn inside
	-- this smaller half-extent so they never land inside a wall.
	ARENA_HALF = 46,

	-- How many coins are on the field at once, and what one coin is worth.
	COIN_TARGET = 12,
	COIN_VALUE = 1,

	-- Damage numbers. A fresh character has 100 health.
	BALL_DAMAGE = 25,
	LAVA_DAMAGE = 50,

	-- Falling balls start every 1.4 s and speed up to every 0.7 s
	-- as the round runs out.
	BALL_INTERVAL_START = 1.4,
	BALL_INTERVAL_END = 0.7,
}

return Config
