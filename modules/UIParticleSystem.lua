-- UIParticleSystem.lua
-- 仅保留粒子飘动和粒子间连线，已移除鼠标/触摸追踪功能
-- 整体透明度已调低，呈现更淡雅的视觉效果

local UIParticleSystem = {}
UIParticleSystem.__index = UIParticleSystem

function UIParticleSystem.new(parentUI)
    local self = setmetatable({}, UIParticleSystem)

    -- 检测是否为手机端（仅用于调整粒子数量，不再用于追踪）
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

    -- 参数配置（调低透明度和连线密度）
    self.particles = {}
    self.particleCount = self.isMobile and 20 or 40      -- 略微减少粒子数，更清爽
    self.particleSize = 3
    self.particleSpeed = {min = 0.2, max = 1.0}          -- 速度稍慢，更舒缓
    self.lineDistance = self.isMobile and 80 or 120      -- 连线距离不变
    self.lineOpacity = 0.06                              -- **关键：线条基础透明度大幅降低（原0.2 -> 0.06）**
    self.particleColor = Color3.fromRGB(119, 221, 255)   -- 主题色

    -- 动画控制
    self.connection = nil
    self.lastUpdate = tick()

    -- 获取UI尺寸
    self.getUISize = function()
        local absSize = parentUI.AbsoluteSize
        return absSize.X, absSize.Y
    end

    self:initParticles()
    -- 已移除 self:setupTouchTracking(parentUI) 调用，不再追踪鼠标/触摸
    self:startAnimation()

    return self
end

-- 创建圆形粒子（用 Frame + UICorner）
function UIParticleSystem:createCircle(parent, size, color)
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, size, 0, size)
    circle.BackgroundColor3 = color
    circle.BackgroundTransparency = 0.7           -- **关键：粒子基础透明度提高（原0.3 -> 0.7），更淡**
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
        -- **关键：粒子的透明度范围整体下调**
        local alphaValue = 0.2 + math.random() * 0.3   -- 原0.4~0.8，现0.2~0.5，整体更淡
        
        local particle = {
            x = math.random(0, width),
            y = math.random(0, height),
            vx = (math.random() - 0.5) * (self.particleSpeed.max - self.particleSpeed.min) * 2,
            vy = (math.random() - 0.5) * (self.particleSpeed.max - self.particleSpeed.min) * 2,
            size = self.particleSize,
            alpha = alphaValue,
            frame = nil
        }

        particle.frame = self:createCircle(self.container, particle.size, self.particleColor)
        particle.frame.Position = UDim2.new(0, particle.x - particle.size/2, 0, particle.y - particle.size/2)
        -- **关键：粒子最终透明度计算方式调整，使其更淡**
        particle.frame.BackgroundTransparency = 1 - (particle.alpha * 0.6)  -- 原为 1 - particle.alpha，现整体降低浓度

        table.insert(self.particles, particle)
    end
end

-- 已移除 setupTouchTracking 函数，不再追踪鼠标/触摸

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

    -- 只画粒子之间的连线（已移除鼠标/触摸连线部分）
    for i = 1, #self.particles do
        local p1 = self.particles[i]

        for j = i + 1, #self.particles do
            local p2 = self.particles[j]
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < self.lineDistance and dist > 5 then
                -- **关键：连线透明度计算，基础透明度已调至0.06，使线条非常淡**
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
    line.InputTransparent = true  -- 让线条不干扰点击
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
    self.particleCount = math.min(count, self.isMobile and 35 or 70)
    for _, p in ipairs(self.particles) do
        if p.frame then p.frame:Destroy() end
    end
    self.particles = {}
    self:initParticles()
end

function UIParticleSystem:setLineDistance(distance)
    self.lineDistance = distance
end

-- setMouseRadius 和 setLineOpacity 方法保留但不再影响鼠标追踪（因为已移除）
-- 其中 setLineOpacity 仍然可用于调整粒子间连线的基础透明度
function UIParticleSystem:setMouseRadius(radius)
    -- 鼠标追踪已移除，此方法保留但不生效，避免调用报错
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