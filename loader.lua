--[[
    Shark Bite 2 Script v1.3 | plalettescripts
    Basierend auf tatsächlichen Spielmechaniken
    Auto-Kill Shark = Auto-Aim + Auto-Shoot + Auto-Track
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==================== KONFIGURATION ====================
local Config = {
    AutoKillShark = false,
    AutoAim = false,
    AutoShoot = false,
    AutoReload = false,
    AutoCollect = false,
    SharkESP = false,
    PlayerESP = false,
    Tracers = false,
    Radar = false,
    SpeedHack = false,
    SpeedValue = 32,
    Fly = false,
    FlySpeed = 50,
    Fullbright = false,
    NoFog = false,
    ESPVisible = true
}

local ESPDrawings = {}
local ShootRemote = nil
local HarpoonRemote = nil
local CurrentTarget = nil

-- ==================== HILFSFUNKTIONEN ====================

-- ESP sichern
local function ClearESP()
    for _, d in pairs(ESPDrawings) do
        pcall(function() d:Remove() end)
    end
    ESPDrawings = {}
end

local function AddESP(drawing)
    if #ESPDrawings >= 80 then
        local old = table.remove(ESPDrawings, 1)
        pcall(function() old:Remove() end)
    end
    table.insert(ESPDrawings, drawing)
    return drawing
end

-- Hai finden (Model mit Humanoid)
local function FindShark()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("shark") or name:find("hai") then
                local humanoid = obj:FindFirstChildOfClass("Humanoid")
                local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and head then
                    return obj, head, humanoid
                end
            end
        end
    end
    -- Auch in Ordnern suchen
    for _, folder in ipairs(Workspace:GetChildren()) do
        if folder:IsA("Folder") and folder.Name:lower():find("shark") then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Model") then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 and head then
                        return obj, head, humanoid
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

-- Remote Events finden (spezifisch für Shark Bite 2)
local function FindRemotes()
    if ShootRemote then return end
    
    -- Häufige Remote-Namen in Shark Bite 2
    local possibleNames = {
        "Shoot", "Fire", "Harpoon", "ShootHarpune", "FireHarpune",
        "ShootEvent", "FireEvent", "Attack", "Hit", "Damage",
        "FireServer", "ShootServer", "HarpuneFire"
    }
    
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local name = obj.Name
            for _, possible in ipairs(possibleNames) do
                if name:lower():find(possible:lower()) then
                    if name:lower():find("harpune") or name:lower():find("harpoon") then
                        HarpoonRemote = obj
                    else
                        ShootRemote = obj
                    end
                    break
                end
            end
        end
    end
    
    -- Fallback: Erstes und zweites Remote
    if not ShootRemote then
        local remotes = {}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                table.insert(remotes, obj)
            end
        end
        if #remotes >= 1 then ShootRemote = remotes[1] end
        if #remotes >= 2 then HarpoonRemote = remotes[2] end
    end
    
    if ShootRemote then
        print("🦈 Shoot Remote gefunden:", ShootRemote.Name)
    end
    if HarpoonRemote then
        print("🦈 Harpoon Remote gefunden:", HarpoonRemote.Name)
    end
end

-- Distanz zum Hai
local function DistanceToShark(sharkPart)
    if not LocalPlayer.Character then return 999 end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not sharkPart then return 999 end
    return (sharkPart.Position - hrp.Position).Magnitude
end

-- Auto-Collect Loot
local function CollectNearbyLoot()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("coin") or name:find("loot") or name:find("money") or name:find("chest") then
                if (obj.Position - hrp.Position).Magnitude < 80 then
                    firetouchinterest(hrp, obj, 0)
                    firetouchinterest(hrp, obj, 1)
                end
            end
        end
    end
end

-- ==================== GUI (Kompakt, links oben) ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SB2_Plalette"
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 210, 0, 290)
Main.Position = UDim2.new(0.01, 0, 0.05, 0)
Main.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Visible = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Border = Instance.new("Frame")
Border.Size = UDim2.new(1, 3, 1, 3)
Border.Position = UDim2.new(0, -1.5, 0, -1.5)
Border.BackgroundColor3 = Color3.fromRGB(255, 50, 30)
Border.BorderSizePixel = 0
Border.Parent = Main
Instance.new("UICorner", Border).CornerRadius = UDim.new(0, 9)

-- Minimiert
local Mini = Instance.new("Frame")
Mini.Size = UDim2.new(0, 160, 0, 30)
Mini.Position = UDim2.new(0.01, 0, 0.05, 0)
Mini.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
Mini.BorderSizePixel = 0
Mini.Visible = false
Mini.Active = true
Mini.Draggable = true
Mini.Parent = ScreenGui
Instance.new("UICorner", Mini).CornerRadius = UDim.new(0, 6)

local MiniText = Instance.new("TextLabel")
MiniText.Size = UDim2.new(1, 0, 1, 0)
MiniText.BackgroundTransparency = 1
MiniText.TextColor3 = Color3.fromRGB(255, 60, 40)
MiniText.Text = "🦈 SB2 v1.3 | plalettescripts"
MiniText.Font = Enum.Font.SourceSansBold
MiniText.TextSize = 11
MiniText.Parent = Mini

-- CTRL Toggle
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        Main.Visible = not Main.Visible
        Mini.Visible = not Mini.Visible
    end
end)

-- Titel
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 0.5, 0)
Title.Position = UDim2.new(0.04, 0, 0, 2)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 70, 40)
Title.Text = "🦈 Shark Bite 2"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(0.6, 0, 0.4, 0)
Sub.Position = UDim2.new(0.04, 0, 0.5, 0)
Sub.BackgroundTransparency = 1
Sub.TextColor3 = Color3.fromRGB(140, 140, 160)
Sub.Text = "v1.3 | plalettescripts"
Sub.Font = Enum.Font.SourceSans
Sub.TextSize = 9
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.Parent = TitleBar

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 22, 0, 18)
Close.Position = UDim2.new(1, -26, 0, 7)
Close.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.Text = "X"
Close.Font = Enum.Font.SourceSansBold
Close.TextSize = 11
Close.Parent = TitleBar
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 4)
Close.MouseButton1Click:Connect(function()
    ClearESP()
    ScreenGui:Destroy()
end)

-- Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -6, 1, -36)
Scroll.Position = UDim2.new(0, 3, 0, 34)
Scroll.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 30)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 650)
Scroll.Parent = Main

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0, 2)
List.FillDirection = Enum.FillDirection.Vertical
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Parent = Scroll

-- UI-Elemente
local function Div(t)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -2, 0, 16)
    f.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    f.Parent = Scroll
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(255, 90, 50)
    l.Text = t
    l.Font = Enum.Font.SourceSansBold
    l.TextSize = 9
    l.Parent = f
end

local function Tog(name, key)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -2, 0, 26)
    f.BackgroundColor3 = Color3.fromRGB(24, 26, 38)
    f.Parent = Scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.52, 0, 1, 0)
    l.Position = UDim2.new(0.03, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(220, 220, 240)
    l.Text = name .. ": OFF"
    l.Font = Enum.Font.SourceSansSemibold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 30, 0, 16)
    b.Position = UDim2.new(0.9, -30, 0, 5)
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    b.Text = ""
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

    local on = false
    b.MouseButton1Click:Connect(function()
        on = not on
        Config[key] = on
        l.Text = name .. ": " .. (on and "ON" or "OFF")
        b.BackgroundColor3 = on and Color3.fromRGB(255, 60, 30) or Color3.fromRGB(50, 50, 65)
    end)
end

local function Sli(name, key, min, max, def)
    Config[key] = def
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -2, 0, 40)
    f.BackgroundColor3 = Color3.fromRGB(24, 26, 38)
    f.Parent = Scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 15)
    l.Position = UDim2.new(0.03, 0, 0, 2)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(220, 220, 240)
    l.Text = name .. ": " .. def
    l.Font = Enum.Font.SourceSans
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local inp = Instance.new("TextBox")
    inp.Size = UDim2.new(0.28, 0, 0, 18)
    inp.Position = UDim2.new(0.35, 0, 0, 20)
    inp.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
    inp.TextColor3 = Color3.fromRGB(255, 200, 180)
    inp.Text = tostring(def)
    inp.Font = Enum.Font.SourceSans
    inp.TextSize = 10
    inp.Parent = f
    Instance.new("UICorner", inp).CornerRadius = UDim.new(0, 3)

    inp.FocusLost:Connect(function()
        local v = tonumber(inp.Text)
        if v and v >= min and v <= max then
            Config[key] = v
            l.Text = name .. ": " .. v
        else
            inp.Text = tostring(Config[key])
        end
    end)
end

local function Btn(name, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -2, 0, 24)
    b.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = name
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 10
    b.Parent = Scroll
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(cb)
end

-- ==================== GUI INHALT ====================
Div("🎯 Auto Kill Shark")
Tog("Auto-Kill Shark", "AutoKillShark")
Tog("Auto-Shoot", "AutoShoot")
Tog("Auto-Reload", "AutoReload")
Tog("Auto-Collect Loot", "AutoCollect")

Div("👁 ESP")
Tog("Shark ESP", "SharkESP")
Tog("Player ESP", "PlayerESP")
Tog("Tracers", "Tracers")
Tog("Radar", "Radar")

Div("🏃 Movement")
Sli("Walk Speed", "SpeedValue", 16, 100, 32)
Tog("Speed Hack", "SpeedHack")
Sli("Fly Speed", "FlySpeed", 20, 150, 50)
Tog("Fly (WASD)", "Fly")

Div("🌍 World")
Tog("Fullbright", "Fullbright")
Tog("No Fog", "NoFog")

Btn("Teleport to Shark", function()
    local _, head = FindShark()
    if head and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(head.Position + Vector3.new(0, 10, 0))
        end
    end
end)

-- ==================== AUTO-KILL SHARK SYSTEM ====================
-- Funktioniert durch: Auto-Aim (Kamera verfolgt Hai) + Auto-Shoot (schießt kontinuierlich)

-- Auto-Aim: Kamera folgt dem Hai
task.spawn(function()
    while task.wait() do
        if Config.AutoKillShark and LocalPlayer.Character then
            pcall(function()
                local _, head = FindShark()
                if head then
                    -- Kamera sofort auf Hai richten
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                    CurrentTarget = head
                else
                    CurrentTarget = nil
                end
            end)
        end
    end
end)

-- Auto-Shoot: Kontinuierlich schießen wenn Hai in Reichweite
task.spawn(function()
    while task.wait(0.05) do
        if Config.AutoShoot or Config.AutoKillShark then
            pcall(function()
                FindRemotes()
                local _, head = FindShark()
                
                if head and ShootRemote then
                    -- Auf Hai schießen
                    ShootRemote:FireServer(head.Position)
                    
                    -- Auch Harpune nutzen falls vorhanden
                    if HarpoonRemote then
                        HarpoonRemote:FireServer(head.Position)
                    end
                end
            end)
        end
    end
end)

-- Auto-Reload: Munition auffüllen
task.spawn(function()
    while task.wait(0.1) do
        if Config.AutoReload or Config.AutoKillShark then
            pcall(function()
                for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        local ammo = tool:FindFirstChild("Ammo")
                        if ammo then
                            if ammo:IsA("IntValue") then ammo.Value = 999
                            elseif ammo:IsA("NumberValue") then ammo.Value = 999 end
                        end
                    end
                end
                local equipped = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if equipped then
                    local ammo = equipped:FindFirstChild("Ammo")
                    if ammo then
                        if ammo:IsA("IntValue") then ammo.Value = 999
                        elseif ammo:IsA("NumberValue") then ammo.Value = 999 end
                    end
                end
            end)
        end
    end
end)

-- Auto-Collect
task.spawn(function()
    while task.wait(0.3) do
        if Config.AutoCollect then
            CollectNearbyLoot()
        end
    end
end)

-- ==================== ESP SYSTEM ====================
task.spawn(function()
    while task.wait(0.06) do
        ClearESP()
        
        -- Shark ESP
        if Config.SharkESP then
            local _, head, humanoid = FindShark()
            if head then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    -- Name
                    local t = AddESP(Drawing.new("Text"))
                    t.Text = "🦈 SHARK"
                    t.Color = Color3.fromRGB(255, 40, 20)
                    t.Size = 14
                    t.Position = Vector2.new(pos.X, pos.Y - 25)
                    t.Center = true
                    t.Visible = true
                    
                    -- Health
                    if humanoid then
                        local hp = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                        local ht = AddESP(Drawing.new("Text"))
                        ht.Text = hp .. "%"
                        ht.Color = hp > 50 and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(255, 50, 50)
                        ht.Size = 11
                        ht.Position = Vector2.new(pos.X, pos.Y - 10)
                        ht.Center = true
                        ht.Visible = true
                    end
                    
                    -- Distanz
                    if LocalPlayer.Character then
                        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local dist = math.floor((head.Position - hrp.Position).Magnitude)
                            local dt = AddESP(Drawing.new("Text"))
                            dt.Text = dist .. "m"
                            dt.Color = Color3.fromRGB(200, 200, 200)
                            dt.Size = 10
                            dt.Position = Vector2.new(pos.X, pos.Y + 2)
                            dt.Center = true
                            dt.Visible = true
                        end
                    end
                end
            end
        end
        
        -- Player ESP
        if Config.PlayerESP then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and pl.Character then
                    local head = pl.Character:FindFirstChild("Head")
                    if head then
                        local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
                        if onScreen then
                            local t = AddESP(Drawing.new("Text"))
                            t.Text = pl.Name
                            t.Color = Color3.fromRGB(255, 255, 255)
                            t.Size = 11
                            t.Position = Vector2.new(pos.X, pos.Y)
                            t.Center = true
                            t.Visible = true
                        end
                    end
                end
            end
        end
        
        -- Tracers
        if Config.Tracers then
            local _, head = FindShark()
            if head then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local l = AddESP(Drawing.new("Line"))
                    l.Color = Color3.fromRGB(255, 70, 40)
                    l.Thickness = 0.8
                    l.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    l.To = Vector2.new(pos.X, pos.Y)
                    l.Visible = true
                end
            end
        end
        
        -- Radar (unten rechts)
        if Config.Radar then
            local rs = 65
            local rx = Camera.ViewportSize.X - rs - 8
            local ry = Camera.ViewportSize.Y - rs - 8
            
            local bg = AddESP(Drawing.new("Square"))
            bg.Color = Color3.fromRGB(0, 0, 0)
            bg.Size = Vector2.new(rs, rs)
            bg.Position = Vector2.new(rx, ry)
            bg.Filled = true
            bg.Visible = true
            
            if LocalPlayer.Character then
                local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    -- Spieler-Punkte
                    for _, pl in ipairs(Players:GetPlayers()) do
                        if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                            local tHrp = pl.Character.HumanoidRootPart
                            local off = tHrp.Position - myHrp.Position
                            local rd = math.clamp(off.Magnitude / 3, 0, rs/2 - 2)
                            local ang = math.atan2(off.Z, off.X)
                            local dx = rx + rs/2 + math.cos(ang) * rd
                            local dy = ry + rs/2 + math.sin(ang) * rd
                            local dot = AddESP(Drawing.new("Circle"))
                            dot.Color = pl == LocalPlayer and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
                            dot.Radius = 2
                            dot.Position = Vector2.new(dx, dy)
                            dot.Filled = true
                            dot.Visible = true
                        end
                    end
                    -- Hai-Punkt
                    local _, head = FindShark()
                    if head then
                        local off = head.Position - myHrp.Position
                        local rd = math.clamp(off.Magnitude / 3, 0, rs/2 - 2)
                        local ang = math.atan2(off.Z, off.X)
                        local dx = rx + rs/2 + math.cos(ang) * rd
                        local dy = ry + rs/2 + math.sin(ang) * rd
                        local dot = AddESP(Drawing.new("Circle"))
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
end)

-- ==================== MOVEMENT ====================
RunService.Stepped:Connect(function()
    if Config.SpeedHack and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.SpeedValue end
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

-- ==================== WORLD ====================
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

-- ==================== ANTI-AFK ====================
task.spawn(function()
    while task.wait(100) do
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
        end)
    end
end)

print("🦈 Shark Bite 2 v1.3 geladen | plalettescripts")
print("🎯 Auto-Kill = Auto-Aim + Auto-Shoot + Auto-Reload")
print("⌨️ CTRL = Minimieren")
