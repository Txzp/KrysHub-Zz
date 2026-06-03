-- ============================================================
-- KrysHub | [🌌] Duel Stars!
-- Click Shoot (FIXED: sin paredes, disparo directo)
-- ESP (Ultra Robusto + Billboard) | FOV Configurable
-- Versión: 2.1.0 (Soporte Móvil incluido)
-- ============================================================

task.wait(3)

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Txzp/KrysHub-Zzz/main/WindUI-main/dist/main.lua?t=" .. os.time()))()

local Window = WindUI:CreateWindow({
    Title = "KrysHub | [🌌] Duel Stars!",
    Icon = "rocket",
    Theme = "Dark",
    Size = UDim2.fromOffset(450, 400),
    Folder = "KrysHub"
})

-- ============================================================
-- DETECCIÓN MÓVIL
-- ============================================================
local UserInputService = game:GetService("UserInputService")
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local OpenButtonMain = nil
local uiOpen = true

-- ============================================================
-- TABS
-- ============================================================
local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
local CombatTab = Window:Tab({ Title = "Combat", Icon = "target" })
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ============================================================
-- SERVICIOS
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
local fovVisible = true
local fovColor = "White"
local fovRadius = 150
local fovCircle = nil
local lastShotTime = 0
local shotDelay = 0.15

-- ESP (sistema robusto con billboard)
local espData = {}
local espCharConns = {}
local ESPColor = Color3.fromRGB(255, 0, 0)
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

local fovColors = {
    Green = Color3.fromRGB(0, 255, 0),
    Red = Color3.fromRGB(255, 0, 0),
    White = Color3.fromRGB(255, 255, 255),
    Blue = Color3.fromRGB(0, 100, 255),
    Yellow = Color3.fromRGB(255, 255, 0)
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
-- FUNCIONES UI PARA MÓVIL
-- ============================================================
local function closeUI()
    if IsMobile and OpenButtonMain then
        OpenButtonMain.Visible = true
    end
    if Window then
        Window:Close()
    end
end

local function openUI()
    if Window then
        Window:Open()
    end
    if IsMobile and OpenButtonMain then
        OpenButtonMain.Visible = false
    end
end

-- ============================================================
-- OPENBUTTON SYSTEM (MÓVIL)
-- ============================================================
local function setupOpenButton()
    if not IsMobile then return end
    
    OpenButtonMain = Instance.new("TextButton")
    OpenButtonMain.Name = "OpenButtonMain"
    OpenButtonMain.Parent = game:GetService("CoreGui")
    OpenButtonMain.Size = UDim2.new(0, 50, 0, 50)
    OpenButtonMain.Position = UDim2.new(0, 10, 0, 100)
    OpenButtonMain.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    OpenButtonMain.BackgroundTransparency = 0.2
    OpenButtonMain.Text = "▶"
    OpenButtonMain.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpenButtonMain.TextSize = 24
    OpenButtonMain.Font = Enum.Font.GothamBold
    OpenButtonMain.Visible = false
    OpenButtonMain.ZIndex = 10
    
    local corner = Instance.new("UICorner", OpenButtonMain)
    corner.CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    OpenButtonMain.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = OpenButtonMain.Position
        end
    end)
    
    OpenButtonMain.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            OpenButtonMain.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    OpenButtonMain.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    OpenButtonMain.MouseButton1Click:Connect(function()
        if Window then
            Window:Open()
            OpenButtonMain.Visible = false
        end
    end)
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
-- ESP ROBUSTO
-- ============================================================
local function removeESP(player)
    if not espData[player] then return end
    pcall(function()
        if espData[player].hl and espData[player].hl.Parent then
            espData[player].hl:Destroy()
        end
        if espData[player].bb and espData[player].bb.Parent then
            espData[player].bb:Destroy()
        end
    end)
    espData[player] = nil
end

local function addESP(player)
    if not espEnabled then return end
    if player == LocalPlayer then return end
    if not isEnemy(player) then return end

    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then return end

    removeESP(player)

    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESPColor
    highlight.OutlineColor = ESPColor
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = rootPart
    billboard.AlwaysOnTop = true
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    billboard.Size = UDim2.new(0, 90, 0, 22)
    billboard.MaxDistance = 300
    billboard.Parent = rootPart

    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName
    nameLabel.TextColor3 = ESPColor
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    espData[player] = {
        hl = highlight,
        bb = billboard,
        char = character
    }
end

local function updateESP()
    if not espEnabled then
        for plr in pairs(espData) do
            removeESP(plr)
        end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local data = espData[player]
            local currentChar = player.Character
            local needRebuild = not data
                or not data.hl or not data.hl.Parent
                or not data.bb or not data.bb.Parent
                or data.char ~= currentChar
            if needRebuild then
                addESP(player)
            else
                data.hl.FillColor = ESPColor
                data.hl.OutlineColor = ESPColor
                local lbl = data.bb:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.TextColor3 = ESPColor end
            end
        end
    end

    for plr in pairs(espData) do
        if not plr.Parent then
            removeESP(plr)
            if espCharConns[plr] then
                espCharConns[plr]:Disconnect()
                espCharConns[plr] = nil
            end
        end
    end
end

local function setupESPWatcher(player)
    if espCharConns[player] then
        espCharConns[player]:Disconnect()
    end
    espCharConns[player] = player.CharacterAdded:Connect(function()
        removeESP(player)
        task.wait(0.5)
        addESP(player)
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        setupESPWatcher(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    setupESPWatcher(player)
    task.wait(0.5)
    addESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    if espCharConns[player] then
        espCharConns[player]:Disconnect()
        espCharConns[player] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    updateESP()
end)

task.spawn(function()
    while true do
        task.wait(1)
        if espEnabled then
            updateESP()
        end
    end
end)

-- ============================================================
-- CLICK SHOOT
-- ============================================================
local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local distance = (targetPart.Position - origin).Magnitude
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction * distance, rayParams)
    if result and result.Instance then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        return hitModel == targetPart.Parent
    end
    return false
end

local function getVisibleEnemyAtCursor()
    local cursorPos = UserInputService:GetMouseLocation()
    local cursorX, cursorY = cursorPos.X, cursorPos.Y

    local bestTargetPart = nil
    local bestDistance = fovRadius
    local bestPlayer = nil

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character }

    for _, player in pairs(Players:GetPlayers()) do
        if isEnemy(player) and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if hrp and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(cursorX, cursorY)).Magnitude
                    if dist <= fovRadius and dist < bestDistance then
                        local origin = Camera.CFrame.Position
                        local direction = (hrp.Position - origin).Unit
                        local ray = workspace:Raycast(origin, direction * 500, rayParams)
                        if ray and ray.Instance then
                            local hitModel = ray.Instance:FindFirstAncestorOfClass("Model")
                            if hitModel == player.Character then
                                bestDistance = dist
                                bestTargetPart = hrp
                                bestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTargetPart, bestPlayer
end

local function shootAtEnemy(targetPart, targetPlayer)
    if not targetPart or not FireWeapon then return false end
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

local function setupClickShoot()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not clickShootEnabled then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        local now = tick()
        if now - lastShotTime < shotDelay then return end
        local targetPart, targetPlayer = getVisibleEnemyAtCursor()
        if targetPart then
            shootAtEnemy(targetPart, targetPlayer)
            lastShotTime = now
        end
    end)
end

-- ============================================================
-- FOV CIRCLE
-- ============================================================
local function getFOVColor(isTargeting)
    if isTargeting then
        return Color3.fromRGB(255, 0, 0)
    else
        return fovColors[fovColor] or Color3.fromRGB(255, 255, 255)
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
            fovCircle.Visible = fovVisible
            fovCircle.Radius = fovRadius
            local target, _ = getVisibleEnemyAtCursor()
            fovCircle.Color = getFOVColor(target ~= nil)
        elseif fovCircle then
            fovCircle.Visible = false
        end
    end)
end

-- ============================================================
-- TUTORIAL HUB
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
    stroke.Color = Color3.fromRGB(255, 255, 255)
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
    btnCorner.CornerRadius = UDim.new(1, 0)
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
    Desc = "[🌌] Duel Stars! | v2.1.0\n\nCredit: 4kryx👑\n\nThx For Used I Love You ❤️"
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
local clickShootToggleRef = CombatTab:Toggle({
    Title = "Click Shoot",
    Value = false,
    Callback = function(state)
        clickShootEnabled = state
        notify("Click Shoot", state and "ON ✓" or "OFF", 1)
    end
})

CombatTab:Keybind({
    Title = "Keybind",
    Value = "ShiftRight",
    Callback = function()
        if clickShootToggleRef then
            clickShootToggleRef:SetState(not clickShootToggleRef.Value)
        end
    end
})

CombatTab:Slider({
    Title = "FOV Size",
    Value = { Min = 50, Max = 200, Default = 150 },
    Callback = function(value)
        fovRadius = value
    end
})

CombatTab:Toggle({
    Title = "Hide FOV",
    Value = false,
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
local espToggleRef = ESPTab:Toggle({
    Title = "ESP (Highlight + Name)",
    Value = false,
    Callback = function(state)
        espEnabled = state
        updateESP()
        notify("ESP", state and "ON ✓" or "OFF", 1)
    end
})

ESPTab:Keybind({
    Title = "Keybind",
    Value = "ShiftRight",
    Callback = function()
        if espToggleRef then
            espToggleRef:SetState(not espToggleRef.Value)
        end
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
    Values = {"Green", "Red", "White", "Blue", "Yellow"},
    Default = "White",
    Callback = function(value)
        fovColor = value
        notify("FOV Color", value, 1)
    end
})

SettingsTab:Keybind({
    Title = "Toggle UI",
    Value = "RightShift",
    Callback = function()
        uiOpen = not uiOpen
        if uiOpen then
            openUI()
        else
            closeUI()
        end
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
setupOpenButton()
setupClickShoot()
setupFOVCircle()

-- Si es móvil, al iniciar la UI está abierta, el botón se oculta
if IsMobile then
    OpenButtonMain.Visible = false
    -- Hook para cuando la ventana se cierra/abre manualmente (por si WindUI tiene sus propios métodos)
    local originalClose = Window.Close
    local originalOpen = Window.Open
    Window.Close = function(self)
        if OpenButtonMain then OpenButtonMain.Visible = true end
        originalClose(self)
    end
    Window.Open = function(self)
        if OpenButtonMain then OpenButtonMain.Visible = false end
        originalOpen(self)
    end
end

notify("KrysHub", "[🌌] Duel Stars! (Móvil compatible)", 5)

print("==========================================")
print("KrysHub | [🌌] Duel Stars! v2.1.0")
print("Click Shoot: sin paredes")
print("ESP: Highlight + Billboard")
print("Móvil: " .. (IsMobile and "Sí" or "No"))
print("==========================================")
