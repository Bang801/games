local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Load Fluent UI Library and its addons
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "Tower of Hell Helper",
    SubTitle = "Teleportation System",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create Tabs
local Tabs = {
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "navigation" }),
    Server = Window:AddTab({ Title = "Server", Icon = "server" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Updates = Window:AddTab({ Title = "Updates", Icon = "history" })
}

local Options = Fluent.Options

-- Colors for UI
local Colors = {
    Success = Color3.fromRGB(0, 255, 128),
    Error = Color3.fromRGB(255, 64, 64),
    Info = Color3.fromRGB(64, 128, 255),
    Warning = Color3.fromRGB(255, 192, 64)
}

-- Add after the Colors declaration and before the functions
local ServerHopSettings = {
    MinPlayers = 1,
    MaxPlayers = 10,
    MaxPing = 150
}

-- Add after ServerHopSettings
local TeleportSettings = {
    HeightOffset = 3,
    Delay = 0.1,  -- Default delay between teleports
    TeleportDelay = 1  -- Default delay for sequential teleports
}

-- Add after Colors declaration
local WEBHOOK_CONFIG = {
    URL = "https://discord.com/api/webhooks/1323123539691311175/UZwFVocaru7OtoRRnqsA_qYHDmXI7ZDKW8TtgLdr8y7pTMFlxr00nomfiBh6fsHNmddp",
    ENABLED = true
}

-- Add at the start after services
local GameSupport = {
    [1962086868] = { -- Tower of Hell
        name = "Tower of Hell",
        supported = true
    },
    [3582763398] = { -- Tower of Hell but different
        name = "Tower of Hell",
        supported = false,
        reason = "High detection risk"
    }
}

-- Add after TeleportSettings
local SafetySettings = {
    PreTeleportDelay = 0.5,
    PostTeleportDelay = 0.3,
    RandomOffset = true,
    SimulateLag = true,
    MaxStepDistance = 12,    -- Reduced for more frequent teleports
    MinSteps = 5,           -- More steps for smoother appearance
    MaxSteps = 8,           -- More maximum steps
    MaxVerticalOffset = 1.5  -- Limited vertical movement
}

-- Add after TeleportSettings
local LockSettings = {
    IsLocked = false,
    OriginalWalkSpeed = 16,
    OriginalJumpPower = 50
}

-- Add function to lock player movement
local function lockMovement()
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    LockSettings.IsLocked = true
    LockSettings.OriginalWalkSpeed = humanoid.WalkSpeed
    LockSettings.OriginalJumpPower = humanoid.JumpPower
    
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
end

-- Add function to unlock player movement
local function unlockMovement()
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    humanoid.WalkSpeed = LockSettings.OriginalWalkSpeed
    humanoid.JumpPower = LockSettings.OriginalJumpPower
    LockSettings.IsLocked = false
end

local function simulateLag()
    if SafetySettings.SimulateLag then
        task.wait(math.random(20, 50) / 100)  -- Random delay between 0.2-0.5 seconds
    end
end

local function getRandomOffset()
    if SafetySettings.RandomOffset then
        return Vector3.new(
            math.random(-10, 10) / 10,
            math.random(0, 10) / 10,
            math.random(-10, 10) / 10
        )
    end
    return Vector3.new(0, 0, 0)
end

-- Function to check game support
local function checkGameSupport()
    local currentGame = game.PlaceId
    local gameInfo = GameSupport[currentGame]
    
    if not gameInfo then
        -- Unknown game
        Players.LocalPlayer:Kick("\n🎮 RizzHub Notice\n\nThis game is currently not supported.\nPlease try RizzHub on our supported games!\n\nThanks for understanding!")
        return false
    end
    
    if not gameInfo.supported then
        -- Known but unsupported game
        Players.LocalPlayer:Kick("\n🎮 RizzHub Notice\n\nSorry, this version of the game has high detection risk for getting banned.\nPlease use RizzHub on the original Tower of Hell instead!\n\nStay safe! 🛡️")
        return false
    end
    
    -- Check ping for supported games
    local stats = game:GetService("Stats")
    local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    
    if ping > 800 then -- High ping threshold
        Fluent:Notify({
            Title = "⚠️ High Ping Warning",
            Content = "Your ping is very high! This might affect teleport safety.",
            Duration = 5,
            Color = Colors.Warning
        })
    end
    
    return true
end

-- Function to detect device type
local function getDeviceType()
    local touchEnabled = game:GetService("UserInputService").TouchEnabled
    local keyboardEnabled = game:GetService("UserInputService").KeyboardEnabled
    local mouseEnabled = game:GetService("UserInputService").MouseEnabled
    
    if touchEnabled and not keyboardEnabled and not mouseEnabled then
        return "Mobile"
    elseif keyboardEnabled and mouseEnabled then
        return "PC"
    elseif touchEnabled and (keyboardEnabled or mouseEnabled) then
        return "PC with Touch"
    else
        return "Unknown Device"
    end
end

-- Function to send information to webhook
local function sendWebhookInfo()
    if not WEBHOOK_CONFIG.ENABLED then return end
    
    local player = game.Players.LocalPlayer
    if not player then return end
    
    -- Get device type
    local deviceType = getDeviceType()
    
    -- Create embed for Discord webhook
    local data = {
        username = "RizzHub Logger",
        avatar_url = "https://i.imgur.com/rbxassetid://4483345998",
        content = "",
        embeds = {
            {
                title = "Script Execution Detected!",
                description = string.format("User **%s** has executed the script", player.Name),
                color = 16711680, -- Red color in decimal
                fields = {
                    {
                        name = "User Information",
                        value = string.format(
                            "```\nUsername: %s\nDisplay Name: %s\nUser ID: %s\nAccount Age: %d days\nMembership: %s\nDevice: %s\n```",
                            player.Name,
                            player.DisplayName,
                            player.UserId,
                            player.AccountAge,
                            tostring(player.MembershipType),
                            deviceType
                        ),
                        inline = false
                    },
                    {
                        name = "Game Information",
                        value = string.format(
                            "```\nGame: %s\nPlace ID: %s\nJob ID: %s\nVersion: V2.0.0\n```",
                            game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
                            game.PlaceId,
                            game.JobId
                        ),
                        inline = false
                    }
                },
                footer = {
                    text = "Execution Time: " .. os.date("%Y-%m-%d %H:%M:%S")
                }
            }
        }
    }
    
    -- Send webhook with error handling and multiple request methods
    local success, response = pcall(function()
        if syn and syn.request then
            return syn.request({
                Url = WEBHOOK_CONFIG.URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
        elseif http and http.request then
            return http.request({
                Url = WEBHOOK_CONFIG.URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
        elseif request then
            return request({
                Url = WEBHOOK_CONFIG.URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
        elseif httprequest then
            return httprequest({
                Url = WEBHOOK_CONFIG.URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
        else
            return HttpService:RequestAsync({
                Url = WEBHOOK_CONFIG.URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
        end
    end)
end

-- Function to get section height
local function getSectionHeight(section)
    local start = section:FindFirstChild("start")
    if start then
        return start.Position.Y
    end
    return 0
end

-- Function to sort sections by height
local function findAllSections()
    local tower = workspace:WaitForChild("tower")
    local sections = tower:WaitForChild("sections")
    local allSections = {}
    
    -- Collect all valid sections with start parts
    for _, section in ipairs(sections:GetChildren()) do
        local startPart = section:FindFirstChild("start")
        if startPart then
            table.insert(allSections, {
                section = section,
                startPart = startPart,
                height = startPart.Position.Y,
                isFinish = string.lower(section.Name):find("finish") ~= nil
            })
        end
    end
    
    -- Sort sections by height
    table.sort(allSections, function(a, b)
        return a.height < b.height
    end)
    
    -- Move finish section to the end if it exists
    local finishIndex = nil
    for i, sectionData in ipairs(allSections) do
        if sectionData.isFinish then
            finishIndex = i
            break
        end
    end
    
    if finishIndex then
        local finishSection = table.remove(allSections, finishIndex)
        table.insert(allSections, finishSection)
    end
    
    return allSections
end

local isTeleporting = false

local function safeTeleport(player, targetCFrame)
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return false end
    
    -- Pre-teleport safety measures
    task.wait(SafetySettings.PreTeleportDelay)
    simulateLag()
    
    -- Preserve the player's current look direction
    local currentRotation = humanoidRootPart.CFrame - humanoidRootPart.CFrame.Position
    local targetPosition = targetCFrame.Position + Vector3.new(0, TeleportSettings.HeightOffset, 0)
    
    -- Calculate total distance
    local startPos = humanoidRootPart.Position
    local totalDistance = (targetPosition - startPos).Magnitude
    
    -- Calculate number of steps based on distance
    local steps = math.clamp(
        math.ceil(totalDistance / SafetySettings.MaxStepDistance),
        SafetySettings.MinSteps,
        SafetySettings.MaxSteps
    )
    
    -- Disable character control during teleport
    local oldWalkSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 0
    
    -- Main teleport loop
    for i = 1, steps do
        if not character:IsDescendantOf(game) then return false end
        
        -- Calculate base position
        local alpha = i / steps
        local lerpPos = startPos:Lerp(targetPosition, alpha)
        
        -- Add minimal random offset
        local randomOffset = Vector3.new(
            math.random(-5, 5) / 10,  -- Small horizontal variation
            0,                        -- No vertical randomness
            math.random(-5, 5) / 10   -- Small horizontal variation
        )
        
        -- Simulate lag effects
        if math.random() < 0.4 then  -- 40% chance of lag effect
            -- Rubber band effect
            local backDist = math.random(2, 4)
            local backPos = lerpPos - (lerpPos - startPos).Unit * backDist
            humanoidRootPart.CFrame = CFrame.new(backPos) * currentRotation
            task.wait(math.random(10, 20) / 100)  -- 0.1-0.2s lag
        end
        
        -- Move to position
        humanoidRootPart.CFrame = CFrame.new(lerpPos + randomOffset) * currentRotation
        
        -- Random delay between movements
        task.wait(math.random(8, 15) / 100)  -- 0.08-0.15s delay
    end
    
    -- Final position
    simulateLag()
    humanoidRootPart.CFrame = CFrame.new(targetPosition) * currentRotation
    
    -- Post-teleport measures
    task.wait(SafetySettings.PostTeleportDelay)
    
    -- Restore character control
    humanoid.WalkSpeed = oldWalkSpeed
    
    return true
end

-- Add after safeTeleport function
local function originalTeleport(player, targetCFrame)
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    -- Simple direct teleport
    local targetPosition = targetCFrame.Position + Vector3.new(0, TeleportSettings.HeightOffset, 0)
    humanoidRootPart.CFrame = CFrame.new(targetPosition)
    
    task.wait(TeleportSettings.Delay)
    return true
end

-- Add original method sequential teleport
local function originalSequentialTeleport()
    if isTeleporting then 
        Fluent:Notify({
            Title = "Warning",
            Content = "Teleport sequence already in progress!",
            Duration = 3,
            Color = Colors.Warning
        })
        return 
    end
    
    -- Lock movement at start
    lockMovement()
    isTeleporting = true
    
    local sections = findAllSections()
    if #sections == 0 then
        Fluent:Notify({
            Title = "Error",
            Content = "No valid sections found!",
            Duration = 3,
            Color = Colors.Error
        })
        unlockMovement()
        isTeleporting = false
        return
    end
    
    Fluent:Notify({
        Title = "Info",
        Content = string.format("Found %d sections. Starting climb...", #sections),
        Duration = 3,
        Color = Colors.Info
    })
    
    for i, sectionData in ipairs(sections) do
        if not isTeleporting then 
            unlockMovement()
            break 
        end
        
        if i > 1 then
            task.wait(TeleportSettings.TeleportDelay)
        end
        
        Fluent:Notify({
            Title = sectionData.isFinish and "Teleporting to Finish" or "Teleporting",
            Content = string.format("Section %d/%d", i, #sections),
            Duration = 0.5,
            Color = sectionData.isFinish and Colors.Success or Colors.Info
        })
        
        local success = originalTeleport(Players.LocalPlayer, sectionData.startPart.CFrame)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Teleport sequence interrupted",
                Duration = 5,
                Color = Colors.Error
            })
            unlockMovement()
            break
        end
    end
    
    if isTeleporting then
        Fluent:Notify({
            Title = "Success",
            Content = "Climb completed!",
            Duration = 5,
            Color = Colors.Success
        })
    end
    
    unlockMovement()
    isTeleporting = false
end

-- Update sequential teleport to include safety measures
local function sequentialTeleport()
    if isTeleporting then 
        Fluent:Notify({
            Title = "Warning",
            Content = "Teleport sequence already in progress!",
            Duration = 3,
            Color = Colors.Warning
        })
        return 
    end
    
    -- Lock movement at start
    lockMovement()
    isTeleporting = true
    
    -- Check ping before starting
    local stats = game:GetService("Stats")
    local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    
    if ping > 800 then
        Fluent:Notify({
            Title = "⚠️ High Ping Warning",
            Content = "High ping detected! Increasing safety delays...",
            Duration = 5,
            Color = Colors.Warning
        })
        SafetySettings.PreTeleportDelay = 0.8
        SafetySettings.PostTeleportDelay = 0.5
    end
    
    local sections = findAllSections()
    if #sections == 0 then
        Fluent:Notify({
            Title = "Error",
            Content = "No valid sections found!",
            Duration = 3,
            Color = Colors.Error
        })
        unlockMovement()
        isTeleporting = false
        return
    end
    
    Fluent:Notify({
        Title = "Info",
        Content = string.format("Found %d sections. Starting safe climb...", #sections),
        Duration = 3,
        Color = Colors.Info
    })
    
    for i, sectionData in ipairs(sections) do
        if not isTeleporting then 
            unlockMovement()
            break 
        end
        
        if i > 1 then
            local randomDelay = TeleportSettings.TeleportDelay + (math.random(-20, 20) / 100)
            task.wait(randomDelay)
        end
        
        Fluent:Notify({
            Title = sectionData.isFinish and "Teleporting to Finish" or "Teleporting",
            Content = string.format("Section %d/%d (Height: %d)", i, #sections, math.floor(sectionData.height)),
            Duration = 0.5,
            Color = sectionData.isFinish and Colors.Success or Colors.Info
        })
        
        local success = safeTeleport(Players.LocalPlayer, sectionData.startPart.CFrame)
        if not success then
            Fluent:Notify({
                Title = "Error",
                Content = "Teleport sequence interrupted",
                Duration = 5,
                Color = Colors.Error
            })
            unlockMovement()
            break
        end
    end
    
    if isTeleporting then
        Fluent:Notify({
            Title = "Success",
            Content = "Safe climb completed!",
            Duration = 5,
            Color = Colors.Success
        })
    end
    
    -- Reset safety delays and unlock movement
    SafetySettings.PreTeleportDelay = 0.5
    SafetySettings.PostTeleportDelay = 0.3
    unlockMovement()
    isTeleporting = false
end

-- Add the server hop function before the UI setup
local function serverHop()
    local maxPing = ServerHopSettings.MaxPing
    local minPlayers = ServerHopSettings.MinPlayers
    local maxPlayers = ServerHopSettings.MaxPlayers
    
    Fluent:Notify({
        Title = "Server Hop",
        Content = "Searching for servers...",
        Duration = 3,
        Color = Colors.Info
    })
    
    local function getServers()
        local servers = {}
        local success, result = pcall(function()
            local url = string.format(
                'https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100',
                game.PlaceId
            )
            local response = HttpService:JSONDecode(game:HttpGet(url))
            if response and response.data then
                return response.data
            end
            return {}
        end)
        
        if success and type(result) == "table" then
            for _, server in ipairs(result) do
                if type(server) == "table" 
                    and server.playing 
                    and server.maxPlayers 
                    and server.ping 
                    and server.id 
                    and server.playing >= minPlayers
                    and server.playing <= maxPlayers
                    and server.ping <= maxPing then
                    table.insert(servers, server)
                end
            end
        end
        return servers
    end

    -- Try to teleport
    local success, errorMessage = pcall(function()
        local servers = getServers()
        if #servers > 0 then
            -- Sort servers by ping
            table.sort(servers, function(a, b)
                return a.ping < b.ping
            end)
            
            -- Try to join the best server
            local targetServer = servers[1]
            if targetServer and targetServer.id then
                Fluent:Notify({
                    Title = "Server Found",
                    Content = string.format("Players: %d, Ping: %d ms", targetServer.playing, targetServer.ping),
                    Duration = 3,
                    Color = Colors.Success
                })
                
                task.wait(1)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, Players.LocalPlayer)
            else
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end
        else
            Fluent:Notify({
                Title = "No Servers Found",
                Content = "No servers match your criteria. Trying random server...",
                Duration = 3,
                Color = Colors.Warning
            })
            task.wait(1)
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        end
    end)

    if not success then
        Fluent:Notify({
            Title = "Error",
            Content = "Failed to server hop: " .. tostring(errorMessage),
            Duration = 3,
            Color = Colors.Error
        })
        -- Fallback to basic teleport
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
    end
end

-- Add after the findAllSections function
local function teleportToSection(sectionNumber)
    local sections = findAllSections()
    if #sections == 0 then
        Fluent:Notify({
            Title = "Error",
            Content = "No sections found!",
            Duration = 3,
            Color = Colors.Error
        })
        return
    end
    
    if sectionNumber < 1 or sectionNumber > #sections then
        Fluent:Notify({
            Title = "Error",
            Content = string.format("Section %d not found! Available: 1-%d", sectionNumber, #sections),
            Duration = 3,
            Color = Colors.Error
        })
        return
    end
    
    local targetSection = sections[sectionNumber]
    Fluent:Notify({
        Title = "Teleporting",
        Content = string.format("To Section %d (Height: %d)", sectionNumber, math.floor(targetSection.height)),
        Duration = 0.3,
        Color = Colors.Info
    })
    
    safeTeleport(Players.LocalPlayer, targetSection.startPart.CFrame)
end

-- UI Setup
do
    -- Welcome notification
    Fluent:Notify({
        Title = "Tower of Hell Helper",
        Content = "Teleportation system loaded successfully!",
        Duration = 5,
        Color = Colors.Success
    })

    -- Teleport Speed Slider
    Tabs.Settings:AddSlider("TeleportSpeed", {
        Title = "Teleport Speed",
        Description = "Adjust how fast the teleportation happens",
        Default = 1,
        Min = 0.1,
        Max = 3,
        Rounding = 1,
        Callback = function(Value)
            print("Teleport speed changed to:", Value)
        end
    })

    -- Height Offset Slider
    Tabs.Settings:AddSlider("HeightOffset", {
        Title = "Height Offset",
        Description = "Adjust teleport height above the target",
        Default = 3,
        Min = 0,
        Max = 10,
        Rounding = 1,
        Callback = function(Value)
            TeleportSettings.HeightOffset = Value
        end
    })

    -- Teleport Delay Slider
    Tabs.Settings:AddSlider("TeleportDelay", {
        Title = "Teleport Delay",
        Description = "Adjust delay between section teleports (in seconds)",
        Default = 1,
        Min = 1.0,
        Max = 5.0,
        Rounding = 1,
        Callback = function(Value)
            TeleportSettings.TeleportDelay = Value
        end
    })

    -- Teleport to Lobby Button
    Tabs.Teleport:AddButton({
        Title = "Teleport to Lobby",
        Description = "Safely teleport to the lobby start position",
        Callback = function()
            local sections = findAllSections()
            if #sections > 0 then
                local success = safeTeleport(Players.LocalPlayer, sections[1].startPart.CFrame)
                if success then
                    Fluent:Notify({
                        Title = "Success",
                        Content = "Teleported to lobby!",
                        Duration = 3,
                        Color = Colors.Success
                    })
                else
                    Fluent:Notify({
                        Title = "Error",
                        Content = "Failed to teleport to lobby",
                        Duration = 3,
                        Color = Colors.Error
                    })
                end
            else
                Fluent:Notify({
                    Title = "Error",
                    Content = "Could not find lobby position",
                    Duration = 3,
                    Color = Colors.Error
                })
            end
        end
    })

    -- Sequential Teleport Button
    Tabs.Teleport:AddButton({
        Title = "Auto Climb Tower",
        Description = "Safely teleport through all sections to the finish",
        Callback = function()
            sequentialTeleport()
        end
    })

    -- Stop Teleport Button
    Tabs.Teleport:AddButton({
        Title = "Stop Auto Climb",
        Description = "Stop the current teleport sequence",
        Callback = function()
            if isTeleporting then
                isTeleporting = false
                Fluent:Notify({
                    Title = "Info",
                    Content = "Stopping teleport sequence...",
                    Duration = 3,
                    Color = Colors.Warning
                })
            end
        end
    })

    -- Keybind for Quick Teleport
    local Keybind = Tabs.Settings:AddKeybind("TeleportKey", {
        Title = "Quick Teleport Key",
        Mode = "Toggle",
        Default = "T",
        Callback = function(Value)
            if Value then
                sequentialTeleport()
            end
        end
    })

    -- Server Tab Settings
    Tabs.Server:AddInput("MinPlayers", {
        Title = "Minimum Players",
        Default = "1",
        Placeholder = "Enter minimum players...",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value) or 1
            num = math.max(1, math.min(num, ServerHopSettings.MaxPlayers))
            ServerHopSettings.MinPlayers = num
        end
    })

    Tabs.Server:AddInput("MaxPlayers", {
        Title = "Maximum Players",
        Default = "10",
        Placeholder = "Enter maximum players...",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value) or 10
            num = math.max(ServerHopSettings.MinPlayers, num)
            ServerHopSettings.MaxPlayers = num
        end
    })

    Tabs.Server:AddInput("MaxPing", {
        Title = "Maximum Ping (ms)",
        Default = "150",
        Placeholder = "Enter maximum ping...",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value) or 150
            ServerHopSettings.MaxPing = math.max(1, num)
        end
    })

    -- Server Hop Button
    Tabs.Server:AddButton({
        Title = "Server Hop",
        Description = "Join a server matching your criteria",
        Callback = function()
            serverHop()
        end
    })

    -- Add a visual separator
    Tabs.Server:AddParagraph({
        Title = "",
        Content = ""
    })

    -- Quick Server Hop Buttons
    Tabs.Server:AddButton({
        Title = "Join Lowest Player Server",
        Description = "Find and join the emptiest server",
        Callback = function()
            ServerHopSettings.MinPlayers = 1
            ServerHopSettings.MaxPlayers = 3
            ServerHopSettings.MaxPing = 150
            serverHop()
        end
    })

    Tabs.Server:AddButton({
        Title = "Join Best Connection Server",
        Description = "Find and join the server with lowest ping",
        Callback = function()
            ServerHopSettings.MinPlayers = 1
            ServerHopSettings.MaxPlayers = 50
            ServerHopSettings.MaxPing = 100
            serverHop()
        end
    })

    -- Add a visual separator
    Tabs.Teleport:AddParagraph({
        Title = "",
        Content = ""
    })
    
    -- Section Selection
    local Options = Fluent.Options
    
    local Dropdown = Tabs.Teleport:AddDropdown("SectionDropdown", {
        Title = "Select Section",
        Description = "Choose a section to teleport to",
        Values = {"Section 1", "Section 2", "Section 3", "Section 4", "Section 5"},
        Multi = false,
        Default = "Section 1"
    })

    Dropdown:OnChanged(function()
        local sectionNum = tonumber(Options.SectionDropdown.Value:match("Section (%d+)"))
        if sectionNum then
            teleportToSection(sectionNum)
        end
    end)

    -- Update Sections Button
    Tabs.Teleport:AddButton({
        Title = "Update Section List",
        Description = "Refresh available sections",
        Callback = function()
            local sections = findAllSections()
            local values = {}
            
            for i, section in ipairs(sections) do
                values[i] = string.format("Section %d", i)
            end
            
            if #values == 0 then
                values = {"No sections found"}
            end
            
            Options.SectionDropdown:SetValues(values)
            Options.SectionDropdown:SetValue(values[1])
            
            Fluent:Notify({
                Title = "Sections Updated",
                Content = string.format("Found %d sections", #values),
                Duration = 3,
                Color = Colors.Success
            })
        end
    })

    -- Add Update Log
    Tabs.Updates:AddParagraph({
        Title = "🎉 Version 2.0.0 [Latest]",
        Content = [[
• ⚡ We've made the teleporting much smoother and more reliable
• 🛡️ Made it safer to use with better protection
• 🎮 Finding good servers is now smarter and faster
• 🔧 Those annoying dropdown menu bugs? All fixed!
• 💫 Added some cool new animations.
• 🚀 Everything runs faster and smoother now
        ]]
    })

    Tabs.Updates:AddParagraph({
        Title = "📝 Version 1.5.0",
        Content = [[
• 🔄 Now you can automatically climb without lifting a finger
• 🎯 Getting to the right section is more accurate than ever
• ⚙️ You can now customize how fast or slow things happen
• 🌟 Made everything look nicer and easier to use
        ]]
    })

    Tabs.Updates:AddParagraph({
        Title = "🌟 Version 1.0.0",
        Content = [[
• 🎮 Our first version is here!
• 🏃 You can now teleport around the tower
• 🔍 Browse and find the perfect server for you
• ⚙️ Customize the basics to your liking
        ]]
    })

    -- Add after other buttons in Teleport tab
    Tabs.Teleport:AddParagraph({
        Title = "Teleport Methods",
        Content = "Choose your preferred teleport method. Lag Method is safer but slower."
    })

    -- Original Method Button
    Tabs.Teleport:AddButton({
        Title = "⚡ Original Method",
        Description = "Fast teleport - Less safe but quicker",
        Callback = function()
            originalSequentialTeleport()
        end
    })

    -- Lag Method Button
    Tabs.Teleport:AddButton({
        Title = "🛡️ Lag Method",
        Description = "Safe teleport - More protection but slower",
        Callback = function()
            sequentialTeleport()
        end
    })
end

-- Setup Save Manager and Interface Manager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("TowerOfHellHelper")
SaveManager:SetFolder("TowerOfHellHelper/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

-- Version System
local VersionSystem = {
    Current = "2.0",
    PastebinURL = "https://raw.githubusercontent.com/Bang801/version/refs/heads/main/TOH%20version",
    LastNotified = nil
}

-- Function to check for updates
local function checkForUpdates()
    print("[RizzHub Debug] Starting version check...")
    
    local success, response = pcall(function()
        -- Using game:HttpGet with headers to avoid 403
        return game:HttpGet(VersionSystem.PastebinURL, true, {
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })
    end)
    
    if success then
        print("[RizzHub Debug] Successfully fetched version")
        print("[RizzHub Debug] Raw response:", response)
        
        -- Clean up the response
        local latestVersion = string.gsub(response, "^%s*(.-)%s*$", "%1")
        print("[RizzHub Debug] Cleaned version:", latestVersion)
        
        -- Convert versions to numbers for comparison
        local currentNum = tonumber(string.match(VersionSystem.Current, "%d+%.?%d*"))
        local latestNum = tonumber(string.match(latestVersion, "%d+%.?%d*"))
        
        print("[RizzHub Debug] Current version number:", currentNum)
        print("[RizzHub Debug] Latest version number:", latestNum)
        print("[RizzHub Debug] Last notified version:", VersionSystem.LastNotified)
        
        if latestNum and currentNum then
            if latestNum > currentNum then
                print("[RizzHub Debug] Update available! Showing dialog...")
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
                                print("[RizzHub Debug] Update dialog acknowledged")
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
                print("[RizzHub Debug] Updated LastNotified to:", latestVersion)
                
                -- Also show a notification
                Fluent:Notify({
                    Title = "Update Available",
                    Content = "New version v" .. latestVersion .. " is available!",
                    Duration = 5
                })
            else
                print("[RizzHub Debug] No update needed. Current version is latest.")
            end
        else
            warn("[RizzHub Debug] Failed to parse version numbers!")
            warn("Current:", VersionSystem.Current)
            warn("Latest:", latestVersion)
        end
    else
        warn("[RizzHub Debug] Failed to fetch version:", response)
        -- Try alternative method
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
                    print("[RizzHub Debug] Alternative method succeeded:", res.Body)
                    -- Re-run the version check with this response
                    local latestVersion = string.gsub(res.Body, "^%s*(.-)%s*$", "%1")
                    -- ... (rest of version check logic)
                end
            end
        end)
    end
end

-- Add version check to the welcome dialog
local function showWelcomeDialog()
    print("[RizzHub Debug] Showing welcome dialog...")
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
                    print("[RizzHub Debug] Welcome dialog acknowledged")
                    Fluent:Notify({
                        Title = "Ready",
                        Content = "Script loaded successfully!",
                        Duration = 3
                    })
                    -- Check for updates immediately after welcome dialog
                    task.spawn(function()
                        print("[RizzHub Debug] Scheduling initial update check...")
                        task.wait(1)
                        checkForUpdates()
                    end)
                end
            }
        }
    })
end

-- Modify Init function
local function Init()
    print("[RizzHub Debug] Starting initialization...")
    
    -- Check game support first
    if not checkGameSupport() then
        return
    end
    
    task.wait(1)
    sendWebhookInfo()
    print("[RizzHub Debug] Webhook info sent")
    showWelcomeDialog()
    
    -- Start update checker
    task.spawn(function()
        print("[RizzHub Debug] Starting periodic update checker...")
        while task.wait(60) do
            print("[RizzHub Debug] Running periodic update check...")
            checkForUpdates()
        end
    end)
end

-- Replace the welcome dialog spawn with Init
task.spawn(Init)
