-- civividewtf By hanetloveintim
-- Fixed by Highlight AI
-- Prison Life Script with Rayfield UI

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "civividewtf By hanetloveintim",
   LoadingTitle = "Prison Life Script",
   LoadingSubtitle = "by miskabejbu",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "civividewtf"
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
local Camera = workspace.CurrentCamera
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
local ArrestAuraEnabled = false
local ArrestAuraDistance = 15
local ChamsEnabled = false
local NameEspEnabled = false
local TracersEnabled = false
local StretchEnabled = false
local StretchValue = 1

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
    if not player.Character then return nil end
    if player.Team then return player.Team.Name end
    local teamValue = player.Character:FindFirstChild("TeamC") or player.Character:FindFirstChild("Team")
    if teamValue then return teamValue.Value end
    return nil
end

local function GetMyTeamColor()
    local myTeam = GetPlayerTeam(LocalPlayer)
    if myTeam == "Inmates" or myTeam == "Prisoner" or myTeam == "Medium stone grey" then
        return Color3.fromRGB(255, 165, 0)
    elseif myTeam == "Guards" or myTeam == "Guard" or myTeam == "Bright blue" then
        return Color3.fromRGB(0, 0, 255)
    elseif myTeam == "Criminals" or myTeam == "Criminal" or myTeam == "Bright orange" then
        return Color3.fromRGB(255, 0, 0)
    end
    return Color3.fromRGB(255, 255, 255)
end

local function GetPlayerColor(player)
    local team = GetPlayerTeam(player)
    if team == "Inmates" or team == "Prisoner" or team == "Medium stone grey" then
        return Color3.fromRGB(255, 165, 0)
    elseif team == "Guards" or team == "Guard" or team == "Bright blue" then
        return Color3.fromRGB(0, 0, 255)
    elseif team == "Criminals" or team == "Criminal" or team == "Bright orange" then
        return Color3.fromRGB(255, 0, 0)
    end
    return Color3.fromRGB(255, 255, 255)
end

local function IsEnemy(player)
    if not TeamCheckEnabled then return true end
    local myTeam = GetPlayerTeam(LocalPlayer)
    local theirTeam = GetPlayerTeam(player)
    return myTeam ~= theirTeam
end

local function IsValidTarget(player)
    if not player.Character then return false end
    if DiedCheckEnabled then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then return false end
    end
    if ForceFieldCheckEnabled then
        if player.Character:FindFirstChildOfClass("ForceField") then return false end
    end
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
    if not WallCheckEnabled then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local rayResult = workspace:Raycast(origin, direction, raycastParams)
    return rayResult == nil
end

local function GetClosestPlayerToCursor(maxDist)
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

-- ESP Functions
local function CreateChams(character, player)
    local highlight = Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = GetPlayerColor(player)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    table.insert(EspObjects, highlight)
end

local function CreateNameEsp(character, player)
    local head = character:FindFirstChild("Head")
    if not head then return end
    local billboard = Instance.new("BillboardGui", head)
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    local textLabel = Instance.new("TextLabel", billboard)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.Name
    textLabel.TextColor3 = GetPlayerColor(player)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    table.insert(EspObjects, billboard)
end

local function CreateTracers(character, player)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local line = Drawing.new("Line")
    line.Visible = true
    line.Thickness = 2
    table.insert(EspObjects, {Type = "Tracer", Line = line, Character = character, Player = player})
end

local function ClearEsp()
    for _, obj in pairs(EspObjects) do
        if typeof(obj) == "Instance" then obj:Destroy()
        elseif typeof(obj) == "table" and obj.Line then obj.Line:Remove() end
    end
    EspObjects = {}
end

local function UpdateEsp()
    ClearEsp()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if ChamsEnabled then CreateChams(player.Character, player) end
            if NameEspEnabled then CreateNameEsp(player.Character, player) end
            if TracersEnabled then CreateTracers(player.Character, player) end
        end
    end
end

local function UpdateTracers()
    for _, obj in pairs(EspObjects) do
        if typeof(obj) == "table" and obj.Type == "Tracer" then
            local hrp = obj.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    obj.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    obj.Line.To = Vector2.new(screenPos.X, screenPos.Y)
                    obj.Line.Color = GetPlayerColor(obj.Player)
                    obj.Line.Visible = true
                else obj.Line.Visible = false end
            else obj.Line.Visible = false end
        end
    end
end

-- Tabs
local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

CombatTab:CreateSection("Aimlock Settings")
CombatTab:CreateToggle({Name = "Enable Aimlock", CurrentValue = false, Flag = "AimlockToggle", Callback = function(Value) AimlockEnabled = Value AimlockActive = false end})
CombatTab:CreateToggle({Name = "Use Right Click", CurrentValue = true, Flag = "RightClickToggle", Callback = function(Value) UseRightClick = Value end})
CombatTab:CreateDropdown({Name = "Aim Mode", Options = {"Hold", "Toggle"}, CurrentOption = "Hold", Flag = "AimModeDropdown", Callback = function(Value) AimMode = Value AimlockActive = false end})
CombatTab:CreateKeybind({Name = "Aim Key", CurrentKeybind = "E", HoldToInteract = false, Flag = "AimKeybind", Callback = function(Key) AimKey = Key end})
CombatTab:CreateDropdown({Name = "Aim Part", Options = {"Head", "Torso"}, CurrentOption = "Head", Flag = "AimPartDropdown", Callback = function(Value) AimPart = Value end})
CombatTab:CreateSlider({Name = "Prediction", Range = {0, 1}, Increment = 0.01, Suffix = "", CurrentValue = 0.1, Flag = "PredictionSlider", Callback = function(Value) PredictionAmount = Value end})
CombatTab:CreateSlider({Name = "Smoothness", Range = {0, 1}, Increment = 0.01, Suffix = "", CurrentValue = 0.5, Flag = "SmoothnessSlider", Callback = function(Value) SmoothnessAmount = Value end})
CombatTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = false, Flag = "FovToggle", Callback = function(Value) FovEnabled = Value FovCircle.Visible = Value end})
CombatTab:CreateSlider({Name = "FOV Size", Range = {50, 800}, Increment = 10, Suffix = "px", CurrentValue = 100, Flag = "FovSlider", Callback = function(Value) FovSize = Value FovCircle.Radius = Value end})

CombatTab:CreateSection("Checks")
CombatTab:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "TeamCheckToggle", Callback = function(Value) TeamCheckEnabled = Value end})
CombatTab:CreateToggle({Name = "Wall Check", CurrentValue = true, Flag = "WallCheckToggle", Callback = function(Value) WallCheckEnabled = Value end})
CombatTab:CreateToggle({Name = "Died Check", CurrentValue = true, Flag = "DiedCheckToggle", Callback = function(Value) DiedCheckEnabled = Value end})
CombatTab:CreateToggle({Name = "ForceField Check", CurrentValue = true, Flag = "FFCheckToggle", Callback = function(Value) ForceFieldCheckEnabled = Value end})

VisualsTab:CreateSection("ESP")
VisualsTab:CreateToggle({Name = "Chams", CurrentValue = false, Flag = "ChamsToggle", Callback = function(Value) ChamsEnabled = Value UpdateEsp() end})
VisualsTab:CreateToggle({Name = "Name ESP", CurrentValue = false, Flag = "NameEspToggle", Callback = function(Value) NameEspEnabled = Value UpdateEsp() end})
VisualsTab:CreateToggle({Name = "Tracers", CurrentValue = false, Flag = "TracersToggle", Callback = function(Value) TracersEnabled = Value UpdateEsp() end})

MovementTab:CreateSection("Movement")
MovementTab:CreateToggle({Name = "Infinite Stamina (No Jump Drain)", CurrentValue = false, Flag = "StaminaToggle", Callback = function(Value) InfiniteStaminaEnabled = Value end})
MovementTab:CreateToggle({Name = "Bhop (Jump Acceleration)", CurrentValue = false, Flag = "BhopToggle", Callback = function(Value) BhopEnabled = Value end})
MovementTab:CreateSlider({Name = "Bhop Power", Range = {1, 100}, Increment = 1, Suffix = "", CurrentValue = 20, Flag = "BhopSlider", Callback = function(Value) BhopSpeed = Value end})
MovementTab:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Flag = "InfJumpToggle", Callback = function(Value) InfJumpEnabled = Value end})

MiscTab:CreateSection("Misc")
MiscTab:CreateToggle({Name = "Stretch Resolution", CurrentValue = false, Flag = "StretchToggle", Callback = function(Value) StretchEnabled = Value if Value then Camera.FieldOfView = 120 else Camera.FieldOfView = 70 end end})
MiscTab:CreateSlider({Name = "Stretch Amount", Range = {1, 3}, Increment = 0.1, Suffix = "x", CurrentValue = 1, Flag = "StretchSlider", Callback = function(Value) StretchValue = Value if StretchEnabled then Camera.FieldOfView = 70 * Value end end})

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

-- Main Loop
RunService.RenderStepped:Connect(function()
    -- Aimlock Logic
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
                    Camera.CFrame = Camera.CFrame:Lerp(targetRotation, 1 - SmoothnessAmount)
                else
                    Camera.CFrame = targetRotation
                end
            end
        end
    end
    
    -- Bhop Logic
    if BhopEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        if humanoid.MoveDirection.Magnitude > 0 then
            if humanoid:GetState() == Enum.HumanoidStateType.Jumping or humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + (humanoid.MoveDirection * BhopSpeed / 100)
            end
        end
    end

    -- Infinite Stamina Logic (Aggressive reset)
    if InfiniteStaminaEnabled then
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Stamina") then
                LocalPlayer.Character.Stamina.Value = 100
            end
            if getrenv and getrenv()._G then
                getrenv()._G.stamina = 100
            end
        end)
    end
    
    -- Fix for Infinite Jump releasing (Continuous state check)
    if InfJumpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
    
    if FovEnabled then
        FovCircle.Position = UserInputService:GetMouseLocation()
        FovCircle.Color = GetMyTeamColor()
        FovCircle.Visible = true
    else FovCircle.Visible = false end

    if TracersEnabled then UpdateTracers() end
end)

task.spawn(function()
    while task.wait(5) do
        if ChamsEnabled or NameEspEnabled or TracersEnabled then UpdateEsp() end
    end
end)

UpdateEsp()
