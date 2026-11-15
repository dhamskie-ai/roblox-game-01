-- Kesurupan — Usir Iblis: the client.
-- Draws the timer, the prayer bar, the role label, the start screen and
-- the end screen from what the server broadcasts. It never owns game
-- state; it only sends chant input (hold the button or hold E).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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

-- Top bar: the timer TOP-LEFT (below Roblox's own menu buttons),
-- the role TOP-RIGHT. They can no longer overlap: the timer used to sit
-- centered and ran into the role label on a phone screen.
-- Status + escape warning sit TOP-CENTER, clear of both corners.
local timerLabel = newLabel(
	gui,
	"Timer",
	"SIAP-SIAP",
	UDim2.new(0, 260, 0, 44),
	UDim2.new(0, 16, 0, 64),
	Vector2.new(0, 0)
)
timerLabel.TextSize = 30
timerLabel.TextXAlignment = Enum.TextXAlignment.Left

local roleLabel = newLabel(
	gui,
	"Role",
	"PERAN: -",
	UDim2.new(0, 280, 0, 40),
	UDim2.new(1, -16, 0, 10),
	Vector2.new(1, 0)
)
roleLabel.TextColor3 = GOLD
roleLabel.TextSize = 26
roleLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Prayer bar + percent: BOTTOM-CENTER with their own space, far from
-- the top bar (the old bar sat under the timer and the percent text
-- got covered by it).
local prayerBarBack = Instance.new("Frame")
prayerBarBack.Name = "PrayerBarBack"
prayerBarBack.AnchorPoint = Vector2.new(0.5, 0)
prayerBarBack.Position = UDim2.new(0.5, 0, 1, -190)
prayerBarBack.Size = UDim2.fromOffset(320, 24)
prayerBarBack.BackgroundColor3 = Color3.fromRGB(15, 12, 22)
prayerBarBack.BorderSizePixel = 0
prayerBarBack.Parent = gui

local prayerBarBackCorner = Instance.new("UICorner")
prayerBarBackCorner.CornerRadius = UDim.new(0, 12)
prayerBarBackCorner.Parent = prayerBarBack

local prayerFill = Instance.new("Frame")
prayerFill.Name = "PrayerFill"
prayerFill.Size = UDim2.fromScale(0, 1)
prayerFill.BackgroundColor3 = GOLD
prayerFill.BorderSizePixel = 0
prayerFill.Parent = prayerBarBack

local prayerFillCorner = Instance.new("UICorner")
prayerFillCorner.CornerRadius = UDim.new(0, 12)
prayerFillCorner.Parent = prayerFill

local prayerLabel = newLabel(
	gui,
	"Prayer",
	"DOA  0%",
	UDim2.new(0, 320, 0, 28),
	UDim2.new(0.5, 0, 1, -162)
)
prayerLabel.TextColor3 = GOLD
prayerLabel.TextSize = 22

-- Held status line, top-center (clear of timer left and role right).
local statusLabel = newLabel(
	gui,
	"Status",
	"",
	UDim2.new(0, 480, 0, 28),
	UDim2.new(0.5, 0, 0, 64)
)
statusLabel.TextSize = 20

-- Escape warning, top-center under the status line.
local escapeLabel = newLabel(
	gui,
	"Escape",
	"",
	UDim2.new(0, 480, 0, 28),
	UDim2.new(0.5, 0, 0, 94)
)
escapeLabel.TextColor3 = RED
escapeLabel.TextSize = 20
escapeLabel.Visible = false

-- The doa line being chanted, bottom center.
local chantLineLabel = newLabel(
	gui,
	"ChantLine",
	"",
	UDim2.new(0, 640, 0, 30),
	UDim2.new(0.5, 0, 1, -108)
)
chantLineLabel.TextColor3 = GOLD
chantLineLabel.TextSize = 20
chantLineLabel.Visible = false

-- Chant button: hold it (touch or mouse) to read the doa.
-- Only visible while this player is the Reader in a round.
-- Lifted 140px off the bottom so the mobile thumbstick (which pops up
-- at the bottom corner) does not cover it.
local chantButton = Instance.new("TextButton")
chantButton.Name = "ChantButton"
chantButton.AnchorPoint = Vector2.new(1, 1)
chantButton.Position = UDim2.new(1, -20, 1, -140)
chantButton.Size = UDim2.fromOffset(190, 84)
chantButton.BackgroundColor3 = PURPLE
chantButton.Font = Enum.Font.GothamBold
chantButton.Text = "TAHAN:\nBACA DOA"
chantButton.TextColor3 = WHITE
chantButton.TextSize = 24
chantButton.Visible = false
chantButton.Parent = gui

local chantButtonCorner = Instance.new("UICorner")
chantButtonCorner.CornerRadius = UDim.new(0, 16)
chantButtonCorner.Parent = chantButton

local hintLabel = newLabel(
	gui,
	"Hint",
	"Dekati yang kesurupan, tahan tombol BACA DOA sampai bar penuh!",
	UDim2.new(0, 640, 0, 28),
	UDim2.new(0.5, 0, 1, -12)
)
hintLabel.TextSize = 18
hintLabel.TextTransparency = 0.15

-- Start screen: title, the three roles, and the countdown.
local startFrame = Instance.new("Frame")
startFrame.Name = "StartScreen"
startFrame.AnchorPoint = Vector2.new(0.5, 0.5)
startFrame.Position = UDim2.fromScale(0.5, 0.45)
startFrame.Size = UDim2.fromOffset(480, 330)
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
	UDim2.new(1, 0, 0, 76),
	UDim2.new(0.5, 0, 0, 14)
)
titleLabel.TextColor3 = PURPLE
titleLabel.TextSize = 34

local rulesLabel = newLabel(
	startFrame,
	"Rules",
	"1 pemain dipilih acak jadi KESURUPAN.\nPEMBACA DOA: dekati dia, tahan BACA DOA.\nPENAHAN: tahan dia supaya tidak kabur.\nBar doa penuh = iblis terusir, tim menang!",
	UDim2.new(1, -32, 0, 120),
	UDim2.new(0.5, 0, 0, 96)
)
rulesLabel.TextSize = 20

local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.AnchorPoint = Vector2.new(0.5, 0)
startButton.Position = UDim2.new(0.5, 0, 0, 224)
startButton.Size = UDim2.fromOffset(180, 52)
startButton.BackgroundColor3 = PURPLE
startButton.Font = Enum.Font.GothamBold
startButton.Text = "MULAI"
startButton.TextColor3 = WHITE
startButton.TextSize = 26
startButton.Parent = startFrame

local startButtonCorner = Instance.new("UICorner")
startButtonCorner.CornerRadius = UDim.new(0, 12)
startButtonCorner.Parent = startButton

local countdownLabel = newLabel(
	startFrame,
	"Countdown",
	"Ronde mulai...",
	UDim2.new(1, 0, 0, 30),
	UDim2.new(0.5, 0, 0, 288)
)
countdownLabel.TextColor3 = GOLD
countdownLabel.TextSize = 20

-- End screen: the result, your own score, and the wait for the next round.
local endFrame = Instance.new("Frame")
endFrame.Name = "EndScreen"
endFrame.AnchorPoint = Vector2.new(0.5, 0.5)
endFrame.Position = UDim2.fromScale(0.5, 0.45)
endFrame.Size = UDim2.fromOffset(480, 210)
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
	UDim2.new(1, 0, 0, 52),
	UDim2.new(0.5, 0, 0, 14)
)
endTitle.TextColor3 = GOLD
endTitle.TextSize = 34

local yourScoreLabel = newLabel(
	endFrame,
	"YourScore",
	"",
	UDim2.new(1, -32, 0, 36),
	UDim2.new(0.5, 0, 0, 74)
)
yourScoreLabel.TextSize = 22

local nextLabel = newLabel(
	endFrame,
	"Next",
	"Ronde berikutnya segera...",
	UDim2.new(1, 0, 0, 30),
	UDim2.new(0.5, 0, 0, 120)
)
nextLabel.TextSize = 18
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
	elseif data.state == "Round" then
		startFrame.Visible = false
		endFrame.Visible = false
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
			hintLabel.Text = "Dekati yang kesurupan, tahan tombol BACA DOA sampai bar penuh!"
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
