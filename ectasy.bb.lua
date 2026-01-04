-- ectasy.bb By hanetloveintim
-- Fixed by Highlight AI
-- Prison Life Script with Rayfield UI
-- Final Fix: Restored all Checks, Fixed Auto-Arrest, 6s ESP Refresh
-- Creator: miskabejbu

getgenv().Resolution = {
    [".gg/scripters"] = 1 -- 1 is normal, lower is wider/thicker
}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "ectasy.bb By hanetloveintim",
   LoadingTitle = "Welcome To Ectasy.bb prison life script",
   LoadingSubtitle = "by hanetloveintim",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "ectasy.bb"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = false
   },
   KeySystem = false
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Shared Variables
local AimlockEnabled = false
local AimlockActive = false
local TeamCheckEnabled = true
local WallCheckEnabled = true
local DiedCheckEnabled = true
local ForceFieldCheckEnabled = true

local FovEnabled = false
local FovSize = 100
local AimPart = "Head"
local PredictionAmount = 0.1
local SmoothnessAmount = 0.5
local AimMode = "Hold"
local AimKey = Enum.KeyCode.E
local UseRightClick = true 

local BhopEnabled = false
local BhopSpeed = 20
local InfJumpEnabled = false
local InfiniteStaminaEnabled = false
local AntiJumpDisabled = false 
local AutoArrestEnabled = false
local CustomFOV = 70

local ChamsEnabled = false
local NameEspEnabled = false

-- Drawing FOV Circle
local FovCircle = Drawing.new("Circle")
FovCircle.Thickness = 2
FovCircle.NumSides = 50
FovCircle.Radius = FovSize
FovCircle.Filled = false
FovCircle.Visible = false
FovCircle.ZIndex = 999
FovCircle.Transparency = 1

local CurrentTarget = nil
local EspObjects = {}

-- Functions
local function GetPlayerTeam(player)
    if player and player.Team then return player.Team.Name end
    return nil
end

local function GetMyTeamColor()
    local myTeam = GetPlayerTeam(LocalPlayer)
    if myTeam == "Guards" then
        return Color3.fromRGB(0, 0, 255)
    elseif myTeam == "Inmates" then
        return Color3.fromRGB(255, 165, 0)
    elseif myTeam == "Criminals" then
        return Color3.fromRGB(255, 0, 0)
    end
    return Color3.fromRGB(255, 255, 255)
end

local function GetPlayerColor(player)
    local team = GetPlayerTeam(player)
    if team == "Guards" then
        return Color3.fromRGB(0, 0, 255)
    elseif team == "Inmates" then
        return Color3.fromRGB(255, 165, 0)
    elseif team == "Criminals" then
        return Color3.fromRGB(255, 0, 0)
    end
    return Color3.fromRGB(255, 255, 255)
end

local function IsEnemy(player)
    if not TeamCheckEnabled then return true end
    return GetPlayerTeam(LocalPlayer) ~= GetPlayerTeam(player)
end

local function IsValidTarget(player)
    if not player.Character then return false end
    if DiedCheckEnabled then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then return false end
    end
    if ForceFieldCheckEnabled and player.Character:FindFirstChildOfClass("ForceField") then return false end
    return true
end

local function GetTargetPart(character)
    if AimPart == "Head" then
        return character:FindFirstChild("Head")
    else
        return character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
    end
end

local function CheckWall(targetPart)
    local Camera = workspace.CurrentCamera
    if not WallCheckEnabled then return true end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    return workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, raycastParams) == nil
end

local function GetClosestPlayerToCursor(maxDist)
    local Camera = workspace.CurrentCamera
    local closestPlayer = nil
    local shortestDistance = maxDist
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and IsValidTarget(player) then
            local part = GetTargetPart(player.Character)
            if part and IsEnemy(player) then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and CheckWall(part) then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- ESP Updates
local function ClearEsp()
    for _, obj in pairs(EspObjects) do
        if typeof(obj) == "Instance" then obj:Destroy() end
    end
    EspObjects = {}
end

local function UpdateEsp()
    ClearEsp()
    if not (ChamsEnabled or NameEspEnabled) then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if ChamsEnabled then
                local highlight = Instance.new("Highlight", player.Character)
                highlight.FillColor = GetPlayerColor(player)
                highlight.OutlineColor = Color3.new(1, 1, 1)
                highlight.FillTransparency = 0.5
                table.insert(EspObjects, highlight)
            end
            if NameEspEnabled and player.Character:FindFirstChild("Head") then
                local billboard = Instance.new("BillboardGui", player.Character.Head)
                billboard.AlwaysOnTop, billboard.Size = true, UDim2.new(0, 100, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 2, 0)
                local textLabel = Instance.new("TextLabel", billboard)
                textLabel.Size, textLabel.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
                textLabel.Text, textLabel.TextColor3 = player.Name, GetPlayerColor(player)
                textLabel.Font, textLabel.TextSize = Enum.Font.SourceSansBold, 14
                table.insert(EspObjects, billboard)
            end
        end
    end
end

-- TABS
local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- Combat Tab
CombatTab:CreateSection("Aimlock Settings")
CombatTab:CreateToggle({Name = "Enable Aimlock", CurrentValue = false, Flag = "AimlockToggle", Callback = function(Value) AimlockEnabled = Value AimlockActive = false end})
CombatTab:CreateToggle({Name = "Use Right Click", CurrentValue = true, Flag = "RightClickToggle", Callback = function(Value) UseRightClick = Value end})
CombatTab:CreateDropdown({Name = "Aim Mode", Options = {"Hold", "Toggle"}, CurrentOption = "Hold", Flag = "AimModeDropdown", Callback = function(Value) AimMode = Value AimlockActive = false end})
CombatTab:CreateKeybind({Name = "Aim Key", CurrentKeybind = "E", HoldToInteract = false, Flag = "AimKeybind", Callback = function(Key) AimKey = Key end})
CombatTab:CreateDropdown({Name = "Aim Part", Options = {"Head", "Torso"}, CurrentOption = "Head", Flag = "AimPartDropdown", Callback = function(Value) AimPart = Value end})
CombatTab:CreateSlider({Name = "Prediction", Range = {0, 1}, Increment = 0.01, Suffix = "", CurrentValue = 0.1, Flag = "PredictionSlider", Callback = function(Value) PredictionAmount = Value end})
CombatTab:CreateSlider({Name = "Smoothness", Range = {0, 1}, Increment = 0.01, Suffix = "", CurrentValue = 0.5, Flag = "SmoothnessSlider", Callback = function(Value) SmoothnessAmount = Value end})

CombatTab:CreateSection("Targeting Checks")
CombatTab:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "TeamCheckToggle", Callback = function(Value) TeamCheckEnabled = Value end})
CombatTab:CreateToggle({Name = "Wall Check", CurrentValue = true, Flag = "WallCheckToggle", Callback = function(Value) WallCheckEnabled = Value end})
CombatTab:CreateToggle({Name = "Died Check", CurrentValue = true, Flag = "DiedCheckToggle", Callback = function(Value) DiedCheckEnabled = Value end})
CombatTab:CreateToggle({Name = "ForceField Check", CurrentValue = true, Flag = "FFCheckToggle", Callback = function(Value) ForceFieldCheckEnabled = Value end})

CombatTab:CreateSection("FOV Settings")
CombatTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = false, Flag = "FovToggle", Callback = function(Value) FovEnabled = Value FovCircle.Visible = Value end})
CombatTab:CreateSlider({Name = "FOV Size", Range = {50, 800}, Increment = 10, Suffix = "px", CurrentValue = 100, Flag = "FovSlider", Callback = function(Value) FovSize = Value FovCircle.Radius = Value end})

CombatTab:CreateSection("Auto Arrest")
CombatTab:CreateToggle({Name = "Auto Arrest (Guard Only)", CurrentValue = false, Flag = "AutoArrestToggle", Callback = function(Value) AutoArrestEnabled = Value end})

-- Visuals Tab
VisualsTab:CreateToggle({Name = "Chams", CurrentValue = false, Flag = "ChamsToggle", Callback = function(Value) ChamsEnabled = Value UpdateEsp() end})
VisualsTab:CreateToggle({Name = "Name ESP", CurrentValue = false, Flag = "NameEspToggle", Callback = function(Value) NameEspEnabled = Value UpdateEsp() end})

-- Movement Tab
MovementTab:CreateToggle({Name = "Infinite Stamina", CurrentValue = false, Flag = "StaminaToggle", Callback = function(Value) InfiniteStaminaEnabled = Value end})
MovementTab:CreateToggle({Name = "Bhop", CurrentValue = false, Flag = "BhopToggle", Callback = function(Value) BhopEnabled = Value end})
MovementTab:CreateSlider({Name = "Bhop Power", Range = {1, 100}, Increment = 1, Suffix = "", CurrentValue = 20, Flag = "BhopSlider", Callback = function(Value) BhopSpeed = Value end})
MovementTab:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Flag = "InfJumpToggle", Callback = function(Value) InfJumpEnabled = Value end})
MovementTab:CreateToggle({Name = "Disable Anti-Jump Plugin", CurrentValue = false, Flag = "AntiJumpToggle", Callback = function(Value) AntiJumpDisabled = Value end})

-- Misc Tab
MiscTab:CreateSlider({Name = "FOV Changer", Range = {30, 120}, Increment = 1, Suffix = "°", CurrentValue = 70, Flag = "FOVSlider", Callback = function(Value) CustomFOV = Value end})
MiscTab:CreateSlider({Name = "Stretch Amount", Range = {0.3, 1.5}, Increment = 0.05, Suffix = "x", CurrentValue = 1, Flag = "StretchSlider", Callback = function(Value) getgenv().Resolution[".gg/scripters"] = Value end})

-- Camera & Stretch Rendering
RunService:BindToRenderStep("ectasy.bb_Camera", Enum.RenderPriority.Camera.Value + 1, function()
    local Camera = workspace.CurrentCamera
    local FinalCFrame = Camera.CFrame

    if AimlockEnabled and AimlockActive then
        CurrentTarget = GetClosestPlayerToCursor(FovSize)
        if CurrentTarget and CurrentTarget.Character then
            local part = GetTargetPart(CurrentTarget.Character)
            if part then
                local targetPos = part.Position
                local hrp = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
                if hrp and PredictionAmount > 0 then
                    targetPos = targetPos + (hrp.AssemblyLinearVelocity * PredictionAmount)
                end
                
                local targetRotation = CFrame.lookAt(Camera.CFrame.Position, targetPos)
                if SmoothnessAmount > 0 then
                    FinalCFrame = Camera.CFrame:Lerp(targetRotation, 1 - SmoothnessAmount)
                else
                    FinalCFrame = targetRotation
                end
            end
        end
    end

    Camera.FieldOfView = CustomFOV
    local stretch = getgenv().Resolution[".gg/scripters"]
    local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = FinalCFrame:GetComponents()
    Camera.CFrame = CFrame.new(x, y, z, R00, R01, R02, R10, R11 * stretch, R12, R20, R21, R22)
end)

-- Constant Loops
RunService.RenderStepped:Connect(function()
    if BhopEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local h = LocalPlayer.Character.Humanoid
        if h.MoveDirection.Magnitude > 0 and (h:GetState() == Enum.HumanoidStateType.Jumping or h:GetState() == Enum.HumanoidStateType.Freefall) then
            LocalPlayer.Character.HumanoidRootPart.CFrame += (h.MoveDirection * BhopSpeed / 100)
        end
    end

    if InfiniteStaminaEnabled then
        pcall(function()
            if LocalPlayer.Character:FindFirstChild("Stamina") then LocalPlayer.Character.Stamina.Value = 100 end
            if getrenv and getrenv()._G then getrenv()._G.stamina = 100 end
        end)
    end
    
    if InfJumpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            local Hum = LocalPlayer.Character.Humanoid
            Hum:ChangeState(Enum.HumanoidStateType.Jumping)
            Hum.Jump = true
        end
    end
    
    if FovEnabled then
        FovCircle.Position = UserInputService:GetMouseLocation()
        FovCircle.Color = GetMyTeamColor()
        FovCircle.Visible = true
    else FovCircle.Visible = false end
end)

-- Faster Auto Arrest Loop
task.spawn(function()
    while task.wait(0.1) do
        if AutoArrestEnabled and GetPlayerTeam(LocalPlayer) == "Guards" then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                    local team = GetPlayerTeam(p)
                    if team == "Inmates" or team == "Criminals" then
                        local dist = (LocalPlayer.Character:GetPivot().Position - p.Character:GetPivot().Position).Magnitude
                        if dist < 18 then -- Increased distance slightly for reliability
                            workspace.Remote.arrest:FireServer(p.Character.Head)
                        end
                    end
                end
            end
        end
    end
end)

-- Input Logic
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local isAimKey = (UseRightClick and input.UserInputType == Enum.UserInputType.MouseButton2) or (not UseRightClick and input.KeyCode == AimKey)
    if isAimKey and AimlockEnabled then
        if AimMode == "Toggle" then AimlockActive = not AimlockActive else AimlockActive = true end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local isAimKey = (UseRightClick and input.UserInputType == Enum.UserInputType.MouseButton2) or (not UseRightClick and input.KeyCode == AimKey)
    if isAimKey and AimMode == "Hold" then AimlockActive = false end
end)

-- Anti-Jump Loop
task.spawn(function()
    while task.wait(0.1) do
        if AntiJumpDisabled and LocalPlayer.Character then
            local antiJump = LocalPlayer.Character:FindFirstChild("Anti-Jump") or LocalPlayer.Character:FindFirstChild("AntiJump")
            if antiJump then antiJump.Disabled = true end
            if LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = 50
            end
        end
    end
end)

-- 6 Second ESP Refresh Loop
task.spawn(function()
    while task.wait(6) do
        if ChamsEnabled or NameEspEnabled then
            UpdateEsp()
        end
    end
end)

getgenv().gg_scripters = "hanetloveintim"
UpdateEsp()
