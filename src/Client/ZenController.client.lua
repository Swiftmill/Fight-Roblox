--!strict
-- ZenController.client.lua
-- Handles client-side input, animations, lock-on camera, and HUD logic for ZEN Reborn.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local CombatShared = require(ReplicatedStorage:WaitForChild("CombatShared"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local animator = humanoid:WaitForChild("Animator")
local animations = {}
for name, assetId in pairs(CombatShared.Animations) do
    local animation = Instance.new("Animation")
    animation.AnimationId = assetId
    animation.Name = name
    animations[name] = animator:LoadAnimation(animation)
end

local lockTarget: Player? = nil
local lockHighlight: Highlight? = nil
local isBlocking = false
local running = false
local actionCooldowns: {[string]: number} = {}
local infoGui = nil
local shopGui = nil
local emoteHolding = false

local function setWalkSpeed()
    if isBlocking then
        humanoid.WalkSpeed = CombatShared.Config.BlockWalkSpeed
    elseif running then
        humanoid.WalkSpeed = CombatShared.Config.RunSpeed
    else
        humanoid.WalkSpeed = CombatShared.Config.WalkSpeed
    end
end

local function ensureHighlight(targetCharacter: Model)
    if lockHighlight and lockHighlight.Adornee ~= targetCharacter then
        lockHighlight:Destroy()
        lockHighlight = nil
    end

    if not lockHighlight then
        lockHighlight = Instance.new("Highlight")
        lockHighlight.FillColor = Color3.fromRGB(255, 84, 84)
        lockHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        lockHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
        lockHighlight.Parent = targetCharacter
    end

    lockHighlight.Adornee = targetCharacter
end

local function clearLock()
    if lockHighlight then
        lockHighlight:Destroy()
        lockHighlight = nil
    end
    lockTarget = nil
    Remotes.LockOn:FireServer(nil)
end

local function setLockTarget(targetPlayer: Player?)
    if targetPlayer then
        lockTarget = targetPlayer
        Remotes.LockOn:FireServer(targetPlayer)
        local targetCharacter = targetPlayer.Character
        if targetCharacter then
            ensureHighlight(targetCharacter)
        end
    else
        clearLock()
    end
end

local function toggleLock()
    if lockTarget then
        clearLock()
        return
    end

    local candidate = CombatShared.FindClosestEnemy(player, CombatShared.Config.LockOnRange)
    if candidate then
        setLockTarget(candidate)
    end
end

local function canUse(actionName: string, cooldown: number)
    local now = os.clock()
    local last = actionCooldowns[actionName]
    if last and now - last < cooldown then
        return false
    end
    actionCooldowns[actionName] = now
    return true
end

local function playAnimation(name: string)
    local anim = animations[name]
    if anim then
        anim:Play()
    end
end

local function stopAnimation(name: string)
    local anim = animations[name]
    if anim then
        anim:Stop()
    end
end

local function startEmoteHold()
    if emoteHolding then
        return
    end
    emoteHolding = true
    playAnimation("EmoteHold")
end

local function stopEmoteHold()
    if not emoteHolding then
        return
    end
    emoteHolding = false
    stopAnimation("EmoteHold")
end

local function handleAttack()
    if not lockTarget then
        toggleLock()
    end

    local target = lockTarget and lockTarget.Character and lockTarget.Character:FindFirstChildOfClass("Humanoid")
    if target then
        Remotes.Attack:FireServer(target)
        playAnimation("AttackLight")
    end
end

local function handleBlock(actionName, inputState)
    if inputState == Enum.UserInputState.Begin then
        isBlocking = true
        setWalkSpeed()
        Remotes.Block:FireServer(true)
        playAnimation("Block")
    elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
        isBlocking = false
        setWalkSpeed()
        Remotes.Block:FireServer(false)
        stopAnimation("Block")
    end
end

local function handleShockwave()
    if not canUse("Shockwave", CombatShared.Config.ShockwaveCooldown) then
        return
    end
    playAnimation("Shockwave")
    Remotes.Shockwave:FireServer(lockTarget and lockTarget.Character and lockTarget.Character:FindFirstChild("HumanoidRootPart"))
end

local function handleKick()
    if not canUse("Kick", CombatShared.Config.KickCooldown) then
        return
    end

    playAnimation("Kick")
    Remotes.Kick:FireServer(lockTarget and lockTarget.Character and lockTarget.Character:FindFirstChildOfClass("Humanoid"))
end

local function handleTaunt()
    if not canUse("Taunt", CombatShared.Config.TauntCooldown) then
        return
    end

    playAnimation("Taunt")
    Remotes.Taunt:FireServer()
end

local function toggleShop()
    if shopGui then
        shopGui.Enabled = not shopGui.Enabled
    end
end

local function buildInfoGui()
    if player:FindFirstChild("PlayerGui") then
        local screenGui = player.PlayerGui:FindFirstChild("ZenHUD")
        if screenGui then
            infoGui = screenGui:FindFirstChild("ControlsFrame")
            shopGui = screenGui:FindFirstChild("ShopFrame")
        end
    end
end

local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    root = newCharacter:WaitForChild("HumanoidRootPart")
    animator = humanoid:WaitForChild("Animator")
    animations = {}
    for name, assetId in pairs(CombatShared.Animations) do
        local animation = Instance.new("Animation")
        animation.AnimationId = assetId
        animation.Name = name
        animations[name] = animator:LoadAnimation(animation)
    end

    isBlocking = false
    emoteHolding = false
    setWalkSpeed()
end

player.CharacterAdded:Connect(onCharacterAdded)

local function onInputBegan(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftShift then
        running = true
        setWalkSpeed()
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        handleAttack()
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        handleBlock("Block", Enum.UserInputState.Begin)
    elseif input.KeyCode == Enum.KeyCode.R then
        handleShockwave()
    elseif input.KeyCode == Enum.KeyCode.F then
        handleKick()
    elseif input.KeyCode == Enum.KeyCode.T then
        handleTaunt()
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        toggleLock()
    elseif input.KeyCode == Enum.KeyCode.B then
        toggleShop()
    elseif input.KeyCode == Enum.KeyCode.Q then
        startEmoteHold()
    end
end

local function onInputEnded(input, processed)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        running = false
        setWalkSpeed()
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        handleBlock("Block", Enum.UserInputState.End)
    elseif input.KeyCode == Enum.KeyCode.Q then
        stopEmoteHold()
    end
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

RunService.RenderStepped:Connect(function()
    if lockTarget then
        local targetCharacter = lockTarget.Character
        if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
            clearLock()
            return
        end

        ensureHighlight(targetCharacter)

        local targetRoot = targetCharacter.HumanoidRootPart
        local lookAt = CFrame.lookAt(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
        root.CFrame = lookAt
    end
end)

buildInfoGui()
setWalkSpeed()

StarterGui:SetCore("SendNotification", {
    Title = "Bienvenue à ZEN Reborn",
    Text = "Donnez un pouce et rejoignez la communauté !",
    Duration = 5,
})

Remotes.BlockBroken.OnClientEvent:Connect(function()
    if isBlocking then
        isBlocking = false
        stopAnimation("Block")
        setWalkSpeed()
        StarterGui:SetCore("SendNotification", {
            Title = "Blocage brisé",
            Text = "Vous êtes vulnérable quelques instants !",
            Duration = 3,
        })
    end
end)

Remotes.Announcement.OnClientEvent:Connect(function(message)
    StarterGui:SetCore("SendNotification", {
        Title = "ZEN Reborn",
        Text = message,
        Duration = 4,
    })
end)
