local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local Aiming = false
 
------------------------------------------------
-- RGB COLOR HELPER
------------------------------------------------
local function HSVtoRGB(h, s, v)
	local c = v * s
	local x = c * (1 - math.abs((h * 6) % 2 - 1))
	local m = v - c
	local r, g, b = 0, 0, 0
	if h < 1/6 then
		r, g, b = c, x, 0
	elseif h < 2/6 then
		r, g, b = x, c, 0
	elseif h < 3/6 then
		r, g, b = 0, c, x
	elseif h < 4/6 then
		r, g, b = 0, x, c
	elseif h < 5/6 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end
	return Color3.new(r+m, g+m, b+m)
end
 
local hue = 0
 
------------------------------------------------
-- ESP (Highlight around enemy players)
------------------------------------------------
-- Prison Life CHAMS PRO
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local me = Players.LocalPlayer

-- Цвета для команд
local teamColors = {
    Prisoners = Color3.fromRGB(255, 50, 50),   -- Красный
    Guards = Color3.fromRGB(50, 50, 255),      -- Синий
    Criminals = Color3.fromRGB(50, 255, 50),   -- Зеленый
    Innocents = Color3.fromRGB(255, 255, 50),  -- Желтый
    Neutral = Color3.fromRGB(255, 165, 0)      -- Оранжевый (для нейтральных)
}

-- Основная функция
local function applyChams(player, character)
    if player == me or not character then return end
    
    -- Удаляем старый если есть
    local old = character:FindFirstChild("PL_Chams")
    if old then old:Destroy() end
    
    -- Создаем новый
    local chams = Instance.new("Highlight")
    chams.Name = "PL_Chams"
    chams.Adornee = character
    chams.DepthMode = "AlwaysOnTop"
    chams.FillTransparency = 0.3
    chams.OutlineTransparency = 0
    
    -- Определяем цвет
    local teamName = player.Team and player.Team.Name or "Neutral"
    local color = teamColors[teamName] or teamColors.Neutral
    
    chams.FillColor = color
    chams.OutlineColor = Color3.new(
        math.clamp(color.R + 0.2, 0, 1),
        math.clamp(color.G + 0.2, 0, 1),
        math.clamp(color.B + 0.2, 0, 1)
    )
    
    -- Включаем/выключаем в зависимости от команды
    if me.Team and player.Team then
        chams.Enabled = me.Team ~= player.Team
    else
        chams.Enabled = true
    end
    
    chams.Parent = character
end

-- Функция для полной настройки игрока
local function setupPlayer(player)
    if player == me then return end
    
    -- Обработчик появления персонажа
    local function onCharacterAdded(character)
        task.wait(0.15) -- Небольшая задержка для загрузки
        applyChams(player, character)
    end
    
    -- Обработчик смены команды
    local function onTeamChanged()
        task.wait(0.1)
        if player.Character then
            applyChams(player, player.Character)
        end
    end
    
    -- Настройка отслеживания
    player:GetPropertyChangedSignal("Team"):Connect(onTeamChanged)
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    
    -- Автоочистка при удалении персонажа
    player.CharacterRemoving:Connect(function(char)
        local chams = char:FindFirstChild("PL_Chams")
        if chams then
            chams:Destroy()
        end
    end)
end

-- Инициализация всех игроков
for _, player in pairs(Players:GetPlayers()) do
    setupPlayer(player)
end

-- Новые игроки
Players.PlayerAdded:Connect(setupPlayer)

-- Обновление при смене своей команды
if me then
    me:GetPropertyChangedSignal("Team"):Connect(function()
        task.wait(0.2)
        -- Обновляем всех игроков
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= me and player.Character then
                applyChams(player, player.Character)
            end
        end
    end)
end

-- Информация
print("========================================")
print("🎮 Prison Life CHAMS PRO")
print("✅ Автоматическое обновление новых игроков")
print("✅ Динамическая смена цветов")
print("========================================")

if me.Team then
    print("Ваша команда: " .. me.Team.Name)
    local color = teamColors[me.Team.Name] or teamColors.Neutral
    print("Цвет вашей команды: " .. tostring(color))
end
 
------------------------------------------------
-- FOV RING (Drawing API circle)
------------------------------------------------
local FOV = 300
local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.NumSides = 64
circle.Radius = FOV
circle.Filled = false
circle.Color = HSVtoRGB(hue,1,1) -- initial rainbow color
circle.Transparency = 1
circle.Visible = true
 
game:GetService("RunService").RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	local viewport = cam.ViewportSize
	circle.Position = Vector2.new(viewport.X/2, viewport.Y/2)
 
	-- update hue for rainbow fade
	hue = (hue + 0.001) % 1
	circle.Color = HSVtoRGB(hue,1,1)
 
	-- also update ESP outline color for all players
	for _, plr in pairs(game.Players:GetPlayers()) do
		if plr.Character then
			local highlight = plr.Character:FindFirstChild("ESP_Highlight")
			if highlight then
				highlight.OutlineColor = HSVtoRGB(hue,1,1)
			end
		end
	end
end)
 
------------------------------------------------
-- AIMLOCK
------------------------------------------------
function AimLock()
	local player = game.Players.LocalPlayer
	local target
	local lastMagnitude = math.huge
	
	for _, v in pairs(game.Players:GetPlayers()) do
		
		if v ~= player and v.Character and v.Character.PrimaryPart then
		
			local playerTeam = player.Team
			local targetTeam = v.Team
			
			
			if playerTeam and targetTeam and playerTeam == targetTeam then
				continue
			end
			

			local teamName = targetTeam and targetTeam.Name or ""
			
	
	
			if (teamName == "Prisoners" and playerTeam and playerTeam.Name == "Prisoners") then
				continue
			end
			
			if (teamName == "Police" and playerTeam and playerTeam.Name == "Police") then
				continue
			end
			
			if (teamName == "Criminals" and playerTeam and playerTeam.Name == "Criminals") then
				continue
			end
			
		
			if v.Character:FindFirstChild("KO") and v.Character.KO.Value then
				continue
			end
			
			
			local charPos = v.Character.PrimaryPart.Position
			local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(charPos)
			
			if onScreen then
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - circle.Position).Magnitude
				if dist < circle.Radius and dist < lastMagnitude then
					lastMagnitude = dist
					target = v
				end
			end
		end
	end
 
	if target and target.Character and target.Character.PrimaryPart then
		local charPos = target.Character.PrimaryPart.Position
		local cam = workspace.CurrentCamera
		local pos = cam.CFrame.Position
		workspace.CurrentCamera.CFrame = CFrame.new(pos, charPos)
	end
end
 
------------------------------------------------
-- INPUT HANDLING
------------------------------------------------
local UserInputService = game:GetService("UserInputService")
 
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed then
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			Aiming = true
		elseif input.KeyCode == Enum.KeyCode.E then
			InfiniteJump = not InfiniteJump
			if InfiniteJump then
				print("Infinite Jump Enabled")
			else
				print("Infinite Jump Disabled")
			end
		elseif input.KeyCode == Enum.KeyCode.R then
			NoclipEnabled = not NoclipEnabled
			if NoclipEnabled then
				print("Noclip Enabled")
			else
				print("Noclip Disabled")
			end
		end
	end
end)
 
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		Aiming = false
	end
end)
 
------------------------------------------------
-- RUN AIMLOCK
------------------------------------------------
game:GetService("RunService").RenderStepped:Connect(function()
	if Aiming then
		AimLock()
	end
end)
 
------------------------------------------------
-- INFINITE JUMP
------------------------------------------------
local Player = game:GetService'Players'.LocalPlayer;
local UIS = game:GetService'UserInputService';
 
_G.JumpHeight = 50;
 
function Action(Object, Function) if Object ~= nil then Function(Object); end end
 
UIS.InputBegan:connect(function(UserInput)
    if UserInput.UserInputType == Enum.UserInputType.Keyboard and UserInput.KeyCode == Enum.KeyCode.Space then
        Action(Player.Character.Humanoid, function(self)
            if self:GetState() == Enum.HumanoidStateType.Jumping or self:GetState() == Enum.HumanoidStateType.Freefall then
                Action(self.Parent.HumanoidRootPart, function(self)
                    self.Velocity = Vector3.new(0, _G.JumpHeight, 0);
                end)
            end
        end)
    end
end)
 
------------------------------------------------
-- NO DOORS
------------------------------------------------
local doors = workspace:FindFirstChild("Doors")
if not doors then return end
for i,v in pairs(doors:GetChildren()) do
v:Destroy()
end

------------------------------------------------
-- fullbight
------------------------------------------------
pcall(function()
	local lighting = game:GetService("Lighting");
	lighting.Ambient = Color3.fromRGB(255, 255, 255);
	lighting.Brightness = 1;
	lighting.FogEnd = 1e10;
	for i, v in pairs(lighting:GetDescendants()) do
		if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
			v.Enabled = false;
		end;
	end;
	lighting.Changed:Connect(function()
		lighting.Ambient = Color3.fromRGB(255, 255, 255);
		lighting.Brightness = 1;
		lighting.FogEnd = 1e10;
	end);
	spawn(function()
		local character = game:GetService("Players").LocalPlayer.Character;
		while wait() do
			repeat wait() until character ~= nil;
			if not character.HumanoidRootPart:FindFirstChildWhichIsA("PointLight") then
				local headlight = Instance.new("PointLight", character.HumanoidRootPart);
				headlight.Brightness = 1;
				headlight.Range = 60;
			end;
		end;
	end);
end)
