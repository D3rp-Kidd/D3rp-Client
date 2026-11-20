-- D3rp Client: UI-only theme revert patch
-- Apply these two changes to the Settings section of D3rp-Client.lua.
-- This patch contains only theme/UI code; it is not a standalone client script.

-- 1) Replace the existing applyTheme(color) function with this version.
local function applyTheme(color, textColor)
    ACCENT = color
    THEME_TEXT = textColor or color

    for _, object in ipairs(gui:GetDescendants()) do
        if object:IsA("UIStroke") and object.Name == "BrightRedOutline" then
            object.Color = color
        elseif object:IsA("GuiObject") and object.BorderSizePixel > 0 then
            object.BorderColor3 = color
        end

        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            object.TextColor3 = THEME_TEXT
        end

        if object:IsA("ScrollingFrame") then
            object.ScrollBarImageColor3 = color
        end
    end
end

-- 2) Add this after the loop that creates the theme preset buttons.
local revertThemeButton = Instance.new("TextButton")
revertThemeButton.Name = "RevertThemeButton"
revertThemeButton.Position = UDim2.fromOffset(0, 710)
revertThemeButton.Size = UDim2.new(1, 0, 0, 34)
styleButton(revertThemeButton, "Revert to Default Colors")
revertThemeButton.Parent = settingsBody
revertThemeButton.Activated:Connect(function()
    applyTheme(Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 255))
end)

-- Make sure the Settings ScrollingFrame canvas reaches the new button.
settingsBody.CanvasSize = UDim2.new(0, 0, 0, 760)
