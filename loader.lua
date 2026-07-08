-- Shark Bite 2 Script v1.2 | plalettescripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = {}
local ESP = {}
local ShootRemote = nil

local function ClearESP()
    for _, d in pairs(ESP) do pcall(function() d:Remove() end) end
    ESP = {}
end

local function AddESP(d)
    if #ESP > 80 then table.remove(ESP, 1):Remove() end
    table.insert(ESP, d)
end

-- Hai finden
local function GetShark()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find("shark") then
            local h = v:FindFirstChildOfClass("Humanoid")
            local p = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Head")
            if h and h.Health > 0 and p then return v, p, h end
        end
    end
    return nil, nil, nil
end

-- Remote finden
local function GetRemote()
    if ShootRemote then return end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") then ShootRemote = v break end
    end
end

-- Kleines GUI (200x280, oben rechts)
local GUI = Instance.new("ScreenGui")
GUI.Name = "SB2"
GUI.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 200, 0, 280)
Main.Position = UDim2.new(0.82, 0, 0.08, 0)
Main.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Border = Instance.new("Frame")
Border.Size = UDim2.new(1, 3, 1, 3)
Border.Position = UDim2.new(0, -1.5, 0, -1.5)
Border.BackgroundColor3 = Color3.fromRGB(255, 60, 30)
Border.BorderSizePixel = 0
Border.Parent = Main
Instance.new("UICorner", Border).CornerRadius = UDim.new(0, 9)

task.spawn(function()
    local h = 0.05
    while GUI and GUI.Parent do
        h = (h + 0.004) % 0.15 + 0.05
        pcall(function() Border.BackgroundColor3 = Color3.fromHSV(h, 1, 1) end)
        task.wait(0.04)
    end
end)

-- Titel
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 28)
Title.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
Title.TextColor3 = Color3.fromRGB(255, 80, 40)
Title.Text = "🦈 SB2 v1.2"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.Parent = Main

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, 0, 0, 14)
Sub.Position = UDim2.new(0, 0, 0, 28)
Sub.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
Sub.TextColor3 = Color3.fromRGB(150, 150, 170)
Sub.Text = "plalettescripts"
Sub.Font = Enum.Font.SourceSans
Sub.TextSize = 9
Sub.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 22, 0, 20)
Close.Position = UDim2.new(1, -26, 0, 4)
Close.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.Text = "X"
Close.Font = Enum.Font.SourceSansBold
Close.TextSize = 12
Close.Parent = Main
Close.MouseButton1Click:Connect(function() ClearESP() GUI:Destroy() end)

-- Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -8, 1, -50)
Scroll.Position = UDim2.new(0, 4, 0, 45)
Scroll.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 60, 30)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
Scroll.Parent = Main

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0, 2)
List.FillDirection = Enum.FillDirection.Vertical
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Parent = Scroll

-- Divider
local function Div(t)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -2, 0, 16)
    f.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
    f.Parent = Scroll
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(255, 100, 60)
    l.Text = t
    l.Font = Enum.Font.SourceSansBold
    l.TextSize = 9
    l.Parent = f
end

-- Toggle
local function Tog(name, key)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -2, 0, 24)
    f.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
    f.Parent = Scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.5, 0, 1, 0)
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
    b.Position = UDim2.new(0.92, -28, 0, 5)
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    b.Text = ""
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)

    local on = false
    b.MouseButton1Click:Connect(function()
        on = not on
        Settings[key] = on
        l.Text = name .. ": " .. (on and "ON" or "OFF")
        b.BackgroundColor3 = on and Color3.fromRGB(255, 60, 30) or Color3.fromRGB(50, 50, 65)
    end)
end

-- Slider
local function Sli(name, key, min, max, def)
    Settings[key] = def
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -2, 0, 38)
    f.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
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
    inp.Size = UDim2.new(0.3, 0, 0, 18)
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
            Settings[key] = v
            l.Text = name .. ": " .. v
        else
            inp.Text = tostring(Settings[key])
        end
    end)
end

-- Button
local function Btn(name, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -2, 0, 22)
    b.BackgroundColor3 = Color3.fromRGB(0, 150, 180)
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = name
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 10
    b.Parent = Scroll
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(cb)
end

-- GUI Inhalt
Div("⚡ Combat")
Tog("Auto Kill Shark", "AutoKill")
Tog("Auto Aim", "AutoAim")
Sli("Aim FOV", "AimFOV", 50, 400, 200)
Tog("Instant Reload", "Reload")
Tog("Auto Collect", "AutoLoot")

Div("👁 ESP")
Tog("Shark ESP", "SharkESP")
Tog("Player ESP", "PlayerESP")
Tog("Tracer", "Tracer")
Tog("Radar", "Radar")

Div("🏃 Move")
Sli("Speed", "Speed", 16, 100, 32)
Tog("Speed Hack", "SpeedHack")
Sli("Fly Speed", "FlySpeed", 20, 150, 50)
Tog("Fly", "Fly")

Div("🦈 Shark Mode")
Tog("Auto Kill Player", "AutoKillP")

Div("⚙ Other")
Btn("Teleport to Shark", function()
    local s, p = GetShark()
    if s and p and LocalPlayer.Character then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(p.Position + Vector3.new(0, 5, 0))
    end
end)
Tog("Fullbright", "FB")
Tog("No Fog", "NF")

-- Footer
local Foot = Instance.new("TextLabel")
Foot.Size = UDim2.new(1, -2, 0, 14)
Foot.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
Foot.TextColor3 = Color3.fromRGB(100, 100, 120)
Foot.Text = "v1.2 | plalettescripts"
Foot.Font = Enum.Font.SourceSans
Foot.TextSize = 8
Foot.Parent = Scroll

-- ==================== FEATURES ====================

-- Auto Kill Shark (0ms, kein Limit)
task.spawn(function()
    while task.wait() do
        if Settings.AutoKill then
            pcall(function()
                GetRemote()
                local s, p = GetShark()
                if s and p and ShootRemote then
                    for _ = 1, 3 do
                        ShootRemote:FireServer(p.Position)
                    end
                end
            end)
        end
    end
end)

-- Auto Aim
task.spawn(function()
    while task.wait(0.02) do
        if Settings.AutoAim and LocalPlayer.Character then
            local _, p = GetShark()
            if p then
                local sp, on = Camera:WorldToViewportPoint(p.Position)
                if on and (Vector2.new(sp.X, sp.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude < (Settings.AimFOV or 200) then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, p.Position)
                end
            end
        end
    end
end)

-- Instant Reload
task.spawn(function()
    while task.wait(0.1) do
        if Settings.Reload then
            pcall(function()
                for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if t:IsA("Tool") and t:FindFirstChild("Ammo") then t.Ammo.Value = 99 end
                end
                local ct = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if ct and ct:FindFirstChild("Ammo") then ct.Ammo.Value = 99 end
            end)
        end
    end
end)

-- Auto Collect
task.spawn(function()
    while task.wait(0.2) do
        if Settings.AutoLoot and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("loot") or v.Name:lower():find("coin")) then
                        if (v.Position - hrp.Position).Magnitude < 60 then
                            firetouchinterest(hrp, v, 0) firetouchinterest(hrp, v, 1)
                        end
                    end
                end
            end
        end
    end
end)

-- ESP
task.spawn(function()
    while task.wait(0.05) do
        ClearESP()
        
        -- Shark ESP
        if Settings.SharkESP then
            local _, p, h = GetShark()
            if p then
                local pos, on = Camera:WorldToViewportPoint(p.Position)
                if on then
                    local t = AddESP(Drawing.new("Text"))
                    t.Text = "🦈 Shark"
                    t.Color = Color3.fromRGB(255, 50, 30)
                    t.Size = 14
                    t.Position = Vector2.new(pos.X, pos.Y - 20)
                    t.Center = true
                    t.Visible = true
                end
            end
        end
        
        -- Player ESP
        if Settings.PlayerESP then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("Head") then
                    local hp, on = Camera:WorldToViewportPoint(pl.Character.Head.Position + Vector3.new(0, 0.5, 0))
                    if on then
                        local t = AddESP(Drawing.new("Text"))
                        t.Text = pl.Name
                        t.Color = Color3.fromRGB(255, 255, 255)
                        t.Size = 11
                        t.Position = Vector2.new(hp.X, hp.Y)
                        t.Center = true
                        t.Visible = true
                    end
                end
            end
        end
        
        -- Tracer
        if Settings.Tracer then
            local _, p = GetShark()
            if p then
                local pos, on = Camera:WorldToViewportPoint(p.Position)
                if on then
                    local l = AddESP(Drawing.new("Line"))
                    l.Color = Color3.fromRGB(255, 80, 50)
                    l.Thickness = 0.8
                    l.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    l.To = Vector2.new(pos.X, pos.Y)
                    l.Visible = true
                end
            end
        end
        
        -- Radar
        if Settings.Radar then
            local rs = 70
            local rx = Camera.ViewportSize.X - rs - 8
            local ry = Camera.ViewportSize.Y - rs - 8
            local bg = AddESP(Drawing.new("Square"))
            bg.Color = Color3.fromRGB(0, 0, 0)
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
                local _, p = GetShark()
                if p then
                    local off = p.Position - my.Position
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

-- Speed Hack
RunService.Stepped:Connect(function()
    if Settings.SpeedHack and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = Settings.Speed or 32 end
    end
end)

-- Fly
task.spawn(function()
    while task.wait() do
        if Settings.Fly and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local g = hrp:FindFirstChild("FG") or Instance.new("BodyGyro", hrp)
                local v = hrp:FindFirstChild("FV") or Instance.new("BodyVelocity", hrp)
                g.Name = "FG" g.MaxTorque = Vector3.new(9e9,9e9,9e9) g.CFrame = Camera.CFrame
                v.Name = "FV" v.MaxForce = Vector3.new(9e9,9e9,9e9)
                local s = Settings.FlySpeed or 50
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

-- Fullbright & No Fog
task.spawn(function()
    while task.wait(1) do
        if Settings.FB then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        end
        if Settings.NF then
            Lighting.FogEnd = 1000000
            Lighting.FogStart = 0
        end
    end
end)

-- Anti-AFK
task.spawn(function()
    while task.wait(120) do
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
        end)
    end
end)

print("🦈 Shark Bite 2 v1.2 | plalettescripts")
