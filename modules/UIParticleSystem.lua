-- UIParticleSystem.lua
local UIParticleSystem = {}
UIParticleSystem.__index = UIParticleSystem

function UIParticleSystem.new(parentUI)
    local self = setmetatable({}, UIParticleSystem)

    local UserInputService = game:GetService("UserInputService")
    self.isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

    self.container = Instance.new("Frame")
    self.container.Name = "ParticleSystem"
    self.container.Size = UDim2.new(1, 0, 1, 0)
    self.container.BackgroundTransparency = 1
    self.container.BorderSizePixel = 0
    self.container.ClipsDescendants = true
    self.container.ZIndex = 10
    self.container.Parent = parentUI

    self.particles = {}
    self.particleCount = 45
    self.particleSize = 3
    self.particleSpeed = {min = 0.3, max = 1.2}
    self.lineDistance = 120
    self.mouseRadius = 120
    self.lineOpacity = 0.15
    self.particleColor = Color3.fromRGB(119, 221, 255)

    self.mouseInUI = false
    self.mousePos = Vector2.new(-1000, -1000)

    self.connection = nil
    self.lastUpdate = tick()

    self.getUISize = function()
        local absSize = parentUI.AbsoluteSize
        return absSize.X, absSize.Y
    end

    self:initParticles()
    self:setupMouseTracking(parentUI)
    self:startAnimation()

    return self
end

function UIParticleSystem:createCircle(parent, size, color)
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, size, 0, size)
    circle.BackgroundColor3 = color
    circle.BackgroundTransparency = 0.5
    circle.BorderSizePixel = 0
    circle.ZIndex = 11

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    circle.Parent = parent
    return circle
end

function UIParticleSystem:initParticles()
    local width, height = self:getUISize()
    if width == 0 or height == 0 then
        width = 500
        height = 500
    end

    for i = 1, self.particleCount do
        local particle = {
            x = math.random(0, width),
            y = math.random(0, height),
            vx = (math.random() - 0.5) * (self.particleSpeed.max - self.particleSpeed.min) * 2,
            vy = (math.random() - 0.5) * (self.particleSpeed.max - self.particleSpeed.min) * 2,
            size = self.particleSize,
            alpha = 0.3 + math.random() * 0.3,
            frame = nil
        }

        particle.frame = self:createCircle(self.container, particle.size, self.particleColor)
        particle.frame.Position = UDim2.new(0, particle.x - particle.size/2, 0, particle.y - particle.size/2)
        particle.frame.BackgroundTransparency = 1 - particle.alpha * 0.6

        table.insert(self.particles, particle)
    end
end

function UIParticleSystem:setupMouseTracking(parentUI)
    local UserInputService = game:GetService("UserInputService")

    local function isInUI(screenPos)
        local absPos = parentUI.AbsolutePosition
        local absSize = parentUI.AbsoluteSize
        return screenPos.X >= absPos.X and screenPos.X <= absPos.X + absSize.X
            and screenPos.Y >= absPos.Y and screenPos.Y <= absPos.Y + absSize.Y
    end

    -- 鼠标移动
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = input.Position
            if isInUI(pos) then
                self.mouseInUI = true
                self.mousePos = Vector2.new(pos.X, pos.Y)
            else
                self.mouseInUI = false
                self.mousePos = Vector2.new(-1000, -1000)
            end
        end
    end)

    -- 鼠标离开
    parentUI.MouseLeave:Connect(function()
        self.mouseInUI = false
        self.mousePos = Vector2.new(-1000, -1000)
    end)
    
    -- 鼠标进入
    parentUI.MouseEnter:Connect(function()
        self.mouseInUI = true
    end)
end

function UIParticleSystem:updateParticles(deltaTime)
    local width, height = self:getUISize()
    if width == 0 or height == 0 then return end

    for _, p in ipairs(self.particles) do
        p.x = p.x + p.vx * deltaTime * 60
        p.y = p.y + p.vy * deltaTime * 60

        if p.x < -10 then
            p.x = -10
            p.vx = -p.vx
        elseif p.x > width + 10 then
            p.x = width + 10
            p.vx = -p.vx
        end

        if p.y < -10 then
            p.y = -10
            p.vy = -p.vy
        elseif p.y > height + 10 then
            p.y = height + 10
            p.vy = -p.vy
        end

        if p.frame then
            p.frame.Position = UDim2.new(0, p.x - p.size/2, 0, p.y - p.size/2)
        end
    end
end

function UIParticleSystem:drawLines()
    -- 清除旧线条
    for _, child in ipairs(self.container:GetChildren()) do
        if child:IsA("Frame") and child.Name == "Line" then
            child:Destroy()
        end
    end

    local width, height = self:getUISize()
    if width == 0 or height == 0 then return end

    -- 粒子之间的连线
    for i = 1, #self.particles do
        local p1 = self.particles[i]

        for j = i + 1, #self.particles do
            local p2 = self.particles[j]
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < self.lineDistance then
                local opacity = (1 - dist / self.lineDistance) * self.lineOpacity
                self:createLine(p1, p2, opacity)
            end
        end

        -- 鼠标连线
        if self.mouseInUI and self.mousePos.X > 0 then
            local dx = p1.x - self.mousePos.X
            local dy = p1.y - self.mousePos.Y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < self.mouseRadius then
                local opacity = (1 - dist / self.mouseRadius) * 0.2
                self:createLine(p1, {x = self.mousePos.X, y = self.mousePos.Y}, opacity)
            end
        end
    end
end

function UIParticleSystem:createLine(p1, p2, opacity)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < 0.5 then return end

    local angle = math.atan2(dy, dx)
    local centerX = p1.x + dx / 2
    local centerY = p1.y + dy / 2

    local line = Instance.new("Frame")
    line.Name = "Line"
    line.Size = UDim2.new(0, dist, 0, 1)
    line.Position = UDim2.new(0, centerX - dist/2, 0, centerY - 0.5)
    line.Rotation = math.deg(angle)
    line.BackgroundColor3 = self.particleColor
    line.BackgroundTransparency = 1 - opacity
    line.BorderSizePixel = 0
    line.ZIndex = 9
    line.InputTransparent = true
    line.Parent = self.container
end

function UIParticleSystem:startAnimation()
    self.connection = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
        local now = tick()
        local dt = math.min(now - self.lastUpdate, 0.033)
        self.lastUpdate = now

        self:updateParticles(dt)
        self:drawLines()
    end)
end

function UIParticleSystem:setColor(color)
    self.particleColor = color
    for _, p in ipairs(self.particles) do
        if p.frame then
            p.frame.BackgroundColor3 = color
        end
    end
end

function UIParticleSystem:setParticleCount(count)
    self.particleCount = math.min(count, 80)
    for _, p in ipairs(self.particles) do
        if p.frame then p.frame:Destroy() end
    end
    self.particles = {}
    self:initParticles()
end

function UIParticleSystem:setLineDistance(distance)
    self.lineDistance = distance
end

function UIParticleSystem:setMouseRadius(radius)
    self.mouseRadius = radius
end

function UIParticleSystem:setLineOpacity(opacity)
    self.lineOpacity = opacity
end

function UIParticleSystem:destroy()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.container then
        self.container:Destroy()
    end
end

return UIParticleSystem