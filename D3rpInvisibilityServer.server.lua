-- D3rp Client server-sided invisibility handler
-- Place this Script in ServerScriptService in YOUR Roblox game.
-- The client toggle fires the RemoteEvent; this script changes replicated properties.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:FindFirstChild("D3rpInvisibilityRemote")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "D3rpInvisibilityRemote"
    remote.Parent = ReplicatedStorage
end

local invisiblePlayers = {}
local savedProperties = {}

local function saveOriginal(instance, property)
    savedProperties[instance] = savedProperties[instance] or {}
    if savedProperties[instance][property] == nil then
        savedProperties[instance][property] = instance[property]
    end
end

local function setCharacterInvisible(player, enabled)
    local character = player.Character
    if not character then return end

    if enabled then
        invisiblePlayers[player] = true
        for _, object in ipairs(character:GetDescendants()) do
            if object:IsA("BasePart") then
                saveOriginal(object, "Transparency")
                object.Transparency = 1
            elseif object:IsA("Decal") or object:IsA("Texture") then
                saveOriginal(object, "Transparency")
                object.Transparency = 1
            end
        end
    else
        invisiblePlayers[player] = nil
        for object, properties in pairs(savedProperties) do
            if object and object:IsDescendantOf(character) then
                for property, originalValue in pairs(properties) do
                    pcall(function() object[property] = originalValue end)
                end
                savedProperties[object] = nil
            end
        end
    end
end

remote.OnServerEvent:Connect(function(player, enabled)
    -- Only accept a boolean and only affect the sender's own character.
    if typeof(enabled) ~= "boolean" then return end
    setCharacterInvisible(player, enabled)
end)

local function setupPlayer(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if invisiblePlayers[player] then
            setCharacterInvisible(player, true)
        end
    end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
    invisiblePlayers[player] = nil
    for object in pairs(savedProperties) do
        if not object or not object.Parent then
            savedProperties[object] = nil
        end
    end
end)
