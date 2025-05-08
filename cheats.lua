-- Aimbot Modülü

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local aimbot = false
local isLeftClicking = false
local TeamCheck = false
local visibility = false
local Smoothness = 1
local VisualFOV_Radius = 10
local AimBot_FOV_Radius = VisualFOV_Radius

-- FOV Görsellemesi
local function drawVisualFOV()
    -- FOV'yi çizmek için gerekli koşul
    if not Show_VisualFOV then
        if fovCircle then
            fovCircle.Visible = false
        end
        return
    end

    -- Eğer fovCircle mevcut değilse, yeni bir tane oluştur
    if not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius = VisualFOV_Radius
        fovCircle.Color = VisualFOV_Color
        fovCircle.Thickness = 1
        fovCircle.Transparency = 0.5
        fovCircle.Visible = true
    else
        -- Var olan fovCircle'ı güncelle
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius = VisualFOV_Radius
        fovCircle.Visible = true
    end
end

-- Ekran Tabanı Görünürlük Kontrolü
local function isPartVisibleOnScreen(part)
    local partPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end

    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 1000 -- uzun mesafe ray

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, rayParams)
    return result and result.Instance and part:IsDescendantOf(result.Instance.Parent)
end

-- Ekrandaki her parçayı tarama ve görünürlük kontrolü yapma
local function isVisibleOnScreen(character)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if isPartVisibleOnScreen(part) then
                return true
            end
        end
    end
    return false
end

-- Aimbot'un en yakın hedefi bulma
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            local character = player.Character
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 then
                -- Hedefin FOV'ye girmesi gerekiyor
                local screenPoint = Camera:WorldToViewportPoint(head.Position)
                local distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude

                -- FOV kontrolü yapalım
                if distance <= AimBot_FOV_Radius then
                    -- Eğer Visibility aktifse, o zaman görünürlük kontrolünü yapalım
                    if visibility and not isVisibleOnScreen(character) then
                        continue -- Eğer görünür değilse atla
                    end

                    if distance < shortestDistance then
                        shortestDistance = distance
                        closest = head -- Kafaya kilitlenme
                    end
                end
            end
        end
    end

    return closest
end

-- Mouse tuşu tıklama
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isLeftClicking = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isLeftClicking = false
    end
end)

-- Aimbot fonksiyonları
RunService.RenderStepped:Connect(function()
    -- FOV görsellemesi
    drawVisualFOV()

    -- Aimbot işlemi
    if aimbot and isLeftClicking then
        local target = getClosestPlayer()

        if target then
            local camPos = Camera.CFrame.Position
            local newLook = (target.Position - camPos).Unit
            local currentLook = Camera.CFrame.LookVector
            local lerpedLook = currentLook:Lerp(newLook, math.clamp(1 / Smoothness, 0, 1))
            Camera.CFrame = CFrame.new(camPos, camPos + lerpedLook)
        end
    end
end)

-- Return the public API of this module
return {
    ToggleAimbot = function(state)
        aimbot = state
    end,
    SetSmoothness = function(value)
        Smoothness = value
    end,
    SetFOV = function(value)
        AimBot_FOV_Radius = value
    end
}
