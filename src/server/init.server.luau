-- Coin Rush Dodge: the server.
-- Owns the round loop, the coins, the falling balls, the lava and the
-- scoreboard. The client only draws what this script broadcasts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundEvent = remotes:WaitForChild("RoundEvent")
local feedbackEvent = remotes:WaitForChild("FeedbackEvent")

-- State shared by the round loop: "Intermission", "Round" or "Ending".
local state = "Intermission"
local timeLeft = 0
local roundActive = false
local winnerName = ""
local winnerCoins = 0

-- Coins collected this round, keyed by player. Mirrored into leaderstats.
local scores = {}

local coinFolder = Instance.new("Folder")
coinFolder.Name = "Coins"
coinFolder.Parent = Workspace

local ballFolder = Instance.new("Folder")
ballFolder.Name = "Balls"
ballFolder.Parent = Workspace

local function randomArenaPosition(y)
	return Vector3.new(
		math.random(-Config.ARENA_HALF, Config.ARENA_HALF),
		y,
		math.random(-Config.ARENA_HALF, Config.ARENA_HALF)
	)
end

local function setCoins(player, value)
	scores[player] = value
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then
		coins.Value = value
	end
end

local function setupLeaderstats(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = stats

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = stats

	stats.Parent = player
	scores[player] = 0
end

Players.PlayerAdded:Connect(setupLeaderstats)
for _, player in ipairs(Players:GetPlayers()) do
	setupLeaderstats(player)
end
Players.PlayerRemoving:Connect(function(player)
	scores[player] = nil
end)

-- Coins ---------------------------------------------------------------------

local function spawnCoin()
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.6, 2.4, 2.4)
	coin.CFrame = CFrame.new(randomArenaPosition(2)) * CFrame.Angles(0, 0, math.rad(90))
	coin.Anchored = true
	coin.CanCollide = false
	coin.Material = Enum.Material.Neon
	coin.Color = Color3.fromRGB(255, 200, 40)
	coin:SetAttribute("Spin", math.random(0, 359))
	coin.Parent = coinFolder

	local collected = false
	coin.Touched:Connect(function(hit)
		if collected then
			return
		end
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local player = humanoid and Players:GetPlayerFromCharacter(character)
		if not player or humanoid.Health <= 0 then
			return
		end
		collected = true
		setCoins(player, (scores[player] or 0) + Config.COIN_VALUE)
		feedbackEvent:FireClient(player, "Coin", scores[player])
		coin:Destroy()
	end)
end

-- One slow loop keeps the field topped up and spins every coin on its own
-- vertical axis, so a coin reads as a pickup from any angle.
task.spawn(function()
	while true do
		task.wait(0.05)
		for _, coin in ipairs(coinFolder:GetChildren()) do
			if coin:IsA("BasePart") then
				local angle = ((coin:GetAttribute("Spin") or 0) + 6) % 360
				coin:SetAttribute("Spin", angle)
				coin.CFrame = CFrame.new(coin.Position)
					* CFrame.Angles(0, math.rad(angle), 0)
					* CFrame.Angles(0, 0, math.rad(90))
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		local missing = Config.COIN_TARGET - #coinFolder:GetChildren()
		for _ = 1, missing do
			spawnCoin()
		end
	end
end)

for _ = 1, Config.COIN_TARGET do
	spawnCoin()
end

-- Falling balls --------------------------------------------------------------

local function spawnBall()
	local size = math.random(3, 5)
	local ball = Instance.new("Part")
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(size, size, size)
	ball.Position = randomArenaPosition(55)
	ball.Anchored = false
	ball.CanCollide = true
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.fromRGB(200, 40, 40)
	ball.Parent = ballFolder
	Debris:AddItem(ball, 8)

	local gone = false
	ball.Touched:Connect(function(other)
		if gone then
			return
		end
		if other.Name == "Baseplate" then
			gone = true
			ball:Destroy()
			return
		end
		local character = other.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local player = humanoid and Players:GetPlayerFromCharacter(character)
		if player and humanoid.Health > 0 then
			gone = true
			humanoid:TakeDamage(Config.BALL_DAMAGE)
			feedbackEvent:FireClient(player, "Hit", Config.BALL_DAMAGE)
			task.delay(0.1, function()
				if ball.Parent then
					ball:Destroy()
				end
			end)
		end
	end)
end

-- Balls fall only while a round runs, and faster as the clock runs down.
local function ballLoop()
	while roundActive do
		local progress = 1 - (timeLeft / Config.ROUND_LENGTH)
		local interval = Config.BALL_INTERVAL_START
			+ (Config.BALL_INTERVAL_END - Config.BALL_INTERVAL_START) * progress
		spawnBall()
		task.wait(interval)
	end
end

-- Lava -----------------------------------------------------------------------

local lavaDebounce = {}
local lavaFolder = Workspace:WaitForChild("Lava")
for _, lava in ipairs(lavaFolder:GetChildren()) do
	if lava:IsA("BasePart") then
		lava.Touched:Connect(function(hit)
			local character = hit.Parent
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local player = humanoid and Players:GetPlayerFromCharacter(character)
			if not player or humanoid.Health <= 0 then
				return
			end
			local now = os.clock()
			if now - (lavaDebounce[player] or 0) < 1 then
				return
			end
			lavaDebounce[player] = now
			humanoid:TakeDamage(Config.LAVA_DAMAGE)
			feedbackEvent:FireClient(player, "Lava", Config.LAVA_DAMAGE)
		end)
	end
end

-- Rounds ---------------------------------------------------------------------

local function broadcast()
	roundEvent:FireAllClients(state, timeLeft, winnerName, winnerCoins)
end

local function resetScores()
	for _, player in ipairs(Players:GetPlayers()) do
		setCoins(player, 0)
	end
end

local function runRounds()
	while true do
		-- Lobby: the field is open, the clock counts down to the round.
		state = "Intermission"
		winnerName = ""
		winnerCoins = 0
		roundActive = false
		for t = Config.INTERMISSION_LENGTH, 1, -1 do
			timeLeft = t
			broadcast()
			task.wait(1)
		end

		-- The round: 60 seconds, most coins wins.
		resetScores()
		state = "Round"
		roundActive = true
		task.spawn(ballLoop)
		for t = Config.ROUND_LENGTH, 1, -1 do
			timeLeft = t
			broadcast()
			task.wait(1)
		end
		roundActive = false

		-- The result: crown the round winner, then loop back to the lobby.
		state = "Ending"
		timeLeft = 0
		local bestPlayer = nil
		local bestCoins = 0
		for player, coins in pairs(scores) do
			if coins > bestCoins then
				bestPlayer = player
				bestCoins = coins
			end
		end
		if bestPlayer then
			winnerName = bestPlayer.DisplayName
			winnerCoins = bestCoins
			local stats = bestPlayer:FindFirstChild("leaderstats")
			local wins = stats and stats:FindFirstChild("Wins")
			if wins then
				wins.Value += 1
			end
		end
		broadcast()
		task.wait(Config.ENDING_LENGTH)
	end
end

task.spawn(runRounds)
