-- ============================================================
-- KrysHub | Dig Deeper for Brainrots
-- ============================================================

task.wait(3)

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Txzp/Astras-Zzz/main/WindUI-main/dist/main.lua?t=" .. os.time()))()

local Window = WindUI:CreateWindow({
    Title = "KrysHub | Dig DEEPER for Brainrots!",
    Icon = "rocket",
    Theme = "Dark",
    Size = UDim2.fromOffset(450, 400),
    Folder = "KrysHub"
})

-- TABS (Formato correcto)
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house"
})

local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "shield"
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

-- SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- MOBILE
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- NOTIFICATIONS
local notificationsEnabled = true
local function notify(title, content, duration)
    if notificationsEnabled then
        WindUI:Notify({ Title = title, Content = content, Duration = duration or 2 })
    end
end

-- ZONES
local zones = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Secret", "Celestial", "Eternal", "Brainrot God"}

-- BASE POSITION
local BASE_POSITION = Vector3.new(-1012.8, 21908.9, -747.0)

-- ============================================================
-- TP ZONE
-- ============================================================
local function teleportToZone(zoneName)
    local zonesContainer = workspace:FindFirstChild("Zones")
    if not zonesContainer then
        notify("Error", "Zones not found", 2)
        return
    end
    
    local zone = zonesContainer:FindFirstChild(zoneName)
    if not zone then
        zone = zonesContainer:FindFirstChild("Visuals")
        if zone then
            zone = zone:FindFirstChild(zoneName)
        end
    end
    
    if not zone then
        notify("Error", "Zone not found", 2)
        return
    end
    
    local warden = zone:FindFirstChild("Warden")
    if not warden then
        notify("Error", "Warden not found", 2)
        return
    end
    
    local safeModel = nil
    for _, child in pairs(warden:GetChildren()) do
        if child:IsA("Model") then
            safeModel = child
            break
        end
    end
    
    if not safeModel then
        notify("Error", "Safe model not found", 2)
        return
    end
    
    local safePart = nil
    for _, part in pairs(safeModel:GetChildren()) do
        if part:IsA("BasePart") then
            safePart = part
            break
        end
    end
    
    if not safePart then
        notify("Error", "Teleport part not found", 2)
        return
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    hrp.CFrame = safePart.CFrame + Vector3.new(0, 5, 0)
    notify("Teleport", "To " .. zoneName, 2)
end

-- ============================================================
-- TP BASE
-- ============================================================
local function teleportToBase()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    hrp.CFrame = CFrame.new(BASE_POSITION) + Vector3.new(0, 3, 0)
    notify("Teleport", "To base", 2)
end

-- ============================================================
-- UI: MAIN TAB
-- ============================================================
local displayName = LocalPlayer.DisplayName or LocalPlayer.Name

MainTab:Paragraph({
    Title = "Welcome To KrysHub @ " .. displayName,
    Desc = "⛏️ Dig DEEPER for Brainrots! | v1.0.0\n\nCredit: 4kryx👑\n\nThx For Used I Love You ❤️"
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
-- UI: TELEPORT TAB
-- ============================================================
local selectedZone = "Common"

TeleportTab:Dropdown({
    Title = "Select Zone",
    Values = zones,
    Default = "Common",
    Callback = function(v) selectedZone = v end
})

TeleportTab:Button({
    Title = "📍 Teleport to Zone",
    Callback = function()
        teleportToZone(selectedZone)
    end
})

TeleportTab:Button({
    Title = "🏠 Teleport to Lobby",
    Callback = function()
        teleportToBase()
    end
})

-- ============================================================
-- UI: SETTINGS TAB
-- ============================================================
SettingsTab:Paragraph({
    Title = "KrysHub | Dig Deeper",
    Desc = "⛏️ Edited: 5/23/2026"
})

SettingsTab:Keybind({
    Title = "Toggle UI",
    Value = "RightShift",
    Callback = function()
        Window:Toggle()
    end
})

SettingsTab:Button({
    Title = "🔁 Reset UI Position",
    Callback = function()
        Window:SetToTheCenter()
        notify("UI", "Centered", 1)
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
-- MOBILE OPEN BUTTON
-- ============================================================
if IsMobile then
    local OpenButtonMain = Instance.new("TextButton")
    OpenButtonMain.Name = "OpenButtonMain"
    OpenButtonMain.Parent = game:GetService("CoreGui")
    OpenButtonMain.Size = UDim2.new(0, 50, 0, 50)
    OpenButtonMain.Position = UDim2.new(0, 15, 0, 100)
    OpenButtonMain.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    OpenButtonMain.BackgroundTransparency = 0.15
    OpenButtonMain.Text = "▶"
    OpenButtonMain.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpenButtonMain.TextSize = 24
    OpenButtonMain.Font = Enum.Font.GothamBold
    OpenButtonMain.Visible = false
    OpenButtonMain.ZIndex = 999
    
    local corner = Instance.new("UICorner", OpenButtonMain)
    corner.CornerRadius = UDim.new(1, 0)
    
    -- Draggable mobile
    local dragging = false
    local dragStart
    local startPos
    
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
            OpenButtonMain.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    OpenButtonMain.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    OpenButtonMain.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)
    
    local originalToggle = Window.Toggle
    
Window.Toggle = function(self, ...)
    local result = originalToggle(self, ...)
    
    task.wait()

    if Window and Window.GUI then
        OpenButtonMain.Visible = Window.GUI.Visible == false
    end

    return result
end

-- ============================================================
-- INIT
-- ============================================================
notify("KrysHub", "Dig Deeper | Ready", 3)

print("==========================================")
print("KrysHub | Dig Deeper")
print("==========================================")
