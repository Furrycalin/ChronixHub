-- UIParticleSystem.lua
-- 电脑端：鼠标在区域内移动/停留时画线
-- 手机端：只显示粒子，不追踪触摸（纯视觉效果）

local UIParticleSystem = {}
UIParticleSystem.__index = UIParticleSystem

function UIParticleSystem.new(parentUI)
    local self = setmetatable({}, UIParticleSystem)

    -- 检测设备类型
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

    -- 参数配置（手机端进一步简化）
    self.particles = {}
    self.particleCount = self.isMobile and 20 or 45      -- 手机端粒子更少
    self.particleSize = 3
    self.particleSpeed = {min = 0.2, max = 1.0}         -- 手机端速度更慢
    self.lineDistance = 120                              -- 连线距离
    self.mouseRadius = 120                               -- 鼠标影响半径
    self.lineOpacity = 0.08                              -- 线条基础透明度
    self.particleColor = Color3.fromRGB(119, 221, 255)   -- 主题色

    -- 鼠标追踪专用（电脑端）
    self.mouseInUI = false
    self.mousePos = Vector2.new(-1000, -1000)

    -- 动画控制
    self.connection = nil
    self.lastUpdate = tick()

    -- 获取UI尺寸的函数
    self.getUISize = function()
        local absSize = parentUI.AbsoluteSize
        return absSize.X, absSize.Y
    end

    self:initParticles()
    
    -- 仅在电脑端启用鼠标追踪
    if not self.isMobile then
        self:setupMouseTracking(parentUI)
    end
    
    self:startAnimation()

    return self
end

-- 创建圆形粒子
function UIParticleSystem:createCircle(parent, size, color)
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, size, 0, size)
    circle.BackgroundColor3 = color
    circle.BackgroundTransparency = 0.3
    circle.BorderSizePixel = 0
    circle.ZIndex = 11

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    circle.Parent = parent
    return circle
end

-- 初始化粒子
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
            alpha = 0.3 + math.random() * 0.3,          -- 手机端粒子更淡
            frame = nil
        }

        particle.frame = self:createCircle(self.container, particle.size, self.particleColor)
        particle.frame.Position = UDim2.new(0, particle.x - particle.size/2, 0, particle.y - particle.size/2)
        particle.frame.BackgroundTransparency = 1 - particle.alpha * 0.4

        table.insert(self.particles, particle)
    end
end

-- 电脑端鼠标追踪（移动/停留均触发）
function UIParticleSystem:setupMouseTracking(parentUI)
    local UserInputService = game:GetService("UserInputService")

    -- 检查坐标是否在 UI 内
    local function isInUI(screenPos)
        local absPos = parentUI.AbsolutePosition
        local absSize = parentUI.AbsoluteSize
        return screenPos.X >= absPos.X and screenPos.X <= absPos.X + absSize.X
            and screenPos.Y >= absPos.Y and screenPos.Y <= absPos.Y + absSize.Y
    end

    -- 鼠标移动时更新位置
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

    -- 鼠标离开 UI 区域时清除
    parentUI.MouseLeave:Connect(function()
        self.mouseInUI = false
        self.mousePos = Vector2.new(-1000, -1000)
    end)
end

-- 更新粒子位置
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

-- 绘制连线
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

            if dist < self.lineDistance and dist > 5 then
                local opacity = (1 - dist / self.lineDistance) * self.lineOpacity
                self:createLine(p1, p2, opacity)
            end
        end

        -- 电脑端鼠标连线（仅在非手机端且鼠标在UI内时）
        if not self.isMobile and self.mouseInUI and self.mousePos.X > 0 then
            local dx = p1.x - self.mousePos.X
            local dy = p1.y - self.mousePos.Y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < self.mouseRadius then
                local opacity = (1 - dist / self.mouseRadius) * 0.12  -- 线条更淡
                self:createLine(p1, {x = self.mousePos.X, y = self.mousePos.Y}, opacity)
            end
        end
    end
end

-- 创建单条线段
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

-- 启动动画循环
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
    local maxCount = self.isMobile and 35 or 70
    self.particleCount = math.min(count, maxCount)
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