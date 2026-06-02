-- ============================================================
-- KrysHub | [🌌] Duel Stars!
-- Click Shoot | ESP (Estable) | FOV Configurable | Settings
-- Versión: 2.0.0 (Final)
-- ============================================================

task.wait(3)

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Txzp/KrysHub-Zzz/main/WindUI-main/dist/main.lua?t=" .. os.time()))()

local Window = WindUI:CreateWindow({
    Title = "KrysHub | [🌌] Duel Stars!",
    Icon = "rocket",
    Theme = "Dark",
    Size = UDim2.fromOffset(450, 400), -- <--- Aquí es donde se cambia
    Folder = "KrysHub"
})

-- ============================================================
-- TABS
-- ============================================================
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house"
})

local CombatTab = Window:Tab({
    Title = "Combat",
    Icon = "target"
})

local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "eye"
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

-- ============================================================
-- SERVICIOS
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

print("[KrysHub] Duel Stars! - Iniciado")

-- ============================================================
-- REMOTES
-- ============================================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local FireWeapon = Remotes and Remotes:FindFirstChild("FireWeapon")

-- ============================================================
-- VARIABLES
-- ============================================================
local clickShootEnabled = false
local espEnabled = false
local notificationsEnabled = true
local fovVisible = true       -- Por defecto, el FOV es visible (el toggle "Invisible FOV" estará en false)
local fovColor = "White"      -- Color del FOV cuando no apunta a enemigo (blanco por defecto)
local fovRadius = 150
local fovCircle = nil
local lastShotTime = 0
local shotDelay = 0.15

-- ESP: Almacenamiento y conexiones robustas (tomado del Universal Hub)
local espHighlights = {}
local espCharacterAddedConns = {}
local ESPColor = Color3.fromRGB(255, 0, 0)  -- Rojo por defecto
local espColorNames = {
    Red = Color3.fromRGB(255, 60, 60),
    Green = Color3.fromRGB(60, 200, 110),
    Blue = Color3.fromRGB(80, 160, 255),
    Yellow = Color3.fromRGB(255, 210, 50),
    Purple = Color3.fromRGB(255, 0, 255),
    Orange = Color3.fromRGB(255, 165, 0),
    White = Color3.fromRGB(255, 255, 255)
}
local selectedESPColor = "Red"

-- Colores para el FOV
local fovColors = {
    Verde = Color3.fromRGB(0, 255, 0),
    Rojo = Color3.fromRGB(255, 0, 0),
    Blanco = Color3.fromRGB(255, 255, 255),
    Azul = Color3.fromRGB(0, 100, 255),
    Amarillo = Color3.fromRGB(255, 255, 0)
}

-- ============================================================
-- NOTIFICACIONES
-- ============================================================
local function notify(title, content, duration)
    if notificationsEnabled then
        WindUI:Notify({ Title = title, Content = content, Duration = duration or 2 })
    end
end

-- ============================================================
-- TEAM CHECK
-- ============================================================
local function isEnemy(player)
    if player == LocalPlayer then return false end
    
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    if myTeam and theirTeam then
        return myTeam ~= theirTeam
    end
    
    local myTeamAttr = LocalPlayer:GetAttribute("Team")
    local theirTeamAttr = player:GetAttribute("Team")
    if myTeamAttr and theirTeamAttr then
        return myTeamAttr ~= theirTeamAttr
    end
    
    return true
end

-- ============================================================
-- ESP ROBUSTO (No se desactiva solo)
-- ============================================================
local function addESPToPlayer(player)
    if not espEnabled then return end
    if player == LocalPlayer then return end
    if not isEnemy(player) then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    if espHighlights[player] and espHighlights[player].Parent then
        -- Solo actualizar color si ya existe
        espHighlights[player].FillColor = ESPColor
        espHighlights[player].OutlineColor = ESPColor
        return
    end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESPColor
    highlight.OutlineColor = ESPColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character
    espHighlights[player] = highlight
end

local function removeESPFromPlayer(player)
    if espHighlights[player] then
        pcall(function() espHighlights[player]:Destroy() end)
        espHighlights[player] = nil
    end
end

local function updateESP()
    if not espEnabled then
        for player, _ in pairs(espHighlights) do
            removeESPFromPlayer(player)
        end
        return
    end
    
    -- Aplicar ESP a todos los enemigos actuales
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            addESPToPlayer(player)
        else
            removeESPFromPlayer(player)
        end
    end
end

-- Watchers para respawn
local function setupESPWatcher(player)
    if espCharacterAddedConns[player] then
        espCharacterAddedConns[player]:Disconnect()
    end
    
    espCharacterAddedConns[player] = player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled and isEnemy(player) then
            addESPToPlayer(player)
        end
    end)
end

-- Conectar eventos para todos los jugadores (actuales y futuros)
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        setupESPWatcher(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    setupESPWatcher(player)
    if espEnabled then
        task.wait(0.5)
        addESPToPlayer(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESPFromPlayer(player)
    if espCharacterAddedConns[player] then
        espCharacterAddedConns[player]:Disconnect()
        espCharacterAddedConns[player] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    updateESP()
end)

-- ============================================================
-- DETECTAR ENEMIGO EN FOV
-- ============================================================
local function getClosestEnemyToCursor()
    local cursorPos = UserInputService:GetMouseLocation()
    local cursorX = cursorPos.X
    local cursorY = cursorPos.Y
    
    local closestTarget = nil
    local closestDistance = fovRadius
    local closestPlayer = nil
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            local targetPart = head or player.Character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPos, isOnScreen = Camera:WorldToViewportPoint(targetPart.Position)
                
                if isOnScreen then
                    local distanceFromCursor = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(cursorX, cursorY)).Magnitude
                    
                    if distanceFromCursor <= fovRadius and distanceFromCursor < closestDistance then
                        closestDistance = distanceFromCursor
                        closestTarget = targetPart
                        closestPlayer = player
                    end
                end
            end
        end
    end
    
    return closestTarget, closestPlayer
end

-- ============================================================
-- DISPARAR
-- ============================================================
local function shootAtEnemy(targetPart, targetPlayer)
    if not targetPart then return false end
    if not FireWeapon then return false end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local gunTool = character:FindFirstChild("GunTool") or character:FindFirstChild("Gun")
    if not gunTool then return false end
    
    local handle = gunTool:FindFirstChild("Handle")
    local origin = handle and handle.Position or character:FindFirstChild("HumanoidRootPart").Position
    
    local targetPosition = targetPart.Position
    
    pcall(function()
        FireWeapon:FireServer("Gun", CFrame.new(targetPosition), {
            Origin = origin,
            HitPosition = targetPosition,
            Time = os.clock(),
            ClientServerTime = workspace:GetServerTimeNow(),
            EnemyUserId = targetPlayer and targetPlayer.UserId or 0
        })
    end)
    
    return true
end

-- ============================================================
-- CLICK SHOOT (Sin keybind fijo)
-- ============================================================
local function setupClickShoot()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if clickShootEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local now = tick()
            if now - lastShotTime < shotDelay then return end
            
            local targetPart, targetPlayer = getClosestEnemyToCursor()
            
            if targetPart then
                shootAtEnemy(targetPart, targetPlayer)
                lastShotTime = now
            end
        end
    end)
end

-- ============================================================
-- FOV CIRCLE (Configurable)
-- ============================================================
local function getFOVColor(isTargeting)
    if isTargeting then
        return Color3.fromRGB(255, 0, 0)  -- Rojo al apuntar a enemigo
    else
        return fovColors[fovColor] or Color3.fromRGB(255, 255, 255)  -- Color configurado
    end
end

local function setupFOVCircle()
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Radius = fovRadius
    fovCircle.Thickness = 2
    fovCircle.Color = getFOVColor(false)
    fovCircle.Filled = false
    fovCircle.NumSides = 64
    fovCircle.Transparency = 1
    
    RunService.RenderStepped:Connect(function()
        if fovCircle and clickShootEnabled then
            local cursorPos = UserInputService:GetMouseLocation()
            fovCircle.Position = Vector2.new(cursorPos.X, cursorPos.Y)
            
            -- Solo mostrar si fovVisible está activado
            fovCircle.Visible = fovVisible
            fovCircle.Radius = fovRadius
            
            local target, _ = getClosestEnemyToCursor()
            fovCircle.Color = getFOVColor(target ~= nil)
        elseif fovCircle then
            fovCircle.Visible = false
        end
    end)
end

-- ============================================================
-- TUTORIAL HUB (Mejorado, con UIStroke blanco y X circular)
-- ============================================================
local function showTutorial()
    local tutorialGui = Instance.new("ScreenGui")
    tutorialGui.Name = "KrysHub_Tutorial"
    tutorialGui.Parent = game:GetService("CoreGui")
    tutorialGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 480, 0, 340)
    mainFrame.Position = UDim2.new(0.5, -240, 0.5, -170)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = tutorialGui
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)  -- Borde blanco
    stroke.Thickness = 1.5
    stroke.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Text = "📖 Tutorial"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = mainFrame
    
    -- Botón X circular con solo la letra
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34)
    closeBtn.Position = UDim2.new(1, -44, 0, 6)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    closeBtn.BackgroundTransparency = 0
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = mainFrame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)  -- Circular
    btnCorner.Parent = closeBtn
    
    -- English Frame
    local engFrame = Instance.new("Frame")
    engFrame.Size = UDim2.new(0.48, -10, 1, -60)
    engFrame.Position = UDim2.new(0, 10, 0, 55)
    engFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    engFrame.BackgroundTransparency = 0.3
    engFrame.BorderSizePixel = 0
    engFrame.Parent = mainFrame
    Instance.new("UICorner", engFrame).CornerRadius = UDim.new(0, 10)
    local engStroke = Instance.new("UIStroke", engFrame)
    engStroke.Color = Color3.fromRGB(80, 80, 100)
    engStroke.Thickness = 1
    
    local engTitle = Instance.new("TextLabel")
    engTitle.Size = UDim2.new(1, 0, 0, 32)
    engTitle.Text = "🇬🇧 English"
    engTitle.TextColor3 = Color3.fromRGB(100, 180, 255)
    engTitle.BackgroundTransparency = 1
    engTitle.Font = Enum.Font.GothamBold
    engTitle.TextSize = 15
    engTitle.Parent = engFrame
    
    local engText = Instance.new("TextLabel")
    engText.Size = UDim2.new(1, -15, 1, -42)
    engText.Position = UDim2.new(0, 8, 0, 38)
    engText.Text = "1. Activate Click Shoot in Combat tab\n2. Enter a match\n3. Aim the FOV at the enemy\n4. FOV turns RED when aiming\n5. Click anywhere to shoot\n6. Be discreet"
    engText.TextColor3 = Color3.fromRGB(200, 200, 200)
    engText.BackgroundTransparency = 1
    engText.Font = Enum.Font.Gotham
    engText.TextSize = 13
    engText.TextXAlignment = Enum.TextXAlignment.Left
    engText.TextYAlignment = Enum.TextYAlignment.Top
    engText.TextWrapped = true
    engText.Parent = engFrame
    
    -- Spanish Frame
    local espFrame = Instance.new("Frame")
    espFrame.Size = UDim2.new(0.48, -10, 1, -60)
    espFrame.Position = UDim2.new(0.5, 5, 0, 55)
    espFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    espFrame.BackgroundTransparency = 0.3
    espFrame.BorderSizePixel = 0
    espFrame.Parent = mainFrame
    Instance.new("UICorner", espFrame).CornerRadius = UDim.new(0, 10)
    local espStroke = Instance.new("UIStroke", espFrame)
    espStroke.Color = Color3.fromRGB(80, 80, 100)
    espStroke.Thickness = 1
    
    local espTitle = Instance.new("TextLabel")
    espTitle.Size = UDim2.new(1, 0, 0, 32)
    espTitle.Text = "🇪🇸 Español"
    espTitle.TextColor3 = Color3.fromRGB(100, 180, 255)
    espTitle.BackgroundTransparency = 1
    espTitle.Font = Enum.Font.GothamBold
    espTitle.TextSize = 15
    espTitle.Parent = espFrame
    
    local espText = Instance.new("TextLabel")
    espText.Size = UDim2.new(1, -15, 1, -42)
    espText.Position = UDim2.new(0, 8, 0, 38)
    espText.Text = "1. Activa Click Shoot en la pestaña Combat\n2. Entra a una partida\n3. Apunta el FOV al enemigo\n4. El FOV se pone ROJO al apuntar\n5. Haz clic para disparar\n6. Sé discreto"
    espText.TextColor3 = Color3.fromRGB(200, 200, 200)
    espText.BackgroundTransparency = 1
    espText.Font = Enum.Font.Gotham
    espText.TextSize = 13
    espText.TextXAlignment = Enum.TextXAlignment.Left
    espText.TextYAlignment = Enum.TextYAlignment.Top
    espText.TextWrapped = true
    espText.Parent = espFrame
    
    closeBtn.MouseButton1Click:Connect(function()
        tutorialGui:Destroy()
    end)
end

-- ============================================================
-- UI: MAIN TAB
-- ============================================================
local displayName = LocalPlayer.DisplayName or LocalPlayer.Name

MainTab:Paragraph({
    Title = "Welcome To KrysHub @ " .. displayName,
    Desc = "[🌌] Duel Stars! | v2.0.0\n\nCredit: 4kryx👑\n\nThx For Used I Love You ❤️"
})

MainTab:Paragraph({
    Title = "📢: Join Server Discord For More",
    Desc = ""
})

MainTab:Button({
    Title = "Copy Discord Link",
    Callback = function()
        setclipboard("https://discord.gg/BfZGVSguC")
        notify("Discord", "Link copied", 1)
    end
})

MainTab:Paragraph({
    Title = "📢: UPDATE COMING",
    Desc = ""
})

-- ============================================================
-- UI: COMBAT TAB
-- ============================================================
CombatTab:Toggle({
    Title = "Click Shoot",
    Value = false,
    Callback = function(state)
        clickShootEnabled = state
        notify("Click Shoot", state and "ON ✓" or "OFF", 1)
    end
})

CombatTab:Keybind({
    Title = "Keybind",
    Value = "ShiftRight",          -- Sin tecla predeterminada, el jugador asigna la suya
    Callback = function()
        clickShootEnabled = not clickShootEnabled
        notify("Click Shoot", clickShootEnabled and "ON ✓" or "OFF", 1)
    end
})

CombatTab:Slider({
    Title = "FOV Size",
    Value = { Min = 50, Max = 300, Default = 150 },
    Callback = function(value)
        fovRadius = value
    end
})

CombatTab:Toggle({
    Title = "Invisible FOV",
    Value = false,       -- Por defecto, el FOV es visible. El toggle "activado" lo hace invisible.
    Callback = function(state)
        fovVisible = not state
        notify("Invisible FOV", state and "Activado (FOV oculto)" or "Desactivado (FOV visible)", 1)
    end
})

CombatTab:Button({
    Title = "📖 Tutorial",
    Callback = function()
        showTutorial()
    end
})

-- ============================================================
-- UI: ESP TAB
-- ============================================================
ESPTab:Toggle({
    Title = "ESP (Highlight)",
    Value = false,
    Callback = function(state)
        espEnabled = state
        updateESP()
        notify("ESP", state and "ON ✓" or "OFF", 1)
    end
})

ESPTab:Keybind({
    Title = "Keybind",
    Value = "ShiftRight",          -- Sin tecla predeterminada
    Callback = function()
        espEnabled = not espEnabled
        updateESP()
        notify("ESP", espEnabled and "ON ✓" or "OFF", 1)
    end
})

ESPTab:Dropdown({
    Title = "ESP Color",
    Values = {"Red", "Green", "Blue", "Yellow", "Purple", "Orange", "White"},
    Default = "Red",
    Callback = function(value)
        selectedESPColor = value
        ESPColor = espColorNames[value] or Color3.fromRGB(255, 255, 255)
        updateESP()
        notify("ESP Color", value, 1)
    end
})

-- ============================================================
-- UI: SETTINGS TAB
-- ============================================================
SettingsTab:Paragraph({
    Title = "KrysHub | Duel Stars!",
    Desc = "🌌 Edited: 6/2/2026"
})

SettingsTab:Dropdown({
    Title = "FOV Color",
    Values = {"Verde", "Rojo", "Blanco", "Azul", "Amarillo"},
    Default = "Blanco",
    Callback = function(value)
        fovColor = value
        notify("FOV Color", value, 1)
    end
})

SettingsTab:Keybind({
    Title = "Toggle UI",
    Value = "RightShift",
    Callback = function()
        Window:Toggle()
    end
})

SettingsTab:Toggle({
    Title = "Notifications",
    Value = true,
    Callback = function(state)
        notificationsEnabled = state
    end
})

-- ============================================================
-- INICIALIZACIÓN
-- ============================================================
setupClickShoot()
setupFOVCircle()

notify("KrysHub", "[🌌] Duel Stars!", 5)

print("==========================================")
print("KrysHub | [🌌] Duel Stars! v2.0.0 (Final)")
print("==========================================")
