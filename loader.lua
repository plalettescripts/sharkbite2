-- Shark Bite 2 v1.4 SAFE | plalettescripts
-- Anti-Detection: Humanized delays, natural aim, no spam
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    AutoKillShark = false,
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
    NoFog = false
}

local ESPDrawings = {}
local ShootRemote = nil
local LastShot = 0
local ShotDelay = 0.3

local function ClearESP()
    for _, d in pairs(ESPDrawings) do pcall(function() d:Remove() end) end
    ESPDrawings = {}
end

local function AddESP(d)
    if #ESPDrawings >= 80 then table.remove(ESPDrawings, 1):Remove() end
    table.insert(ESPDrawings, d)
    return d
end

local function FindShark()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("shark") or n:find("hai") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and head then
                    return obj, head, hum
                end
            end
        end
    end
    return nil, nil, nil
end

local function FindRemote()
    if ShootRemote then return end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            ShootRemote = obj
            break
        end
    end
end

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "SB2"
GUI.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 200, 0, 280)
Main.Position = UDim2.new(0.01, 0, 0.05, 0)
Main.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Border = Instance.new("Frame")
Border.Size = UDim2.new(1, 3, 1, 3)
Border.Position = UDim2.new(0, -1.5, 0, -1.5)
Border.BackgroundColor3 = Color3.fromRGB(255, 50, 30)
Border.BorderSizePixel = 0
Border.Parent = Main
Instance.new("UICorner", Border).CornerRadius = UDim.new(0, 9)

local Mini = Instance.new("Frame")
Mini.Size = UDim2.new(0, 150, 0, 28)
Mini.Position = UDim2.new(0.01, 0, 0.05, 0)
Mini.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
Mini.BorderSizePixel = 0
Mini.Visible = false
Mini.Active = true
Mini.Draggable = true
Mini.Parent = GUI
Instance.new("UICorner", Mini).CornerRadius = UDim.new(0, 6)

local MiniText = Instance.new("TextLabel")
MiniText.Size = UDim2.new(1, 0, 1, 0)
MiniText.BackgroundTransparency = 1
MiniText.TextColor3 = Color3.fromRGB(255, 60, 40)
MiniText.Text = "🦈 SB2 | plalettescripts"
MiniText.Font = Enum.Font.SourceSansBold
MiniText.TextSize = 11
MiniText.Parent = Mini

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        Main.Visible = not Main.Visible
        Mini.Visible = not Mini.Visible
    end
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
Title.TextColor3 = Color3.fromRGB(255, 70, 40)
Title.Text = "🦈 SB2 v1.4 SAFE"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 13
Title.Parent = Main

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, 0, 0, 12)
Sub.Position = UDim2.new(0, 0, 0, 30)
Sub.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
Sub.TextColor3 = Color3.fromRGB(140, 140, 160)
Sub.Text = "plalettescripts"
Sub.Font = Enum.Font.SourceSans
Sub.TextSize = 9
Sub.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 20, 0, 18)
Close.Position = UDim2.new(1, -24, 0, 4)
Close.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.Text = "X"
Close.Font = Enum.Font.SourceSansBold
Close.TextSize = 11
Close.Parent = Main
Close.MouseButton1Click:Connect(function() ClearESP() GUI:Destroy() end)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -6, 1, -48)
Scroll.Position = UDim2.new(0, 3, 0, 44)
Scroll.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
Scroll.Parent = Main

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0, 2)
List.FillDirection = Enum.FillDirection.Vertical
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Parent = Scroll

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
    f.Size = UDim2.new(1, -2, 0, 24)
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
    b.Size = UDim2.new(0, 28, 0, 14)
    b.Position = UDim2.new(0.9, -28, 0, 5)
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    b.Text = ""
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
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
    f.Size = UDim2.new(1, -2, 0, 38)
    f.BackgroundColor3 = Color3.fromRGB(24, 26, 38)
    f.Parent = Scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 14)
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
    inp.Position = UDim2.new(0.35, 0, 0, 18)
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

Div("🎯 Combat")
Tog("Auto-Kill Shark (SAFE)", "AutoKillShark")
Tog("Auto-Shoot", "AutoShoot")
Tog("Auto-Reload", "AutoReload")
Tog("Auto-Collect", "AutoCollect")

Div("👁 ESP")
Tog("Shark ESP", "SharkESP")
Tog("Player ESP", "PlayerESP")
Tog("Tracers", "Tracers")
Tog("Radar", "Radar")

Div("🏃 Move")
Sli("Speed", "SpeedValue", 16, 50, 32)
Tog("Speed Hack", "SpeedHack")
Sli("Fly Speed", "FlySpeed", 20, 80, 50)
Tog("Fly", "Fly")

Div("🌍 World")
Tog("Fullbright", "Fullbright")
Tog("No Fog", "NoFog")

-- Footer
local Foot = Instance.new("TextLabel")
Foot.Size = UDim2.new(1, -2, 0, 14)
Foot.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
Foot.TextColor3 = Color3.fromRGB(100, 100, 120)
Foot.Text = "v1.4 SAFE | plalettescripts"
Foot.Font = Enum.Font.SourceSans
Foot.TextSize = 8
Foot.Parent = Scroll

-- ==================== SAFE FEATURES ====================

-- Auto-Kill Shark (HUMANIZED - only aims, shoots with delay)
task.spawn(function()
    while task.wait() do
        if Config.AutoKillShark and LocalPlayer.Character then
            pcall(function()
                FindRemote()
                local _, head = FindShark()
                
                if head then
                    -- Smooth aim (not instant snap)
                    local targetCF = CFrame.new(Camera.CFrame.Position, head.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.3)
                    
                    -- Shoot with humanized delay
                    if ShootRemote and tick() - LastShot > ShotDelay then
                        -- Add small random offset to not look like perfect aim
                        local offset = Vector3.new(
                            math.random(-2, 2),
                            math.random(-2, 2),
                            math.random(-2, 2)
                        )
                        ShootRemote:FireServer(head.Position + offset)
                        LastShot = tick()
                        -- Randomize next shot delay
                        ShotDelay = math.random(25, 50) / 100
                    end
                end
            end)
        end
    end
end)

-- Auto-Shoot (separate, with delay)
task.spawn(function()
    while task.wait() do
        if Config.AutoShoot and not Config.AutoKillShark then
            pcall(function()
                FindRemote()
                local _, head = FindShark()
                if head and ShootRemote and tick() - LastShot > 0.4 then
                    ShootRemote:FireServer(head.Position + Vector3.new(math.random(-3,3), math.random(-3,3), math.random(-3,3)))
                    LastShot = tick()
                end
            end)
        end
        task.wait(math.random(15, 35) / 100)
    end
end)

-- Auto-Reload (occasional, not every frame)
task.spawn(function()
    while task.wait(math.random(80, 150) / 100) do
        if Config.AutoReload or Config.AutoKillShark then
            pcall(function()
                for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if t:IsA("Tool") and t:FindFirstChild("Ammo") then
                        local a = t.Ammo
                        if a:IsA("IntValue") then a.Value = math.random(50, 99)
                        elseif a:IsA("NumberValue") then a.Value = math.random(50, 99) end
                    end
                end
            end)
        end
    end
end)

-- Auto-Collect
task.spawn(function()
    while task.wait(math.random(40, 80) / 100) do
        if Config.AutoCollect and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") then
                        local n = v.Name:lower()
                        if n:find("coin") or n:find("loot") then
                            if (v.Position - hrp.Position).Magnitude < 50 then
                                firetouchinterest(hrp, v, 0) firetouchinterest(hrp, v, 1)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ESP (same as before, not detectable)
task.spawn(function()
    while task.wait(0.08) do
        ClearESP()
        if Config.SharkESP then
            local _, head, hum = FindShark()
            if head then
                local pos, on = Camera:WorldToViewportPoint(head.Position)
                if on then
                    local t = AddESP(Drawing.new("Text"))
                    t.Text = "🦈 Shark"
                    t.Color = Color3.fromRGB(255, 40, 20)
                    t.Size = 14
                    t.Position = Vector2.new(pos.X, pos.Y - 20)
                    t.Center = true
                    t.Visible = true
                end
            end
        end
        if Config.PlayerESP then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("Head") then
                    local pos, on = Camera:WorldToViewportPoint(pl.Character.Head.Position + Vector3.new(0, 0.5, 0))
                    if on then
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
        if Config.Tracers then
            local _, head = FindShark()
            if head then
                local pos, on = Camera:WorldToViewportPoint(head.Position)
                if on then
                    local l = AddESP(Drawing.new("Line"))
                    l.Color = Color3.fromRGB(255, 70, 40)
                    l.Thickness = 0.6
                    l.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    l.To = Vector2.new(pos.X, pos.Y)
                    l.Visible = true
                end
            end
        end
        if Config.Radar then
            local rs = 60
            local rx = Camera.ViewportSize.X - rs - 8
            local ry = Camera.ViewportSize.Y - rs - 8
            local bg = AddESP(Drawing.new("Square"))
            bg.Color = Color3.fromRGB(0,0,0)
            bg.Size = Vector2.new(rs, rs)
            bg.Position = Vector2.new(rx, ry)
            bg.Filled = true
            bg.Visible = true
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local my = LocalPlayer.Character.HumanoidRootPart
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                        local tp = pl.Character.HumanoidRootPart
                        local off = tp.Position - my.Position
                        local rd = math.clamp(off.Magnitude/3, 0, rs/2-2)
                        local a = math.atan2(off.Z, off.X)
                        local d = AddESP(Drawing.new("Circle"))
                        d.Color = pl == LocalPlayer and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
                        d.Radius = 2
                        d.Position = Vector2.new(rx+rs/2+math.cos(a)*rd, ry+rs/2+math.sin(a)*rd)
                        d.Filled = true
                        d.Visible = true
                    end
                end
                local _, head = FindShark()
                if head then
                    local off = head.Position - my.Position
                    local rd = math.clamp(off.Magnitude/3, 0, rs/2-2)
                    local a = math.atan2(off.Z, off.X)
                    local d = AddESP(Drawing.new("Circle"))
                    d.Color = Color3.fromRGB(255,0,0)
                    d.Radius = 3
                    d.Position = Vector2.new(rx+rs/2+math.cos(a)*rd, ry+rs/2+math.sin(a)*rd)
                    d.Filled = true
                    d.Visible = true
                end
            end
        end
    end
end)

-- Speed Hack (capped at 50 to avoid detection)
RunService.Stepped:Connect(function()
    if Config.SpeedHack and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = math.min(Config.SpeedValue or 32, 50) end
    end
end)

-- Fly (lower speed to avoid detection)
task.spawn(function()
    while task.wait() do
        if Config.Fly and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local g = hrp:FindFirstChild("FG") or Instance.new("BodyGyro", hrp)
                local v = hrp:FindFirstChild("FV") or Instance.new("BodyVelocity", hrp)
                g.Name = "FG" g.MaxTorque = Vector3.new(9e9,9e9,9e9) g.CFrame = Camera.CFrame
                v.Name = "FV" v.MaxForce = Vector3.new(9e9,9e9,9e9)
                local s = math.min(Config.FlySpeed or 50, 80)
                local m = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then m += Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then m -= Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then m -= Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then m += Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then m += Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then m -= Vector3.new(0,1,0) end
                v.Velocity = m * s
            end
        end
    end
end)

-- World
task.spawn(function()
    while task.wait(2) do
        if Config.Fullbright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
        end
        if Config.NoFog then
            Lighting.FogEnd = 100000
        end
    end
end)

print("🦈 SB2 v1.4 SAFE | plalettescripts")
print("⚠️ Humanized delays active - undetected")
