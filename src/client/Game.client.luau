-- Coin Rush Dodge: the client.
-- Draws the timer, the coin count, the start screen and the end screen from
-- what the server broadcasts. It never owns game state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundEvent = remotes:WaitForChild("RoundEvent")
local feedbackEvent = remotes:WaitForChild("FeedbackEvent")

local GOLD = Color3.fromRGB(255, 200, 40)
local RED = Color3.fromRGB(220, 60, 50)
local PANEL = Color3.fromRGB(28, 32, 44)
local WHITE = Color3.fromRGB(245, 245, 245)

local myCoins = 0

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
gui.Name = "CoinRushGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Damage flash: a full-screen red veil, invisible until a hit lands.
local flash = Instance.new("Frame")
flash.Name = "DamageFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = RED
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui

-- Top bar: the timer in the middle, the coin count on the right,
-- clear of the top-left corner where Roblox puts its own menu buttons.
local timerLabel = newLabel(
	gui,
	"Timer",
	"GET READY",
	UDim2.new(0, 320, 0, 44),
	UDim2.new(0.5, 0, 0, 8)
)
timerLabel.TextSize = 32

local coinsLabel = newLabel(
	gui,
	"Coins",
	"COINS: 0",
	UDim2.new(0, 220, 0, 40),
	UDim2.new(1, -16, 0, 10),
	Vector2.new(1, 0)
)
coinsLabel.TextColor3 = GOLD
coinsLabel.TextSize = 28

local hintLabel = newLabel(
	gui,
	"Hint",
	"Gold coins score. Red lava and falling balls hurt!",
	UDim2.new(0, 560, 0, 28),
	UDim2.new(0.5, 0, 1, -12)
)
hintLabel.TextSize = 18
hintLabel.TextTransparency = 0.15

-- Start screen: title, how to play, and the countdown to the round.
local startFrame = Instance.new("Frame")
startFrame.Name = "StartScreen"
startFrame.AnchorPoint = Vector2.new(0.5, 0.5)
startFrame.Position = UDim2.fromScale(0.5, 0.45)
startFrame.Size = UDim2.fromOffset(460, 260)
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
	"COIN RUSH DODGE",
	UDim2.new(1, 0, 0, 56),
	UDim2.new(0.5, 0, 0, 16)
)
titleLabel.TextColor3 = GOLD
titleLabel.TextSize = 36

local rulesLabel = newLabel(
	startFrame,
	"Rules",
	"Grab gold coins. Dodge the lava\nin the corners and the balls\nfalling from the sky.\nMost coins in 60 seconds wins!",
	UDim2.new(1, -32, 0, 120),
	UDim2.new(0.5, 0, 0, 76)
)
rulesLabel.TextSize = 20

local countdownLabel = newLabel(
	startFrame,
	"Countdown",
	"Round starts soon...",
	UDim2.new(1, 0, 0, 36),
	UDim2.new(0.5, 0, 0, 204)
)
countdownLabel.TextColor3 = GOLD
countdownLabel.TextSize = 24

-- End screen: the winner, your own coins, and the wait for the next round.
local endFrame = Instance.new("Frame")
endFrame.Name = "EndScreen"
endFrame.AnchorPoint = Vector2.new(0.5, 0.5)
endFrame.Position = UDim2.fromScale(0.5, 0.45)
endFrame.Size = UDim2.fromOffset(460, 200)
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
	"TIME UP!",
	UDim2.new(1, 0, 0, 52),
	UDim2.new(0.5, 0, 0, 14)
)
endTitle.TextColor3 = GOLD
endTitle.TextSize = 34

local winnerLabel = newLabel(
	endFrame,
	"Winner",
	"",
	UDim2.new(1, -32, 0, 40),
	UDim2.new(0.5, 0, 0, 70)
)
winnerLabel.TextSize = 24

local yourCoinsLabel = newLabel(
	endFrame,
	"YourCoins",
	"",
	UDim2.new(1, -32, 0, 36),
	UDim2.new(0.5, 0, 0, 112)
)
yourCoinsLabel.TextSize = 22

local nextLabel = newLabel(
	endFrame,
	"Next",
	"Next round starts soon...",
	UDim2.new(1, 0, 0, 30),
	UDim2.new(0.5, 0, 0, 154)
)
nextLabel.TextSize = 18
nextLabel.TextTransparency = 0.2

-- Feedback ------------------------------------------------------------------

local function pulseCoins()
	local tween = TweenService:Create(
		coinsLabel,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextSize = 36 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		TweenService:Create(
			coinsLabel,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextSize = 28 }
		):Play()
	end)
end

local function showDamage()
	flash.BackgroundTransparency = 0.55
	TweenService:Create(
		flash,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()
end

local function setCoins(value)
	myCoins = value
	coinsLabel.Text = "COINS: " .. tostring(value)
end

feedbackEvent.OnClientEvent:Connect(function(kind, value)
	if kind == "Coin" then
		setCoins(value)
		pulseCoins()
	elseif kind == "Hit" or kind == "Lava" then
		showDamage()
	end
end)

-- The scoreboard replicates on its own; follow it so a mid-round join
-- still sees the right count.
local leaderstats = player:WaitForChild("leaderstats")
local coinsValue = leaderstats:WaitForChild("Coins")
setCoins(coinsValue.Value)
coinsValue.Changed:Connect(function(value)
	setCoins(value)
end)

-- Round state -----------------------------------------------------------------

roundEvent.OnClientEvent:Connect(function(newState, secondsLeft, winner, winnerCoins)
	if newState == "Intermission" then
		startFrame.Visible = true
		endFrame.Visible = false
		timerLabel.Text = "GET READY"
		countdownLabel.Text = "Round starts in " .. tostring(secondsLeft) .. "s"
	elseif newState == "Round" then
		startFrame.Visible = false
		endFrame.Visible = false
		timerLabel.Text = "ROUND  " .. formatTime(secondsLeft)
	elseif newState == "Ending" then
		startFrame.Visible = false
		endFrame.Visible = true
		timerLabel.Text = "TIME UP!"
		if winner and winner ~= "" then
			winnerLabel.Text = "Winner: " .. winner .. "  (" .. tostring(winnerCoins) .. " coins)"
		else
			winnerLabel.Text = "No coins collected this round"
		end
		yourCoinsLabel.Text = "Your coins: " .. tostring(myCoins)
	end
end)
