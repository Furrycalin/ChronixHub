-- UIParticleSystem.lua (内存泄漏修复版)
local UIParticleSystem = {}
UIParticleSystem.__index = UIParticleSystem

function UIParticleSystem.new(parentUI)
    local self = setmetatable({}, UIParticleSystem)
    
    -- 检测是否为手机端
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
    
    -- 参数配置
    self.particles = {}
    self.lines = {}          -- ✅ 新增：存储线条对象以便复用
    self.particleCount = self.isMobile and 25 or 50
    self.particleSize = 3
    self.particleSpeed = {min = 0.3, max = 1.2}
    self.lineDistance = self.isMobile and 80 or 120
    self.lineOpacity = 0.06
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
    self:startAnimation()
    
    return self
end

-- 创建圆形粒子
function UIParticleSystem:createCircle(parent, size, color)
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, size, 0, size)
    circle.BackgroundColor3 = color
    circle.BackgroundTransparency = 0.7
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
            alpha = 0.15 + math.random() * 0.25,
            frame = nil
        }
        
        particle.frame = self:createCircle(self.container, particle.size, self.particleColor)
        particle.frame.Position = UDim2.new(0, particle.x - particle.size/2, 0, particle.y - particle.size/2)
        particle.frame.BackgroundTransparency = 1 - (particle.alpha * 0.6)
        
        table.insert(self.particles, particle)
    end
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
    local width, height = self:getUISize()
    if width == 0 or height == 0 then return end
    
    -- ✅ 修复：先隐藏所有现有线条，而不是销毁
    for _, line in ipairs(self.lines) do
        line.Visible = false
    end
    
    local lineIndex = 1
    local maxLines = #self.particles * (#self.particles - 1) / 2  -- 最大可能线条数
    
    -- 确保有足够的线条对象
    while #self.lines < maxLines and lineIndex <= maxLines do
        local line = Instance.new("Frame")
        line.Name = "Line"
        line.Size = UDim2.new(0, 0, 0, 1)
        line.BackgroundColor3 = self.particleColor
        line.BorderSizePixel = 0
        line.ZIndex = 9
        line.Visible = false
        line.Parent = self.container
        table.insert(self.lines, line)
    end
    
    -- 绘制可见的线条
    for i = 1, #self.particles do
        local p1 = self.particles[i]
        
        for j = i + 1, #self.particles do
            local p2 = self.particles[j]
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist < self.lineDistance and dist > 5 then
                local opacity = (1 - dist / self.lineDistance) * self.lineOpacity
                local line = self.lines[lineIndex]
                if line then
                    -- 更新现有线条的位置和大小
                    local angle = math.atan2(dy, dx)
                    local centerX = p1.x + dx / 2
                    local centerY = p1.y + dy / 2
                    
                    line.Size = UDim2.new(0, dist, 0, 1)
                    line.Position = UDim2.new(0, centerX - dist/2, 0, centerY - 0.5)
                    line.Rotation = math.deg(angle)
                    line.BackgroundTransparency = 1 - opacity
                    line.Visible = true
                    line.BackgroundColor3 = self.particleColor
                end
                lineIndex = lineIndex + 1
            end
        end
    end
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
    for _, line in ipairs(self.lines) do
        line.BackgroundColor3 = color
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

function UIParticleSystem:setLineOpacity(opacity)
    self.lineOpacity = opacity
end

function UIParticleSystem:destroy()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    for _, line in ipairs(self.lines) do
        line:Destroy()
    end
    if self.container then
        self.container:Destroy()
    end
end

return UIParticleSystem