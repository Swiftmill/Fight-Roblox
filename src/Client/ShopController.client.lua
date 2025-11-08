--!strict
-- ShopController.client.lua
-- Wires buttons from the shop GUI to the server purchase remote.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local function bindButton(button: TextButton, itemId: string)
    button.MouseButton1Click:Connect(function()
        Remotes.Purchase:FireServer(itemId)
    end)
end

local function setupGui(gui: ScreenGui)
    local shopFrame = gui:WaitForChild("ShopFrame")
    for _, child in ipairs(shopFrame:GetChildren()) do
        if child:IsA("TextButton") then
            bindButton(child, child.Name)
        end
    end
end

local function onPlayerGuiAdded(gui)
    if gui.Name == "ZenHUD" then
        setupGui(gui)
    end
end

local playerGui = player:WaitForChild("PlayerGui")
playerGui.ChildAdded:Connect(onPlayerGuiAdded)

local existing = playerGui:FindFirstChild("ZenHUD")
if existing then
    setupGui(existing)
end
