local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = script.Parent
local remotes = ReplicatedStorage:WaitForChild("QueueRemotes")
local queueActionRemote = remotes:WaitForChild("QueueAction")
local queueStateRemote = remotes:WaitForChild("QueueState")
local returnToLobbyRemote = remotes:WaitForChild("ReturnToLobby")

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 1)
root.Position = UDim2.fromScale(0.5, 0.965)
root.Size = UDim2.fromOffset(820, 228)
root.BackgroundTransparency = 1
root.Parent = gui

local topBanner = Instance.new("Frame")
topBanner.Name = "TopBanner"
topBanner.AnchorPoint = Vector2.new(0, 0)
topBanner.Position = UDim2.fromOffset(28, 24)
topBanner.Size = UDim2.fromOffset(560, 92)
topBanner.BackgroundColor3 = Color3.fromRGB(15, 19, 27)
topBanner.BackgroundTransparency = 0.18
topBanner.Parent = gui
corner(topBanner, 24)
stroke(topBanner, Color3.fromRGB(73, 84, 107), 1, 0.25)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 14)
title.Size = UDim2.fromOffset(300, 30)
title.Font = Enum.Font.GothamBlack
title.Text = "Creeper Survival"
title.TextColor3 = Color3.fromRGB(245, 247, 250)
title.TextSize = 28
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBanner

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(20, 50)
subtitle.Size = UDim2.fromOffset(500, 24)
subtitle.Font = Enum.Font.GothamMedium
subtitle.Text = "Queue for an arena and drop in when the timer ends."
subtitle.TextColor3 = Color3.fromRGB(191, 199, 214)
subtitle.TextSize = 15
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = topBanner

local returnButton = Instance.new("TextButton")
returnButton.Name = "ReturnButton"
returnButton.AnchorPoint = Vector2.new(1, 0)
returnButton.Position = UDim2.new(1, -28, 0, 24)
returnButton.Size = UDim2.fromOffset(180, 56)
returnButton.BackgroundColor3 = Color3.fromRGB(233, 91, 91)
returnButton.Text = "Return To Lobby"
returnButton.Font = Enum.Font.GothamBold
returnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
returnButton.TextSize = 18
returnButton.Visible = false
returnButton.AutoButtonColor = false
returnButton.Parent = gui
corner(returnButton, 18)
stroke(returnButton, Color3.fromRGB(255, 201, 201), 1, 0.35)

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.AnchorPoint = Vector2.new(0.5, 1)
playButton.Position = UDim2.new(0.5, 0, 1, -24)
playButton.Size = UDim2.fromOffset(220, 64)
playButton.BackgroundColor3 = Color3.fromRGB(88, 193, 255)
playButton.Text = "Play"
playButton.Font = Enum.Font.GothamBlack
playButton.TextColor3 = Color3.fromRGB(13, 18, 26)
playButton.TextSize = 26
playButton.AutoButtonColor = false
playButton.Parent = gui
corner(playButton, 20)
stroke(playButton, Color3.fromRGB(215, 242, 255), 1, 0.3)

local playSubtext = Instance.new("TextLabel")
playSubtext.Name = "PlaySubtext"
playSubtext.BackgroundTransparency = 1
playSubtext.AnchorPoint = Vector2.new(0.5, 1)
playSubtext.Position = UDim2.new(0.5, 0, 1, -6)
playSubtext.Size = UDim2.fromOffset(280, 18)
playSubtext.Font = Enum.Font.GothamMedium
playSubtext.Text = "Choose an arena queue"
playSubtext.TextColor3 = Color3.fromRGB(204, 216, 231)
playSubtext.TextSize = 14
playSubtext.Parent = gui

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -16, 0, 16)
closeButton.Size = UDim2.fromOffset(38, 38)
closeButton.BackgroundColor3 = Color3.fromRGB(26, 31, 42)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextColor3 = Color3.fromRGB(236, 240, 245)
closeButton.TextSize = 16
closeButton.AutoButtonColor = false
closeButton.Parent = topBanner
corner(closeButton, 14)
stroke(closeButton, Color3.fromRGB(93, 102, 121), 1, 0.35)

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 18)
layout.Parent = root

local cards = {}
local queueOrder = {"mountain", "canyon"}
local accentMap = {
    mountain = Color3.fromRGB(91, 194, 255),
    canyon = Color3.fromRGB(255, 205, 92),
}

local function createCard(arenaId)
    local card = Instance.new("Frame")
    card.Name = arenaId .. "Card"
    card.Size = UDim2.fromOffset(401, 228)
    card.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
    card.BackgroundTransparency = 0.12
    card.Parent = root
    corner(card, 26)
    stroke(card, Color3.fromRGB(72, 79, 98), 1, 0.22)

    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.BackgroundColor3 = accentMap[arenaId]
    glow.BackgroundTransparency = 0.82
    glow.BorderSizePixel = 0
    glow.Position = UDim2.fromOffset(0, 0)
    glow.Size = UDim2.new(1, 0, 0, 8)
    glow.Parent = card
    corner(glow, 26)

    local name = Instance.new("TextLabel")
    name.Name = "Name"
    name.BackgroundTransparency = 1
    name.Position = UDim2.fromOffset(22, 20)
    name.Size = UDim2.fromOffset(260, 34)
    name.Font = Enum.Font.GothamBlack
    name.Text = "Arena"
    name.TextColor3 = Color3.fromRGB(245, 247, 250)
    name.TextSize = 24
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = card

    local desc = Instance.new("TextLabel")
    desc.Name = "Description"
    desc.BackgroundTransparency = 1
    desc.Position = UDim2.fromOffset(22, 56)
    desc.Size = UDim2.fromOffset(250, 42)
    desc.Font = Enum.Font.Gotham
    desc.TextWrapped = true
    desc.Text = "Arena description"
    desc.TextColor3 = Color3.fromRGB(177, 186, 200)
    desc.TextSize = 15
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Parent = card

    local pill = Instance.new("Frame")
    pill.Name = "StatusPill"
    pill.Position = UDim2.fromOffset(22, 114)
    pill.Size = UDim2.fromOffset(148, 34)
    pill.BackgroundColor3 = Color3.fromRGB(30, 35, 49)
    pill.Parent = card
    corner(pill, 17)

    local pillText = Instance.new("TextLabel")
    pillText.Name = "StatusText"
    pillText.BackgroundTransparency = 1
    pillText.Size = UDim2.fromScale(1, 1)
    pillText.Font = Enum.Font.GothamBold
    pillText.Text = "Waiting"
    pillText.TextColor3 = Color3.fromRGB(220, 226, 236)
    pillText.TextSize = 15
    pillText.Parent = pill

    local count = Instance.new("TextLabel")
    count.Name = "Count"
    count.BackgroundTransparency = 1
    count.Position = UDim2.fromOffset(22, 150)
    count.Size = UDim2.fromOffset(170, 30)
    count.Font = Enum.Font.GothamBlack
    count.Text = "0 / 6 queued"
    count.TextColor3 = Color3.fromRGB(245, 247, 250)
    count.TextSize = 22
    count.TextXAlignment = Enum.TextXAlignment.Left
    count.Parent = card

    local countdown = Instance.new("TextLabel")
    countdown.Name = "Countdown"
    countdown.BackgroundTransparency = 1
    countdown.Position = UDim2.fromOffset(22, 184)
    countdown.Size = UDim2.fromOffset(200, 24)
    countdown.Font = Enum.Font.GothamMedium
    countdown.Text = "Countdown: waiting"
    countdown.TextColor3 = Color3.fromRGB(179, 188, 202)
    countdown.TextSize = 15
    countdown.TextXAlignment = Enum.TextXAlignment.Left
    countdown.Parent = card

    local button = Instance.new("TextButton")
    button.Name = "ActionButton"
    button.AnchorPoint = Vector2.new(1, 1)
    button.Position = UDim2.new(1, -22, 1, -22)
    button.Size = UDim2.fromOffset(146, 48)
    button.BackgroundColor3 = accentMap[arenaId]
    button.Text = "Join Queue"
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.fromRGB(15, 18, 24)
    button.TextSize = 18
    button.AutoButtonColor = false
    button.Parent = card
    corner(button, 18)

    cards[arenaId] = {
        frame = card,
        pill = pill,
        pillText = pillText,
        name = name,
        desc = desc,
        count = count,
        countdown = countdown,
        button = button,
        accent = accentMap[arenaId],
    }

    button.MouseButton1Click:Connect(function()
        local current = player:GetAttribute("QueuedArena")
        local zone = player:GetAttribute("CurrentZone") or "Lobby"
        if zone ~= "Lobby" then
            return
        end
        if current == arenaId then
            queueActionRemote:FireServer("leave")
        else
            queueActionRemote:FireServer("join", arenaId)
        end
    end)
end

for _, arenaId in ipairs(queueOrder) do
    createCard(arenaId)
end

local waveStatus = Instance.new("TextLabel")
waveStatus.Name = "WaveStatus"
waveStatus.AnchorPoint = Vector2.new(0.5, 0)
waveStatus.Position = UDim2.fromScale(0.5, 0.06)
waveStatus.Size = UDim2.fromOffset(260, 42)
waveStatus.BackgroundColor3 = Color3.fromRGB(16, 20, 29)
waveStatus.BackgroundTransparency = 0.18
waveStatus.Font = Enum.Font.GothamBlack
waveStatus.Text = ""
waveStatus.TextColor3 = Color3.fromRGB(245, 247, 250)
waveStatus.TextSize = 28
waveStatus.Visible = false
waveStatus.Parent = gui
corner(waveStatus, 18)
stroke(waveStatus, Color3.fromRGB(89, 101, 127), 1, 0.3)

local lastSnapshot = {
    queues = {},
    yourQueue = nil,
    currentZone = player:GetAttribute("CurrentZone") or "Lobby",
}
local queuePanelOpen = false
local updateUi

local function setQueuePanelOpen(isOpen)
    queuePanelOpen = isOpen
end

playButton.MouseButton1Click:Connect(function()
    setQueuePanelOpen(true)
    updateUi(lastSnapshot)
end)

closeButton.MouseButton1Click:Connect(function()
    setQueuePanelOpen(false)
    updateUi(lastSnapshot)
end)

returnButton.MouseButton1Click:Connect(function()
    returnToLobbyRemote:FireServer()
end)

updateUi = function(snapshot)
    lastSnapshot = snapshot or lastSnapshot
    local zone = lastSnapshot.currentZone or "Lobby"
    local yourQueue = lastSnapshot.yourQueue
    local inLobby = zone == "Lobby"

    if not inLobby then
        queuePanelOpen = false
    end

    root.Visible = inLobby and queuePanelOpen
    topBanner.Visible = inLobby and queuePanelOpen
    playButton.Visible = inLobby and not queuePanelOpen
    playSubtext.Visible = inLobby and not queuePanelOpen
    closeButton.Visible = inLobby and queuePanelOpen
    returnButton.Visible = not inLobby
    local currentWave = player:GetAttribute("CurrentWave")
    waveStatus.Visible = not inLobby and type(currentWave) == "number" and currentWave > 0
    waveStatus.Text = waveStatus.Visible and string.format("Wave %d", currentWave) or ""

    for arenaId, card in pairs(cards) do
        local data = lastSnapshot.queues and lastSnapshot.queues[arenaId]
        if data then
            card.name.Text = data.name
            card.desc.Text = data.description
            card.count.Text = string.format("%d / %d queued", data.count, data.maxPlayers)
            if data.countdown then
                card.pill.BackgroundColor3 = Color3.fromRGB(44, 58, 84)
                card.pillText.Text = "Launching"
                card.countdown.Text = string.format("Match begins in %ds", data.countdown)
            elseif data.count > 0 then
                card.pill.BackgroundColor3 = Color3.fromRGB(37, 49, 67)
                card.pillText.Text = "Forming"
                card.countdown.Text = string.format("Waiting for %d player(s)", math.max(0, data.minPlayers - data.count))
            else
                card.pill.BackgroundColor3 = Color3.fromRGB(30, 35, 49)
                card.pillText.Text = "Open"
                card.countdown.Text = "Ready for the next squad"
            end

            local isYourQueue = yourQueue == arenaId
            if not inLobby then
                card.button.Text = "In Match"
                card.button.BackgroundColor3 = Color3.fromRGB(66, 70, 78)
                card.button.TextColor3 = Color3.fromRGB(210, 214, 222)
            elseif isYourQueue then
                card.button.Text = "Leave Queue"
                card.button.BackgroundColor3 = Color3.fromRGB(239, 95, 95)
                card.button.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                card.button.Text = "Join Queue"
                card.button.BackgroundColor3 = card.accent
                card.button.TextColor3 = Color3.fromRGB(15, 18, 24)
            end
        end
    end
end

player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
    lastSnapshot.currentZone = player:GetAttribute("CurrentZone") or "Lobby"
    updateUi(lastSnapshot)
end)

player:GetAttributeChangedSignal("QueuedArena"):Connect(function()
    lastSnapshot.yourQueue = player:GetAttribute("QueuedArena")
    updateUi(lastSnapshot)
end)

player:GetAttributeChangedSignal("CurrentWave"):Connect(function()
    updateUi(lastSnapshot)
end)

queueStateRemote.OnClientEvent:Connect(function(snapshot)
    updateUi(snapshot)
end)

updateUi(lastSnapshot)
