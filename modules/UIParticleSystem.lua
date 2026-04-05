-- 模块脚本：UIParticleSystem
-- 放在ReplicatedStorage或ServerScriptService中

local UIParticleSystem = {}
UIParticleSystem.__index = UIParticleSystem

-- 创建新的粒子系统实例
function UIParticleSystem.new(parentUI)
    local self = setmetatable({}, UIParticleSystem)
    
    -- 创建主容器
    self.container = Instance.new("Frame")
    self.container.Name = "ParticleSystem"
    self.container.Size = UDim2.new(1, 0, 1, 0)
    self.container.BackgroundTransparency = 1
    self.container.BorderSizePixel = 0
    self.container.ClipsDescendants = false
    self.container.Parent = parentUI
    
    -- 创建CanvasGroup用于更好的性能
    self.canvasGroup = Instance.new("CanvasGroup")
    self.canvasGroup.Name = "ParticleCanvas"
    self.canvasGroup.Size = UDim2.new(1, 0, 1, 0)
    self.canvasGroup.BackgroundTransparency = 1
    self.canvasGroup.BorderSizePixel = 0
    self.canvasGroup.Parent = self.container
    self.canvasGroup.ZIndex = 0
    
    -- 参数配置
    self.particles = {}
    self.particleCount = 80
    self.particleSize = {min = 2, max = 4}
    self.particleSpeed = {min = 0.5, max = 2}
    self.lineDistance = 150
    self.mouseRadius = 120
    self.lineOpacity = 0.3
    self.particleColor = Color3.new(1, 1, 1) -- 白色
    
    -- 鼠标位置
    self.mousePos = Vector2.new()
    self.mouseInUI = false
    
    -- 动画连接
    self.connection = nil
    self.lastUpdate = tick()
    
    -- 获取UI绝对尺寸的函数
    self.getUISize = function()
        local absSize = parentUI.AbsoluteSize
        return absSize.X, absSize.Y
    end
    
    -- 初始化粒子
    self:initParticles()
    
    -- 设置鼠标追踪
    self:setupMouseTracking(parentUI)
    
    -- 启动动画
    self:startAnimation()
    
    return self
end

-- 初始化所有粒子
function UIParticleSystem:initParticles()
    local width, height = self:getUISize()
    if width == 0 or height == 0 then
        width = 800
        height = 600
    end
    
    for i = 1, self.particleCount do
        local particle = {
            x = math.random(0, width),
            y = math.random(0, height),
            vx = (math.random() - 0.5) * (self.particleSpeed.max - self.particleSpeed.min) * 2,
            vy = (math.random() - 0.5) * (self.particleSpeed.max - self.particleSpeed.min) * 2,
            size = math.random(self.particleSize.min, self.particleSize.max),
            alpha = 0.5 + math.random() * 0.5,
            imageLabel = nil
        }
        
        -- 创建粒子图像
        local image = Instance.new("ImageLabel")
        image.Name = "Particle_" .. i
        image.Size = UDim2.new(0, particle.size, 0, particle.size)
        image.Position = UDim2.new(0, particle.x, 0, particle.y)
        image.BackgroundTransparency = 1
        image.Image = "rbxasset://textures/ui/rounded_circle.png" -- 使用圆形图片
        image.ImageColor3 = self.particleColor
        image.ImageTransparency = 1 - particle.alpha
        image.ZIndex = 0
        image.InputTransparent = true
        image.Parent = self.canvasGroup
        
        particle.imageLabel = image
        table.insert(self.particles, particle)
    end
end

-- 设置鼠标追踪
function UIParticleSystem:setupMouseTracking(parentUI)
    -- 鼠标进入UI区域
    parentUI.MouseEnter:Connect(function()
        self.mouseInUI = true
    end)
    
    -- 鼠标离开UI区域
    parentUI.MouseLeave:Connect(function()
        self.mouseInUI = false
        self.mousePos = Vector2.new(-1000, -1000)
    end)
    
    -- 鼠标移动
    parentUI.MouseMoved:Connect(function(x, y)
        if self.mouseInUI then
            self.mousePos = Vector2.new(x, y)
        end
    end)
end

-- 更新粒子位置
function UIParticleSystem:updateParticles(deltaTime)
    local width, height = self:getUISize()
    if width == 0 or height == 0 then return end
    
    for _, particle in ipairs(self.particles) do
        -- 更新位置
        particle.x = particle.x + particle.vx * deltaTime * 60
        particle.y = particle.y + particle.vy * deltaTime * 60
        
        -- 边界反弹
        if particle.x < 0 then
            particle.x = 0
            particle.vx = -particle.vx
        elseif particle.x > width then
            particle.x = width
            particle.vx = -particle.vx
        end
        
        if particle.y < 0 then
            particle.y = 0
            particle.vy = -particle.vy
        elseif particle.y > height then
            particle.y = height
            particle.vy = -particle.vy
        end
        
        -- 更新ImageLabel位置
        if particle.imageLabel then
            particle.imageLabel.Position = UDim2.new(0, particle.x - particle.size/2, 0, particle.y - particle.size/2)
        end
    end
end

-- 绘制粒子之间的连线
function UIParticleSystem:drawLines()
    local width, height = self:getUISize()
    if width == 0 or height == 0 then return end
    
    -- 创建一个临时画布用于绘制线条（使用Frame的Tween或直接修改颜色）
    -- 由于Roblox UI限制，我们使用动态创建LineFrame的方式
    -- 为了性能，我们只在实际需要时创建/更新线条
    
    -- 清除旧的线条
    for _, child in ipairs(self.canvasGroup:GetChildren()) do
        if child:IsA("Frame") and child.Name == "LineConnection" then
            child:Destroy()
        end
    end
    
    -- 创建新的线条
    for i = 1, #self.particles do
        local p1 = self.particles[i]
        
        -- 粒子之间的连线
        for j = i + 1, #self.particles do
            local p2 = self.particles[j]
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < self.lineDistance then
                local opacity = (1 - distance / self.lineDistance) * self.lineOpacity
                self:createLine(p1, p2, opacity)
            end
        end
        
        -- 鼠标连线
        if self.mouseInUI and self.mousePos.X > 0 and self.mousePos.Y > 0 then
            local dx = p1.x - self.mousePos.X
            local dy = p1.y - self.mousePos.Y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < self.mouseRadius then
                local opacity = (1 - distance / self.mouseRadius) * 0.5
                self:createLine(p1, {x = self.mousePos.X, y = self.mousePos.Y}, opacity, true)
            end
        end
    end
end

-- 创建线条Frame
function UIParticleSystem:createLine(p1, p2, opacity, isMouseLine)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance < 0.1 then return end
    
    local angle = math.atan2(dy, dx)
    
    local line = Instance.new("Frame")
    line.Name = "LineConnection"
    line.Size = UDim2.new(0, distance, 0, 1)
    line.Position = UDim2.new(0, p1.x, 0, p1.y)
    line.Rotation = math.deg(angle)
    line.BackgroundColor3 = self.particleColor
    line.BackgroundTransparency = 1 - opacity
    line.BorderSizePixel = 0
    line.Parent = self.canvasGroup
    line.ZIndex = 0
    line.InputTransparent = true 
end

-- 动画循环
function UIParticleSystem:startAnimation()
    self.connection = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
        local currentTime = tick()
        local dt = math.min(currentTime - self.lastUpdate, 0.033) -- 限制最大帧间隔
        self.lastUpdate = currentTime
        
        self:updateParticles(dt)
        self:drawLines()
    end)
end

-- 设置粒子颜色
function UIParticleSystem:setColor(color)
    self.particleColor = color
    for _, particle in ipairs(self.particles) do
        if particle.imageLabel then
            particle.imageLabel.ImageColor3 = color
        end
    end
end

-- 设置粒子数量（需要重新初始化）
function UIParticleSystem:setParticleCount(count)
    self.particleCount = count
    self:clearParticles()
    self:initParticles()
end

-- 清除所有粒子
function UIParticleSystem:clearParticles()
    for _, particle in ipairs(self.particles) do
        if particle.imageLabel then
            particle.imageLabel:Destroy()
        end
    end
    self.particles = {}
end

-- 设置连线距离
function UIParticleSystem:setLineDistance(distance)
    self.lineDistance = distance
end

-- 设置鼠标交互半径
function UIParticleSystem:setMouseRadius(radius)
    self.mouseRadius = radius
end

-- 设置线条透明度
function UIParticleSystem:setLineOpacity(opacity)
    self.lineOpacity = opacity
end

-- 暂停动画
function UIParticleSystem:pause()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

-- 恢复动画
function UIParticleSystem:resume()
    if not self.connection then
        self:startAnimation()
    end
end

-- 销毁粒子系统
function UIParticleSystem:destroy()
    self:pause()
    self:clearParticles()
    if self.container then
        self.container:Destroy()
    end
end

return UIParticleSystem