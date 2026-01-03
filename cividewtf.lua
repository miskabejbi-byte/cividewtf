-- civividewtf By hanetloveintim
-- Prison Life Script with Rayfield UI

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "civividewtf By hanetloveintim",
   LoadingTitle = "Prison Life Script",
   LoadingSubtitle = "by hanetloveintim",
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

local AimlockEnabled = false
local ArrestAuraEnabled = false
local TeamCheckEnabled = true
local ChamsEnabled = false
local NameEspEnabled = false
local TracersEnabled = false
local FovEnabled = false
local InfJumpEnabled = false
local StretchEnabled = false
local FovSize = 100
local StretchValue = 1
local RightMouseDown = false
local ArrestAuraDistance = 15

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

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = FovSize
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if IsEnemy(player) then
                local head = player.Character.Head
                local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
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

local function ArrestAura()
    if not ArrestAuraEnabled then return end
    local myTeam = GetPlayerTeam(LocalPlayer)
    if myTeam ~= "Guards" and myTeam ~= "Guard" and myTeam ~= "Bright blue" then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local theirTeam = GetPlayerTeam(player)
            if theirTeam == "Criminals" or theirTeam == "Criminal" or theirTeam == "Bright orange" then
                local theirHRP = player.Character:FindFirstChild("HumanoidRootPart")
                if theirHRP then
                    local distance = (myPos - theirHRP.Position).Magnitude
                    if distance <= ArrestAuraDistance then
                        pcall(function()
                            workspace.Remote.arrest:InvokeServer(player.Character)
                        end)
                    end
                end
            end
        end
    end
end

local function CreateChams(character, player)
    local highlight = Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = GetPlayerColor(player)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = true
    table.insert(EspObjects, highlight)
end

local function CreateNameEsp(character, player)
    local head = character:FindFirstChild("Head")
    if not head then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = head
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = billboard
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.Name
    textLabel.TextColor3 = GetPlayerColor(player)
    textLabel.TextStrokeTransparency = 0
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    table.insert(EspObjects, billboard)
end

local function CreateTracers(character, player)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local line = Drawing.new("Line")
    line.Visible = true
    line.Color = GetPlayerColor(player)
    line.Thickness = 2
    line.Transparency = 1
    table.insert(EspObjects, {Type = "Tracer", Line = line, Character = character, Player = player})
end

local function ClearEsp()
    for _, obj in pairs(EspObjects) do
        if obj then
            if typeof(obj) == "table" and obj.Type == "Tracer" then
                if obj.Line then obj.Line:Remove() end
            elseif typeof(obj) == "Instance" then
                obj:Destroy()
            end
        end
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
            local character = obj.Character
            local line = obj.Line
            local player = obj.Player
            if character and character:FindFirstChild("HumanoidRootPart") then
                local hrp = character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local screenSize = Camera.ViewportSize
                    line.From = Vector2.new(screenSize.X / 2, screenSize.Y)
                    line.To = Vector2.new(screenPos.X, screenPos.Y)
                    line.Color = GetPlayerColor(player)
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end
end

local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

CombatTab:CreateSection("Aimlock")
CombatTab:CreateToggle({Name = "Aimlock (Hold Right Mouse)", CurrentValue = false, Flag = "AimlockToggle", Callback = function(Value) AimlockEnabled = Value end})
CombatTab:CreateToggle({Name = "Team Check", CurrentValue = true, Flag = "TeamCheckToggle", Callback = function(Value) TeamCheckEnabled = Value end})
CombatTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = false, Flag = "FovToggle", Callback = function(Value) FovEnabled = Value FovCircle.Visible = Value end})
CombatTab:CreateSlider({Name = "FOV Size", Range = {50, 500}, Increment = 10, Suffix = "px", CurrentValue = 100, Flag = "FovSlider", Callback = function(Value) FovSize = Value FovCircle.Radius = Value end})

CombatTab:CreateSection("Arrest Aura")
CombatTab:CreateToggle({Name = "Arrest Aura (Guard Only)", CurrentValue = false, Flag = "ArrestAuraToggle", Callback = function(Value) ArrestAuraEnabled = Value end})
CombatTab:CreateSlider({Name = "Arrest Distance", Range = {5, 30}, Increment = 1, Suffix = " studs", CurrentValue = 15, Flag = "ArrestDistanceSlider", Callback = function(Value) ArrestAuraDistance = Value end})

VisualsTab:CreateSection("ESP")
VisualsTab:CreateToggle({Name = "Chams", CurrentValue = false, Flag = "ChamsToggle", Callback = function(Value) ChamsEnabled = Value UpdateEsp() end})
VisualsTab:CreateToggle({Name = "Name ESP", CurrentValue = false, Flag = "NameEspToggle", Callback = function(Value) NameEspEnabled = Value UpdateEsp() end})
VisualsTab:CreateToggle({Name = "Tracers", CurrentValue = false, Flag = "TracersToggle", Callback = function(Value) TracersEnabled = Value UpdateEsp() end})

MovementTab:CreateSection("Movement")
MovementTab:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Flag = "InfJumpToggle", Callback = function(Value) InfJumpEnabled = Value end})

MiscTab:CreateSection("Misc")
MiscTab:CreateToggle({Name = "Stretch Resolution", CurrentValue = false, Flag = "StretchToggle", Callback = function(Value) StretchEnabled = Value if Value then Camera.FieldOfView = 120 else Camera.FieldOfView = 70 end end})
MiscTab:CreateSlider({Name = "Stretch Amount", Range = {1, 3}, Increment = 0.1, Suffix = "x", CurrentValue = 1, Flag = "StretchSlider", Callback = function(Value) StretchValue = Value if StretchEnabled then Camera.FieldOfView = 70 * Value end end})

UserInputService.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton2 then RightMouseDown = true end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton2 then RightMouseDown = false end end)

RunService.RenderStepped:Connect(function()
    if AimlockEnabled and RightMouseDown then
        CurrentTarget = GetClosestPlayerToCursor()
        if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("Head") then
            local head = CurrentTarget.Character.Head
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
        end
    end
    if FovEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        FovCircle.Position = mousePos
        FovCircle.Color = GetMyTeamColor()
        FovCircle.Visible = true
    else
        FovCircle.Visible = false
    end
    if StretchEnabled then Camera.FieldOfView = 70 * StretchValue end
    if TracersEnabled then UpdateTracers() end
    ArrestAura()
end)

UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

task.spawn(function()
    while task.wait(5) do
        if ChamsEnabled or NameEspEnabled or TracersEnabled then UpdateEsp() end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if ChamsEnabled or NameEspEnabled or TracersEnabled then UpdateEsp() end
    end)
end)

Players.PlayerRemoving:Connect(function()
    if ChamsEnabled or NameEspEnabled or TracersEnabled then UpdateEsp() end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if ChamsEnabled or NameEspEnabled or TracersEnabled then UpdateEsp() end
end)

UpdateEsp()
