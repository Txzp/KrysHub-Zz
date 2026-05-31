-- ============================================================
-- GnsysHub Zz | Esok Sekolah SECRET
-- Mobile: OpenButton System | PC: Keybinds
-- Speed + Jump + Fly + TP Zone + TP Base
-- SIN duplicación de loops | SIN destrucción de UI
-- ============================================================

task.wait(3)

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Txzp/KrysHub-Zz/main/WindUI-main/dist/main.lua?t=" .. os.time()))()

local Window = WindUI:CreateWindow({
    Title = "KrysHub | Esok Sekolah",
    Icon = "rocket",
    Theme = "Dark",
    Size = UDim2.fromOffset(450, 400),
    Folder = "GnsysHub"
})

-- TABS
local MovementTab = Window:Tab({ Title = "Movement", Icon = "zap" })
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "shield" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ============================================================
-- SERVICIOS
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
-- DETECCIÓN MÓVIL
-- ============================================================
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================
-- VARIABLES
-- ============================================================
local speedValue = 50
local jumpValue = 100
local flySpeed = 80

local originalWalkSpeed = 16
local originalJumpPower = 50

local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil

-- Referencias toggles
local speedToggleRef = nil
local jumpToggleRef = nil
local flyToggleRef = nil

-- Notificaciones
local notificationsEnabled = true

-- OpenButton (móvil)
local OpenButtonMain = nil

-- Loop único global
local movementConnection = nil

-- ============================================================
-- NOTIFICACIONES
-- ============================================================
local function notify(title, content, duration)
    if notificationsEnabled then
        WindUI:Notify({ Title = title, Content = content, Duration = duration or 2 })
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
-- FUNCIONES UI
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
-- LOOP ÚNICO GLOBAL (SPEED + JUMP)
-- ============================================================
local function setupMovementLoop()
    if movementConnection then return end
    
    movementConnection = RunService.RenderStepped:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        if speedToggleRef and speedToggleRef.Value then
            humanoid.WalkSpeed = speedValue
        elseif humanoid.WalkSpeed ~= originalWalkSpeed then
            humanoid.WalkSpeed = originalWalkSpeed
        end
        
        if jumpToggleRef and jumpToggleRef.Value then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = jumpValue
        elseif humanoid.JumpPower ~= originalJumpPower then
            humanoid.UseJumpPower = false
            humanoid.JumpPower = originalJumpPower
        end
    end)
end

-- ============================================================
-- DETECTAR BASE
-- ============================================================
local function getPlayerBase()
    local bases = workspace:FindFirstChild("Bases")
    if not bases then return nil end
    
    for _, base in pairs(bases:GetChildren()) do
        if base.Name == LocalPlayer.Name then
            return base
        end
    end
    
    for _, base in pairs(bases:GetChildren()) do
        local owner = base:GetAttribute("Owner") or base:GetAttribute("Player")
        if owner == LocalPlayer.Name then
            return base
        end
    end
    
    local baseList = {}
    for _, base in pairs(bases:GetChildren()) do
        table.insert(baseList, base)
    end
    
    table.sort(baseList, function(a, b)
        local numA = tonumber(a.Name) or 999
        local numB = tonumber(b.Name) or 999
        return numA < numB
    end)
    
    return baseList[1]
end

-- ============================================================
-- TP ZONE
-- ============================================================
local function teleportToZone(zoneName)
    local zones = workspace:FindFirstChild("Zones")
    if not zones then
        notify("Error", "Zones not found", 2)
        return false
    end
    
    local zone = zones:FindFirstChild(zoneName)
    if not zone then
        notify("Error", "Zone not found", 2)
        return false
    end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local teleportPos = zone:FindFirstChild("TeleportPosition") or zone:FindFirstChild("SpawnLocation")
    
    if teleportPos then
        humanoidRootPart.CFrame = teleportPos.CFrame
    else
        local targetPos = zone.CFrame.Position
        targetPos = Vector3.new(targetPos.X, targetPos.Y + 10, targetPos.Z)
        humanoidRootPart.CFrame = CFrame.new(targetPos)
    end
    
    notify("Teleport", "To " .. zoneName, 2)
    return true
end

-- ============================================================
-- TP BASE
-- ============================================================
local function teleportToBase()
    local base = getPlayerBase()
    if not base then
        notify("Error", "Base not found", 2)
        return false
    end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local spawnPoint = base:FindFirstChild("Spawn") or base:FindFirstChild("Teleport") or base
    humanoidRootPart.CFrame = spawnPoint.CFrame
    notify("Teleport", "To your base", 2)
    return true
end

-- ============================================================
-- FLY HACK
-- ============================================================
local function startFly()
    if flyConnection then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    flyBodyVelocity.Parent = humanoidRootPart
    
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.CFrame = humanoidRootPart.CFrame
    flyBodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
    flyBodyGyro.Parent = humanoidRootPart
    
    flyConnection = RunService.RenderStepped:Connect(function()
        if not (flyToggleRef and flyToggleRef.Value) or not LocalPlayer.Character then
            return
        end
        
        local cameraCFrame = Camera.CFrame
        local moveDirection = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + cameraCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - cameraCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - cameraCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + cameraCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end
        
        if flyBodyVelocity then
            flyBodyVelocity.Velocity = moveDirection * flySpeed
        end
        
        if flyBodyGyro and humanoidRootPart then
            flyBodyGyro.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + cameraCFrame.LookVector)
        end
    end)
end

local function stopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    
    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

-- ============================================================
-- UI: MOVEMENT TAB
-- ============================================================

-- Speed
speedToggleRef = MovementTab:Toggle({
    Title = "Speed Hack",
    Value = false,
    Callback = function(state)
        notify("Speed", state and "ON" or "OFF", 1)
    end
})

MovementTab:Slider({
    Title = "Speed Value",
    Value = { Min = 20, Max = 300, Default = 50 },
    Callback = function(value)
        speedValue = value
    end
})

MovementTab:Keybind({
    Title = "Key",
    Value = "V",
    Callback = function()
        if speedToggleRef then
            speedToggleRef:SetState(not speedToggleRef.Value)
        end
    end
})

-- Jump
jumpToggleRef = MovementTab:Toggle({
    Title = "Jump Hack",
    Value = false,
    Callback = function(state)
        notify("Jump", state and "ON" or "OFF", 1)
    end
})

MovementTab:Slider({
    Title = "Jump Value",
    Value = { Min = 50, Max = 300, Default = 100 },
    Callback = function(value)
        jumpValue = value
    end
})

-- Fly
flyToggleRef = MovementTab:Toggle({
    Title = "Fly Hack",
    Value = false,
    Callback = function(state)
        if state then
            startFly()
        else
            stopFly()
        end
        notify("Fly", state and "ON" or "OFF", 1)
    end
})

MovementTab:Slider({
    Title = "Fly Value",
    Value = { Min = 50, Max = 500, Default = 80 },
    Callback = function(value)
        flySpeed = value
    end
})

MovementTab:Keybind({
    Title = "Key",
    Value = "F",
    Callback = function()
        if flyToggleRef then
            flyToggleRef:SetState(not flyToggleRef.Value)
        end
    end
})

-- ============================================================
-- UI: TELEPORT TAB
-- ============================================================

local selectedZone = "OG"

TeleportTab:Dropdown({
    Title = "Select Zone",
    Values = {"Common", "Epic", "God", "Legendary", "Mythic", "OG", "Rare", "Secret"},
    Default = "OG",
    Callback = function(value)
        selectedZone = value
    end
})

TeleportTab:Button({
    Title = "Teleport to Zone",
    Callback = function()
        teleportToZone(selectedZone)
    end
})

TeleportTab:Button({
    Title = "Teleport to My Base",
    Callback = function()
        teleportToBase()
    end
})

-- ============================================================
-- UI: SETTINGS TAB
-- ============================================================

SettingsTab:Paragraph({
    Title = "Esok Sekolah | v1.3.1",
    Desc = "Credit: 4gnx👑\n\n📢: UPDATE COMING\n📢: Join Server Discord For More"
})

SettingsTab:Button({
    Title = "Server Link",
    Callback = function()
        setclipboard("https://discord.gg/BfZGVSguC")
        notify("Discord", "Link copied", 1)
    end
})

SettingsTab:Toggle({
    Title = "Notifications",
    Value = true,
    Callback = function(state)
        notificationsEnabled = state
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

-- ============================================================
-- INICIALIZACIÓN
-- ============================================================

setupOpenButton()
setupMovementLoop()

if IsMobile then
    local originalClose = Window.Close
    local originalOpen = Window.Open
    
    Window.Close = function(self)
        if OpenButtonMain then
            OpenButtonMain.Visible = true
        end
        originalClose(self)
    end
    
    Window.Open = function(self)
        if OpenButtonMain then
            OpenButtonMain.Visible = false
        end
        originalOpen(self)
    end
end

notify("KrysHub", "Loading KrysHub | Esok Sekolah", 3)

print("[KrysHub] Script Working")
print("[KrysHub] Mobile: " .. (IsMobile and "SÍ" or "NO"))
