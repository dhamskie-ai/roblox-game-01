-- Kesurupan — Usir Iblis: the client.
-- Draws the timer, the prayer bar, the role label, the start screen and
-- the end screen from what the server broadcasts. It never owns game
-- state; it only sends chant input (hold the button or hold E).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundEvent = remotes:WaitForChild("RoundEvent")
local chantEvent = remotes:WaitForChild("ChantEvent")

local PURPLE = Color3.fromRGB(170, 80, 220)
local GOLD = Color3.fromRGB(255, 210, 90)
local GREEN = Color3.fromRGB(90, 220, 120)
local RED = Color3.fromRGB(230, 70, 60)
local PANEL = Color3.fromRGB(24, 18, 34)
local WHITE = Color3.fromRGB(245, 245, 245)

local myRole = ""
local myScore = 0
local chanting = false
local chantLineIndex = 1
local lastChantSwap = 0
local lastHeld = false -- server says the possessed is held (prayer bar rising)

-- Sounds: every ID verified 2026-11-15 via economy.roblox.com/v2/assets —
-- exists, AssetTypeId 3 (Audio), IsPublicDomain true (playable by any
-- experience). No verified mengaji-specific audio exists on Roblox, so
-- the recitation uses a verified vocal chant instead (see BUILD_LOG).
local function newSound(name, id, volume, looped)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume
	s.Looped = looped
	s.Parent = SoundService
	return s
end

-- Horror ambient loop (Forgotten Crypt Ambient, DistrokidOfficial).
local ambientSound = newSound("HorrorAmbient", "139743346356072", 0.3, true)
-- Recitation while chanting (Gregorian chant vocals, DistrokidOfficial).
local chantSound = newSound("Chant", "133365325304034", 0.5, true)
-- Win sting (Funky Fanfare, APMOfficial) / lose sting (T-Rex roar).
local winSound = newSound("WinSting", "1840511219", 0.5, false)
local loseSound = newSound("LoseSting", "150829983", 0.5, false)

-- Preload so the first play is not delayed; never blocks the round loop.
task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({ ambientSound, chantSound, winSound, loseSound })
	end)
end)

-- The chant sound plays only while the reader holds BACA DOA AND the
-- possessed is held (i.e. the prayer bar is actually rising); it stops
-- the moment the button is released or the possessed gets free.
local function updateChantSound()
	if chanting and lastHeld then
		if not chantSound.IsPlaying then
			pcall(function()
				chantSound:Play()
			end)
		end
	else
		if chantSound.IsPlaying then
			chantSound:Stop()
		end
	end
end

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local rest = seconds % 60
	return string.format("%d:%02d", minutes, rest)
end

local function newLabel(parent, name, text, size, position, anchor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = anchor or Vector2.new(0.5, 0)
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = WHITE
	label.TextSize = 28
	label.TextStrokeTransparency = 0.6
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "KesurupanGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Possessed overlay: a dark purple veil, visible only while this player
-- is the possessed one.
local possessedOverlay = Instance.new("Frame")
possessedOverlay.Name = "PossessedOverlay"
possessedOverlay.Size = UDim2.fromScale(1, 1)
possessedOverlay.BackgroundColor3 = Color3.fromRGB(60, 10, 90)
possessedOverlay.BackgroundTransparency = 0.82
possessedOverlay.BorderSizePixel = 0
possessedOverlay.Visible = false
possessedOverlay.Parent = gui

-- HUD scale (revisi 7): on Dham's phone the Lua GUI renders ~2.5x the
-- code pixel sizes (measured from his 2048x984 screenshot: a 190x84
-- button rendered 473x208). The logical viewport is ~753x336, so every
-- HUD element is kept SMALL in code units. Never trust a "looks fine
-- on 2048x984" check that assumes 1 code px = 1 screen px.
-- Top bar: the timer TOP-LEFT (below Roblox's own menu buttons),
-- the role TOP-RIGHT. Status + escape sit LEFT under the timer.
local timerLabel = newLabel(
	gui,
	"Timer",
	"SIAP-SIAP",
	UDim2.new(0, 95, 0, 16),
	UDim2.new(0, 8, 0, 8),
	Vector2.new(0, 0)
)
timerLabel.TextSize = 14
timerLabel.TextXAlignment = Enum.TextXAlignment.Left

local roleLabel = newLabel(
	gui,
	"Role",
	"PERAN: -",
	UDim2.new(0, 100, 0, 14),
	UDim2.new(1, -8, 0, 4),
	Vector2.new(1, 0)
)
roleLabel.TextColor3 = GOLD
roleLabel.TextSize = 13
roleLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Prayer bar + percent: BOTTOM-CENTER, thin (5px) and short (200px),
-- above the percent label; part of the compact bottom stack.
local prayerBarBack = Instance.new("Frame")
prayerBarBack.Name = "PrayerBarBack"
prayerBarBack.AnchorPoint = Vector2.new(0.5, 0)
prayerBarBack.Position = UDim2.new(0.5, 0, 1, -50)
prayerBarBack.Size = UDim2.fromOffset(200, 5)
prayerBarBack.BackgroundColor3 = Color3.fromRGB(15, 12, 22)
prayerBarBack.BorderSizePixel = 0
prayerBarBack.Parent = gui

local prayerBarBackCorner = Instance.new("UICorner")
prayerBarBackCorner.CornerRadius = UDim.new(0, 2)
prayerBarBackCorner.Parent = prayerBarBack

local prayerFill = Instance.new("Frame")
prayerFill.Name = "PrayerFill"
prayerFill.Size = UDim2.fromScale(0, 1)
prayerFill.BackgroundColor3 = GOLD
prayerFill.BorderSizePixel = 0
prayerFill.Parent = prayerBarBack

local prayerFillCorner = Instance.new("UICorner")
prayerFillCorner.CornerRadius = UDim.new(0, 2)
prayerFillCorner.Parent = prayerFill

local prayerLabel = newLabel(
	gui,
	"Prayer",
	"DOA  0%",
	UDim2.new(0, 200, 0, 9),
	UDim2.new(0.5, 0, 1, -43)
)
prayerLabel.TextColor3 = GOLD
prayerLabel.TextSize = 12

-- Holder stamina bar + label: BOTTOM-CENTER above the prayer bar
-- (bottom stack: stamina label, stamina bar, prayer bar, prayer label,
-- then ONE shared line for the chant line / hint). Visible only during
-- a round. Shows "LELAH!" in red while the holder rests, so players
-- understand why the possessed got free.
local staminaLabel = newLabel(
	gui,
	"Stamina",
	"STAMINA PENAHAN  100%",
	UDim2.new(0, 200, 0, 9),
	UDim2.new(0.5, 0, 1, -68)
)
staminaLabel.TextColor3 = GREEN
staminaLabel.TextSize = 11
staminaLabel.Visible = false

local staminaBarBack = Instance.new("Frame")
staminaBarBack.Name = "StaminaBarBack"
staminaBarBack.AnchorPoint = Vector2.new(0.5, 0)
staminaBarBack.Position = UDim2.new(0.5, 0, 1, -57)
staminaBarBack.Size = UDim2.fromOffset(200, 4)
staminaBarBack.BackgroundColor3 = Color3.fromRGB(15, 12, 22)
staminaBarBack.BorderSizePixel = 0
staminaBarBack.Visible = false
staminaBarBack.Parent = gui

local staminaBarBackCorner = Instance.new("UICorner")
staminaBarBackCorner.CornerRadius = UDim.new(0, 2)
staminaBarBackCorner.Parent = staminaBarBack

local staminaFill = Instance.new("Frame")
staminaFill.Name = "StaminaFill"
staminaFill.Size = UDim2.fromScale(1, 1)
staminaFill.BackgroundColor3 = GREEN
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaBarBack

local staminaFillCorner = Instance.new("UICorner")
staminaFillCorner.CornerRadius = UDim.new(0, 2)
staminaFillCorner.Parent = staminaFill

-- Held status line, LEFT under the timer: small (200x10, TextSize 11)
-- with a dark panel behind the text to keep it readable.
local statusLabel = newLabel(
	gui,
	"Status",
	"",
	UDim2.new(0, 200, 0, 10),
	UDim2.new(0, 8, 0, 30),
	Vector2.new(0, 0)
)
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.BackgroundTransparency = 0.3
statusLabel.BackgroundColor3 = PANEL

-- Escape warning, left under the status line.
local escapeLabel = newLabel(
	gui,
	"Escape",
	"",
	UDim2.new(0, 200, 0, 10),
	UDim2.new(0, 8, 0, 42),
	Vector2.new(0, 0)
)
escapeLabel.TextColor3 = RED
escapeLabel.TextSize = 11
escapeLabel.TextXAlignment = Enum.TextXAlignment.Left
escapeLabel.BackgroundTransparency = 0.3
escapeLabel.BackgroundColor3 = PANEL
escapeLabel.Visible = false

-- The doa line being chanted, bottom center.
local chantLineLabel = newLabel(
	gui,
	"ChantLine",
	"",
	UDim2.new(0, 260, 0, 9),
	UDim2.new(0.5, 0, 1, -31)
)
chantLineLabel.TextColor3 = GOLD
chantLineLabel.TextSize = 11
chantLineLabel.Visible = false

-- Chant button: hold it (touch or mouse) to read the doa.
-- Only visible while this player is the Reader in a round.
-- Small (72x28) at the lower right, ABOVE the mobile jump button
-- (jump button sits at the bottom-right corner).
local chantButton = Instance.new("TextButton")
chantButton.Name = "ChantButton"
chantButton.AnchorPoint = Vector2.new(1, 1)
chantButton.Position = UDim2.new(1, -8, 1, -104)
chantButton.Size = UDim2.fromOffset(72, 28)
chantButton.BackgroundColor3 = PURPLE
chantButton.Font = Enum.Font.GothamBold
chantButton.Text = "TAHAN:\nBACA DOA"
chantButton.TextColor3 = WHITE
chantButton.TextSize = 13
chantButton.Visible = false
chantButton.Parent = gui

local chantButtonCorner = Instance.new("UICorner")
chantButtonCorner.CornerRadius = UDim.new(0, 8)
chantButtonCorner.Parent = chantButton

local hintLabel = newLabel(
	gui,
	"Hint",
	"Tahan BACA DOA saat kesurupan ditahan & kamu dekat",
	UDim2.new(0, 260, 0, 9),
	UDim2.new(0.5, 0, 1, -31)
)
hintLabel.TextSize = 10
hintLabel.TextTransparency = 0.15

-- Start screen: title, the rules in Dham's own words, and the countdown.
-- Shown during the lobby (Intermission); hidden once the round starts.
-- 280x220 (was 480x490: it overflowed Dham's phone screen, the MULAI
-- button was cut off at the bottom). Same content, smaller text.
local startFrame = Instance.new("Frame")
startFrame.Name = "StartScreen"
startFrame.AnchorPoint = Vector2.new(0.5, 0.5)
startFrame.Position = UDim2.fromScale(0.5, 0.45)
startFrame.Size = UDim2.fromOffset(280, 220)
startFrame.BackgroundColor3 = PANEL
startFrame.BackgroundTransparency = 0.1
startFrame.BorderSizePixel = 0
startFrame.Parent = gui

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 16)
startCorner.Parent = startFrame

local titleLabel = newLabel(
	startFrame,
	"Title",
	"KESURUPAN\nUSIR IBLIS",
	UDim2.new(1, 0, 0, 36),
	UDim2.new(0.5, 0, 0, 6)
)
titleLabel.TextColor3 = PURPLE
titleLabel.TextSize = 15

local caraMainLabel = newLabel(
	startFrame,
	"CaraMain",
	"CARA MAIN",
	UDim2.new(1, 0, 0, 16),
	UDim2.new(0.5, 0, 0, 44)
)
caraMainLabel.TextColor3 = GOLD
caraMainLabel.TextSize = 11

-- Dham's rules, verbatim. ~10 wrapped lines at TextSize 20 in 448px
-- (3 + blank + 3 + blank + 2 lines), 252px tall, top-aligned, left-aligned.
local rulesLabel = newLabel(
	startFrame,
	"Rules",
	"KESURUPAN: Kabur membawa raga yang sedang kesurupan. Kalau iblis berhasil membawa raga pergi, IBLIS MENANG.\n\nTIM PENYADAR (Pembaca Doa + Penahan): Tahan yang kesurupan, baca doa sampai bar penuh. Iblis pergi, TIM MENANG.\n\nPENAHAN: hanya bisa menahan 5 detik, lalu istirahat 3 detik.",
	UDim2.new(1, -16, 0, 104),
	UDim2.new(0.5, 0, 0, 62)
)
rulesLabel.TextSize = 10
rulesLabel.TextWrapped = true
rulesLabel.TextXAlignment = Enum.TextXAlignment.Left
rulesLabel.TextYAlignment = Enum.TextYAlignment.Top

local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.AnchorPoint = Vector2.new(0.5, 0)
startButton.Position = UDim2.new(0.5, 0, 0, 174)
startButton.Size = UDim2.fromOffset(90, 26)
startButton.BackgroundColor3 = PURPLE
startButton.Font = Enum.Font.GothamBold
startButton.Text = "MULAI"
startButton.TextColor3 = WHITE
startButton.TextSize = 12
startButton.Parent = startFrame

local startButtonCorner = Instance.new("UICorner")
startButtonCorner.CornerRadius = UDim.new(0, 12)
startButtonCorner.Parent = startButton

local countdownLabel = newLabel(
	startFrame,
	"Countdown",
	"Ronde mulai...",
	UDim2.new(1, 0, 0, 14),
	UDim2.new(0.5, 0, 0, 204)
)
countdownLabel.TextColor3 = GOLD
countdownLabel.TextSize = 10

-- End screen: the result, your own score, and the wait for the next round.
local endFrame = Instance.new("Frame")
endFrame.Name = "EndScreen"
endFrame.AnchorPoint = Vector2.new(0.5, 0.5)
endFrame.Position = UDim2.fromScale(0.5, 0.45)
endFrame.Size = UDim2.fromOffset(280, 84)
endFrame.BackgroundColor3 = PANEL
endFrame.BackgroundTransparency = 0.1
endFrame.BorderSizePixel = 0
endFrame.Visible = false
endFrame.Parent = gui

local endCorner = Instance.new("UICorner")
endCorner.CornerRadius = UDim.new(0, 16)
endCorner.Parent = endFrame

local endTitle = newLabel(
	endFrame,
	"Title",
	"",
	UDim2.new(1, 0, 0, 26),
	UDim2.new(0.5, 0, 0, 7)
)
endTitle.TextColor3 = GOLD
endTitle.TextSize = 17

local yourScoreLabel = newLabel(
	endFrame,
	"YourScore",
	"",
	UDim2.new(1, -16, 0, 18),
	UDim2.new(0.5, 0, 0, 37)
)
yourScoreLabel.TextSize = 11

local nextLabel = newLabel(
	endFrame,
	"Next",
	"Ronde berikutnya segera...",
	UDim2.new(1, 0, 0, 15),
	UDim2.new(0.5, 0, 0, 60)
)
nextLabel.TextSize = 10
nextLabel.TextTransparency = 0.2

-- Chant input ------------------------------------------------------------------

local function setChanting(value)
	if chanting == value then
		return
	end
	chanting = value
	chantEvent:FireServer(value)
	chantButton.Text = value and "MEMBACA\nDOA..." or "TAHAN:\nBACA DOA"
	chantButton.BackgroundColor3 = value and GREEN or PURPLE
	chantLineLabel.Visible = value
	hintLabel.Visible = not value
	updateChantSound()
	if value then
		chantLineLabel.Text = Config.CHANT_LINES[chantLineIndex]
		lastChantSwap = os.clock()
	end
end

chantButton.MouseButton1Down:Connect(function()
	setChanting(true)
end)
chantButton.MouseButton1Up:Connect(function()
	setChanting(false)
end)
chantButton.MouseLeave:Connect(function()
	setChanting(false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		setChanting(true)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		setChanting(false)
	end
end)

-- The scoreboard replicates on its own; follow it so a mid-round join
-- still sees the right count.
local leaderstats = player:WaitForChild("leaderstats")
local doaValue = leaderstats:WaitForChild("Doa")
local function setScore(value)
	myScore = value
end
setScore(doaValue.Value)
doaValue.Changed:Connect(setScore)

-- Cycle the doa line while chanting.
task.spawn(function()
	while true do
		task.wait(0.2)
		if chanting then
			local now = os.clock()
			if now - lastChantSwap >= 2 then
				lastChantSwap = now
				chantLineIndex = chantLineIndex % #Config.CHANT_LINES + 1
				chantLineLabel.Text = Config.CHANT_LINES[chantLineIndex]
			end
		end
	end
end)

-- The MULAI button just dismisses the start panel early; the round
-- still starts on the server countdown.
startButton.MouseButton1Click:Connect(function()
	startFrame.Visible = false
end)

-- Round state ------------------------------------------------------------------

roundEvent.OnClientEvent:Connect(function(data)
	if data.state == "Intermission" then
		startFrame.Visible = true
		endFrame.Visible = false
		setChanting(false)
		timerLabel.Text = "SIAP-SIAP"
		countdownLabel.Text = "Ronde mulai dalam " .. tostring(data.timeLeft) .. " dtk"
		statusLabel.Text = "Satu pemain akan dipilih jadi kesurupan..."
		escapeLabel.Visible = false
		chantButton.Visible = false
		possessedOverlay.Visible = false
		staminaLabel.Visible = false
		staminaBarBack.Visible = false
		if ambientSound.IsPlaying then
			ambientSound:Stop()
		end
	elseif data.state == "Round" then
		startFrame.Visible = false
		endFrame.Visible = false
		staminaLabel.Visible = true
		staminaBarBack.Visible = true
		if not ambientSound.IsPlaying then
			pcall(function()
				ambientSound:Play()
			end)
		end
		lastHeld = data.held == true
		updateChantSound()
		local stamina = data.stamina or 100
		staminaFill.Size = UDim2.fromScale(math.clamp(stamina / 100, 0, 1), 1)
		if data.resting then
			staminaLabel.Text = "LELAH! Penahan istirahat..."
			staminaLabel.TextColor3 = RED
			staminaFill.BackgroundColor3 = RED
		else
			staminaLabel.Text = "STAMINA PENAHAN  " .. tostring(stamina) .. "%"
			staminaLabel.TextColor3 = GREEN
			staminaFill.BackgroundColor3 = GREEN
		end
		timerLabel.Text = "RONDE  " .. formatTime(data.timeLeft)
		local role = data.roles and data.roles[player.Name] or ""
		myRole = role
		if role == "Possessed" then
			roleLabel.Text = "PERAN: KESURUPAN"
			roleLabel.TextColor3 = RED
			hintLabel.Text = "Kamu kesurupan! Lari dari penahan, jangan sampai doa penuh!"
		elseif role == "Reader" then
			roleLabel.Text = "PERAN: PEMBACA DOA"
			roleLabel.TextColor3 = GOLD
			hintLabel.Text = "Tahan BACA DOA saat kesurupan ditahan & kamu dekat"
		elseif role == "Holder" then
			roleLabel.Text = "PERAN: PENAHAN"
			roleLabel.TextColor3 = GREEN
			hintLabel.Text = "Tempel terus yang kesurupan, jangan biarkan dia kabur!"
		else
			roleLabel.Text = "PERAN: -"
		end
		possessedOverlay.Visible = (role == "Possessed")
		chantButton.Visible = (role == "Reader")
		prayerFill.Size = UDim2.fromScale(math.clamp(data.progress / 100, 0, 1), 1)
		prayerLabel.Text = "DOA  " .. tostring(data.progress) .. "%"
		if data.held then
			statusLabel.Text = "KESURUPAN: TERTAHAN — doa bekerja!"
			statusLabel.TextColor3 = GREEN
		else
			statusLabel.Text = "KESURUPAN: LEPAS! Tahan dia!"
			statusLabel.TextColor3 = RED
		end
		if data.escape >= 5 then
			escapeLabel.Text = "AWAS KABUR: "
				.. tostring(data.escape)
				.. "/"
				.. tostring(data.escapeLimit)
				.. " dtk"
			escapeLabel.Visible = true
		else
			escapeLabel.Visible = false
		end
	elseif data.state == "Ending" then
		startFrame.Visible = false
		endFrame.Visible = true
		setChanting(false)
		staminaLabel.Visible = false
		staminaBarBack.Visible = false
		if ambientSound.IsPlaying then
			ambientSound:Stop()
		end
		if data.result == "IBLIS TERUSIR!" then
			pcall(function()
				winSound:Play()
			end)
		else
			pcall(function()
				loseSound:Play()
			end)
		end
		timerLabel.Text = "SELESAI"
		endTitle.Text = data.result or ""
		if data.result == "IBLIS TERUSIR!" then
			endTitle.TextColor3 = GOLD
		else
			endTitle.TextColor3 = RED
		end
		yourScoreLabel.Text = "Skor doa kamu: " .. tostring(myScore)
	end
end)
