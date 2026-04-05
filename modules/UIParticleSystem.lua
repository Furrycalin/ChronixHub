-- UIParticleSystem.lua
-- 基于原版修改：仅调低粒子/线条透明度，并彻底移除鼠标/触摸追踪功能

local UIParticleSystem = {}
UIParticleSystem.__index = UIParticleSystem

function UIParticleSystem.new(parentUI)
    local self = setmetatable({}, UIParticleSystem)

    -- 检测设备类型（仅用于调整粒子数量，不再用于追踪）
    local UserInputService = game:GetService("UserInputService")
    self.isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

    -- 创建主容器
    self.container = Instance.new("Frame")
    self.container.Name = "ParticleSystem"
    self.container.Size = UDim2.new(1, 0, 1, 0)
    self.container.BackgroundTransparency = 1
    self.container.BorderSizePixel = 0
    self.container.ClipsDescendants = true
    self.container.ZIndex = 10
    self.container.Parent = parentUI

    -- 参数配置（调低透明度）
    self.particles = {}
    self.particleCount = self.isMobile and 25 or 50
    self.particleSize = 3
    self.particleSpeed = {min = 0.3, max = 1.2}
    self.lineDistance = self.isMobile and 80 or 120
    self.lineOpacity = 0.08          -- ✅ 线条透明度降低 (原0.2)
    self.particleColor = Color3.fromRGB(119, 221, 255)

    -- 动画控制
    self.connection = nil
    self.lastUpdate = tick()

    -- 获取UI尺寸
    self.getUISize = function()
        local absSize = parentUI.AbsoluteSize
        return absSize.X, absSize.Y
    end

    self:initParticles()
    -- ✅ 已彻底移除 setupTouchTracking 调用，不再追踪鼠标
    self:startAnimation()

    return self
end

-- 创建圆形粒子
function UIParticleSystem:createCircle(parent, size, color)
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, size, 0, size)
    circle.BackgroundColor3 = color
    circle.BackgroundTransparency = 0.6   -- ✅ 粒子基础透明度提高 (原0.3)
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
            alpha = 0.2 + math.random() * 0.3, -- ✅ 粒子透明度范围降低 (原0.4~0.8)
            frame = nil
        }

        particle.frame = self:createCircle(self.container, particle.size, self.particleColor)
        particle.frame.Position = UDim2.new(0, particle.x - particle.size/2, 0, particle.y - particle.size/2)
        -- ✅ 粒子最终透明度计算，使其更淡
        particle.frame.BackgroundTransparency = 1 - (particle.alpha * 0.6)

        table.insert(self.particles, particle)
    end
end

-- ✅ 已完全移除 setupTouchTracking 函数

function UIParticleSystem:updateParticles(deltaTime)
    local width, height = self:getUISize()
    if width == 0 or height == 0 then return end

    for _, p in ipairs(self.particles) do
        p.x = p.x + p.vx * deltaTime * 60
        p.y = p.y + p.vy * deltaTime * 60

        -- 边界反弹
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

    -- ✅ 修复：粒子之间的连线逻辑（已移除鼠标连线部分）
    for i = 1, #self.particles do
        local p1 = self.particles[i]

        for j = i + 1, #self.particles do
            local p2 = self.particles[j]
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local dist = math.sqrt(dx * dx + dy * dy)

            -- 距离小于连线阈值就画线，阈值内所有粒子对都会连接
            if dist < self.lineDistance then
                -- ✅ 线条透明度计算，使用调低后的 lineOpacity (0.08)
                local opacity = (1 - dist / self.lineDistance) * self.lineOpacity
                self:createLine(p1, p2, opacity)
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
    line.InputTransparent = true -- 让线条不干扰点击
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

-- 公共方法
function UIParticleSystem:setColor(color)
    self.particleColor = color
    for _, p in ipairs(self.particles) do
        if p.frame then
            p.frame.BackgroundColor3 = color
        end
    end
end

function UIParticleSystem:setParticleCount(count)
    self.particleCount = math.min(count, self.isMobile and 40 or 80)
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
    -- 鼠标追踪已移除，此方法保留为空，避免外部调用报错
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