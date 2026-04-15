local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local creeper = script.Parent
local humanoid = creeper:WaitForChild("Humanoid")
local root = creeper:WaitForChild("HumanoidRootPart")
local stats = creeper:WaitForChild("Stats")

local damage = stats:WaitForChild("Damage").Value
local blastRadius = stats:WaitForChild("BlastRadius").Value
local fuseTime = stats:WaitForChild("FuseTime").Value
local triggerDistance = stats:WaitForChild("TriggerDistance").Value

local exploding = false
local currentWaypointIndex = 0
local currentWaypoints = {}
local moveConnection

local function getTarget()
    local bestCharacter, bestDistance
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
        if hrp and targetHumanoid and targetHumanoid.Health > 0 then
            local distance = (hrp.Position - root.Position).Magnitude
            if not bestDistance or distance < bestDistance then
                bestDistance = distance
                bestCharacter = character
            end
        end
    end
    return bestCharacter, bestDistance
end

local function flashBody(on)
    for _, part in ipairs(creeper:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if on then
                part.Color = Color3.fromRGB(190, 255, 190)
                part.Material = Enum.Material.Neon
            else
                if string.find(part.Name, "Eye") or part.Name == "Nose" or string.find(part.Name, "Mouth") then
                    part.Color = Color3.fromRGB(20, 28, 20)
                elseif string.find(part.Name, "Leg") then
                    part.Color = Color3.fromRGB(63, 119, 52)
                else
                    part.Color = Color3.fromRGB(91, 154, 76)
                end
                part.Material = Enum.Material.SmoothPlastic
            end
        end
    end
end

local function explode()
    if exploding then
        return
    end
    exploding = true
    humanoid.WalkSpeed = 0

    local flashes = math.max(3, math.floor(fuseTime / 0.2))
    for _ = 1, flashes do
        flashBody(true)
        task.wait(0.1)
        flashBody(false)
        task.wait(0.1)
    end

    local explosion = Instance.new("Explosion")
    explosion.Position = root.Position
    explosion.BlastRadius = blastRadius
    explosion.BlastPressure = 0
    explosion.DestroyJointRadiusPercent = 0
    explosion.Parent = workspace

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
        if hrp and targetHumanoid and targetHumanoid.Health > 0 then
            local distance = (hrp.Position - root.Position).Magnitude
            if distance <= blastRadius then
                local scale = 1 - (distance / blastRadius)
                targetHumanoid:TakeDamage(math.max(12, damage * scale))
            end
        end
    end

    humanoid.Health = 0
    task.wait(0.05)
    creeper:Destroy()
end

local function followWaypoints(waypoints)
    currentWaypoints = waypoints
    currentWaypointIndex = 2
    if currentWaypoints[currentWaypointIndex] then
        humanoid:MoveTo(currentWaypoints[currentWaypointIndex].Position)
    end
end

local function computePath(targetPosition)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 8,
        AgentCanJump = true,
        WaypointSpacing = 6,
    })

    local ok = pcall(function()
        path:ComputeAsync(root.Position, targetPosition)
    end)

    if not ok or path.Status ~= Enum.PathStatus.Success then
        humanoid:MoveTo(targetPosition)
        currentWaypoints = {}
        currentWaypointIndex = 0
        return
    end

    followWaypoints(path:GetWaypoints())
end

moveConnection = humanoid.MoveToFinished:Connect(function(reached)
    if exploding or humanoid.Health <= 0 then
        return
    end
    if not reached then
        currentWaypoints = {}
        currentWaypointIndex = 0
        return
    end

    currentWaypointIndex += 1
    local nextWaypoint = currentWaypoints[currentWaypointIndex]
    if nextWaypoint then
        if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end
        humanoid:MoveTo(nextWaypoint.Position)
    end
end)

humanoid.Died:Connect(function()
    if moveConnection then
        moveConnection:Disconnect()
    end
    if creeper and creeper.Parent then
        task.delay(2, function()
            if creeper then
                creeper:Destroy()
            end
        end)
    end
end)

local pathAccumulator = 0
RunService.Heartbeat:Connect(function(dt)
    if exploding or humanoid.Health <= 0 or not root.Parent then
        return
    end

    local targetCharacter, distance = getTarget()
    if not targetCharacter then
        return
    end

    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        return
    end

    if distance and distance <= triggerDistance then
        explode()
        return
    end

    pathAccumulator += dt
    if pathAccumulator < 0.75 then
        return
    end
    pathAccumulator = 0

    computePath(targetRoot.Position)
end)
