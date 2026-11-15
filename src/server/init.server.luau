-- Kesurupan — Usir Iblis: the server.
-- Owns the round loop, the roles, the two bots, the prayer progress and
-- the escape meter. The client only draws what this script broadcasts
-- and sends chant input.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundEvent = remotes:WaitForChild("RoundEvent")
local chantEvent = remotes:WaitForChild("ChantEvent")

-- State shared by the round loop: "Intermission", "Round" or "Ending".
local state = "Intermission"
local timeLeft = 0
local roundActive = false
local progress = 0
local escapeMeter = 0
local held = false
local freeUntil = 0 -- possessed break-free window: held is ignored before this
local resultText = ""

-- Roles this round: participant (Player or bot Model) -> role string.
local roles = {}
local possessed = nil
local reader = nil
local holder = nil
local chanting = {} -- Player -> boolean

-- Doa points this round, keyed by player. Mirrored into leaderstats.
local scores = {}

local function isPlayer(x)
	return typeof(x) == "Instance" and x:IsA("Player")
end

local function participantKey(x)
	if isPlayer(x) then
		return x.Name
	end
	return x.Name
end

local function participantDisplay(x)
	if isPlayer(x) then
		return x.DisplayName
	end
	return x.Name
end

local function participantCharacter(x)
	if isPlayer(x) then
		return x.Character
	end
	return x -- bots are Models
end

local function participantRoot(x)
	local char = participantCharacter(x)
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

local function participantHumanoid(x)
	local char = participantCharacter(x)
	if not char then
		return nil
	end
	return char:FindFirstChildOfClass("Humanoid")
end

-- Leaderstats ---------------------------------------------------------------

local function setScore(player, value)
	scores[player] = value
	local stats = player:FindFirstChild("leaderstats")
	local doa = stats and stats:FindFirstChild("Doa")
	if doa then
		doa.Value = math.floor(value)
	end
end

local function addScore(player, amount)
	setScore(player, (scores[player] or 0) + amount)
end

local function setupLeaderstats(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local doa = Instance.new("IntValue")
	doa.Name = "Doa"
	doa.Value = 0
	doa.Parent = stats

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
	chanting[player] = nil
end)

-- Bots ----------------------------------------------------------------------

local botFolder = Instance.new("Folder")
botFolder.Name = "Bots"
botFolder.Parent = Workspace

-- Fallback rig: a rigid blocky figure whose parts are welded to its root.
-- Only used if CreateHumanoidModelFromDescription is unavailable.
local function buildBlockyRig(name, colors)
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Parent = model
	local hum = Instance.new("Humanoid")
	hum.WalkSpeed = 14
	hum.Parent = model
	local function part(partName, size, offset, color)
		local p = Instance.new("Part")
		p.Name = partName
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.CFrame = root.CFrame * CFrame.new(offset)
		p.Parent = model
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
		return p
	end
	part("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 2.6, 0), colors.head)
	part("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 1, 0), colors.torso)
	part("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 1, 0), colors.arm)
	part("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 1, 0), colors.arm)
	part("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -1, 0), colors.leg)
	part("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -1, 0), colors.leg)
	model.PrimaryPart = root
	return model
end

local function makeBot(name, colors)
	local ok, model = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		return Players:CreateHumanoidModelFromDescription(desc)
	end)
	if not ok or not model then
		model = buildBlockyRig(name, colors)
	else
		model.Name = name
		local bodyColors = model:FindFirstChildOfClass("BodyColors")
		if bodyColors then
			bodyColors.HeadColor3 = colors.head
			bodyColors.TorsoColor3 = colors.torso
			bodyColors.LeftArmColor3 = colors.arm
			bodyColors.RightArmColor3 = colors.arm
			bodyColors.LeftLegColor3 = colors.leg
			bodyColors.RightLegColor3 = colors.leg
		end
	end
	model.Parent = botFolder
	local root = model:WaitForChild("HumanoidRootPart")
	root.CFrame = CFrame.new(math.random(-10, 10), 3, math.random(-10, 10))
	return model
end

local botA = makeBot("BotA", {
	head = Color3.fromRGB(60, 30, 90),
	torso = Color3.fromRGB(45, 20, 70),
	arm = Color3.fromRGB(60, 30, 90),
	leg = Color3.fromRGB(30, 15, 50),
})
local botB = makeBot("BotB", {
	head = Color3.fromRGB(240, 200, 120),
	torso = Color3.fromRGB(40, 140, 70),
	arm = Color3.fromRGB(240, 200, 120),
	leg = Color3.fromRGB(50, 60, 90),
})

-- Role visuals ---------------------------------------------------------------

local function setOverheadLabel(character, text, color)
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("RoleLabel")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "RoleLabel"
	gui.Size = UDim2.fromOffset(170, 36)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(20, 16, 28)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color
	label.TextSize = 20
	label.TextStrokeTransparency = 0.5
	label.Parent = gui
end

local function applyPossessedAura(character)
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if root:FindFirstChild("PossessedLight") then
		return
	end
	local light = Instance.new("PointLight")
	light.Name = "PossessedLight"
	light.Color = Color3.fromRGB(150, 40, 200)
	light.Range = 10
	light.Brightness = 2
	light.Parent = root
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "PossessedSmoke"
	smoke.Color = ColorSequence.new(Color3.fromRGB(80, 20, 120))
	smoke.Size = NumberSequence.new(1.5)
	smoke.Rate = 12
	smoke.Lifetime = NumberRange.new(0.8)
	smoke.Speed = NumberRange.new(2)
	smoke.Parent = root
end

local function clearPossessedAura(character)
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _, name in ipairs({ "PossessedLight", "PossessedSmoke" }) do
		local child = root:FindFirstChild(name)
		if child then
			child:Destroy()
		end
	end
end

local function clearAllAuras()
	for _, p in ipairs(Players:GetPlayers()) do
		clearPossessedAura(p.Character)
	end
	clearPossessedAura(botA)
	clearPossessedAura(botB)
end

-- Roles ----------------------------------------------------------------------

local function assignRoles()
	roles = {}
	possessed = nil
	reader = nil
	holder = nil
	freeUntil = 0

	local realPlayers = Players:GetPlayers()
	if #realPlayers == 1 then
		-- Solo: the human is always the Reader, bots take the other seats.
		reader = realPlayers[1]
		possessed = botA
		holder = botB
	else
		-- 2+ real players: fill 3 seats with real players first, bots fill
		-- the rest, then pick the possessed at random.
		local participants = {}
		for _, p in ipairs(realPlayers) do
			table.insert(participants, p)
		end
		local bots = { botA, botB }
		local bi = 1
		while #participants < 3 and bi <= #bots do
			table.insert(participants, bots[bi])
			bi += 1
		end
		local possessedIndex = math.random(1, #participants)
		possessed = participants[possessedIndex]
		local rest = {}
		for i, p in ipairs(participants) do
			if i ~= possessedIndex then
				table.insert(rest, p)
			end
		end
		for _, p in ipairs(rest) do
			if isPlayer(p) and not reader then
				reader = p
			elseif not holder then
				holder = p
			end
		end
		if not reader then
			reader = rest[1]
		end
		if not holder then
			holder = rest[2]
		end
	end

	roles[possessed] = "Possessed"
	roles[reader] = "Reader"
	roles[holder] = "Holder"

	for participant, role in pairs(roles) do
		local char = participantCharacter(participant)
		if role == "Possessed" then
			applyPossessedAura(char)
			setOverheadLabel(char, "KESURUPAN", Color3.fromRGB(255, 70, 70))
		elseif role == "Reader" then
			setOverheadLabel(char, "PEMBACA DOA", Color3.fromRGB(255, 220, 90))
		else
			setOverheadLabel(char, "PENAHAN", Color3.fromRGB(90, 220, 120))
		end
		local hum = participantHumanoid(participant)
		if hum then
			if role == "Possessed" then
				hum.WalkSpeed = Config.POSSESSED_SPEED
			elseif role == "Reader" then
				hum.WalkSpeed = Config.READER_SPEED
			else
				hum.WalkSpeed = Config.HOLDER_SPEED
			end
		end
	end
end

-- Chant input -----------------------------------------------------------------

chantEvent.OnServerEvent:Connect(function(player, value)
	if roles[player] == "Reader" and state == "Round" then
		chanting[player] = value == true
	end
end)

-- Held + prayer tick -----------------------------------------------------------

local function updateHeld()
	local pRoot = participantRoot(possessed)
	local hRoot = participantRoot(holder)
	if not pRoot or not hRoot then
		held = false
		return
	end
	local near = (hRoot.Position - pRoot.Position).Magnitude < 5
	held = near and os.clock() >= freeUntil
end

local function tickRound(dt)
	local rRoot = participantRoot(reader)
	local pRoot = participantRoot(possessed)
	local chantingNow = false
	if isPlayer(reader) then
		chantingNow = chanting[reader] == true
	else
		-- A bot reader chants on its own whenever it is close.
		chantingNow = true
	end
	local near = false
	if rRoot and pRoot then
		near = (rRoot.Position - pRoot.Position).Magnitude <= Config.CHANT_RANGE
	end
	if chantingNow and near and held then
		progress = math.min(100, progress + Config.PRAYER_RATE_HELD * dt)
		if isPlayer(reader) then
			addScore(reader, Config.PRAYER_RATE_HELD * dt)
		end
	elseif not chantingNow or not near then
		progress = math.max(0, progress - Config.PRAYER_DECAY * dt)
	end
	-- Escape meter: fills while free, drains while held.
	if held then
		escapeMeter = math.max(0, escapeMeter - Config.ESCAPE_DRAIN * dt)
	else
		escapeMeter = escapeMeter + Config.ESCAPE_FILL * dt
	end
end

-- Bot brains -------------------------------------------------------------------

local function randomPoint()
	return Vector3.new(
		math.random(-Config.ARENA_HALF, Config.ARENA_HALF),
		0,
		math.random(-Config.ARENA_HALF, Config.ARENA_HALF)
	)
end

local function runBot(bot)
	local hum = bot:WaitForChild("Humanoid")
	local root = bot:WaitForChild("HumanoidRootPart")
	local target = root.Position
	local nextThink = 0
	local burstUntil = 0
	local breakFreeAt = 0
	while true do
		local now = os.clock()
		local role = roles[bot]
		if role == "Possessed" then
			if now >= nextThink then
				target = randomPoint()
				nextThink = now + Config.BOT_RETARGET_MIN
					+ math.random() * (Config.BOT_RETARGET_MAX - Config.BOT_RETARGET_MIN)
				if not held and math.random() < Config.BOT_BURST_CHANCE then
					burstUntil = now + 1.2
				end
			end
			if held then
				hum.WalkSpeed = Config.POSSESSED_HELD_SPEED
				if now >= breakFreeAt then
					breakFreeAt = now + Config.BOT_BREAK_FREE_EVERY
					if math.random() < Config.BOT_BREAK_FREE_CHANCE then
						-- Break free: a speed burst the holder cannot match.
						freeUntil = now + 1.5
						burstUntil = now + 1.5
					end
				end
			elseif now < burstUntil then
				hum.WalkSpeed = Config.POSSESSED_BURST_SPEED
			else
				hum.WalkSpeed = Config.POSSESSED_SPEED
			end
			hum:MoveTo(target)
		elseif role == "Holder" then
			local pRoot = participantRoot(possessed)
			if pRoot then
				hum.WalkSpeed = Config.HOLDER_SPEED
				hum:MoveTo(pRoot.Position)
			end
		elseif role == "Reader" then
			-- A bot reader chases the possessed and chants from close range.
			local pRoot = participantRoot(possessed)
			if pRoot then
				hum.WalkSpeed = Config.READER_SPEED
				hum:MoveTo(pRoot.Position)
			end
		else
			-- No role yet (lobby): slow wander so all three characters
			-- are visible in the arena before the round starts.
			if now >= nextThink then
				target = randomPoint()
				nextThink = now + 2.5
			end
			hum.WalkSpeed = 8
			hum:MoveTo(target)
		end
		task.wait(0.25)
	end
end

task.spawn(runBot, botA)
task.spawn(runBot, botB)

-- Broadcast ---------------------------------------------------------------------

local function broadcast()
	local rolesByName = {}
	for participant, role in pairs(roles) do
		rolesByName[participantKey(participant)] = role
	end
	roundEvent:FireAllClients({
		state = state,
		timeLeft = timeLeft,
		progress = math.floor(progress + 0.5),
		held = held,
		escape = math.floor(escapeMeter + 0.5),
		escapeLimit = Config.ESCAPE_LIMIT,
		roles = rolesByName,
		possessedName = possessed and participantDisplay(possessed) or "",
		result = resultText,
	})
end

-- Rounds ---------------------------------------------------------------------

local function resetScores()
	for _, player in ipairs(Players:GetPlayers()) do
		setScore(player, 0)
	end
end

local function runRounds()
	while true do
		-- Lobby: the field is open, the clock counts down to the round.
		state = "Intermission"
		roundActive = false
		progress = 0
		escapeMeter = 0
		resultText = ""
		clearAllAuras()
		for t = Config.INTERMISSION_LENGTH, 1, -1 do
			timeLeft = t
			broadcast()
			task.wait(1)
		end

		-- The round: 60 seconds. Fill the prayer bar while the possessed
		-- is held and the reader chants nearby; lose if it escapes.
		resetScores()
		assignRoles()
		state = "Round"
		roundActive = true
		local won = false
		local loseReason = ""
		local elapsed = 0
		local last = os.clock()
		while roundActive do
			local now = os.clock()
			local dt = math.min(0.5, now - last)
			last = now
			elapsed += dt
			timeLeft = math.max(0, Config.ROUND_LENGTH - math.floor(elapsed))
			updateHeld()
			tickRound(dt)
			if progress >= 100 then
				won = true
				break
			end
			if escapeMeter >= Config.ESCAPE_LIMIT then
				loseReason = "KABUR"
				break
			end
			if possessed and isPlayer(possessed) and not possessed.Parent then
				loseReason = "HILANG"
				break
			end
			if elapsed >= Config.ROUND_LENGTH then
				loseReason = "WAKTU"
				break
			end
			broadcast()
			task.wait(0.1)
		end
		roundActive = false

		-- The result: the whole team shares the win, then back to lobby.
		state = "Ending"
		timeLeft = 0
		if won then
			resultText = "IBLIS TERUSIR!"
			for _, player in ipairs(Players:GetPlayers()) do
				local stats = player:FindFirstChild("leaderstats")
				local wins = stats and stats:FindFirstChild("Wins")
				if wins then
					wins.Value += 1
				end
			end
		elseif loseReason == "KABUR" then
			resultText = "KESURUPAN KABUR!"
		elseif loseReason == "HILANG" then
			resultText = "KESURUPAN MENGHILANG"
		else
			resultText = "WAKTU HABIS"
		end
		broadcast()
		task.wait(Config.ENDING_LENGTH)
	end
end

task.spawn(runRounds)
