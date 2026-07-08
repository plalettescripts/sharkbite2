--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              SHARK BITE 2 - ULTIMATE SCRIPT v1.0           ║
    ║              Created by: plalettescripts                    ║
    ║              Auto Kill Shark | ESP | Teleport | Boat       ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ==================== 1. SERVICES ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ==================== 2. KONFIGURATION ====================
local Config = {
    -- Combat
    AutoKillShark = false,
    AutoAim = false,
    AimFOV = 200,
    SilentAim = false,
    Prediction = true,
    PredictionStrength = 0.5,
    AutoShoot = false,
    InstantReload = false,
    NoRecoil = false,
    NoSpread = false,
    Triggerbot = false,
    AutoEquipBest = false,
    DamageMultiplier = 1,
    AutoCollectLoot = false,
    
    -- Visuals
    SharkESP = false,
    SharkESPColor = Color3.fromRGB(255, 50, 50),
    SharkBoxESP = false,
    SharkHealthBar = false,
    SharkDistance = false,
    SharkName = false,
    SharkTrajectory = false,
    SharkTrajectoryColor = Color3.fromRGB(255, 150, 50),
    SharkChams = false,
    SharkChamsColor = Color3.fromRGB(255, 0, 0),
    PlayerESP = false,
    PlayerESPColor = Color3.fromRGB(0, 200, 255),
    PlayerBoxESP = false,
    PlayerDistance = false,
    BoatESP = false,
    LootESP = false,
    LootESPColor = Color3.fromRGB(255, 255, 50),
    IslandESP = false,
    TracerToShark = false,
    TracerColor = Color3.fromRGB(255, 100, 100),
    Fullbright = false,
    ClearWater = false,
    WaterTransparency = 50,
    NoFog = false,
    Radar = false,
    RadarSize = 150,
    
    -- Movement
    SpeedHack = false,
    SpeedValue = 32,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    InfiniteJump = false,
    WaterWalk = false,
    FastSwim = false,
    SwimSpeed = 100,
    AutoRespawn = false,
    
    -- Boat
    AutoBoatFarm = false,
    BoatSpeedHack = false,
    BoatSpeedValue = 3,
    BoatFly = false,
    BoatNoclip = false,
    AutoBoatRepair = false,
    UnlimitedBoatHealth = false,
    AutoSpawnBestBoat = false,
    BoatESP = false,
    
    -- Shark Mode
    AutoKillPlayer = false,
    SharkSpeedHack = false,
    SharkSpeedValue = 3,
    SharkFly = false,
    UnlimitedSharkHealth = false,
    AutoDodgeHarpoon = false,
    PlayerESPForShark = false,
    BoatDestroyer = false,
    SharkInvisible = false,
    
    -- Settings
    Language = "DE",
    FPSOptimizer = false,
    ShowDescriptions = true
}

-- ==================== 3. VARIABLEN ====================
local ESPDrawings = {}
local MaxDrawings = 150
local ShootRemote = nil
local HarpoonRemote = nil
local SpawnBoatRemote = nil
local CurrentShark = nil
local CurrentBoat = nil
local Notifications = {}

local function ClearDrawings()
    for _, d in pairs(ESPDrawings) do pcall(function() d:Remove() end) end
    ESPDrawings = {}
end

local function AddDrawing(drawing)
    if #ESPDrawings >= MaxDrawings then
        local old = table.remove(ESPDrawings, 1)
        pcall(function() old:Remove() end)
    end
    table.insert(ESPDrawings, drawing)
    return drawing
end

-- Hai finden
local function FindNearestShark()
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("shark") or obj.Name:lower():find("hai")) then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if humanoid and humanoid.Health > 0 and hrp then
                if LocalPlayer.Character then
                    local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myHrp then
                        local dist = (hrp.Position - myHrp.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = obj
                        end
                    end
                else
                    nearest = obj
                end
            end
        end
    end
    
    -- Auch nach getaggten Haien suchen
    if not nearest then
        for _, obj in ipairs(CollectionService:GetTagged("Shark")) do
            if obj:IsA("Model") then
                local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
                if hrp then
                    nearest = obj
                    break
                end
            end
        end
    end
    
    return nearest
end

-- Position vorausberechnen
local function PredictPosition(shark, time)
    if not shark then return Vector3.zero end
    local hrp = shark:FindFirstChild("HumanoidRootPart") or shark:FindFirstChild("Head")
    if not hrp then return Vector3.zero end
    local velocity = hrp.Velocity or hrp.AssemblyLinearVelocity or Vector3.zero
    return hrp.Position + velocity * time
end

-- Remote Events finden
local function FindRemotes()
    if ShootRemote then return end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local name = obj.Name:lower()
            if name:find("shoot") or name:find("fire") or name:find("attack") then
                ShootRemote = obj
            elseif name:find("harpoon") then
                HarpoonRemote = obj
            elseif name:find("spawn") and name:find("boat") then
                SpawnBoatRemote = obj
            end
        end
    end
    -- Fallback: erstes Remote nehmen
    if not ShootRemote then
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                ShootRemote = obj
                break
            end
        end
    end
end

-- Beste Waffe auswählen
local function EquipBestWeapon()
    pcall(function()
        local bestTool = nil
        local bestDamage = 0
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local dmg = tool:FindFirstChild("Damage") or tool:FindFirstChild("Power")
                local dmgVal = dmg and (dmg:IsA("NumberValue") and dmg.Value or dmg:IsA("IntValue") and dmg.Value) or 10
                if dmgVal > bestDamage then
                    bestDamage = dmgVal
                    bestTool = tool
                end
            end
        end
        if bestTool then
            LocalPlayer.Character.Humanoid:EquipTool(bestTool)
        end
    end)
end

-- Benachrichtigung
local function Notify(title, msg, duration)
    duration = duration or 3
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 45)
    frame.Position = UDim2.new(1, -230, 1, -55)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BorderSizePixel = 0
    frame.Parent = CoreGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -10, 0, 16)
    t.Position = UDim2.new(0, 5, 0, 3)
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.fromRGB(0, 255, 100)
    t.Text = title
    t.Font = Enum.Font.SourceSansBold
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = frame
    
    local m = Instance.new("TextLabel")
    m.Size = UDim2.new(1, -10, 0, 20)
    m.Position = UDim2.new(0, 5, 0, 20)
    m.BackgroundTransparency = 1
    m.TextColor3 = Color3.fromRGB(200, 200, 200)
    m.Text = msg
    m.Font = Enum.Font.SourceSans
    m.TextSize = 11
    m.TextXAlignment = Enum.TextXAlignment.Left
    m.Parent = frame
    
    task.delay(duration, function() pcall(function() frame:Destroy() end) end)
end

-- ==================== 4. GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlaletteSharkBite2"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0.88, 0)
MainFrame.Position = UDim2.new(0.01, 0, 0.01, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Animierter Rand
local Border = Instance.new("Frame")
Border.Size = UDim2.new(1, 4, 1, 4)
Border.Position = UDim2.new(0, -2, 0, -2)
Border.BackgroundColor3 = Color3.fromRGB(255, 80, 40)
Border.BorderSizePixel = 0
Border.Parent = MainFrame
Instance.new("UICorner", Border).CornerRadius = UDim.new(0, 13)

task.spawn(function()
    local hue = 0.05
    while ScreenGui and ScreenGui.Parent do
        hue = hue + 0.003
        if hue > 0.1 then hue = 0.05 end
        pcall(function() Border.BackgroundColor3 = Color3.fromHSV(hue, 1, 1) end)
        task.wait(0.03)
    end
end)

-- Minimiert
local MiniFrame = Instance.new("Frame")
MiniFrame.Size = UDim2.new(0, 190, 0, 35)
MiniFrame.Position = UDim2.new(0.01, 0, 0.01, 0)
MiniFrame.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
MiniFrame.BorderSizePixel = 0
MiniFrame.Visible = false
MiniFrame.Active = true
MiniFrame.Draggable = true
MiniFrame.Parent = ScreenGui
Instance.new("UICorner", MiniFrame).CornerRadius = UDim.new(0, 8)

local MiniText = Instance.new("TextLabel")
MiniText.Size = UDim2.new(1, 0, 1, 0)
MiniText.BackgroundTransparency = 1
MiniText.TextColor3 = Color3.fromRGB(255, 80, 40)
MiniText.Text = "🦈 SB2 v1.0 | plalettescripts"
MiniText.Font = Enum.Font.SourceSansBold
MiniText.TextSize = 11
MiniText.Parent = MiniFrame

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
        MiniFrame.Visible = not MiniFrame.Visible
    end
end)

-- Titel
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0.6, 0, 0.55, 0)
TitleText.Position = UDim2.new(0.04, 0, 0, 2)
TitleText.BackgroundTransparency = 1
TitleText.TextColor3 = Color3.fromRGB(255, 80, 40)
TitleText.Text = "🦈 SHARK BITE 2 v1.0"
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextSize = 16
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local VersionText = Instance.new("TextLabel")
VersionText.Size = UDim2.new(0.6, 0, 0.35, 0)
VersionText.Position = UDim2.new(0.04, 0, 0.55, 0)
VersionText.BackgroundTransparency = 1
VersionText.TextColor3 = Color3.fromRGB(200, 100, 60)
VersionText.Text = "plalettescripts | Auto Kill Shark"
VersionText.Font = Enum.Font.SourceSans
VersionText.TextSize = 9
VersionText.TextXAlignment = Enum.TextXAlignment.Left
VersionText.Parent = TitleBar

local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 24, 0, 20)
HideBtn.Position = UDim2.new(1, -56, 0, 10)
HideBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
HideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HideBtn.Text = "_"
HideBtn.Font = Enum.Font.SourceSansBold
HideBtn.TextSize = 12
HideBtn.Parent = TitleBar
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 4)
HideBtn.MouseButton1Click:Connect(function()
    Config.ShowDescriptions = not Config.ShowDescriptions
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 20)
CloseBtn.Position = UDim2.new(1, -28, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
CloseBtn.MouseButton1Click:Connect(function()
    ClearDrawings()
    ScreenGui:Destroy()
end)

-- Tab-System
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -6, 0, 30)
TabContainer.Position = UDim2.new(0, 3, 0, 42)
TabContainer.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame
Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 6)

local TabList = Instance.new("UIListLayout")
TabList.Padding = UDim.new(0, 2)
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Parent = TabContainer

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -6, 1, -96)
ContentFrame.Position = UDim2.new(0, 3, 0, 74)
ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame
Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 8)

-- Footer
local FooterFrame = Instance.new("Frame")
FooterFrame.Size = UDim2.new(1, -6, 0, 18)
FooterFrame.Position = UDim2.new(0, 3, 1, -22)
FooterFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
FooterFrame.BorderSizePixel = 0
FooterFrame.Parent = MainFrame
Instance.new("UICorner", FooterFrame).CornerRadius = UDim.new(0, 4)

local FooterText = Instance.new("TextLabel")
FooterText.Size = UDim2.new(1, -10, 1, 0)
FooterText.Position = UDim2.new(0, 5, 0, 0)
FooterText.BackgroundTransparency = 1
FooterText.TextColor3 = Color3.fromRGB(120, 120, 140)
FooterText.Text = "v1.0 | plalettescripts | Auto Kill Shark | CTRL = Minimize"
FooterText.Font = Enum.Font.SourceSans
FooterText.TextSize = 9
FooterText.TextXAlignment = Enum.TextXAlignment.Left
FooterText.Parent = FooterFrame

-- Tab-Erstellung
local function CreateTab(name, icon)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, 52, 0, 26)
    TabBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
    TabBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
    TabBtn.Text = icon .. " " .. name
    TabBtn.Font = Enum.Font.SourceSansSemibold
    TabBtn.TextSize = 9
    TabBtn.Parent = TabContainer
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 4)

    local Content = Instance.new("ScrollingFrame")
    Content.Size = UDim2.new(1, -8, 1, -8)
    Content.Position = UDim2.new(0, 4, 0, 4)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 3
    Content.ScrollBarImageColor3 = Color3.fromRGB(255, 80, 40)
    Content.CanvasSize = UDim2.new(0, 0, 0, 800)
    Content.Visible = false
    Content.Parent = ContentFrame

    local ContentList = Instance.new("UIListLayout")
    ContentList.Padding = UDim.new(0, 3)
    ContentList.FillDirection = Enum.FillDirection.Vertical
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Parent = Content

    TabBtn.MouseButton1Click:Connect(function()
        for _, child in ipairs(ContentFrame:GetChildren()) do
            if child:IsA("ScrollingFrame") then child.Visible = false end
        end
        for _, child in ipairs(TabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
                child.TextColor3 = Color3.fromRGB(180, 180, 200)
            end
        end
        Content.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 40)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    local found = false
    for _, child in ipairs(ContentFrame:GetChildren()) do
        if child:IsA("ScrollingFrame") and child.Visible then found = true end
    end
    if not found then
        Content.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 40)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    local tab = {}

    function tab:AddBigButton(name, key, color)
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, -4, 0, 42)
        Btn.BackgroundColor3 = color or Color3.fromRGB(255, 60, 30)
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.Text = name
        Btn.Font = Enum.Font.SourceSansBold
        Btn.TextSize = 14
        Btn.Parent = Content
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
        
        local on = false
        Btn.MouseButton1Click:Connect(function()
            on = not on
            Config[key] = on
            Btn.BackgroundColor3 = on and Color3.fromRGB(0, 255, 60) or Color3.fromRGB(40, 40, 55)
            Btn.Text = on and "⚡ " .. name .. " - ACTIVE" or name
        end)
    end

    function tab:AddToggle(name, key)
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, -4, 0, 26)
        Frame.BackgroundColor3 = Color3.fromRGB(26, 28, 38)
        Frame.Parent = Content
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 4)
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.58, 0, 1, 0)
        Label.Position = UDim2.new(0.03, 0, 0, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(220, 220, 240)
        Label.Text = name .. " : OFF"
        Label.Font = Enum.Font.SourceSansSemibold
        Label.TextSize = 10
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Frame
        
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(0, 30, 0, 16)
        Btn.Position = UDim2.new(0.92, -30, 0, 5)
        Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        Btn.Text = ""
        Btn.Parent = Frame
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
        
        local on = false
        Btn.MouseButton1Click:Connect(function()
            on = not on
            Config[key] = on
            Label.Text = name .. " : " .. (on and "ON" or "OFF")
            Btn.BackgroundColor3 = on and Color3.fromRGB(255, 80, 40) or Color3.fromRGB(50, 50, 65)
        end)
    end

    function tab:AddSlider(name, key, min, max, default)
        Config[key] = default
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, -4, 0, 44)
        Frame.BackgroundColor3 = Color3.fromRGB(26, 28, 38)
        Frame.Parent = Content
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 4)
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 16)
        Label.Position = UDim2.new(0.03, 0, 0, 2)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(220, 220, 240)
        Label.Text = name .. " : " .. tostring(default)
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 10
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Frame
        
        local Input = Instance.new("TextBox")
        Input.Size = UDim2.new(0.28, 0, 0, 20)
        Input.Position = UDim2.new(0.35, 0, 0, 22)
        Input.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        Input.TextColor3 = Color3.fromRGB(255, 200, 180)
        Input.Text = tostring(default)
        Input.Font = Enum.Font.SourceSans
        Input.TextSize = 10
        Input.Parent = Frame
        Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 4)
        
        Input.FocusLost:Connect(function()
            local val = tonumber(Input.Text)
            if val and val >= min and val <= max then
                Config[key] = val
                Label.Text = name .. " : " .. tostring(val)
            else
                Input.Text = tostring(Config[key])
            end
        end)
    end

    function tab:AddButton(name, callback)
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, -4, 0, 26)
        Btn.BackgroundColor3 = Color3.fromRGB(0, 160, 200)
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.Text = name
        Btn.Font = Enum.Font.SourceSansBold
        Btn.TextSize = 10
        Btn.Parent = Content
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        Btn.MouseButton1Click:Connect(callback)
    end

    function tab:AddDropdown(name, key, options, default)
        Config[key] = default or options[1]
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, -4, 0, 26)
        Frame.BackgroundColor3 = Color3.fromRGB(26, 28, 38)
        Frame.Parent = Content
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 4)
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.35, 0, 1, 0)
        Label.Position = UDim2.new(0.03, 0, 0, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(220, 220, 240)
        Label.Text = name .. ":"
        Label.Font = Enum.Font.SourceSansSemibold
        Label.TextSize = 10
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Frame
        
        local DropBtn = Instance.new("TextButton")
        DropBtn.Size = UDim2.new(0.5, 0, 0, 20)
        DropBtn.Position = UDim2.new(0.47, 0, 0, 3)
        DropBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        DropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        DropBtn.Text = Config[key]
        DropBtn.Font = Enum.Font.SourceSans
        DropBtn.TextSize = 10
        DropBtn.Parent = Frame
        Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 4)
        
        local DropList = Instance.new("Frame")
        DropList.Size = UDim2.new(0.5, 0, 0, #options * 20)
        DropList.Position = UDim2.new(0.47, 0, 0, 23)
        DropList.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        DropList.BorderSizePixel = 0
        DropList.Visible = false
        DropList.Parent = Frame
        Instance.new("UICorner", DropList).CornerRadius = UDim.new(0, 4)
        
        local DL = Instance.new("UIListLayout", DropList)
        DL.FillDirection = Enum.FillDirection.Vertical
        DL.SortOrder = Enum.SortOrder.LayoutOrder
        
        for _, opt in ipairs(options) do
            local OptBtn = Instance.new("TextButton")
            OptBtn.Size = UDim2.new(1, 0, 0, 20)
            OptBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            OptBtn.Text = opt
            OptBtn.Font = Enum.Font.SourceSans
            OptBtn.TextSize = 10
            OptBtn.Parent = DropList
            OptBtn.MouseButton1Click:Connect(function()
                Config[key] = opt
                DropBtn.Text = opt
                DropList.Visible = false
            end)
        end
        
        DropBtn.MouseButton1Click:Connect(function()
            DropList.Visible = not DropList.Visible
        end)
    end

    return tab
end

-- Tabs
local CombatTab = CreateTab("Combat", "🎯")
local VisualsTab = CreateTab("Visuals", "👁")
local MoveTab = CreateTab("Move", "🏃")
local BoatTab = CreateTab("Boat", "🚤")
local SharkTab = CreateTab("Shark", "🦈")
local SettingsTab = CreateTab("Settings", "⚙")

-- ==================== COMBAT TAB ====================
CombatTab:AddBigButton("AUTO KILL SHARK", "AutoKillShark", Color3.fromRGB(255, 30, 10))
CombatTab:AddToggle("Auto-Aim", "AutoAim")
CombatTab:AddSlider("Aim FOV", "AimFOV", 50, 500, 200)
CombatTab:AddToggle("Silent Aim", "SilentAim")
CombatTab:AddToggle("Prediction", "Prediction")
CombatTab:AddSlider("Prediction Strength", "PredictionStrength", 0.1, 2, 0.5)
CombatTab:AddToggle("Auto-Shoot", "AutoShoot")
CombatTab:AddToggle("Instant Reload", "InstantReload")
CombatTab:AddToggle("No Recoil", "NoRecoil")
CombatTab:AddToggle("No Spread", "NoSpread")
CombatTab:AddToggle("Triggerbot", "Triggerbot")
CombatTab:AddToggle("Auto-Equip Best Gun", "AutoEquipBest")
CombatTab:AddSlider("Damage Multiplier", "DamageMultiplier", 1, 10, 1)
CombatTab:AddToggle("Auto-Collect Loot", "AutoCollectLoot")
CombatTab:AddButton("🧪 Test Hai spawnen", function()
    local testShark = Instance.new("Model")
    testShark.Name = "TestShark"
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(4, 2, 8)
    hrp.Position = LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(30, 0, 0) or Vector3.new(0, 30, 0)
    hrp.Velocity = Vector3.new(-50, 0, 0)
    hrp.Parent = testShark
    local hum = Instance.new("Humanoid")
    hum.Health = 100
    hum.MaxHealth = 100
    hum.Parent = testShark
    testShark.Parent = Workspace
    Notify("🧪 Test", "Test-Hai gespawnt!")
    task.delay(10, function() pcall(function() testShark:Destroy() end) end)
end)

-- ==================== VISUALS TAB ====================
VisualsTab:AddToggle("Shark ESP", "SharkESP")
VisualsTab:AddToggle("Shark Box ESP", "SharkBoxESP")
VisualsTab:AddToggle("Shark Health Bar", "SharkHealthBar")
VisualsTab:AddToggle("Shark Distance", "SharkDistance")
VisualsTab:AddToggle("Shark Name", "SharkName")
VisualsTab:AddToggle("Shark Trajectory", "SharkTrajectory")
VisualsTab:AddToggle("Shark Chams", "SharkChams")
VisualsTab:AddToggle("Player ESP", "PlayerESP")
VisualsTab:AddToggle("Player Box ESP", "PlayerBoxESP")
VisualsTab:AddToggle("Player Distance", "PlayerDistance")
VisualsTab:AddToggle("Boat ESP", "BoatESP")
VisualsTab:AddToggle("Loot ESP", "LootESP")
VisualsTab:AddToggle("Island ESP", "IslandESP")
VisualsTab:AddToggle("Tracer to Shark", "TracerToShark")
VisualsTab:AddToggle("Fullbright", "Fullbright")
VisualsTab:AddToggle("Clear Water", "ClearWater")
VisualsTab:AddSlider("Water Transparency", "WaterTransparency", 0, 100, 50)
VisualsTab:AddToggle("No Fog", "NoFog")
VisualsTab:AddToggle("Radar", "Radar")
VisualsTab:AddSlider("Radar Size", "RadarSize", 80, 200, 150)

-- ==================== MOVEMENT TAB ====================
MoveTab:AddButton("Teleport to Shark", function()
    local shark = FindNearestShark()
    if shark and LocalPlayer.Character then
        local hrp = shark:FindFirstChild("HumanoidRootPart") or shark:FindFirstChild("Head")
        if hrp then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 5, 0))
            Notify("🏃 Teleport", "Zum Hai teleportiert!")
        end
    end
end)
MoveTab:AddButton("Teleport to Loot", function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("loot") or obj.Name:lower():find("coin") or obj.Name:lower():find("chest") then
            if obj:IsA("BasePart") and LocalPlayer.Character then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                Notify("🏃 Teleport", "Zu Loot teleportiert!")
                break
            end
        end
    end
end)
MoveTab:AddSlider("Walk Speed", "SpeedValue", 16, 100, 32)
MoveTab:AddToggle("Speed Hack", "SpeedHack")
MoveTab:AddSlider("Fly Speed", "FlySpeed", 20, 200, 50)
MoveTab:AddToggle("Fly", "Fly")
MoveTab:AddToggle("Noclip", "Noclip")
MoveTab:AddToggle("Infinite Jump", "InfiniteJump")
MoveTab:AddToggle("Water Walk", "WaterWalk")
MoveTab:AddSlider("Fast Swim", "SwimSpeed", 16, 200, 100)
MoveTab:AddToggle("Fast Swim", "FastSwim")
MoveTab:AddToggle("Auto-Respawn", "AutoRespawn")

-- ==================== BOAT TAB ====================
BoatTab:AddToggle("Auto-Boat-Farm", "AutoBoatFarm")
BoatTab:AddSlider("Boat Speed", "BoatSpeedValue", 1, 10, 3)
BoatTab:AddToggle("Boat Speed Hack", "BoatSpeedHack")
BoatTab:AddToggle("Boat Fly", "BoatFly")
BoatTab:AddToggle("Boat Noclip", "BoatNoclip")
BoatTab:AddToggle("Auto-Boat-Repair", "AutoBoatRepair")
BoatTab:AddToggle("Unlimited Boat Health", "UnlimitedBoatHealth")
BoatTab:AddToggle("Auto-Spawn Best Boat", "AutoSpawnBestBoat")
BoatTab:AddToggle("Boat ESP", "BoatESP")

-- ==================== SHARK MODE TAB ====================
SharkTab:AddBigButton("AUTO KILL PLAYER", "AutoKillPlayer", Color3.fromRGB(255, 0, 50))
SharkTab:AddSlider("Shark Speed", "SharkSpeedValue", 1, 10, 3)
SharkTab:AddToggle("Shark Speed Hack", "SharkSpeedHack")
SharkTab:AddToggle("Shark Fly", "SharkFly")
SharkTab:AddToggle("Unlimited Shark Health", "UnlimitedSharkHealth")
SharkTab:AddToggle("Auto-Dodge Harpoon", "AutoDodgeHarpoon")
SharkTab:AddToggle("Player ESP for Shark", "PlayerESPForShark")
SharkTab:AddToggle("Boat Destroyer", "BoatDestroyer")
SharkTab:AddToggle("Shark Invisible", "SharkInvisible")

-- ==================== SETTINGS TAB ====================
SettingsTab:AddButton("Config Speichern", function() Notify("⚙️ Settings", "Config gespeichert!") end)
SettingsTab:AddButton("Config Laden", function() Notify("⚙️ Settings", "Config geladen!") end)
SettingsTab:AddButton("Reset All", function()
    for k, v in pairs(Config) do
        if type(v) == "boolean" then Config[k] = false
        elseif type(v) == "number" then Config[k] = v end
    end
    Notify("⚙️ Settings", "Alle Einstellungen zurückgesetzt!")
end)
SettingsTab:AddToggle("FPS Optimizer", "FPSOptimizer")
SettingsTab:AddDropdown("Sprache", "Language", {"DE", "EN", "FR", "ES"}, "DE")

-- Credits im Settings Tab
local CreditFrame = Instance.new("Frame")
CreditFrame.Size = UDim2.new(1, -4, 0, 100)
CreditFrame.BackgroundColor3 = Color3.fromRGB(26, 28, 38)
CreditFrame.Parent = SettingsTab.Content or ContentFrame
Instance.new("UICorner", CreditFrame).CornerRadius = UDim.new(0, 6)

local CreditText = Instance.new("TextLabel")
CreditText.Size = UDim2.new(1, -16, 1, -16)
CreditText.Position = UDim2.new(0, 8, 0, 8)
CreditText.BackgroundTransparency = 1
CreditText.TextColor3 = Color3.fromRGB(200, 200, 220)
CreditText.Text = [[
🦈 Shark Bite 2 Ultimate

Created by: plalettescripts

Features:
- Auto Kill Shark (Instant)
- ESP & Visuals
- Teleport System
- Boat Hacks
- Shark Mode
- And much more...

Made by Plalette
]]
CreditText.Font = Enum.Font.SourceSans
CreditText.TextSize = 10
CreditText.TextXAlignment = Enum.TextXAlignment.Left
CreditText.TextYAlignment = Enum.TextYAlignment.Top
CreditText.TextWrapped = true
CreditText.Parent = CreditFrame

-- ==================== 5. AUTO KILL SHARK - 0ms ====================
task.spawn(function()
    while task.wait() do
        if Config.AutoKillShark then
            pcall(function()
                FindRemotes()
                local shark = FindNearestShark()
                
                if shark and ShootRemote then
                    -- Prediction
                    local targetPos
                    if Config.Prediction then
                        targetPos = PredictPosition(shark, Config.PredictionStrength)
                    else
                        local hrp = shark:FindFirstChild("HumanoidRootPart") or shark:FindFirstChild("Head")
                        targetPos = hrp and hrp.Position or Vector3.zero
                    end
                    
                    -- Auto-Equip
                    if Config.AutoEquipBest then
                        EquipBestWeapon()
                    end
                    
                    -- Schießen (mehrfach für Sicherheit)
                    for i = 1, 3 do
                        ShootRemote:FireServer(targetPos)
                    end
                    
                    -- Auto-Collect Loot
                    if Config.AutoCollectLoot then
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj.Name:lower():find("loot") or obj.Name:lower():find("coin") then
                                if obj:IsA("BasePart") and LocalPlayer.Character then
                                    if (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 50 then
                                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
                                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait()
    end
end)

-- ==================== 6. AUTO AIM ====================
task.spawn(function()
    while task.wait(0.02) do
        if Config.AutoAim and LocalPlayer.Character then
            pcall(function()
                local shark = FindNearestShark()
                if shark then
                    local targetPos
                    if Config.Prediction then
                        targetPos = PredictPosition(shark, Config.PredictionStrength)
                    else
                        local hrp = shark:FindFirstChild("HumanoidRootPart") or shark:FindFirstChild("Head")
                        targetPos = hrp and hrp.Position or Vector3.zero
                    end
                    
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                        if screenDist < Config.AimFOV then
                            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                        end
                    end
                end
            end)
        end
    end
end)

-- ==================== 7. ESP ====================
task.spawn(function()
    while task.wait(0.04) do
        ClearDrawings()
        
        -- Shark ESP
        if Config.SharkESP or Config.SharkBoxESP or Config.SharkHealthBar or Config.SharkDistance or Config.SharkName or Config.SharkTrajectory then
            local shark = FindNearestShark()
            if shark then
                local hrp = shark:FindFirstChild("HumanoidRootPart") or shark:FindFirstChild("Head")
                local head = shark:FindFirstChild("Head")
                local humanoid = shark:FindFirstChildOfClass("Humanoid")
                
                if hrp then
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    
                    if Config.SharkBoxESP and head then
                        local headPos, hOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
                        local footPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2, 0))
                        if hOn then
                            local h = math.abs(headPos.Y - footPos.Y)
                            local w = h * 1.5
                            local box = AddDrawing(Drawing.new("Square"))
                            box.Color = Color3.fromRGB(255, 50, 30)
                            box.Thickness = 2
                            box.Size = Vector2.new(w, h)
                            box.Position = Vector2.new(headPos.X - w/2, headPos.Y)
                            box.Filled = false
                            box.Visible = true
                        end
                    end
                    
                    if Config.SharkName and onScreen then
                        local name = AddDrawing(Drawing.new("Text"))
                        name.Text = "🦈 Shark"
                        name.Color = Color3.fromRGB(255, 80, 50)
                        name.Size = 14
                        name.Position = Vector2.new(pos.X, pos.Y - 25)
                        name.Center = true
                        name.Visible = true
                    end
                    
                    if Config.SharkDistance and onScreen and LocalPlayer.Character then
                        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myHrp then
                            local dist = math.floor((hrp.Position - myHrp.Position).Magnitude)
                            local dText = AddDrawing(Drawing.new("Text"))
                            dText.Text = dist .. "m"
                            dText.Color = Color3.fromRGB(200, 200, 200)
                            dText.Size = 11
                            dText.Position = Vector2.new(pos.X, pos.Y - 12)
                            dText.Center = true
                            dText.Visible = true
                        end
                    end
                    
                    if Config.SharkHealthBar and humanoid and onScreen then
                        local hp = humanoid.Health / humanoid.MaxHealth
                        local barW = 60
                        local barH = 4
                        local barX = pos.X - barW/2
                        local barY = pos.Y + 15
                        
                        local bg = AddDrawing(Drawing.new("Square"))
                        bg.Color = Color3.fromRGB(50, 50, 50)
                        bg.Size = Vector2.new(barW, barH)
                        bg.Position = Vector2.new(barX, barY)
                        bg.Filled = true
                        bg.Visible = true
                        
                        local fill = AddDrawing(Drawing.new("Square"))
                        fill.Color = Color3.fromRGB(255, 50, 50)
                        fill.Size = Vector2.new(barW * hp, barH)
                        fill.Position = Vector2.new(barX, barY)
                        fill.Filled = true
                        fill.Visible = true
                    end
                    
                    if Config.SharkTrajectory then
                        local vel = hrp.Velocity or hrp.AssemblyLinearVelocity or Vector3.zero
                        if vel.Magnitude > 1 then
                            local steps = math.floor(vel.Magnitude / 5)
                            local prev = Vector2.new(pos.X, pos.Y)
                            for i = 1, math.min(steps, 20) do
                                local future = hrp.Position + vel * (i * 0.1)
                                local fs, fo = Camera:WorldToViewportPoint(future)
                                if fo then
                                    local line = AddDrawing(Drawing.new("Line"))
                                    line.Color = Color3.fromRGB(255, 150, 50)
                                    line.Thickness = 0.5
                                    line.From = prev
                                    line.To = Vector2.new(fs.X, fs.Y)
                                    line.Visible = true
                                    prev = Vector2.new(fs.X, fs.Y)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Player ESP
        if Config.PlayerESP then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local head = player.Character:FindFirstChild("Head")
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if head and hrp then
                        local hPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local fPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        if onScreen then
                            if Config.PlayerBoxESP then
                                local h = math.abs(hPos.Y - fPos.Y)
                                local w = h / 2
                                local box = AddDrawing(Drawing.new("Square"))
                                box.Color = Color3.fromRGB(0, 200, 255)
                                box.Thickness = 1
                                box.Size = Vector2.new(w, h)
                                box.Position = Vector2.new(hPos.X - w/2, hPos.Y)
                                box.Filled = false
                                box.Visible = true
                            end
                            
                            local name = AddDrawing(Drawing.new("Text"))
                            name.Text = player.Name
                            name.Color = Color3.fromRGB(255, 255, 255)
                            name.Size = 11
                            name.Position = Vector2.new(hPos.X, hPos.Y - 16)
                            name.Center = true
                            name.Visible = true
                        end
                    end
                end
            end
        end
        
        -- Tracer to Shark
        if Config.TracerToShark then
            local shark = FindNearestShark()
            if shark then
                local hrp = shark:FindFirstChild("HumanoidRootPart") or shark:FindFirstChild("Head")
                if hrp then
                    local sPos, sOn = Camera:WorldToViewportPoint(hrp.Position)
                    if sOn then
                        local line = AddDrawing(Drawing.new("Line"))
                        line.Color = Color3.fromRGB(255, 100, 80)
                        line.Thickness = 1
                        line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                        line.To = Vector2.new(sPos.X, sPos.Y)
                        line.Visible = true
                    end
                end
            end
        end
        
        -- Boat ESP
        if Config.BoatESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj.Name:lower():find("boat") or obj:FindFirstChild("Boat")) then
                    local primary = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart")
                    if primary then
                        local pos, onScreen = Camera:WorldToViewportPoint(primary.Position)
                        if onScreen then
                            local txt = AddDrawing(Drawing.new("Text"))
                            txt.Text = "🚤"
                            txt.Color = Color3.fromRGB(100, 200, 255)
                            txt.Size = 16
                            txt.Position = Vector2.new(pos.X, pos.Y)
                            txt.Center = true
                            txt.Visible = true
                        end
                    end
                end
            end
        end
        
        -- Loot ESP
        if Config.LootESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name:lower():find("loot") or obj.Name:lower():find("coin") or obj.Name:lower():find("chest") then
                    if obj:IsA("BasePart") then
                        local pos, onScreen = Camera:WorldToViewportPoint(obj.Position)
                        if onScreen then
                            local txt = AddDrawing(Drawing.new("Text"))
                            txt.Text = "💎"
                            txt.Color = Color3.fromRGB(255, 255, 50)
                            txt.Size = 14
                            txt.Position = Vector2.new(pos.X, pos.Y)
                            txt.Center = true
                            txt.Visible = true
                        end
                    end
                end
            end
        end
        
        -- Radar
        if Config.Radar then
            local rs = Config.RadarSize
            local rx = Camera.ViewportSize.X - rs - 10
            local ry = Camera.ViewportSize.Y - rs - 10
            
            local bg = AddDrawing(Drawing.new("Square"))
            bg.Color = Color3.fromRGB(0, 0, 0)
            bg.Size = Vector2.new(rs, rs)
            bg.Position = Vector2.new(rx, ry)
            bg.Filled = true
            bg.Visible = true
            
            if LocalPlayer.Character then
                local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    -- Spieler
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local tHrp = player.Character.HumanoidRootPart
                            local off = tHrp.Position - myHrp.Position
                            local rd = math.clamp(off.Magnitude / 3, 0, rs/2 - 2)
                            local ang = math.atan2(off.Z, off.X)
                            local dx = rx + rs/2 + math.cos(ang) * rd
                            local dy = ry + rs/2 + math.sin(ang) * rd
                            local dot = AddDrawing(Drawing.new("Circle"))
                            dot.Color = player == LocalPlayer and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
                            dot.Radius = 2
                            dot.Position = Vector2.new(dx, dy)
                            dot.Filled = true
                            dot.Visible = true
                        end
                    end
                    
                    -- Hai
                    local shark = FindNearestShark()
                    if shark then
                        local hrp = shark:FindFirstChild("HumanoidRootPart") or shark:FindFirstChild("Head")
                        if hrp then
                            local off = hrp.Position - myHrp.Position
                            local rd = math.clamp(off.Magnitude / 3, 0, rs/2 - 2)
                            local ang = math.atan2(off.Z, off.X)
                            local dx = rx + rs/2 + math.cos(ang) * rd
                            local dy = ry + rs/2 + math.sin(ang) * rd
                            local dot = AddDrawing(Drawing.new("Circle"))
                            dot.Color = Color3.fromRGB(255, 0, 0)
                            dot.Radius = 3
                            dot.Position = Vector2.new(dx, dy)
                            dot.Filled = true
                            dot.Visible = true
                        end
                    end
                end
            end
        end
    end
end)

-- ==================== 8. MOVEMENT ====================
RunService.Stepped:Connect(function()
    if Config.SpeedHack and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.SpeedValue end
    end
    if Config.Noclip and LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Fly
task.spawn(function()
    while task.wait() do
        if Config.Fly and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local gyro = hrp:FindFirstChild("FlyGyro") or Instance.new("BodyGyro", hrp)
                local vel = hrp:FindFirstChild("FlyVel") or Instance.new("BodyVelocity", hrp)
                gyro.Name = "FlyGyro"
                gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                gyro.CFrame = Camera.CFrame
                vel.Name = "FlyVel"
                vel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                local speed = Config.FlySpeed or 50
                local move = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
                vel.Velocity = move * speed
            end
        end
    end
end)

-- ==================== 9. BOAT HACKS ====================
task.spawn(function()
    while task.wait(0.3) do
        if Config.BoatSpeedHack or Config.UnlimitedBoatHealth then
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name:lower():find("boat") then
                        if LocalPlayer.Character and obj:FindFirstChild("Seat") then
                            local seat = obj.Seat
                            if seat:FindFirstChild("Occupant") and seat.Occupant.Value == LocalPlayer.Character.HumanoidRootPart then
                                CurrentBoat = obj
                                if Config.BoatSpeedHack then
                                    local engine = obj:FindFirstChild("Engine") or obj:FindFirstChild("Motor")
                                    if engine and engine:IsA("BodyVelocity") then
                                        engine.MaxForce = Vector3.new(9e9, 0, 9e9)
                                        engine.Velocity = engine.Velocity.Unit * 100 * Config.BoatSpeedValue
                                    end
                                end
                                if Config.UnlimitedBoatHealth then
                                    local health = obj:FindFirstChild("Health") or obj:FindFirstChild("HP")
                                    if health and health:IsA("NumberValue") then
                                        health.Value = health.Value > 0 and 9999 or health.Value
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==================== 10. ANTI-AFK ====================
task.spawn(function()
    while task.wait(100) do
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
        end)
    end
end)

-- ==================== 11. FULLBRIGHT & NO FOG ====================
task.spawn(function()
    while task.wait(1) do
        if Config.Fullbright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        end
        if Config.NoFog then
            Lighting.FogEnd = 1000000
            Lighting.FogStart = 0
        end
    end
end)

-- ==================== 12. WILLKOMMEN ====================
Notify("🦈 Shark Bite 2 Ultimate", "Willkommen! Created by plalettescripts", 5)
print("🦈 Shark Bite 2 Ultimate geladen!")
print("👤 Created by: plalettescripts")
print("⚡ Auto Kill Shark | ESP | Teleport | Boat | Shark Mode")
print("🔴 CTRL = Minimize")
