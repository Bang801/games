local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local mouse = Players.LocalPlayer:GetMouse()

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local NotificationSettings = {
    KillAuraEnabled = true,
    HitboxEnabled = true,
    AntiVoidEnabled = true,
    NotificationDuration = 3
}

local AutoReconnectSettings = {
    Enabled = false,
    RetryDelay = 5,
    MaxRetries = 5,
    CurrentRetries = 0
}

local Window = Fluent:CreateWindow({
    Title = "RizzHub [Abilty Wars]",
    SubTitle = "RizzHub",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Updates = Window:AddTab({ Title = "Updates", Icon = "history" })
}

local Colors = {
    Success = Color3.fromRGB(0, 255, 128),
    Error = Color3.fromRGB(255, 64, 64),
    Info = Color3.fromRGB(64, 128, 255),
    Warning = Color3.fromRGB(255, 192, 64)
}

local VersionSystem = {
    Current = "1.3",
    PastebinURL = "https://pastebin.com/raw/zTSxYQqN",
    LastNotified = nil
}

local KillAura = {
    enabled = false,
    range = 5,
    cooldown = 0.1,
    lastAttack = 0,
    targetCooldowns = {} -- Store cooldowns for individual targets
}

local AntiVoid = {
    enabled = false,
    part = nil
}

local HitboxSettings = {
    Size = Vector3.new(2, 2, 2),
    Enabled = false
}

local function hitPlayer(player)
    if not player or not player.Character then return end
    local args = {
        player.Character
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remote Events"):WaitForChild("Punch"):FireServer(unpack(args))
end

local function isInRange(player)
    local localPlayer = Players.LocalPlayer
    if not localPlayer or not localPlayer.Character then return false end
    if not player or not player.Character then return false end
    
    local localRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot or not playerRoot then return false end
    
    local distance = (localRoot.Position - playerRoot.Position).Magnitude
    return distance <= tonumber(KillAura.range)
end

local function updateKillAura()
    if not KillAura.enabled then return end
    
    local currentTime = tick()
    if currentTime - KillAura.lastAttack < tonumber(KillAura.cooldown) then return end
    
    local character = Players.LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Get all players in range
    local targetsInRange = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and isInRange(player) then
            local targetCharacter = player.Character
            if targetCharacter then
                local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    -- Check individual target cooldown
                    local lastTargetHit = KillAura.targetCooldowns[player.UserId] or 0
                    if currentTime - lastTargetHit >= tonumber(KillAura.cooldown) then
                        table.insert(targetsInRange, {
                            player = player,
                            root = targetRoot
                        })
                    end
                end
            end
        end
    end
    
    -- Attack all targets in range without rotating
    for _, target in ipairs(targetsInRange) do
        hitPlayer(target.player)
        KillAura.targetCooldowns[target.player.UserId] = currentTime
        KillAura.lastAttack = currentTime
        
        -- Small delay between multiple targets
        task.wait(0.1)
    end
end

local function modifyHitbox(character)
    if not character or character == Players.LocalPlayer.Character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    humanoidRootPart.Size = HitboxSettings.Size
    humanoidRootPart.Transparency = 0.4
    humanoidRootPart.Color = Color3.fromRGB(255, 0, 0)
    humanoidRootPart.Material = Enum.Material.ForceField
    humanoidRootPart.CanCollide = false
end

local function resetHitbox(character)
    if not character or character == Players.LocalPlayer.Character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    humanoidRootPart.Size = Vector3.new(2, 2, 1)
    humanoidRootPart.Transparency = 1
    humanoidRootPart.Color = Color3.fromRGB(163, 162, 165)
    humanoidRootPart.Material = Enum.Material.SmoothPlastic
    humanoidRootPart.CanCollide = false
end

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

local function findNearestSafePart(position)
    local nearestPart = nil
    local shortestDistance = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.CanCollide and obj.Position.Y > 5 then
            local distance = (obj.Position - position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestPart = obj
            end
        end
    end
    return nearestPart
end

local function createAntiVoidPart()
    if AntiVoid.part then return end
    
    local part = Instance.new("Part")
    part.Name = "AntiVoidPart"
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.5
    part.BrickColor = BrickColor.new("Really blue")
    part.Material = Enum.Material.ForceField
    part.Position = Vector3.new(156, 0, 31)
    part.Size = Vector3.new(10000, 20, 10000)
    
    part.Touched:Connect(function(hit)
        if not AntiVoid.enabled then return end
        local character = Players.LocalPlayer.Character
        if not character or not hit:IsDescendantOf(character) then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        local safePart = findNearestSafePart(humanoidRootPart.Position)
        if not safePart then return end
        
        local safePosition = safePart.Position + Vector3.new(0, safePart.Size.Y/2 + 5, 0)
        humanoidRootPart.CFrame = CFrame.new(safePosition)
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Parent = humanoidRootPart
        game:GetService("Debris"):AddItem(bodyVelocity, 0.1)
    end)
    
    part.Parent = workspace
    AntiVoid.part = part
end

do
    local CombatSection = Tabs.Main:AddSection("Combat")

    CombatSection:AddToggle("KillAuraEnabled", {
        Title = "Kill Aura",
        Default = false,
        Callback = function(Value)
            KillAura.enabled = Value
            if Value then
                RunService:BindToRenderStep("KillAura", Enum.RenderPriority.Character.Value, updateKillAura)
                if NotificationSettings.KillAuraEnabled then
                    Fluent:Notify({
                        Title = "Kill Aura",
                        Content = "Kill Aura has been enabled!",
                        Duration = NotificationSettings.NotificationDuration,
                        Color = Colors.Success
                    })
                end
            else
                RunService:UnbindFromRenderStep("KillAura")
                KillAura.targetCooldowns = {} -- Clear cooldowns
                if NotificationSettings.KillAuraEnabled then
                    Fluent:Notify({
                        Title = "Kill Aura",
                        Content = "Kill Aura has been disabled!",
                        Duration = NotificationSettings.NotificationDuration,
                        Color = Colors.Error
                    })
                end
            end
        end
    })

    CombatSection:AddSlider("KillAuraRange", {
        Title = "Kill Aura Range",
        Default = 5,
        Min = 1,
        Max = 15,
        Rounding = 1,
        Callback = function(Value)
            KillAura.range = tonumber(Value)
        end
    })

    CombatSection:AddSlider("KillAuraCooldown", {
        Title = "Attack Speed",
        Default = 0.1,
        Min = 0.1,
        Max = 1,
        Rounding = 2,
        Callback = function(Value)
            KillAura.cooldown = tonumber(Value)
        end
    })

    local VisualsSection = Tabs.Main:AddSection("Visuals")

    VisualsSection:AddToggle("HitboxEnabled", {
        Title = "Show Enemy Hitboxes",
        Default = false,
        Callback = function(Value)
            HitboxSettings.Enabled = Value
            updateAllHitboxes()
            if NotificationSettings.HitboxEnabled then
                if Value then
                    Fluent:Notify({
                        Title = "Hitboxes",
                        Content = "Enemy hitboxes are now visible!",
                        Duration = NotificationSettings.NotificationDuration,
                        Color = Colors.Success
                    })
                else
                    Fluent:Notify({
                        Title = "Hitboxes",
                        Content = "Enemy hitboxes are now hidden!",
                        Duration = NotificationSettings.NotificationDuration,
                        Color = Colors.Error
                    })
                end
            end
        end
    })

    VisualsSection:AddSlider("HitboxSize", {
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

    local MovementSection = Tabs.Main:AddSection("Movement")

    MovementSection:AddToggle("AntiVoidEnabled", {
        Title = "Anti Void",
        Default = false,
        Callback = function(Value)
            AntiVoid.enabled = Value
            if Value then
                createAntiVoidPart()
                if NotificationSettings.HitboxEnabled then
                    Fluent:Notify({
                        Title = "Anti Void",
                        Content = "Anti Void protection enabled!",
                        Duration = NotificationSettings.NotificationDuration,
                        Color = Colors.Success
                    })
                end
            else
                if AntiVoid.part then
                    AntiVoid.part:Destroy()
                    AntiVoid.part = nil
                end
                if NotificationSettings.HitboxEnabled then
                    Fluent:Notify({
                        Title = "Anti Void",
                        Content = "Anti Void protection disabled!",
                        Duration = NotificationSettings.NotificationDuration,
                        Color = Colors.Error
                    })
                end
            end
        end
    })

    local CustomizationSection = Tabs.Settings:AddSection("Customization")

    CustomizationSection:AddDropdown("Theme", {
        Title = "Theme",
        Description = "Choose your preferred theme",
        Values = {"Light", "Dark", "Darker", "Aqua", "Rose"},
        Default = "Dark",
        Callback = function(Value)
            if Value == "Light" then
                Fluent:ToggleTheme()
            elseif Value == "Dark" then
                Fluent:Theme("Dark")
            elseif Value == "Darker" then
                Fluent:Theme("Darker")
            elseif Value == "Aqua" then
                Fluent:Theme("Aqua")
            elseif Value == "Rose" then
                Fluent:Theme("Rose")
            end
        end
    })

    CustomizationSection:AddDropdown("Color", {
        Title = "Accent Color",
        Description = "Choose your preferred accent color",
        Values = {"Default", "Blue", "Red", "Green", "Purple"},
        Default = "Default",
        Callback = function(Value)
            if Value == "Default" then
                Fluent:SetAccent(Color3.fromRGB(64, 128, 255))
            elseif Value == "Blue" then
                Fluent:SetAccent(Color3.fromRGB(0, 128, 255))
            elseif Value == "Red" then
                Fluent:SetAccent(Color3.fromRGB(255, 64, 64))
            elseif Value == "Green" then
                Fluent:SetAccent(Color3.fromRGB(0, 255, 128))
            elseif Value == "Purple" then
                Fluent:SetAccent(Color3.fromRGB(128, 0, 255))
            end
        end
    })

    CustomizationSection:AddSlider("UITransparency", {
        Title = "UI Transparency",
        Description = "Adjust the transparency of the UI",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            if Window and Window.Frame then
                for _, obj in pairs(Window.Frame:GetDescendants()) do
                    if obj:IsA("Frame") then
                        obj.BackgroundTransparency = Value / 100
                    end
                end
            end
        end
    })

    CustomizationSection:AddSlider("UIScale", {
        Title = "UI Scale",
        Description = "Adjust the size of the UI",
        Default = 100,
        Min = 75,
        Max = 150,
        Rounding = 0,
        Callback = function(Value)
            if Window and Window.Main then
                local newSize = UDim2.fromOffset(580 * (Value/100), 460 * (Value/100))
                Window.Main.Size = newSize
            end
        end
    })

    local NotificationSection = Tabs.Settings:AddSection("Notifications")

    NotificationSection:AddToggle("KillAuraNotifications", {
        Title = "Kill Aura Notifications",
        Description = "Show notifications when Kill Aura is active",
        Default = true,
        Callback = function(Value)
            NotificationSettings.KillAuraEnabled = Value
        end
    })

    NotificationSection:AddToggle("HitboxNotifications", {
        Title = "Hitbox Notifications",
        Description = "Show notifications for hitbox changes",
        Default = true,
        Callback = function(Value)
            NotificationSettings.HitboxEnabled = Value
        end
    })

    NotificationSection:AddSlider("NotificationDuration", {
        Title = "Notification Duration",
        Description = "How long notifications stay on screen (seconds)",
        Default = 3,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Callback = function(Value)
            NotificationSettings.NotificationDuration = Value
        end
    })

    local AdvancedSection = Tabs.Settings:AddSection("Advanced")

    AdvancedSection:AddToggle("AutoReconnect", {
        Title = "Auto Reconnect",
        Description = "Automatically reconnect if disconnected",
        Default = false,
        Callback = function(Value)
            AutoReconnectSettings.Enabled = Value
        end
    })

    AdvancedSection:AddToggle("AutoSave", {
        Title = "Auto Save Config",
        Description = "Automatically save settings when changed",
        Default = true,
        Callback = function(Value)
            if Value then
                SaveManager:Save("auto")
                Fluent:Notify({
                    Title = "Auto Save",
                    Content = "Settings will be saved automatically!",
                    Duration = 3,
                    Color = Colors.Success
                })
            else
                Fluent:Notify({
                    Title = "Auto Save",
                    Content = "Auto save disabled!",
                    Duration = 3,
                    Color = Colors.Warning
                })
            end
        end
    })

    AdvancedSection:AddInput("ConfigName", {
        Title = "Config Name",
        Description = "Name for your config file",
        Default = "default",
        Placeholder = "Enter config name...",
        Callback = function(Value)
            SaveManager.ConfigName = Value
        end
    })

    local SecuritySection = Tabs.Settings:AddSection("Security")

    SecuritySection:AddToggle("SafeMode", {
        Title = "Safe Mode",
        Description = "Enable additional safety measures",
        Default = true,
        Callback = function(Value)
            SafeModeEnabled = Value
        end
    })

    SecuritySection:AddToggle("AntiAFK", {
        Title = "Anti AFK",
        Description = "Prevent being kicked for inactivity",
        Default = false,
        Callback = function(Value)
            if Value then
                local VirtualUser = game:GetService("VirtualUser")
                Players.LocalPlayer.Idled:Connect(function()
                    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    wait(1)
                    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end)
            end
        end
    })

    SecuritySection:AddButton({
        Title = "Clear Logs",
        Description = "Clear all script logs and history",
        Callback = function()
            Window:Dialog({
                Title = "Clear Logs",
                Content = "Are you sure you want to clear all logs?",
                Buttons = {
                    {
                        Title = "Yes",
                        Callback = function()
                            SaveManager:ClearLogs()
                            Fluent:Notify({
                                Title = "Success",
                                Content = "All logs have been cleared!",
                                Duration = 3
                            })
                        end
                    },
                    {
                        Title = "No",
                        Callback = function() end
                    }
                }
            })
        end
    })

    local KeybindsSection = Tabs.Settings:AddSection("Keybinds")

    KeybindsSection:AddKeybind("ToggleUI", {
        Title = "Toggle UI",
        Mode = "Toggle",
        Default = "RightControl",
        Callback = function()
            Window:Minimize()
        end
    })

    KeybindsSection:AddKeybind("ToggleKillAura", {
        Title = "Toggle Kill Aura",
        Mode = "Toggle",
        Default = "K",
        Callback = function(Value)
            KillAura.enabled = Value
            if Value then
                RunService:BindToRenderStep("KillAura", Enum.RenderPriority.Character.Value, updateKillAura)
            else
                RunService:UnbindFromRenderStep("KillAura")
            end
        end
    })

    local PerformanceSection = Tabs.Settings:AddSection("Performance")

    PerformanceSection:AddToggle("ReduceAnimations", {
        Title = "Reduce Animations",
        Description = "Reduces UI animations for better performance",
        Default = false,
        Callback = function(Value)
            Window.ReduceAnimations = Value
        end
    })

    PerformanceSection:AddToggle("DisableParticles", {
        Title = "Disable Particles",
        Description = "Disables particle effects for better performance",
        Default = false,
        Callback = function(Value)
            Window.DisableParticles = Value
        end
    })

    local BackupSection = Tabs.Settings:AddSection("Backup & Restore")

    BackupSection:AddButton({
        Title = "Backup Current Config",
        Description = "Save your current configuration to a file",
        Callback = function()
            SaveManager:Save("backup_" .. os.date("%Y%m%d_%H%M%S"))
            Fluent:Notify({
                Title = "Success",
                Content = "Configuration backed up successfully!",
                Duration = 3
            })
        end
    })

    BackupSection:AddButton({
        Title = "Reset All Settings",
        Description = "Reset all settings to their default values",
        Callback = function()
            Window:Dialog({
                Title = "Reset Settings",
                Content = "Are you sure you want to reset all settings to their default values?",
                Buttons = {
                    {
                        Title = "Yes",
                        Callback = function()
                            SaveManager:Delete("auto.json")
                            Fluent:Notify({
                                Title = "Success",
                                Content = "All settings have been reset to default!",
                                Duration = 3
                            })
                            task.wait(1)
                            Window:Dialog({
                                Title = "Restart Required",
                                Content = "Please re-execute the script to apply default settings.",
                                Buttons = {
                                    {
                                        Title = "Ok",
                                        Callback = function() end
                                    }
                                }
                            })
                        end
                    },
                    {
                        Title = "No",
                        Callback = function() end
                    }
                }
            })
        end
    })
end

Players.PlayerAdded:Connect(function(player)
    if player == Players.LocalPlayer then return end
    player.CharacterAdded:Connect(function(character)
        if HitboxSettings.Enabled then
            task.wait(0.5)
            modifyHitbox(character)
        end
    end)
end)

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

Tabs.Updates:AddParagraph({
    Title = "🎉 Version 1.3.0 [Latest]",
    Content = [[
• 🔄 Added Auto Reconnect with script re-execution
• ⚙️ Added comprehensive Settings system with save/load configs
• 🎨 New UI customization options (themes, colors, transparency)
• 🔐 Added Security features (Anti-AFK, Safe Mode)
• ⚡ Performance optimization settings
• 💾 Added Backup & Restore system
• ⌨️ Customizable keybinds for all features
• 🔔 Enhanced notification system
• 🛡️ Improved safety measures
    ]]
})

Tabs.Updates:AddParagraph({
    Title = "🎉 Version 1.2.0",
    Content = [[
• 🎯 Added Hitbox Customization
• 🛡️ Added Anti-Void protection
• ⚙️ Added basic settings options
• 🎨 UI theme customization
• 💫 Smooth animations and transitions
    ]]
})

Tabs.Updates:AddParagraph({
    Title = "🎉 Version 1.1.0",
    Content = [[
• ⚔️ Added Kill Aura feature
• 🎯 Enemy hitbox visualization system
• ⚡ Real-time hitbox size adjustment
• 🛡️ ForceField material for better visibility
• 🔄 Automatic updates for new players
• 💫 Smooth transitions and effects
    ]]
})

Tabs.Updates:AddParagraph({
    Title = "🎉 Version 1.0.0",
    Content = [[
• 🎮 Initial release
• 📱 Basic UI implementation
• ⚡ Core functionality
• 🔧 Basic settings
    ]]
})

Tabs.Updates:AddParagraph({
    Title = "📝 Upcoming Features",
    Content = [[
• 🎯 Advanced targeting system
• 🌈 Custom hitbox colors and effects
• ⚔️ New combat features
• 🤖 Auto ability system
• 📊 Performance monitoring
• ⚡ More optimization options
    ]]
})

local function checkForUpdates()
    local success, response = pcall(function()
        return game:HttpGet(VersionSystem.PastebinURL, true, {
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })
    end)
    
    if success then
        local latestVersion = string.gsub(response, "^%s*(.-)%s*$", "%1")
        local currentNum = tonumber(string.match(VersionSystem.Current, "%d+%.?%d*"))
        local latestNum = tonumber(string.match(latestVersion, "%d+%.?%d*"))
        
        if latestNum and currentNum then
            if latestNum > currentNum and latestVersion ~= VersionSystem.LastNotified then
                Window:Dialog({
                    Title = "Update Available",
                    Content = [[

New Version Available!

Current: v]] .. VersionSystem.Current .. [[
Latest: v]] .. latestVersion .. [[

Join Discord for latest version.]],
                    Buttons = {
                        {
                            Title = "Ok",
                            Callback = function()
                                Fluent:Notify({
                                    Title = "Update",
                                    Content = "Join Discord for new version!",
                                    Duration = 3
                                })
                            end
                        }
                    }
                })
                VersionSystem.LastNotified = latestVersion
                
                Fluent:Notify({
                    Title = "Update Available",
                    Content = "New version v" .. latestVersion .. " is available!",
                    Duration = 5
                })
            end
        end
    else
        pcall(function()
            local alt = syn and syn.request or http and http.request or http_request or request
            if alt then
                local res = alt({
                    Url = VersionSystem.PastebinURL,
                    Method = "GET",
                    Headers = {
                        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                    }
                })
                if res and res.Body then
                    local latestVersion = string.gsub(res.Body, "^%s*(.-)%s*$", "%1")
                end
            end
        end)
    end
end

local function showWelcomeDialog()
    Window:Dialog({
        Title = "RizzHub",
        Content = [[

Welcome to RizzHub v]] .. VersionSystem.Current .. [[

⚠️ Warning: Use at your own risk 🎮

Created by: Jovs]],
        Buttons = {
            {
                Title = "Start",
                Callback = function()
                    Fluent:Notify({
                        Title = "Ready",
                        Content = "Script loaded successfully!",
                        Duration = 3
                    })
                    task.spawn(function()
                        task.wait(1)
                        checkForUpdates()
                    end)
                end
            }
        }
    })
end

task.spawn(function()
    task.wait(1)
    showWelcomeDialog()
    
    task.spawn(function()
        while task.wait(5) do
            checkForUpdates()
        end
    end)
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("AbilityWarsHelper")
SaveManager:SetFolder("AbilityWarsHelper/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig() 
