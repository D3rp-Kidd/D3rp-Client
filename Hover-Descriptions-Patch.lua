-- D3rp Client: UI-only hover descriptions (tooltips)
-- Add this block after the Settings controls have been created.
-- This patch intentionally targets only harmless interface/settings controls.

local GuiService = game:GetService("GuiService")

local tooltip = Instance.new("TextLabel")
tooltip.Name = "D3rpHoverDescription"
tooltip.Visible = false
tooltip.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
tooltip.BackgroundTransparency = 0.05
tooltip.BorderSizePixel = 1
tooltip.BorderColor3 = Color3.fromRGB(255, 0, 0)
tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
tooltip.Font = Enum.Font.Code
tooltip.TextSize = 13
tooltip.TextWrapped = true
tooltip.TextXAlignment = Enum.TextXAlignment.Left
tooltip.TextYAlignment = Enum.TextYAlignment.Center
tooltip.AutomaticSize = Enum.AutomaticSize.Y
tooltip.Size = UDim2.fromOffset(230, 0)
tooltip.ZIndex = 100
tooltip.Parent = gui

local tooltipPadding = Instance.new("UIPadding")
tooltipPadding.PaddingLeft = UDim.new(0, 8)
tooltipPadding.PaddingRight = UDim.new(0, 8)
tooltipPadding.PaddingTop = UDim.new(0, 6)
tooltipPadding.PaddingBottom = UDim.new(0, 6)
tooltipPadding.Parent = tooltip

local tooltipStroke = Instance.new("UIStroke")
tooltipStroke.Color = Color3.fromRGB(125, 0, 0)
tooltipStroke.Thickness = 1
tooltipStroke.Parent = tooltip

local function addHoverDescription(button, description)
    if not button or not button:IsA("GuiButton") then return end

    button.MouseEnter:Connect(function()
        tooltip.Text = description
        tooltip.Visible = true

        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        local inset = GuiService:GetGuiInset()
        local x = button.AbsolutePosition.X
        local y = button.AbsolutePosition.Y + button.AbsoluteSize.Y + 6

        -- Keep the tooltip inside the visible screen area.
        x = math.clamp(x, 6, math.max(6, viewport.X - 240))
        if y + tooltip.AbsoluteSize.Y > viewport.Y - inset.Y then
            y = button.AbsolutePosition.Y - tooltip.AbsoluteSize.Y - 6
        end
        tooltip.Position = UDim2.fromOffset(x, math.max(6, y))
    end)

    button.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
end

-- Settings and appearance controls only.
addHoverDescription(dynamicButton, "Turns smooth window opening, closing, and dragging animations on or off.")
addHoverDescription(applyMaxSpeedButton, "Saves the maximum value allowed by the Walk Speed slider.")
addHoverDescription(setHideKeyButton, "Changes the keyboard key used to hide or show the menu.")

for _, preset in ipairs(themePresets) do
    local themeButton = settingsBody:FindFirstChild(preset.name .. "ThemeButton")
    addHoverDescription(themeButton, "Changes the menu's outline and text theme to " .. preset.name .. ".")
end

-- If the separate Revert Theme patch is installed, describe its button too.
addHoverDescription(settingsBody:FindFirstChild("RevertThemeButton"), "Restores the default bright-red outlines and white text.")
