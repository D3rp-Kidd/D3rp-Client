-- D3rp Client V1.0.3
-- LocalScript for your own Roblox Studio experience.
-- Black / bright-red interface, double outlines, Settings, and optional dynamic animations.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local RED = Color3.fromRGB(255, 0, 0)
local DARK_RED = Color3.fromRGB(125, 0, 0)
local BLACK = Color3.fromRGB(8, 8, 8)
local WHITE = Color3.fromRGB(255, 255, 255)
local PANEL = Color3.fromRGB(14, 14, 14)

local previous = playerGui:FindFirstChild("CoolGuiV2")
if previous then previous:Destroy() end
local previousHubs = playerGui:FindFirstChild("D3rpHubsGui")
if previousHubs then previousHubs:Destroy() end
local previousBaseplateHub = playerGui:FindFirstChild("D3rpJustABaseplateHubGui")
if previousBaseplateHub then previousBaseplateHub:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "CoolGuiV2"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local dynamicAnimations = true
local activeTweens = {}
local normalSizes = {}
local lastWindowSizes = {}

local function addDoubleOutline(object, thickness)
    object.BorderColor3 = RED
    object.BorderSizePixel = thickness or 2
    local stroke = Instance.new("UIStroke")
    stroke.Name = "BrightRedOutline"
    stroke.Color = RED
    stroke.Thickness = 1.5
    stroke.Transparency = 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = object
    return stroke
end

local function tween(object, duration, properties, style, direction)
    if not object or not object.Parent then return nil end
    local old = activeTweens[object]
    if old then old:Cancel() end
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
    local t = TweenService:Create(object, info, properties)
    activeTweens[object] = t
    t.Completed:Connect(function()
        if activeTweens[object] == t then activeTweens[object] = nil end
    end)
    t:Play()
    return t
end

local function animateWindow(frame, open, finalSize)
    if not frame or not frame.Parent then return end
    if not dynamicAnimations then
        frame.Visible = open
        if open and finalSize then frame.Size = finalSize end
        return
    end
    if open then
        frame.Visible = true
        local targetSize = finalSize or lastWindowSizes[frame] or normalSizes[frame]
        if not targetSize then targetSize = frame.Size end
        lastWindowSizes[frame] = targetSize
        frame:SetAttribute("AnimatingOpen", true)
        frame.Size = UDim2.fromOffset(math.max(1, targetSize.X.Offset * 0.88), math.max(1, targetSize.Y.Offset * 0.88))
        frame.BackgroundTransparency = 0.35
        local t = tween(frame, 0.22, {Size = targetSize, BackgroundTransparency = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        if t then t.Completed:Connect(function() if frame and frame.Parent then frame:SetAttribute("AnimatingOpen", false) end end) end
    else
        local size = frame.Size
        lastWindowSizes[frame] = size
        local t = tween(frame, 0.16, {Size = UDim2.fromOffset(math.max(1, size.X.Offset * 0.88), math.max(1, size.Y.Offset * 0.88)), BackgroundTransparency = 0.35}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        if t then t.Completed:Connect(function() if frame and frame.Parent then frame.Visible = false; frame.BackgroundTransparency = 0 end end) else frame.Visible = false end
    end
end

local function styleButton(button, text, color)
    button.BackgroundColor3 = BLACK
    button.BorderColor3 = RED
    button.BorderSizePixel = 1
    button.Text = text
    button.TextColor3 = color or WHITE
    button.Font = Enum.Font.Code
    button.TextSize = 15
    button.AutoButtonColor = false
    addDoubleOutline(button, 1)
    button.MouseEnter:Connect(function()
        if dynamicAnimations then tween(button, 0.1, {BackgroundColor3 = Color3.fromRGB(35, 0, 0)}) else button.BackgroundColor3 = Color3.fromRGB(35, 0, 0) end
    end)
    button.MouseLeave:Connect(function()
        if dynamicAnimations then tween(button, 0.1, {BackgroundColor3 = BLACK}) else button.BackgroundColor3 = BLACK end
    end)
end

local function makeWindow(name, title, size, position, parent)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = BLACK
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = parent
    normalSizes[frame] = size
    addDoubleOutline(frame, 3)

    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, -44, 0, 42)
    header.Position = UDim2.fromOffset(8, 0)
    header.BackgroundTransparency = 1
    header.Text = title
    header.TextColor3 = WHITE
    header.Font = Enum.Font.Code
    header.TextSize = 19
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Active = true
    header.Parent = frame

    local close = Instance.new("TextButton")
    close.Name = "CloseButton"
    close.Size = UDim2.fromOffset(34, 34)
    close.Position = UDim2.new(1, -38, 0, 4)
    styleButton(close, "X", RED)
    close.TextSize = 20
    close.ZIndex = 5
    close.Parent = frame
    return frame, header, close
end

-- Smooth custom dragging: mouse/touch movement is interpolated while animations are enabled.
local function makeDraggable(frame, handle)
    handle.Active = true
    local dragging = false
    local dragInput, dragStart, startPosition
    local targetPosition
    local dragConnection

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPosition = frame.Position
            targetPosition = frame.Position
            if dragConnection then dragConnection:Disconnect() end
            dragConnection = RunService.RenderStepped:Connect(function(dt)
                if not dragging or not targetPosition then return end
                if dynamicAnimations then
                    local alpha = 1 - math.exp(-dt * 24)
                    frame.Position = UDim2.new(
                        frame.Position.X.Scale + (targetPosition.X.Scale - frame.Position.X.Scale) * alpha,
                        frame.Position.X.Offset + (targetPosition.X.Offset - frame.Position.X.Offset) * alpha,
                        frame.Position.Y.Scale + (targetPosition.Y.Scale - frame.Position.Y.Scale) * alpha,
                        frame.Position.Y.Offset + (targetPosition.Y.Offset - frame.Position.Y.Offset) * alpha
                    )
                else
                    frame.Position = targetPosition
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            targetPosition = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and targetPosition then frame.Position = targetPosition end
            dragging = false
            if dragConnection then dragConnection:Disconnect(); dragConnection = nil end
        end
    end)
end

local main, heading, closeButton = makeWindow("Main", "D3rp Client V1.0.3", UDim2.fromOffset(350, 420), UDim2.new(0.5, -175, 0.5, -210), gui)
makeDraggable(main, heading)

-- Disconnect button sits ABOVE the main menu, outside the menu's normal content.
local disconnectButton = Instance.new("TextButton")
disconnectButton.Name = "DisconnectButton"
disconnectButton.Size = UDim2.new(1, -20, 0, 30)
disconnectButton.Position = UDim2.new(0, 10, 0, -36)
styleButton(disconnectButton, "DISCONNECT", RED)
disconnectButton.TextSize = 14
disconnectButton.ZIndex = 10
disconnectButton.Parent = main
disconnectButton.Activated:Connect(function()
    player:Kick("Disconnected by user.")
end)

local list = Instance.new("ScrollingFrame")
list.Name = "ButtonList"
list.Position = UDim2.fromOffset(10, 52)
list.Size = UDim2.new(1, -20, 1, -150)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = RED
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = main
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local creditsPage = Instance.new("Frame")
creditsPage.Name = "CreditsPage"
creditsPage.Position = UDim2.fromOffset(10, 52)
creditsPage.Size = UDim2.new(1, -20, 1, -150)
creditsPage.BackgroundColor3 = BLACK
creditsPage.Visible = false
creditsPage.Parent = main
addDoubleOutline(creditsPage, 2)
local creditsText = Instance.new("TextLabel")
creditsText.Size = UDim2.new(1, 0, 0, 140)
creditsText.Position = UDim2.fromOffset(0, 25)
creditsText.BackgroundTransparency = 1
creditsText.Text = "Credits\n\nOwner: D3rp\nBeta Testers: Bmg"
creditsText.TextColor3 = RED
creditsText.TextSize = 22
creditsText.Font = Enum.Font.Code
creditsText.Parent = creditsPage
local backButton = Instance.new("TextButton")
backButton.Size = UDim2.fromOffset(100, 32)
backButton.Position = UDim2.new(0.5, -50, 1, -45)
styleButton(backButton, "Back", RED)
backButton.TextSize = 18
backButton.Parent = creditsPage

local function getCharacter() return player.Character end
local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

-- Leet Speak remembers each label's unmodified text.
local leetEnabled = false
local originalTexts = {}
local function toLeet(text)
    local replacements = {a="4",e="3",i="1",o="0",s="5",t="7",A="4",E="3",I="1",O="0",S="5",T="7"}
    return text:gsub("[aAeEiIoOsStT]", replacements)
end
local function rememberText(object)
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        if originalTexts[object] == nil then originalTexts[object] = object.Text end
    end
end
local function updateLeet()
    for object, original in pairs(originalTexts) do
        if object and object.Parent then object.Text = leetEnabled and toLeet(original) or original end
    end
end
local function addButton(label, callback)
    local button = Instance.new("TextButton")
    button.Name = (label:gsub("[^%w]", "")) .. "Button"
    button.Size = UDim2.new(1, -5, 0, 34)
    styleButton(button, label)
    button.Parent = list
    rememberText(button)
    button.Activated:Connect(function() callback(button) end)
    return button
end

closeButton.Activated:Connect(function() gui:Destroy() end)
backButton.Activated:Connect(function() creditsPage.Visible = false; list.Visible = true end)

-- Settings window and the actual Dynamic Animations toggle.
local settingsFrame, settingsHeader, settingsClose = makeWindow("SettingsWindow", "D3rp Client - Settings", UDim2.fromOffset(360, 280), UDim2.new(0.5, 185, 0.5, -140), gui)
settingsFrame.Visible = false
makeDraggable(settingsFrame, settingsHeader)
local settingsBody = Instance.new("ScrollingFrame")
settingsBody.Name = "SettingsScrollingFrame"
settingsBody.Position = UDim2.fromOffset(10, 55)
settingsBody.Size = UDim2.new(1, -20, 1, -65)
settingsBody.BackgroundTransparency = 1
settingsBody.BorderSizePixel = 0
settingsBody.ScrollBarThickness = 6
settingsBody.ScrollBarImageColor3 = RED
settingsBody.ScrollingDirection = Enum.ScrollingDirection.Y
settingsBody.ScrollingEnabled = true
settingsBody.Active = true
settingsBody.ClipsDescendants = true
-- The content is positioned manually, so use an explicit canvas height.
-- This makes the Settings controls scroll even when the window is small.
settingsBody.AutomaticCanvasSize = Enum.AutomaticSize.None
settingsBody.CanvasSize = UDim2.new(0, 0, 0, 590)
settingsBody.Parent = settingsFrame
local dynamicButton = Instance.new("TextButton")
dynamicButton.Size = UDim2.new(1, 0, 0, 42)
styleButton(dynamicButton, "Enable Dynamic animations: ON")
dynamicButton.TextWrapped = true
dynamicButton.Parent = settingsBody
local settingsHint = Instance.new("TextLabel")
settingsHint.Position = UDim2.fromOffset(0, 46)
settingsHint.Size = UDim2.new(1, 0, 0, 42)
settingsHint.BackgroundTransparency = 1
settingsHint.Text = "Smooth dragging and window transitions.\nUtility controls are managed below."
settingsHint.TextColor3 = WHITE
settingsHint.Font = Enum.Font.Code
settingsHint.TextSize = 14
settingsHint.TextWrapped = true
settingsHint.Parent = settingsBody

-- User-configurable maximum for the Walk Speed slider.
local maxSpeedLabel = Instance.new("TextLabel")
maxSpeedLabel.Name = "MaxWalkSpeedLabel"
maxSpeedLabel.Position = UDim2.fromOffset(0, 322)
maxSpeedLabel.ZIndex = 5
maxSpeedLabel.Size = UDim2.new(1, 0, 0, 22)
maxSpeedLabel.BackgroundTransparency = 1
maxSpeedLabel.Text = "Set Max Walk Speed (1–10000)"
maxSpeedLabel.TextColor3 = WHITE
maxSpeedLabel.Font = Enum.Font.Code
maxSpeedLabel.TextSize = 14
maxSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
maxSpeedLabel.Parent = settingsBody

local maxSpeedInput = Instance.new("TextBox")
maxSpeedInput.Name = "MaxWalkSpeedInput"
maxSpeedInput.Position = UDim2.fromOffset(0, 347)
maxSpeedInput.ZIndex = 5
maxSpeedInput.Size = UDim2.new(1, 0, 0, 32)
maxSpeedInput.BackgroundColor3 = BLACK
maxSpeedInput.BorderColor3 = RED
maxSpeedInput.BorderSizePixel = 1
maxSpeedInput.TextColor3 = WHITE
maxSpeedInput.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
maxSpeedInput.PlaceholderText = "Type maximum walk speed"
maxSpeedInput.Text = tostring(maxWalkSpeed)
maxSpeedInput.ClearTextOnFocus = false
maxSpeedInput.Font = Enum.Font.Code
maxSpeedInput.TextSize = 15
maxSpeedInput.Parent = settingsBody
addDoubleOutline(maxSpeedInput, 1).Parent = maxSpeedInput
for _, child in ipairs(maxSpeedInput:GetChildren()) do
    if child:IsA("UIStroke") then child.ZIndex = 5 end
end

local applyMaxSpeedButton = Instance.new("TextButton")
applyMaxSpeedButton.Name = "ApplyMaxWalkSpeedButton"
applyMaxSpeedButton.Position = UDim2.fromOffset(0, 385)
applyMaxSpeedButton.ZIndex = 5
applyMaxSpeedButton.Size = UDim2.new(1, 0, 0, 32)
styleButton(applyMaxSpeedButton, "Apply Max Walk Speed")
applyMaxSpeedButton.Parent = settingsBody
applyMaxSpeedButton.Activated:Connect(function()
    local number = tonumber(maxSpeedInput.Text)
    if not number or number ~= number then
        maxSpeedLabel.Text = "Enter a valid number from 1 to 10000"
        return
    end
    maxWalkSpeed = math.clamp(math.floor(number + 0.5), 1, 10000)
    maxSpeedInput.Text = tostring(maxWalkSpeed)
    maxSpeedLabel.Text = "Max Walk Speed: " .. tostring(maxWalkSpeed)
    if walkSpeed > maxWalkSpeed then setWalkSpeedSlider(maxWalkSpeed) else setWalkSpeedSlider(walkSpeed) end
end)

-- Custom keybind for hiding/showing the main GUI (defaults to Q).
local hideKeyHint = Instance.new("TextLabel")
hideKeyHint.Name = "HideKeybindHint"
hideKeyHint.Position = UDim2.fromOffset(0, 435)
hideKeyHint.Size = UDim2.new(1, 0, 0, 22)
hideKeyHint.BackgroundTransparency = 1
hideKeyHint.Text = "Hide/Show keybind (current: Q)"
hideKeyHint.TextColor3 = WHITE
hideKeyHint.Font = Enum.Font.Code
hideKeyHint.TextSize = 14
hideKeyHint.TextXAlignment = Enum.TextXAlignment.Left
hideKeyHint.Parent = settingsBody

local hideKeyInput = Instance.new("TextBox")
hideKeyInput.Name = "HideKeybindInput"
hideKeyInput.Position = UDim2.fromOffset(0, 460)
hideKeyInput.Size = UDim2.new(1, 0, 0, 32)
hideKeyInput.BackgroundColor3 = BLACK
hideKeyInput.BorderColor3 = RED
hideKeyInput.BorderSizePixel = 1
hideKeyInput.TextColor3 = WHITE
hideKeyInput.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
hideKeyInput.PlaceholderText = "Type a key, e.g. Q, G, F"
hideKeyInput.Text = ""
hideKeyInput.ClearTextOnFocus = false
hideKeyInput.Font = Enum.Font.Code
hideKeyInput.TextSize = 15
hideKeyInput.Parent = settingsBody
addDoubleOutline(hideKeyInput, 1)

local setHideKeyButton = Instance.new("TextButton")
setHideKeyButton.Name = "SetHideKeybindButton"
setHideKeyButton.Position = UDim2.fromOffset(0, 498)
setHideKeyButton.Size = UDim2.new(1, 0, 0, 32)
styleButton(setHideKeyButton, "Set Hide Keybind")
setHideKeyButton.Parent = settingsBody
setHideKeyButton.Activated:Connect(function()
    local typedKey = string.upper((hideKeyInput.Text or ""):gsub("%s+", ""))
    local keyCode = Enum.KeyCode[typedKey]
    if not keyCode or keyCode == Enum.KeyCode.Unknown then
        hideKeyHint.Text = "Invalid key. Try Q, G, F, Space, etc."
        return
    end
    hideKeyCode = keyCode
    hideKeyHint.Text = "Hide/Show keybind (current: " .. typedKey .. ")"
end)

dynamicButton.Activated:Connect(function()
    dynamicAnimations = not dynamicAnimations
    dynamicButton.Text = "Enable Dynamic animations: " .. (dynamicAnimations and "ON" or "OFF")
    originalTexts[dynamicButton] = dynamicButton.Text
    updateLeet()
end)
settingsClose.Activated:Connect(function() animateWindow(settingsFrame, false) end)

-- Flight
local flying, flySpeed = false, 50
local flyConnection, flyAttachment, flyVelocity, flyOrientation
local function stopFly()
    flying = false
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
    if flyOrientation then flyOrientation:Destroy(); flyOrientation = nil end
    if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end
end
local function startFly()
    local character = getCharacter()
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = getHumanoid()
    if not root or not humanoid then return false end
    stopFly(); flying = true
    flyAttachment = Instance.new("Attachment"); flyAttachment.Parent = root
    flyVelocity = Instance.new("LinearVelocity")
    flyVelocity.Attachment0 = flyAttachment
    flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyVelocity.MaxForce = math.huge
    flyVelocity.VectorVelocity = Vector3.zero
    flyVelocity.Parent = root
    flyOrientation = Instance.new("AlignOrientation")
    flyOrientation.Attachment0 = flyAttachment
    flyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyOrientation.Responsiveness = 15
    flyOrientation.Parent = root
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying or not root.Parent then stopFly(); return end
        local camera = workspace.CurrentCamera
        if not camera then return end
        local direction = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.yAxis end
        flyVelocity.VectorVelocity = direction.Magnitude > 0 and direction.Unit * flySpeed or Vector3.zero
        flyOrientation.CFrame = camera.CFrame.Rotation
    end)
    return true
end
local function toggleFly(button)
    if flying then stopFly(); button.Text = "Fly: OFF" else if startFly() then button.Text = "Fly: ON" end end
    originalTexts[button] = button.Text; updateLeet()
end

-- Noclip
local noclipEnabled, noclipConnection = false, nil
local function setNoclip(enabled)
    noclipEnabled = enabled
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    if enabled then
        noclipConnection = RunService.Stepped:Connect(function()
            local character = player.Character
            if not character then return end
            for _, part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
        end)
    else
        local character = player.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = part.Name ~= "HumanoidRootPart" end
            end
        end
    end
end
addButton("Noclip: OFF", function(button)
    setNoclip(not noclipEnabled); button.Text = noclipEnabled and "Noclip: ON" or "Noclip: OFF"
    originalTexts[button] = button.Text; updateLeet()
end)

-- ESP
local espEnabled = false
local espFolder = Instance.new("Folder"); espFolder.Name = "D3rpESP"; espFolder.Parent = gui
local highlights = {}
local function removeESP(target)
    if highlights[target] then highlights[target]:Destroy(); highlights[target] = nil end
end
local function addESP(target)
    if target == player or not target.Character then return end
    removeESP(target)
    local highlight = Instance.new("Highlight")
    highlight.Name = "D3rpESPHighlight"; highlight.Adornee = target.Character
    highlight.FillColor = RED; highlight.OutlineColor = Color3.fromRGB(255, 40, 40)
    highlight.FillTransparency = 0.5; highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; highlight.Parent = espFolder
    highlights[target] = highlight
end
local function refreshESP()
    for _, target in ipairs(Players:GetPlayers()) do if target ~= player then if espEnabled then addESP(target) else removeESP(target) end end end
end
local function setupESPPlayer(target)
    target.CharacterAdded:Connect(function() if espEnabled then task.wait(0.5); addESP(target) end end)
end
for _, target in ipairs(Players:GetPlayers()) do setupESPPlayer(target) end
Players.PlayerAdded:Connect(function(target) setupESPPlayer(target); if espEnabled then task.wait(0.5); addESP(target) end end)
Players.PlayerRemoving:Connect(removeESP)
addButton("ESP: OFF", function(button)
    espEnabled = not espEnabled; button.Text = espEnabled and "ESP: ON" or "ESP: OFF"; refreshESP()
    originalTexts[button] = button.Text; updateLeet()
end)


-- Item ESP: highlights pickup-like objects red and watches Workspace for new items.
-- Roblox games organize items differently, so this detects Tools and Models/parts
-- whose names suggest they are pickups, weapons, consumables, or other inventory items.
local itemESPEnabled = false
local itemESPFolder = Instance.new("Folder")
itemESPFolder.Name = "D3rpItemESP"
itemESPFolder.Parent = gui
local itemHighlights = {}
local itemKeywords = {
    "item", "tool", "pickup", "pick up", "weapon", "sword", "knife",
    "gun", "ammo", "medkit", "med kit", "health", "bandage", "key",
    "coin", "gem", "collectible", "loot", "battery", "flashlight",
    "food", "drink", "potion", "artifact", "drop"
}
local function looksLikeItem(instance)
    if not instance or not instance:IsDescendantOf(workspace) then return false end
    if instance:IsA("Tool") then return true end
    if not (instance:IsA("Model") or instance:IsA("BasePart")) then return false end
    local lowerName = string.lower(instance.Name)
    for _, keyword in ipairs(itemKeywords) do
        if string.find(lowerName, keyword, 1, true) then return true end
    end
    -- A named Model that contains a Tool is also a likely item container.
    if instance:IsA("Model") then
        for _, descendant in ipairs(instance:GetDescendants()) do
            if descendant:IsA("Tool") then return true end
        end
    end
    return false
end
local function removeItemHighlight(target)
    local highlight = itemHighlights[target]
    if highlight then highlight:Destroy(); itemHighlights[target] = nil end
end
local function addItemHighlight(target)
    if not itemESPEnabled or not looksLikeItem(target) then return end
    if itemHighlights[target] and itemHighlights[target].Parent then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "D3rpRedItemHighlight"
    highlight.Adornee = target
    highlight.FillColor = RED
    highlight.OutlineColor = RED
    highlight.FillTransparency = 0.35
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = itemESPFolder
    itemHighlights[target] = highlight
end
local function scanItemESP()
    for _, instance in ipairs(workspace:GetDescendants()) do
        if looksLikeItem(instance) then addItemHighlight(instance) end
    end
end
local function clearItemESP()
    for target, highlight in pairs(itemHighlights) do
        if highlight then highlight:Destroy() end
        itemHighlights[target] = nil
    end
end
workspace.DescendantAdded:Connect(function(instance)
    if not itemESPEnabled then return end
    task.defer(function()
        if itemESPEnabled and instance.Parent then
            addItemHighlight(instance)
            -- Newly inserted Models may receive their parts a moment later.
            if instance:IsA("Model") then
                for _, descendant in ipairs(instance:GetDescendants()) do addItemHighlight(descendant) end
            end
        end
    end)
end)
workspace.DescendantRemoving:Connect(function(instance)
    removeItemHighlight(instance)
end)
addButton("Item ESP: OFF", function(button)
    itemESPEnabled = not itemESPEnabled
    button.Text = itemESPEnabled and "Item ESP: ON" or "Item ESP: OFF"
    if itemESPEnabled then scanItemESP() else clearItemESP() end
    originalTexts[button] = button.Text
    updateLeet()
end)

-- Movement
local walkSpeed, jumpPower, infiniteJump = 16, 50, false
addButton("Fly: OFF", toggleFly)
addButton("Credits", function() list.Visible = false; creditsPage.Visible = true end)

-- Draggable movement sliders (0-200), styled to match the black/red menu.
local function addMovementSlider(labelText, initialValue, onValueChanged, getMaxValue)
    local row = Instance.new("Frame")
    row.Name = labelText:gsub("%W", "") .. "SliderRow"
    row.Size = UDim2.new(1, -5, 0, 58)
    row.BackgroundColor3 = BLACK
    row.BorderSizePixel = 1
    row.BorderColor3 = RED
    row.Parent = list
    addDoubleOutline(row, 1)

    local label = Instance.new("TextLabel")
    label.Name = "SliderLabel"
    label.Position = UDim2.fromOffset(8, 2)
    label.Size = UDim2.new(1, -16, 0, 22)
    label.BackgroundTransparency = 1
    label.TextColor3 = WHITE
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "SliderValue"
    valueLabel.Position = UDim2.new(1, -48, 0, 2)
    valueLabel.Size = UDim2.fromOffset(40, 22)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = RED
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row

    local bar = Instance.new("TextButton")
    bar.Name = "SliderTrack"
    bar.Position = UDim2.new(0, 8, 0, 32)
    bar.Size = UDim2.new(1, -16, 0, 14)
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.BackgroundColor3 = Color3.fromRGB(55, 0, 0)
    bar.BorderSizePixel = 0
    bar.Active = true
    bar.Parent = row
    addDoubleOutline(bar, 1)

    local fill = Instance.new("Frame")
    fill.Name = "SliderFill"
    local function maxValue()
        return getMaxValue and getMaxValue() or 200
    end
    fill.Size = UDim2.new(math.clamp(initialValue / maxValue(), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = RED
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local value = initialValue
    local dragging = false
    local function setValue(nextValue)
        local maximum = maxValue()
        value = math.clamp(math.floor(nextValue + 0.5), 0, maximum)
        fill.Size = UDim2.new(value / maximum, 0, 1, 0)
        label.Text = labelText
        valueLabel.Text = tostring(value)
        onValueChanged(value)
    end
    local function setFromInput(input)
        local width = math.max(1, bar.AbsoluteSize.X)
        local ratio = math.clamp((input.Position.X - bar.AbsolutePosition.X) / width, 0, 1)
        setValue(ratio * maxValue())
    end
    label.Text = labelText
    valueLabel.Text = tostring(value)
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromInput(input)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromInput(input)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return setValue
end

local maxWalkSpeed = 200
local setWalkSpeedSlider = addMovementSlider("Walk Speed", walkSpeed, function(value)
    walkSpeed = value
    local humanoid = getHumanoid()
    if humanoid then humanoid.WalkSpeed = walkSpeed end
end, function() return maxWalkSpeed end)
local setJumpPowerSlider = addMovementSlider("Jump Power", jumpPower, function(value)
    jumpPower = value
    local humanoid = getHumanoid()
    if humanoid then humanoid.UseJumpPower = true; humanoid.JumpPower = jumpPower end
end)
addButton("Infinite Jump: OFF", function(button)
    infiniteJump = not infiniteJump; button.Text = infiniteJump and "Infinite Jump: ON" or "Infinite Jump: OFF"
    originalTexts[button] = button.Text; updateLeet()
end)
UIS.JumpRequest:Connect(function()
    if not infiniteJump then return end
    local humanoid = getHumanoid(); if humanoid and humanoid.Health > 0 then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
addButton("Reset Movement", function()
    walkSpeed, jumpPower = 16, 50
    setWalkSpeedSlider(walkSpeed)
    setJumpPowerSlider(jumpPower)
    local humanoid = getHumanoid()
    if humanoid then humanoid.WalkSpeed = walkSpeed; humanoid.UseJumpPower = true; humanoid.JumpPower = jumpPower end
    updateLeet()
end)

local leetButton = Instance.new("TextButton")
leetButton.Name = "LeetSpeakButton"; leetButton.Size = UDim2.fromOffset(125, 42)
leetButton.Position = UDim2.new(1, -135, 0.5, -21); styleButton(leetButton, "Enable Leet Speak", RED)
leetButton.TextWrapped = true; leetButton.Parent = gui; rememberText(leetButton)
leetButton.Activated:Connect(function()
    leetEnabled = not leetEnabled
    originalTexts[leetButton] = leetEnabled and "Disable Leet Speak" or "Enable Leet Speak"
    updateLeet()
end)

-- Hide/show controls and keyboard shortcut.
local mainHidden = false
local mainHideButton = Instance.new("TextButton")
mainHideButton.Name = "MainHideButton"; mainHideButton.Size = UDim2.new(1, -20, 0, 30)
mainHideButton.Position = UDim2.new(0, 10, 1, -85); styleButton(mainHideButton, "Hide GUI", WHITE); mainHideButton.Parent = main
local showMainButton = Instance.new("TextButton")
showMainButton.Name = "ShowMainButton"; showMainButton.Size = UDim2.fromOffset(110, 35)
showMainButton.Position = UDim2.new(0, 15, 0.5, 0); styleButton(showMainButton, "Show GUI", WHITE)
showMainButton.Visible = false; showMainButton.Parent = gui
local function hideMain()
    if mainHidden then return end
    mainHidden = true
    animateWindow(main, false)
    if dynamicAnimations then task.delay(0.17, function() if showMainButton.Parent then showMainButton.Visible = true end end) else showMainButton.Visible = true end
end
local function showMain()
    mainHidden = false; showMainButton.Visible = false; animateWindow(main, true)
end
mainHideButton.Activated:Connect(hideMain)
showMainButton.Activated:Connect(showMain)
addButton("Hide GUI (Q)", hideMain)

-- Hubs window
local hubsGui = Instance.new("ScreenGui")
hubsGui.Name = "D3rpHubsGui"; hubsGui.ResetOnSpawn = false; hubsGui.DisplayOrder = 10; hubsGui.Parent = playerGui
local hubsFrame, hubsHeader, closeHubs = makeWindow("HubsFrame", "D3rp Client - Hubs", UDim2.fromOffset(300, 250), UDim2.new(0.5, -150, 0.5, -125), hubsGui)
makeDraggable(hubsFrame, hubsHeader)
hubsFrame.Visible = false
closeHubs.Activated:Connect(function() animateWindow(hubsFrame, false) end)
local hubList = Instance.new("ScrollingFrame")
hubList.Size = UDim2.new(1, -20, 1, -60); hubList.Position = UDim2.fromOffset(10, 50)
hubList.BackgroundTransparency = 1; hubList.BorderSizePixel = 0; hubList.ScrollBarThickness = 4
hubList.ScrollBarImageColor3 = RED; hubList.AutomaticCanvasSize = Enum.AutomaticSize.Y; hubList.CanvasSize = UDim2.new(); hubList.Parent = hubsFrame
local hubLayout = Instance.new("UIListLayout"); hubLayout.Padding = UDim.new(0, 5); hubLayout.SortOrder = Enum.SortOrder.LayoutOrder; hubLayout.Parent = hubList
local function addHub(hubName, callback)
    local button = Instance.new("TextButton"); button.Size = UDim2.new(1, -5, 0, 35); styleButton(button, hubName); button.Parent = hubList
    button.Activated:Connect(callback); return button
end
addHub("Infinite Yield", function()
    local success, err = pcall(function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end)
    if not success then
        warn("Failed to load Infinite Yield: " .. tostring(err))
    end
end)
addHub("AirHub", function()
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/AirHub/main/AirHub.lua"))()
    end)
    if not success then
        warn("Failed to load AirHub: " .. tostring(err))
    end
end)
addButton("Hubs", function() animateWindow(hubsFrame, not hubsFrame.Visible) end)

-- Game-specific hub: only create the opener while in Just a baseplate.
if game.PlaceId == 123974602339071 then
    local baseplateGui = Instance.new("ScreenGui")
    baseplateGui.Name = "D3rpJustABaseplateHubGui"
    baseplateGui.ResetOnSpawn = false
    baseplateGui.DisplayOrder = 11
    baseplateGui.Parent = playerGui

    local baseplateFrame, baseplateHeader, baseplateClose = makeWindow(
        "JustABaseplateHubWindow",
        "D3rp Just a Baseplate Hub",
        UDim2.fromOffset(350, 260),
        UDim2.new(0.5, 190, 0.5, -130),
        baseplateGui
    )
    makeDraggable(baseplateFrame, baseplateHeader)
    baseplateFrame.Visible = false
    baseplateClose.Activated:Connect(function() animateWindow(baseplateFrame, false) end)

    local baseplateList = Instance.new("ScrollingFrame")
    baseplateList.Name = "HubContents"
    baseplateList.BackgroundTransparency = 1
    baseplateList.BorderSizePixel = 0
    baseplateList.ScrollBarThickness = 6
    baseplateList.ScrollBarImageColor3 = RED
    baseplateList.ScrollingDirection = Enum.ScrollingDirection.Y
    baseplateList.ScrollingEnabled = true
    baseplateList.Active = true
    baseplateList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    baseplateList.CanvasSize = UDim2.new()
    baseplateList.Position = UDim2.fromOffset(10, 55)
    baseplateList.Size = UDim2.new(1, -20, 1, -65)
    baseplateList.Parent = baseplateFrame
    local baseplateLayout = Instance.new("UIListLayout")
    baseplateLayout.Padding = UDim.new(0, 6)
    baseplateLayout.SortOrder = Enum.SortOrder.LayoutOrder
    baseplateLayout.Parent = baseplateList

    local locustButton = Instance.new("TextButton")
    locustButton.Name = "FELocustButton"
    locustButton.Size = UDim2.new(1, 0, 0, 36)
    locustButton.LayoutOrder = 1
    styleButton(locustButton, "FE locust")
    locustButton.Parent = baseplateList
    locustButton.Activated:Connect(function()
        local player = game:GetService("Players").LocalPlayer
        local messages = {
            "-gh",
            "-gh 105900284766105 89011214394076 80591929991021 74841586768030 79723296413410 71673828053110 18626055142 18625377030 17314457081 17606680159",
            "-sh",
            "-pd",
        }

        -- Send each command through whichever Roblox chat system is available.
        local function sendChatMessage(message)
            local textChatService = game:GetService("TextChatService")
            if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channels = textChatService:FindFirstChild("TextChannels")
                local general = channels and channels:FindFirstChild("RBXGeneral")
                if not general then
                    error("RBXGeneral chat channel was not found")
                end
                general:SendAsync(message)
            else
                local replicatedStorage = game:GetService("ReplicatedStorage")
                local events = replicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                local sayRequest = events and events:FindFirstChild("SayMessageRequest")
                if not sayRequest then
                    error("Legacy chat send event was not found")
                end
                sayRequest:FireServer(message, "All")
            end
        end

        local success, err = pcall(function()
            for _, message in ipairs(messages) do
                task.wait(1)
                sendChatMessage(message)
            end
            task.wait(1)
            loadstring(game:HttpGet("https://rawscripts.net/raw/UP-Just-a-baseplate.-locust-by-melon-scripter-check-the-description-for-the-hats-223048"))()
        end)
        if not success then
            warn("FE locust failed: " .. tostring(err))
        end
    end)

    local lolitaButton = Instance.new("TextButton")
    lolitaButton.Name = "LolitaGlicherButton"
    lolitaButton.Size = UDim2.new(1, 0, 0, 36)
    lolitaButton.LayoutOrder = 2
    styleButton(lolitaButton, "lolita Glicher")
    lolitaButton.Parent = baseplateList
    lolitaButton.Activated:Connect(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Jskfhggjxu/My-Script/refs/heads/main/fe-Lolita-glitcher.lua"))()
        end)
        if not success then
            warn("Failed to load lolita Glicher: " .. tostring(err))
        end
    end)

    -- TEMPLATE BUTTON 1: paste your own code inside runTemplate1().
    -- Keep the code in this function so it runs when the button is clicked.
    local function runTemplate1()
        -- PASTE YOUR SCRIPT CODE BELOW THIS LINE.
        -- Example: print("Template 1 clicked!")
        -- PASTE YOUR SCRIPT CODE ABOVE THIS LINE.
    end

    local templateButton = Instance.new("TextButton")
    templateButton.Name = "HackerX"
    templateButton.Size = UDim2.new(1, 0, 0, 36)
    templateButton.LayoutOrder = 3
    styleButton(templateButton, "HackerX")
    templateButton.Parent = baseplateList
    templateButton.Activated:Connect(function()
        local success, err = pcall(function()
            runTemplate1()
            loadstring(game:HttpGet("https://scriptblox.com/raw/UP-Just-a-baseplate.-FE-ServerHcker-X-or-Working-226068"))()
        end)
        if not success then
            warn("HackerX 1 failed: " .. tostring(err))
        end
    end)

    -- TEMPLATE BUTTON 2: paste your own code inside runTemplate2().
    local function runTemplate2()
        -- PASTE YOUR SCRIPT CODE BELOW THIS LINE.
        -- Example: print("Template 2 clicked!")
        -- PASTE YOUR SCRIPT CODE ABOVE THIS LINE.
    end

    local templateButton2 = Instance.new("TextButton")
    templateButton2.Name = "CustomScript2Button"
    templateButton2.Size = UDim2.new(1, 0, 0, 36)
    templateButton2.LayoutOrder = 4
    styleButton(templateButton2, "FE Admin Noli")
    templateButton2.Parent = baseplateList
    templateButton2.Activated:Connect(function()
        local success, err = pcall(function()
            runTemplate2()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Jskfhggjxu/My-Script/refs/heads/main/Admin%20Noli%20-%20Limb%20Reanimation.lua"))()
        end)
        if not success then
            warn("FE Admin Noli failed: " .. tostring(err))
        end
    end)

    -- TEMPLATE BUTTON 3: paste your own code inside runTemplate3().
    local function runTemplate3()
        -- PASTE YOUR SCRIPT CODE BELOW THIS LINE.
        -- Example: print("Template 3 clicked!")
        -- PASTE YOUR SCRIPT CODE ABOVE THIS LINE.
    end

    local templateButton3 = Instance.new("TextButton")
    templateButton3.Name = "CustomScript3Button"
    templateButton3.Size = UDim2.new(1, 0, 0, 36)
    templateButton3.LayoutOrder = 5
    styleButton(templateButton3, "FE Slasher")
    templateButton3.Parent = baseplateList
    templateButton3.Activated:Connect(function()
        local success, err = pcall(function()
            runTemplate3()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Jskfhggjxu/My-Script/refs/heads/main/Fe%20Forsaken%20Jason%20-%20Limb%20Reanimation%20v2.lua"))()
        end)
        if not success then
            warn("FE Slasher failed: " .. tostring(err))
        end
    end)

    local baseplateOpener = addButton("Just a Baseplate Hub", function()
        animateWindow(baseplateFrame, not baseplateFrame.Visible)
    end)
    baseplateOpener.LayoutOrder = 140
end


-- Local-only Invisibility toggle (visual effect on this client; not server-side).
local invisEnabled = false
local invisOriginals = {}

local function setCharacterInvisible(character, invisible)
    if not character then return end
    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            if invisOriginals[object] == nil then
                invisOriginals[object] = object.LocalTransparencyModifier
            end
            object.LocalTransparencyModifier = invisible and 1 or invisOriginals[object]
        elseif object:IsA("Decal") or object:IsA("Texture") then
            if invisOriginals[object] == nil then
                invisOriginals[object] = object.Transparency
            end
            object.Transparency = invisible and 1 or invisOriginals[object]
        elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") then
            if invisOriginals[object] == nil then
                invisOriginals[object] = object.Enabled
            end
            object.Enabled = invisible and false or invisOriginals[object]
        end
    end
    if not invisible then
        -- Restore and clear saved values so future character changes are tracked cleanly.
        for object, original in pairs(invisOriginals) do
            if object and object.Parent then
                pcall(function()
                    if object:IsA("BasePart") then
                        object.LocalTransparencyModifier = original
                    elseif object:IsA("Decal") or object:IsA("Texture") then
                        object.Transparency = original
                    elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") then
                        object.Enabled = original
                    end
                end)
            end
        end
        table.clear(invisOriginals)
    end
end

local invisButton = addButton("Invis: OFF (local)", function(button)
    invisEnabled = not invisEnabled
    button.Text = invisEnabled and "Invis: ON (local)" or "Invis: OFF (local)"
    originalTexts[button] = button.Text
    setCharacterInvisible(player.Character, invisEnabled)
    updateLeet()
end)
invisButton.LayoutOrder = 85

player.CharacterAdded:Connect(function(character)
    table.clear(invisOriginals)
    if invisEnabled then
        task.wait(0.25)
        setCharacterInvisible(character, true)
    end
end)

-- Music Player: plays audio locally for this client.
local musicPlayer, musicHeader, musicClose = makeWindow(
    "MusicPlayerWindow",
    "D3rp Client - Music Player",
    UDim2.fromOffset(420, 340),
    UDim2.new(0.5, -210, 0.5, -170),
    gui
)
musicPlayer.Visible = false
makeDraggable(musicPlayer, musicHeader)

local musicStatus = Instance.new("TextLabel")
musicStatus.Name = "MusicStatus"
musicStatus.Position = UDim2.fromOffset(12, 45)
musicStatus.Size = UDim2.new(1, -24, 0, 22)
musicStatus.BackgroundTransparency = 1
musicStatus.Text = "Enter a Roblox audio ID to play it."
musicStatus.TextColor3 = WHITE
musicStatus.Font = Enum.Font.Code
musicStatus.TextSize = 13
musicStatus.TextXAlignment = Enum.TextXAlignment.Left
musicStatus.Parent = musicPlayer

local soundIdInput = Instance.new("TextBox")
soundIdInput.Name = "SoundIdInput"
soundIdInput.Position = UDim2.fromOffset(12, 72)
soundIdInput.Size = UDim2.new(1, -24, 0, 36)
soundIdInput.BackgroundColor3 = BLACK
soundIdInput.BorderColor3 = RED
soundIdInput.BorderSizePixel = 1
soundIdInput.TextColor3 = WHITE
soundIdInput.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
soundIdInput.PlaceholderText = "Type Roblox Sound ID (or rbxassetid://...)"
soundIdInput.Text = ""
soundIdInput.ClearTextOnFocus = false
soundIdInput.Font = Enum.Font.Code
soundIdInput.TextSize = 14
soundIdInput.Parent = musicPlayer
addDoubleOutline(soundIdInput, 1)

local musicPlayButton = Instance.new("TextButton")
musicPlayButton.Name = "PlaySoundButton"
musicPlayButton.Position = UDim2.fromOffset(12, 116)
musicPlayButton.Size = UDim2.new(0.5, -18, 0, 34)
styleButton(musicPlayButton, "PLAY SOUND", RED)
musicPlayButton.Parent = musicPlayer

local musicStopButton = Instance.new("TextButton")
musicStopButton.Name = "StopSoundButton"
musicStopButton.Position = UDim2.new(0.5, 6, 0, 116)
musicStopButton.Size = UDim2.new(0.5, -18, 0, 34)
styleButton(musicStopButton, "STOP SOUND", WHITE)
musicStopButton.Parent = musicPlayer

local musicNowPlaying = Instance.new("TextLabel")
musicNowPlaying.Name = "NowPlaying"
musicNowPlaying.Position = UDim2.fromOffset(12, 155)
musicNowPlaying.Size = UDim2.new(1, -24, 0, 22)
musicNowPlaying.BackgroundTransparency = 1
musicNowPlaying.Text = "Built-in songs"
musicNowPlaying.TextColor3 = RED
musicNowPlaying.Font = Enum.Font.Code
musicNowPlaying.TextSize = 15
musicNowPlaying.TextXAlignment = Enum.TextXAlignment.Left
musicNowPlaying.Parent = musicPlayer

local builtInList = Instance.new("ScrollingFrame")
builtInList.Name = "BuiltInSongs"
builtInList.Position = UDim2.fromOffset(12, 180)
builtInList.Size = UDim2.new(1, -24, 1, -192)
builtInList.BackgroundTransparency = 1
builtInList.BorderSizePixel = 0
builtInList.ScrollBarThickness = 5
builtInList.ScrollBarImageColor3 = RED
builtInList.AutomaticCanvasSize = Enum.AutomaticSize.Y
builtInList.CanvasSize = UDim2.new()
builtInList.Parent = musicPlayer

local builtInLayout = Instance.new("UIListLayout")
builtInLayout.Padding = UDim.new(0, 6)
builtInLayout.SortOrder = Enum.SortOrder.LayoutOrder
builtInLayout.Parent = builtInList

local currentMusicSound
local function stopMusic()
    if currentMusicSound then
        pcall(function() currentMusicSound:Stop() end)
        currentMusicSound:Destroy()
        currentMusicSound = nil
    end
    musicStatus.Text = "Playback stopped."
end

local function playMusicId(rawId, label)
    local id = tostring(rawId or ""):gsub("%s+", "")
    id = id:gsub("^rbxassetid://", "")
    if not id:match("^%d+$") then
        musicStatus.Text = "Enter a numeric Roblox audio ID."
        return
    end
    stopMusic()
    local sound = Instance.new("Sound")
    sound.Name = "D3rpMusicPlayerSound"
    sound.SoundId = "rbxassetid://" .. id
    sound.Volume = 0.5
    sound.Looped = false
    sound.Parent = playerGui
    currentMusicSound = sound
    musicStatus.Text = "Loading audio..."
    local ok, err = pcall(function() sound:Play() end)
    if not ok then
        musicStatus.Text = "Couldn't play this audio. Check its permissions/ID."
        warn("D3rp Music Player: " .. tostring(err))
        sound:Destroy()
        currentMusicSound = nil
        return
    end
    musicNowPlaying.Text = label or ("Sound ID: " .. id)
    task.spawn(function()
        local loaded = false
        local success = pcall(function()
            sound.Loaded:Wait()
            loaded = true
        end)
        if currentMusicSound == sound and sound.Parent then
            if success and loaded then
                musicStatus.Text = "Now playing locally."
            else
                musicStatus.Text = "Audio may be unavailable or restricted."
            end
        end
    end)
    sound.Ended:Connect(function()
        if currentMusicSound == sound then
            currentMusicSound = nil
            sound:Destroy()
            musicStatus.Text = "Playback finished."
        end
    end)
end

musicPlayButton.Activated:Connect(function()
    playMusicId(soundIdInput.Text)
end)
soundIdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then playMusicId(soundIdInput.Text) end
end)
musicStopButton.Activated:Connect(stopMusic)
musicClose.Activated:Connect(function() animateWindow(musicPlayer, false) end)

-- Built-in entries are placeholders until you add your chosen audio IDs.
-- Replace the empty IDs with audio assets you own or have permission to use.
local builtInSongs = {
    {name = "Built-in Song 1", id = ""},
    {name = "Built-in Song 2", id = ""},
    {name = "Built-in Song 3", id = ""},
}
for index, song in ipairs(builtInSongs) do
    local songButton = Instance.new("TextButton")
    songButton.Name = "BuiltInSong" .. index
    songButton.Size = UDim2.new(1, -4, 0, 32)
    songButton.LayoutOrder = index
    styleButton(songButton, song.name, WHITE)
    songButton.Parent = builtInList
    songButton.Activated:Connect(function()
        if song.id == "" then
            musicStatus.Text = "Add a Sound ID for this built-in song in the script."
            return
        end
        soundIdInput.Text = song.id
        playMusicId(song.id, song.name)
    end)
end

addButton("Music Player", function()
    animateWindow(musicPlayer, not musicPlayer.Visible)
end)

-- Settings opener on the main button list.
addButton("Settings", function() animateWindow(settingsFrame, not settingsFrame.Visible) end)

-- Main and Hubs resizing controls.
local function addResizeControls(frame, minSize, maxSize, buttonText, buttonY)
    local enabled = false
    local toggle = Instance.new("TextButton")
    toggle.Name = frame.Name .. "SizableModeButton"; toggle.Size = UDim2.new(1, -20, 0, 30)
    toggle.Position = UDim2.new(0, 10, 1, buttonY); styleButton(toggle, buttonText .. ": OFF"); toggle.TextSize = 13; toggle.Parent = frame
    local handle = Instance.new("TextButton")
    handle.Name = frame.Name .. "ResizeHandle"; handle.Size = UDim2.fromOffset(22, 22)
    handle.Position = UDim2.new(1, -22, 1, -22); styleButton(handle, "↘", WHITE); handle.Visible = false; handle.Parent = frame
    local resizing, resizeStart, sizeStart = false, nil, nil
    toggle.Activated:Connect(function()
        enabled = not enabled; toggle.Text = buttonText .. ": " .. (enabled and "ON" or "OFF"); handle.Visible = enabled
    end)
    handle.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true; resizeStart = input.Position; sizeStart = frame.AbsoluteSize
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not resizing then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - resizeStart
            frame.Size = UDim2.fromOffset(math.clamp(sizeStart.X + delta.X, minSize.X, maxSize.X), math.clamp(sizeStart.Y + delta.Y, minSize.Y, maxSize.Y))
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
    end)
    return toggle, handle
end
local mainSizableButton, mainResizeHandle = addResizeControls(main, Vector2.new(300, 250), Vector2.new(650, 650), "Enable Sizable Mode", -120)
local settingsSizableButton, settingsResizeHandle = addResizeControls(settingsFrame, Vector2.new(320, 240), Vector2.new(700, 650), "Enable Settings Resizing", -45)

-- Fly speed slider in Settings.
local flySpeedLabel = Instance.new("TextLabel")
flySpeedLabel.Name = "FlySpeedLabel"
flySpeedLabel.Position = UDim2.fromOffset(0, 95)
flySpeedLabel.Size = UDim2.new(1, 0, 0, 22)
flySpeedLabel.BackgroundTransparency = 1
flySpeedLabel.TextColor3 = WHITE
flySpeedLabel.Font = Enum.Font.Code
flySpeedLabel.TextSize = 14
flySpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
flySpeedLabel.Text = "Fly Speed: " .. tostring(flySpeed)
flySpeedLabel.Parent = settingsBody

local flySpeedTrack = Instance.new("TextButton")
flySpeedTrack.Name = "FlySpeedSliderTrack"
flySpeedTrack.Position = UDim2.fromOffset(0, 120)
flySpeedTrack.Size = UDim2.new(1, 0, 0, 18)
flySpeedTrack.Text = ""
flySpeedTrack.BackgroundColor3 = Color3.fromRGB(45, 0, 0)
flySpeedTrack.BorderSizePixel = 1
flySpeedTrack.BorderColor3 = RED
flySpeedTrack.AutoButtonColor = false
flySpeedTrack.ClipsDescendants = false
flySpeedTrack.Parent = settingsBody

local flySpeedFill = Instance.new("Frame")
flySpeedFill.Name = "Fill"
flySpeedFill.Size = UDim2.new(math.clamp(flySpeed / 200, 0, 1), 0, 1, 0)
flySpeedFill.BackgroundColor3 = RED
flySpeedFill.BorderSizePixel = 0
flySpeedFill.Parent = flySpeedTrack

local flySpeedKnob = Instance.new("Frame")
flySpeedKnob.Name = "Knob"
flySpeedKnob.AnchorPoint = Vector2.new(0.5, 0.5)
flySpeedKnob.Position = UDim2.new(math.clamp(flySpeed / 200, 0, 1), 0, 0.5, 0)
flySpeedKnob.Size = UDim2.fromOffset(10, 24)
flySpeedKnob.BackgroundColor3 = WHITE
flySpeedKnob.BorderColor3 = RED
flySpeedKnob.BorderSizePixel = 1
flySpeedKnob.Parent = flySpeedTrack

local draggingFlySlider = false
local function setFlySpeedFromX(x)
    local width = math.max(1, flySpeedTrack.AbsoluteSize.X)
    local alpha = math.clamp((x - flySpeedTrack.AbsolutePosition.X) / width, 0, 1)
    flySpeed = math.clamp(math.floor(alpha * 200 + 0.5), 1, 200)
    local fraction = flySpeed / 200
    flySpeedLabel.Text = "Fly Speed: " .. tostring(flySpeed)
    flySpeedFill.Size = UDim2.new(fraction, 0, 1, 0)
    flySpeedKnob.Position = UDim2.new(fraction, 0, 0.5, 0)
end
flySpeedTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFlySlider = true
        setFlySpeedFromX(input.Position.X)
    end
end)
UIS.InputChanged:Connect(function(input)
    if draggingFlySlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        setFlySpeedFromX(input.Position.X)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFlySlider = false
    end
end)

-- Utility controls live in Settings instead of cluttering the main window.
-- These buttons are available after opening Settings.
mainSizableButton.Parent = settingsBody
mainSizableButton.Position = UDim2.fromOffset(0, 155)
mainSizableButton.Size = UDim2.new(1, 0, 0, 32)
mainSizableButton.TextSize = 13
mainHideButton.Parent = settingsBody
mainHideButton.Position = UDim2.fromOffset(0, 195)
mainHideButton.Size = UDim2.new(1, 0, 0, 32)
mainHideButton.Text = "Hide Main GUI"
mainHideButton.TextSize = 13
settingsSizableButton.Parent = settingsBody
settingsSizableButton.Position = UDim2.fromOffset(0, 235)
settingsSizableButton.Size = UDim2.new(1, 0, 0, 32)
settingsSizableButton.TextSize = 13

local resetSizesButton = Instance.new("TextButton")
resetSizesButton.Name = "ResetAllWindowSizesButton"
resetSizesButton.Position = UDim2.fromOffset(0, 275)
resetSizesButton.Size = UDim2.new(1, 0, 0, 32)
styleButton(resetSizesButton, "Reset All Window Sizes", WHITE)
resetSizesButton.TextSize = 13
resetSizesButton.Parent = settingsBody
resetSizesButton.Activated:Connect(function()
    -- Restore every resizable window to the size it had when created.
    for _, frame in ipairs({main, settingsFrame, hubsFrame}) do
        local normalSize = normalSizes[frame]
        if normalSize and frame and frame.Parent then
            lastWindowSizes[frame] = normalSize
            tween(frame, 0.2, {Size = normalSize})
        end
    end
end)

-- Keep the resize handles attached to their actual windows, not Settings.
mainResizeHandle.Parent = main
settingsResizeHandle.Parent = settingsFrame

-- Click teleport
local clickTeleportEnabled = false
addButton("Click TP: OFF", function(button)
    clickTeleportEnabled = not clickTeleportEnabled; button.Text = clickTeleportEnabled and "Click TP: ON" or "Click TP: OFF"
    originalTexts[button] = button.Text; updateLeet()
end)
mouse.Button1Down:Connect(function()
    if not clickTeleportEnabled then return end
    local target = mouse.Target; if not target then return end
    if target:IsDescendantOf(main) or target:IsDescendantOf(leetButton) or target:IsDescendantOf(hubsFrame) or target:IsDescendantOf(settingsFrame) then return end
    local character = player.Character; local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 4, 0)) end
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == hideKeyCode then
        if mainHidden then showMain() else hideMain() end
    elseif input.KeyCode == Enum.KeyCode.F then
        -- Reserved for compatibility; use the Fly button to toggle flight.
    end
end)
player.CharacterAdded:Connect(function() stopFly() end)
for _, object in ipairs(gui:GetDescendants()) do rememberText(object) end

-- Organize the main menu: gameplay/mod controls first, utility pages at the bottom.
local orderedItems = {
    FlyOFFButton = 10,
    NoclipOFFButton = 20,
    ESPOFFButton = 30,
    ItemESPOFFButton = 35,
    WalkSpeedSliderRow = 40,
    JumpPowerSliderRow = 50,
    InfiniteJumpOFFButton = 60,
    ResetMovementButton = 70,
    ClickTPOFFButton = 80,
    CreditsButton = 100,
    HideGUIQButton = 110,
    HubsButton = 120,
    SettingsButton = 130,
    JustaBaseplateHubButton = 140,
}
for _, item in ipairs(list:GetChildren()) do
    local order = orderedItems[item.Name]
    if order then
        item.LayoutOrder = order
    elseif item:IsA("GuiObject") and item ~= layout then
        -- Any future/unclassified buttons appear after the mod controls but before utilities.
        item.LayoutOrder = 90
    end
end
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Startup intro: red flashes, laugh sound, message card morphs into the main GUI.
-- Audio asset availability depends on Roblox permissions; change this ID if needed.
main.Visible = false
local introGui = Instance.new("ScreenGui")
introGui.Name = "D3rpStartupIntro"
introGui.IgnoreGuiInset = true
introGui.ResetOnSpawn = false
introGui.DisplayOrder = 100
introGui.Parent = playerGui

local flash = Instance.new("Frame")
flash.Name = "RedFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = RED
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = introGui

local introCard = Instance.new("Frame")
introCard.Name = "IntroSquare"
introCard.AnchorPoint = Vector2.new(0.5, 0.5)
introCard.Position = UDim2.fromScale(0.5, 0.5)
introCard.Size = UDim2.fromOffset(30, 30)
introCard.BackgroundColor3 = BLACK
introCard.BorderSizePixel = 0
introCard.ClipsDescendants = true
introCard.Parent = introGui
addDoubleOutline(introCard, 3)

local introText = Instance.new("TextLabel")
introText.Name = "IntroMessage"
introText.Size = UDim2.new(1, -20, 1, -20)
introText.Position = UDim2.fromOffset(10, 10)
introText.BackgroundTransparency = 1
introText.Text = "Thanks For Using D3rp Client"
introText.TextColor3 = WHITE
introText.Font = Enum.Font.Code
introText.TextSize = 20
introText.TextWrapped = true
introText.TextTransparency = 1
introText.Parent = introCard

local laugh = Instance.new("Sound")
laugh.Name = "StartupLaugh"
laugh.SoundId = "rbxassetid://80268147592899"
laugh.Volume = 0.8
laugh.Parent = introGui
pcall(function() laugh:Play() end)

task.spawn(function()
    -- Smooth red flashes, then a soft fade to black before the intro card appears.
    for i = 1, 3 do
        tween(flash, 0.22, {BackgroundColor3 = RED, BackgroundTransparency = 0.05})
        task.wait(0.22)
        tween(flash, 0.32, {BackgroundTransparency = 1})
        task.wait(0.12)
    end
    tween(flash, 0.65, {BackgroundColor3 = BLACK, BackgroundTransparency = 0})
    task.wait(0.25)
    tween(introCard, 0.55, {Size = UDim2.fromOffset(320, 150)})
    task.wait(0.3)
    tween(introText, 0.4, {TextTransparency = 0})
    task.wait(1.6)
    tween(introText, 0.35, {TextTransparency = 1})
    tween(introCard, 0.7, {Size = UDim2.fromOffset(350, 420), BackgroundTransparency = 1})
    task.wait(0.72)
    tween(flash, 0.55, {BackgroundTransparency = 1})
    task.wait(0.58)
    introGui:Destroy()
    main.Visible = true
    animateWindow(main, true, UDim2.fromOffset(350, 420))
end)

print("D3rp Client V1.0.3 loaded!")