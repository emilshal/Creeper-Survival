local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local remotes = ReplicatedStorage:WaitForChild("QueueRemotes")
local queueActionRemote = remotes:WaitForChild("QueueAction")
local queueStateRemote = remotes:WaitForChild("QueueState")
local returnToLobbyRemote = remotes:WaitForChild("ReturnToLobby")

local LOBBY_CFRAME = CFrame.new(0, 24, 520)
local QUEUE_COUNTDOWN = 8
local MATCH_SPREAD = 10
local WAVE_ONE_CREEPER_COUNT = 2
local WAVE_ONE_SPAWN_DELAY = 1.5

local creeperTemplate = ServerStorage:WaitForChild("Enemies"):WaitForChild("CreeperTemplate")
local enemyFolder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
enemyFolder.Name = "Enemies"
enemyFolder.Parent = Workspace

local arenas = {
    mountain = {
        id = "mountain",
        name = "Mountain Arena",
        description = "Rock tunnels, close cover, and fast creeper pressure.",
        minPlayers = 1,
        maxPlayers = 6,
        destination = CFrame.new(0, 9, 0),
        modelName = "MountainArena",
        accent = Color3.fromRGB(82, 187, 255),
    },
    canyon = {
        id = "canyon",
        name = "Canyon Arena",
        description = "A second queue slot ready for the next arena build.",
        minPlayers = 1,
        maxPlayers = 6,
        destination = CFrame.new(520, 9, 0),
        modelName = "ArenaBetaShell",
        accent = Color3.fromRGB(255, 198, 84),
    },
}

local queues = {}
for arenaId, arena in pairs(arenas) do
    queues[arenaId] = {
        arena = arena,
        players = {},
        countdown = nil,
    }
end

local function pivotCharacter(player, destination)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end
    character:PivotTo(destination)
    return true
end

local function compactPlayers(list)
    local kept = {}
    for _, player in ipairs(list) do
        if player and player.Parent == Players then
            table.insert(kept, player)
        end
    end
    return kept
end

local function getArenaBounds(arena)
    local model = arena.modelName and Workspace:FindFirstChild(arena.modelName)
    if model and model:IsA("Model") then
        local cf, size = model:GetBoundingBox()
        return cf.Position, size
    end
    return arena.destination.Position, Vector3.new(120, 20, 120)
end

local function findGroundPosition(position)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {enemyFolder}

    local origin = position + Vector3.new(0, 80, 0)
    local result = Workspace:Raycast(origin, Vector3.new(0, -220, 0), rayParams)
    if result then
        return result.Position + Vector3.new(0, 3.5, 0)
    end
    return position
end

local function getWaveOneSpawnPoints(arena)
    local center, size = getArenaBounds(arena)
    local edgeOffsetX = math.max(18, size.X * 0.5 - 14)
    local first = Vector3.new(center.X - edgeOffsetX, arena.destination.Position.Y, center.Z)
    local second = Vector3.new(center.X + edgeOffsetX, arena.destination.Position.Y, center.Z)
    return {
        findGroundPosition(first),
        findGroundPosition(second),
    }
end

local function clearArenaEnemies(arenaId)
    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        if enemy:GetAttribute("ArenaId") == arenaId then
            enemy:Destroy()
        end
    end
end

local function spawnWaveOne(arenaId)
    local queue = queues[arenaId]
    if not queue then
        return
    end

    clearArenaEnemies(arenaId)

    local spawnPoints = getWaveOneSpawnPoints(queue.arena)
    for index = 1, math.min(WAVE_ONE_CREEPER_COUNT, #spawnPoints) do
        local spawnPosition = spawnPoints[index]
        local enemy = creeperTemplate:Clone()
        enemy.Name = string.format("%sWave1Creeper%d", queue.arena.id, index)
        enemy:SetAttribute("ArenaId", arenaId)
        enemy:SetAttribute("ArenaZone", queue.arena.name)
        enemy.Parent = enemyFolder

        local center = queue.arena.destination.Position
        enemy:PivotTo(CFrame.lookAt(spawnPosition, Vector3.new(center.X, spawnPosition.Y, center.Z)))
    end
end

local function removePlayerFromQueue(player, skipBroadcast)
    local changed = false
    for _, queue in pairs(queues) do
        local nextPlayers = {}
        for _, queuedPlayer in ipairs(queue.players) do
            if queuedPlayer ~= player then
                table.insert(nextPlayers, queuedPlayer)
            else
                changed = true
            end
        end
        queue.players = nextPlayers
    end
    if changed then
        player:SetAttribute("QueuedArena", nil)
    end
    if changed and not skipBroadcast then
        return true
    end
    return changed
end

local function buildSnapshot()
    local snapshot = {
        queues = {},
    }

    for arenaId, queue in pairs(queues) do
        queue.players = compactPlayers(queue.players)
        local names = {}
        for _, player in ipairs(queue.players) do
            table.insert(names, player.Name)
        end
        snapshot.queues[arenaId] = {
            id = queue.arena.id,
            name = queue.arena.name,
            description = queue.arena.description,
            minPlayers = queue.arena.minPlayers,
            maxPlayers = queue.arena.maxPlayers,
            count = #queue.players,
            countdown = queue.countdown,
            players = names,
        }
    end

    return snapshot
end

local function broadcastState()
    local snapshot = buildSnapshot()
    for _, player in ipairs(Players:GetPlayers()) do
        snapshot.youAreQueued = player:GetAttribute("QueuedArena") ~= nil
        snapshot.yourQueue = player:GetAttribute("QueuedArena")
        snapshot.currentZone = player:GetAttribute("CurrentZone") or "Lobby"
        queueStateRemote:FireClient(player, snapshot)
    end
end

local function cancelCountdownIfNeeded(queue)
    if queue.countdown and #queue.players < queue.arena.minPlayers then
        queue.countdown = nil
    end
end

local function launchMatch(arenaId)
    local queue = queues[arenaId]
    if not queue then
        return
    end

    local playersToSend = compactPlayers(queue.players)
    queue.players = {}
    queue.countdown = nil

    for index, player in ipairs(playersToSend) do
        player:SetAttribute("QueuedArena", nil)
        player:SetAttribute("CurrentZone", queue.arena.name)
        player:SetAttribute("CurrentWave", 1)
        local offsetX = ((index - 1) % 3 - 1) * MATCH_SPREAD
        local offsetZ = math.floor((index - 1) / 3) * MATCH_SPREAD
        pivotCharacter(player, queue.arena.destination * CFrame.new(offsetX, 0, offsetZ))
    end

    broadcastState()

    task.delay(WAVE_ONE_SPAWN_DELAY, function()
        spawnWaveOne(arenaId)
    end)
end

local function startCountdown(arenaId)
    local queue = queues[arenaId]
    if not queue or queue.countdown then
        return
    end

    queue.countdown = QUEUE_COUNTDOWN
    broadcastState()

    task.spawn(function()
        while queue.countdown do
            task.wait(1)
            if not queue.countdown then
                return
            end
            queue.players = compactPlayers(queue.players)
            if #queue.players < queue.arena.minPlayers then
                queue.countdown = nil
                broadcastState()
                return
            end

            queue.countdown -= 1
            if queue.countdown <= 0 then
                launchMatch(arenaId)
                return
            end
            broadcastState()
        end
    end)
end

local function joinQueue(player, arenaId)
    local queue = queues[arenaId]
    if not queue then
        return
    end
    if (player:GetAttribute("CurrentZone") or "Lobby") ~= "Lobby" then
        return
    end

    removePlayerFromQueue(player, true)

    queue.players = compactPlayers(queue.players)
    if #queue.players >= queue.arena.maxPlayers then
        broadcastState()
        return
    end

    table.insert(queue.players, player)
    player:SetAttribute("QueuedArena", arenaId)
    if #queue.players >= queue.arena.minPlayers then
        startCountdown(arenaId)
    end
    broadcastState()
end

local function leaveQueue(player)
    local changed = removePlayerFromQueue(player, true)
    if changed then
        for _, queue in pairs(queues) do
            cancelCountdownIfNeeded(queue)
        end
        broadcastState()
    end
end

queueActionRemote.OnServerEvent:Connect(function(player, action, arenaId)
    if action == "join" and typeof(arenaId) == "string" then
        joinQueue(player, string.lower(arenaId))
    elseif action == "leave" then
        leaveQueue(player)
    end
end)

returnToLobbyRemote.OnServerEvent:Connect(function(player)
    leaveQueue(player)
    player:SetAttribute("CurrentZone", "Lobby")
    player:SetAttribute("CurrentWave", nil)
    pivotCharacter(player, LOBBY_CFRAME)
    broadcastState()
end)

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("CurrentZone", "Lobby")
    player:SetAttribute("QueuedArena", nil)
    player:SetAttribute("CurrentWave", nil)

    player.CharacterAdded:Connect(function()
        task.defer(function()
            if (player:GetAttribute("CurrentZone") or "Lobby") == "Lobby" then
                pivotCharacter(player, LOBBY_CFRAME)
            end
            broadcastState()
        end)
    end)

    broadcastState()
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerFromQueue(player, true)
    for _, queue in pairs(queues) do
        cancelCountdownIfNeeded(queue)
    end
    broadcastState()
end)

broadcastState()
