-- Load Fluent library
local function LoadFluent()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", true))()
    end)
    if not success or not result then
        error("Failed to load Fluent library: " .. (result or "Unknown error"))
    end
    return result
end
local Fluent = LoadFluent()
Fluent.Notify = function() end -- Disable all Fluent notifications

-- Create main window
local Window = Fluent:CreateWindow({
    Title = "civide.wtf",
    SubTitle = "By @han3t0_0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.Insert
})

-- Define tabs
local Tabs = {
    Visual = Window:AddTab({ Title = "Visual", Icon = "palette" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Wallhack = Window:AddTab({ Title = "Wallhack", Icon = "eye" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "sword" }),
    Utilities = Window:AddTab({ Title = "Utilities", Icon = "wrench" }),
    Troll = Window:AddTab({ Title = "Troll", Icon = "smile" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Centralized effect management for JumpEffect only
local EffectManager = {
    Effects = {},
    Connections = {},
    Objects = {},
    Active = {}
}

-- Register effect with enable and disable functions
function EffectManager:RegisterEffect(name, enableFunc, disableFunc)
    self.Effects[name] = { Enable = enableFunc, Disable = disableFunc }
end

-- Enable effect
function EffectManager:EnableEffect(name)
    if self.Effects[name] and not self.Active[name] then
        pcall(function()
            self.Effects[name].Enable()
            self.Active[name] = true
        end)
    end
end

-- Disable effect
function EffectManager:DisableEffect(name)
    if self.Effects[name] and self.Active[name] then
        pcall(function()
            self.Effects[name].Disable()
            self.Active[name] = false
        end)
    end
end

-- Clear only remaining effects
function EffectManager:ClearVisual()
    for name, _ in pairs(self.Active) do
        self:DisableEffect(name)
    end
    for _, conn in pairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, obj in pairs(self.Objects) do
        pcall(function() obj:Destroy() end)
    end
    self.Connections = {}
    self.Objects = {}
    self.Active = {}
end

-- Rainbow color function using HSV for smoother transitions
local function RainbowColor(time)
    local hue = (time * 0.3) % 1
    return Color3.fromHSV(hue, 1, 1)
end

-- Global rainbow update loop
local rainbow_updaters = {}
local rainbowConnection
local function StartRainbowLoop()
    if rainbowConnection then return end
    rainbowConnection = RunService.RenderStepped:Connect(function()
        local t = tick()
        for name, updater in pairs(rainbow_updaters) do
            pcall(updater, t)
        end
    end)
end

local function StopRainbowLoop()
    if rainbowConnection and next(rainbow_updaters) == nil then
        pcall(function() rainbowConnection:Disconnect() end)
        rainbowConnection = nil
    end
end

-- Rainbow UI Gradient
local uiGradientConnections = {}
task.spawn(function()
    task.wait(0.5)
    local CoreGui = game:GetService("CoreGui")
    local screenGui = CoreGui:FindFirstChild("Fluent")
    if not screenGui then return end

    local function ApplyGradient(obj)
        if not (obj:IsA("Frame") or obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
        obj.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        if not obj:FindFirstChild("UIGradient") then
            local gradient = Instance.new("UIGradient")
            gradient.Rotation = 45
            gradient.Parent = obj
            local conn
            conn = RunService.RenderStepped:Connect(function()
                if not obj or not obj.Parent or not gradient.Parent then
                    pcall(function() conn:Disconnect() end)
                    return
                end
                local t = tick() * 0.3
                local color1 = Color3.fromRGB(120 + math.sin(t*1.2)*20, 90 + math.sin(t)*15, 150 + math.sin(t*0.8)*20)
                local color2 = Color3.fromRGB(255, 180 + math.sin(t*0.5)*20, 200 + math.sin(t*0.7)*20)
                local color3 = Color3.fromRGB(10, 10, 20)
                gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, color1),
                    ColorSequenceKeypoint.new(0.5, color2),
                    ColorSequenceKeypoint.new(1, color3)
                })
            end)
            table.insert(uiGradientConnections, conn)
        end
        if obj.BorderSizePixel and obj.BorderSizePixel > 0 then
            obj.BorderColor3 = Color3.fromRGB(255, 140, 180)
        end
    end

    for _, obj in pairs(screenGui:GetDescendants()) do
        ApplyGradient(obj)
    end

    local descendantConn = screenGui.DescendantAdded:Connect(ApplyGradient)
    table.insert(uiGradientConnections, descendantConn)
end)

-- Player variables
local OriginalWalkSpeed = 16
local OriginalJumpPower = 50
local OriginalJumpHeight = 7.2
local OriginalUseJumpPower = true
local CurrentWalkSpeed = 16
local CurrentJumpPower = 50
local InfiniteJumpEnabled = false
local NoclipEnabled = false
local FlyEnabled = false
local FlySpeed = 50
local flyBodyVelocity
local flyConnection
local noclipConnection
local speedConnection
local jumpConnection
local trails = {}
local trailsCharConn
local particleEmitter
local particlesCharConn
local chinaHat
local chinaHatConn
local starTrailEmitter
local starTrailConn
local aimbotEnabled = false
local aimbotFOV = 100
local aimbotConnection
local fovCircle
local fovConnection
local lockedTarget = nil
local aimbotActive = false
local aimbotBind = "MB2"
local aimbotMode = "Hold"
local SpinbotEnabled = false
local SpinbotSpeed = 10
local spinbotConnection
local TeamCheckEnabled = false
local teamCheckConnection
local WallCheckEnabled = false
local wallCheckConnection
local espTextSize = 25
local espColor = Color3.fromRGB(255, 255, 255)
local espRed = 255
local espGreen = 255
local espBlue = 255

-- Bind mappings
local bindMap = {
    MB1 = {Type = "UserInputType", Value = Enum.UserInputType.MouseButton1},
    MB2 = {Type = "UserInputType", Value = Enum.UserInputType.MouseButton2},
    MB3 = {Type = "UserInputType", Value = Enum.UserInputType.MouseButton3},
    Q = {Type = "KeyCode", Value = Enum.KeyCode.Q},
    E = {Type = "KeyCode", Value = Enum.KeyCode.E},
    R = {Type = "KeyCode", Value = Enum.KeyCode.R},
    T = {Type = "KeyCode", Value = Enum.KeyCode.T},
    Y = {Type = "KeyCode", Value = Enum.KeyCode.Y},
    U = {Type = "KeyCode", Value = Enum.KeyCode.U},
    I = {Type = "KeyCode", Value = Enum.KeyCode.I},
    O = {Type = "KeyCode", Value = Enum.KeyCode.O},
    P = {Type = "KeyCode", Value = Enum.KeyCode.P},
    F = {Type = "KeyCode", Value = Enum.KeyCode.F},
    G = {Type = "KeyCode", Value = Enum.KeyCode.G},
    H = {Type = "KeyCode", Value = Enum.KeyCode.H},
    J = {Type = "KeyCode", Value = Enum.KeyCode.J},
    K = {Type = "KeyCode", Value = Enum.KeyCode.K},
    L = {Type = "KeyCode", Value = Enum.KeyCode.L},
    Z = {Type = "KeyCode", Value = Enum.KeyCode.Z},
    X = {Type = "KeyCode", Value = Enum.KeyCode.X},
    C = {Type = "KeyCode", Value = Enum.KeyCode.C},
    V = {Type = "KeyCode", Value = Enum.KeyCode.V},
    B = {Type = "KeyCode", Value = Enum.KeyCode.B},
    N = {Type = "KeyCode", Value = Enum.KeyCode.N},
    M = {Type = "KeyCode", Value = Enum.KeyCode.M},
    One = {Type = "KeyCode", Value = Enum.KeyCode.One},
    Two = {Type = "KeyCode", Value = Enum.KeyCode.Two},
    Three = {Type = "KeyCode", Value = Enum.KeyCode.Three},
    Four = {Type = "KeyCode", Value = Enum.KeyCode.Four},
    Five = {Type = "KeyCode", Value = Enum.KeyCode.Five},
    LShift = {Type = "KeyCode", Value = Enum.KeyCode.LeftShift},
    RShift = {Type = "KeyCode", Value = Enum.KeyCode.RightShift},
    LCtrl = {Type = "KeyCode", Value = Enum.KeyCode.LeftControl},
    RCtrl = {Type = "KeyCode", Value = Enum.KeyCode.RightControl},
    LAlt = {Type = "KeyCode", Value = Enum.KeyCode.LeftAlt},
    RAlt = {Type = "KeyCode", Value = Enum.KeyCode.RightAlt}
}

-- Function to check if input matches bind
local function IsMatchingInput(input)
    local bindInfo = bindMap[aimbotBind]
    if not bindInfo then return false end
    if bindInfo.Type == "UserInputType" then
        return input.UserInputType == bindInfo.Value
    elseif bindInfo.Type == "KeyCode" then
        return input.KeyCode == bindInfo.Value
    end
    return false
end

-- Function to check if target is visible (Wall Check)
local function IsVisible(localRoot, targetHead)
    if not localRoot or not targetHead then return false end
    local ray = Ray.new(localRoot.Position, (targetHead.Position - localRoot.Position).Unit * 1000)
    local ignoreList = {LocalPlayer.Character}
    local hit, _ = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    return hit == nil or hit:IsDescendantOf(targetHead.Parent)
end

-- Function to update ESP color
local function UpdateESPColor()
    espColor = Color3.fromRGB(espRed, espGreen, espBlue)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if player.Character:FindFirstChild("ESPHighlight") then
                player.Character.ESPHighlight.FillColor = espColor
                player.Character.ESPHighlight.OutlineColor = espColor
            end
            if player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("NameTag") then
                player.Character.Head.NameTag.TagLabel.TextColor3 = espColor
            end
            if player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart:FindFirstChild("DistanceTag") then
                player.Character.HumanoidRootPart.DistanceTag.TagLabel.TextColor3 = espColor
            end
        end
    end
end

-- Capture original WalkSpeed and JumpPower
local function CaptureOriginals(char)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if humanoid then
        OriginalWalkSpeed = humanoid.WalkSpeed
        OriginalJumpPower = humanoid.JumpPower
        OriginalJumpHeight = humanoid.JumpHeight
        OriginalUseJumpPower = humanoid.UseJumpPower
        CurrentWalkSpeed = math.max(CurrentWalkSpeed, OriginalWalkSpeed)
        CurrentJumpPower = math.max(CurrentJumpPower, OriginalJumpPower)
    end
end

if LocalPlayer.Character then
    CaptureOriginals(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(CaptureOriginals)

-- Jump Effect
EffectManager:RegisterEffect("Jump effect", function()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not root then return end

    local function CreateJumpEffect()
        local wave = Instance.new("Part")
        wave.Anchored = true
        wave.CanCollide = false
        wave.Size = Vector3.new(1, 0.2, 1)
        wave.Transparency = 0.5
        wave.Material = Enum.Material.Neon
        wave.Color = RainbowColor(tick())
        wave.Parent = workspace
        
        local mesh = Instance.new("CylinderMesh", wave)
        mesh.Scale = Vector3.new(0.1, 1, 0.1)
        
        local startPos = root.Position - Vector3.new(0, root.Size.Y/2 + 0.1, 0)
        wave.CFrame = CFrame.new(startPos) * CFrame.Angles(math.rad(90), 0, 0)
        
        local startTime = tick()
        local waveConn = RunService.RenderStepped:Connect(function()
            local t = tick() - startTime
            mesh.Scale = Vector3.new(2 + t * 8, 0.05, 2 + t * 8)
            wave.Transparency = math.clamp(0.3 + t*2, 0, 1)
            
            if t > 1 then
                waveConn:Disconnect()
                wave:Destroy()
            end
        end)
        table.insert(EffectManager.Connections, waveConn)
    end

    local conn = humanoid.Jumping:Connect(CreateJumpEffect)
    table.insert(EffectManager.Connections, conn)
    
    if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
        CreateJumpEffect()
    end
end, function()
    for _, conn in pairs(EffectManager.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    EffectManager.Connections = {}
end)

-- Visual Effects Module
local VisualEffects = {}

function VisualEffects:FireAura()
    self:ClearEffectByName("Fire aura")
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not root then return end
    
    local fire = Instance.new("Fire")
    fire.Name = "FireAura"
    fire.Size = 8
    fire.Heat = 5
    fire.Color = Color3.fromRGB(255, 100, 0)
    fire.SecondaryColor = Color3.fromRGB(255, 255, 0)
    fire.Parent = root
end

function VisualEffects:SmokeTrail()
    self:ClearEffectByName("Smoke trail")
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not root then return end
    
    local smoke = Instance.new("Smoke")
    smoke.Name = "SmokeTrail"
    smoke.Size = 2
    smoke.Color = Color3.fromRGB(200, 200, 200)
    smoke.RiseVelocity = 2
    smoke.Opacity = 0.3
    smoke.Parent = root
end

function VisualEffects:SparkleBody()
    self:ClearEffectByName("Body sparkles")
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not root then return end
    
    local sparkles = Instance.new("Sparkles")
    sparkles.Name = "BodySparkles"
    sparkles.SparkleColor = Color3.fromRGB(255, 255, 0)
    sparkles.Parent = root
end

function VisualEffects:ColorShift()
    self:ClearEffectByName("Color shift")
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not char then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ColorShift"
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.3
    highlight.Parent = char
    
    task.spawn(function()
        while highlight and highlight.Parent do
            for hue = 0, 1, 0.05 do
                if not highlight or not highlight.Parent then break end
                local color = Color3.fromHSV(hue, 1, 1)
                highlight.FillColor = color
                highlight.OutlineColor = color
                task.wait(0.2)
            end
        end
    end)
end

function VisualEffects:NeonGlow()
    self:ClearEffectByName("Neon glow")
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not char then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "NeonGlow"
    highlight.Adornee = char
    highlight.FillTransparency = 0.9
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = RainbowColor(tick())
    highlight.Parent = char
    
    rainbow_updaters["NeonGlow"] = function(t)
        if highlight and highlight.Parent then
            highlight.OutlineColor = RainbowColor(t)
        end
    end
    StartRainbowLoop()
end

function VisualEffects:StarTrail()
    self:ClearEffectByName("Star trail")
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not root then return end
    
    starTrailEmitter = Instance.new("ParticleEmitter")
    starTrailEmitter.Name = "StarTrail"
    starTrailEmitter.Parent = root
    starTrailEmitter.Size = NumberSequence.new(0.3)
    starTrailEmitter.Transparency = NumberSequence.new(0.2)
    starTrailEmitter.Lifetime = NumberRange.new(1)
    starTrailEmitter.Rate = 10
    starTrailEmitter.Speed = NumberRange.new(5)
    starTrailEmitter.VelocitySpread = 180
    starTrailEmitter.Rotation = NumberRange.new(0, 360)
    starTrailEmitter.Texture = "rbxassetid://243660364"
    starTrailEmitter.Color = ColorSequence.new(RainbowColor(tick()))
    starTrailEmitter.Enabled = true
    
    rainbow_updaters["StarTrail"] = function(t)
        if starTrailEmitter and starTrailEmitter.Parent then
            starTrailEmitter.Color = ColorSequence.new(RainbowColor(t))
        end
    end
    StartRainbowLoop()
end

function VisualEffects:ClearEffectByName(name)
    local char = LocalPlayer.Character
    if char then
        for _, effect in pairs(char:GetDescendants()) do
            if effect.Name == name then
                pcall(function() effect:Destroy() end)
            end
        end
    end
end

-- Highlight ESP Module
local HighlightESP = {}
local highlightESPConnection

function HighlightESP:CreateHighlight(player)
    local character = player.Character
    if character then
        local highlight = character:FindFirstChild("ESPHighlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "ESPHighlight"
            highlight.FillColor = espColor
            highlight.OutlineColor = espColor
            highlight.FillTransparency = 0.6
            highlight.OutlineTransparency = 0
            highlight.Adornee = character
            highlight.Parent = character
        end
    end
end

function HighlightESP:EnableESP()
    if highlightESPConnection then return end

    local function SetupHighlight(player)
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function(character)
                task.wait(0.5)
                HighlightESP:CreateHighlight(player)
            end)
            if player.Character then
                HighlightESP:CreateHighlight(player)
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        SetupHighlight(player)
    end

    highlightESPConnection = Players.PlayerAdded:Connect(SetupHighlight)
end

function HighlightESP:DisableESP()
    if highlightESPConnection then
        pcall(function() highlightESPConnection:Disconnect() end)
        highlightESPConnection = nil
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("ESPHighlight")
            if highlight then
                pcall(function() highlight:Destroy() end)
            end
        end
    end
end

-- Name ESP Module
local NameESP = {}
local nameESPConnection

function NameESP:CreateNameTag(player)
    local character = player.Character
    if character then
        local head = character:WaitForChild("Head", 10)
        if head then
            local billboard = head:FindFirstChild("NameTag")
            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Name = "NameTag"
                billboard.Adornee = head
                billboard.Size = UDim2.new(0, 130, 0, espTextSize)
                billboard.StudsOffset = Vector3.new(0, 2, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = head

                local textLabel = Instance.new("TextLabel")
                textLabel.Name = "TagLabel"
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundTransparency = 1
                textLabel.TextColor3 = espColor
                textLabel.Font = Enum.Font.Cartoon
                textLabel.TextScaled = true
                textLabel.TextStrokeTransparency = 0.6
                textLabel.Text = player.Name
                textLabel.Parent = billboard
