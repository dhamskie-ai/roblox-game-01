-- Kesurupan — Usir Iblis: shared tuning in one place.
-- Server and client both read these numbers, so a balance change is a one-line edit.

local Config = {
	-- A round lasts 60 seconds; the lobby between rounds lasts 10 seconds;
	-- the end screen stays up for 6 seconds.
	ROUND_LENGTH = 60,
	INTERMISSION_LENGTH = 10,
	ENDING_LENGTH = 6,

	-- The house spans X -45..45, Z -30..30 (3 rooms); bots and spawns stay
	-- inside this smaller area so they never clip into an outer wall.
	ARENA_X_HALF = 43,
	ARENA_Z_HALF = 26,

	-- Room centres for the round-start scatter (living room, bedroom,
	-- kitchen). Each round the three participants start in different rooms.
	ROOM_CENTERS = {
		Vector3.new(0, 0, 0),
		Vector3.new(-30, 0, 0),
		Vector3.new(30, 0, 0),
	},

	-- Prayer progress: fills only while the reader chants close to the
	-- possessed AND the possessed is held. 100 = demon expelled.
	-- At 3.5%/s, about 29 s of good chanting wins a 60 s round.
	PRAYER_RATE_HELD = 3.5, -- % per second while chanting, close, held
	PRAYER_DECAY = 1.5, -- % per second lost when not chanting / too far
	CHANT_RANGE = 14, -- reader must be this close to the possessed

	-- Escape meter: fills while the possessed is NOT held; 12 s = escape.
	ESCAPE_LIMIT = 12,
	ESCAPE_FILL = 1, -- per second while free
	ESCAPE_DRAIN = 2, -- per second while held

	-- Speeds (default WalkSpeed 16).
	READER_SPEED = 16,
	POSSESSED_SPEED = 14,
	POSSESSED_BURST_SPEED = 23,
	POSSESSED_HELD_SPEED = 6,
	HOLDER_SPEED = 18,

	-- Bot behaviour.
	BOT_RETARGET_MIN = 0.6,
	BOT_RETARGET_MAX = 1.6,
	BOT_BURST_CHANCE = 0.25, -- per retarget while free
	BOT_BREAK_FREE_EVERY = 4, -- seconds held before a break-free attempt
	BOT_BREAK_FREE_CHANCE = 0.6,

	-- Doa lines shown while chanting (short, polite).
	CHANT_LINES = {
		"A'udzu billahi minasy syaithonir rojim",
		"Bismillahirrohmanirrohim",
		"Allahu la ilaha illa Huwal Hayyul Qoyyum",
	},
}

return Config
