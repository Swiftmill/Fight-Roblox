--!strict
-- CombatService.server.lua
-- Authoritative combat logic and lobby messaging for ZEN Reborn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local CombatShared = require(ReplicatedStorage:WaitForChild("CombatShared"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

export type PlayerState = {
    Blocking: boolean,
    BlockStart: number,
    Target: Player?,
    LastKick: number,
    LastShockwave: number,
    LastTaunt: number,
}

local playerStates: {[Player]: PlayerState} = {}

local function getState(player: Player): PlayerState
    local state = playerStates[player]
    if not state then
        state = {
            Blocking = false,
            BlockStart = 0,
            Target = nil,
            LastKick = 0,
            LastShockwave = 0,
            LastTaunt = 0,
        }
        playerStates[player] = state
    end
    return state
end

local function getHumanoidFromTarget(target: Instance?): Humanoid?
    if not target then
        return nil
    end

    if target:IsA("Humanoid") then
        return target
    end

    return target:FindFirstAncestorOfClass("Model") and target:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid")
end

local function applyDamage(attacker: Player, humanoid: Humanoid, amount: number)
    if humanoid.Health <= 0 then
        return
    end

    local victimPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)
    if victimPlayer then
        local victimState = getState(victimPlayer)
        if victimState.Blocking then
            amount *= CombatShared.Config.BlockDamageScalar
        end
    end

    humanoid:TakeDamage(amount)
    if humanoid.Health <= 0 and victimPlayer then
        Remotes.Announcement:FireAllClients(string.format("%s a vaincu %s!", attacker.DisplayName, victimPlayer.DisplayName))
    end
end

local function handleAttack(player: Player, targetHumanoid: Humanoid?)
    if not targetHumanoid then
        return
    end

    local state = getState(player)
    local attackerCharacter = player.Character
    local attackerRoot = attackerCharacter and attackerCharacter:FindFirstChild("HumanoidRootPart")
    if not attackerRoot then
        return
    end

    local victimCharacter = targetHumanoid.Parent
    local victimRoot = victimCharacter and victimCharacter:FindFirstChild("HumanoidRootPart")
    if not victimRoot then
        return
    end

    local distance = (attackerRoot.Position - victimRoot.Position).Magnitude
    if distance > CombatShared.Config.AttackRange then
        return
    end

    applyDamage(player, targetHumanoid, CombatShared.Config.AttackDamage)
end

local function handleBlock(player: Player, isBlocking: boolean)
    local state = getState(player)
    state.Blocking = isBlocking
    if isBlocking then
        state.BlockStart = os.clock()
    else
        state.BlockStart = 0
    end
end

local function handleShockwave(player: Player, targetRoot: BasePart?)
    local state = getState(player)
    local now = os.clock()
    if now - state.LastShockwave < CombatShared.Config.ShockwaveCooldown then
        return
    end

    state.LastShockwave = now

    local center: Vector3
    if targetRoot then
        center = targetRoot.Position
    else
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end
        center = root.Position
    end

    for _, other in Players:GetPlayers() do
        if other ~= player then
            local character = other.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local otherRoot = character and character:FindFirstChild("HumanoidRootPart")
            if humanoid and otherRoot then
                local distance = (otherRoot.Position - center).Magnitude
                if distance <= CombatShared.Config.ShockwaveRadius then
                    applyDamage(player, humanoid, CombatShared.Config.ShockwaveDamage)
                    local bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.MaxForce = Vector3.new(4e4, 4e4, 4e4)
                    bodyVelocity.Velocity = (otherRoot.Position - center).Unit * 60 + Vector3.new(0, 30, 0)
                    bodyVelocity.Parent = otherRoot
                    Debris:AddItem(bodyVelocity, 0.35)
                end
            end
        end
    end
end

local function handleKick(player: Player, targetHumanoid: Humanoid?)
    if not targetHumanoid then
        return
    end

    local state = getState(player)
    local now = os.clock()
    if now - state.LastKick < CombatShared.Config.KickCooldown then
        return
    end
    state.LastKick = now

    local victimPlayer = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
    if victimPlayer then
        local victimState = getState(victimPlayer)
        if victimState.Blocking then
            if victimState.BlockStart > 0 and now - victimState.BlockStart >= CombatShared.Config.BlockBreakThreshold then
                victimState.Blocking = false
                victimState.BlockStart = 0
                Remotes.BlockBroken:FireClient(victimPlayer)
            end
        end
    end

    applyDamage(player, targetHumanoid, CombatShared.Config.KickDamage)
end

local function handleTaunt(player: Player)
    local state = getState(player)
    local now = os.clock()
    if now - state.LastTaunt < CombatShared.Config.TauntCooldown then
        return
    end
    state.LastTaunt = now

    Remotes.Announcement:FireAllClients(string.format("%s provoque l'adversaire...", player.DisplayName))
end

local function handleLock(player: Player, targetPlayer: Player?)
    local state = getState(player)
    state.Target = targetPlayer
end

local function onPurchaseRequest(player: Player, itemId: string)
    Remotes.Announcement:FireClient(player, string.format("%s acheté (prototype)", itemId))
end

Remotes.Attack.OnServerEvent:Connect(function(player, target)
    handleAttack(player, getHumanoidFromTarget(target))
end)

Remotes.Block.OnServerEvent:Connect(handleBlock)

Remotes.Shockwave.OnServerEvent:Connect(function(player, targetRoot)
    handleShockwave(player, targetRoot)
end)

Remotes.Kick.OnServerEvent:Connect(function(player, target)
    handleKick(player, getHumanoidFromTarget(target))
end)

Remotes.Taunt.OnServerEvent:Connect(handleTaunt)
Remotes.LockOn.OnServerEvent:Connect(handleLock)
Remotes.Purchase.OnServerEvent:Connect(onPurchaseRequest)

Players.PlayerRemoving:Connect(function(player)
    playerStates[player] = nil
end)

Remotes.Announcement:FireAllClients("Bienvenue à ZEN Reborn. Soutenez-nous avec un pouce levé !")
