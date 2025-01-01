local Players = game:GetService("Players")

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "RizzHub [Abilty Wars]",
    SubTitle = "by Jovs",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 300),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create Main Tab
local Main = Window:AddTab({ Title = "Main", Icon = "home" })

-- Hitbox Settings
local HitboxSettings = {
    Size = Vector3.new(2, 2, 2),
    Enabled = false
}

-- Function to modify hitbox for a player
local function modifyHitbox(character)
    if not character then return end
    if character == Players.LocalPlayer.Character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    humanoidRootPart.Size = HitboxSettings.Size
    humanoidRootPart.Transparency = 0.4
    humanoidRootPart.Color = Color3.fromRGB(255, 0, 0)
    humanoidRootPart.Material = Enum.Material.ForceField
    humanoidRootPart.CanCollide = false
end

-- Function to reset hitbox for a player
local function resetHitbox(character)
    if not character then return end
    if character == Players.LocalPlayer.Character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    humanoidRootPart.Size = Vector3.new(2, 2, 1)
    humanoidRootPart.Transparency = 1
    humanoidRootPart.Color = Color3.fromRGB(163, 162, 165)
    humanoidRootPart.Material = Enum.Material.SmoothPlastic
    humanoidRootPart.CanCollide = false
end

-- Function to update all players' hitboxes
local function updateAllHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            if HitboxSettings.Enabled then
                modifyHitbox(player.Character)
            else
                resetHitbox(player.Character)
            end
        end
    end
end

-- Main Tab Elements
do
    -- Toggle for Hitbox Modifier
    Main:AddToggle("HitboxEnabled", {
        Title = "Show Enemy Hitboxes",
        Default = false,
        Callback = function(Value)
            HitboxSettings.Enabled = Value
            updateAllHitboxes()
        end
    })

    -- Size Slider
    Main:AddSlider("HitboxSize", {
        Title = "Hitbox Size",
        Default = 2,
        Min = 1,
        Max = 15,
        Rounding = 1,
        Callback = function(Value)
            HitboxSettings.Size = Vector3.new(Value, Value, Value)
            if HitboxSettings.Enabled then
                updateAllHitboxes()
            end
        end
    })
end

-- Player Added Event
Players.PlayerAdded:Connect(function(player)
    if player == Players.LocalPlayer then return end
    
    player.CharacterAdded:Connect(function(character)
        if HitboxSettings.Enabled then
            task.wait(0.5)
            modifyHitbox(character)
        end
    end)
end)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Players.LocalPlayer then
        player.CharacterAdded:Connect(function(character)
            if HitboxSettings.Enabled then
                task.wait(0.5)
                modifyHitbox(character)
            end
        end)
        
        if player.Character and HitboxSettings.Enabled then
            modifyHitbox(player.Character)
        end
    end
end

-- Select Main Tab
Window:SelectTab(1)
