-- 创建通知系统模块
local Notification = {}
notification.__index = notification

-- 通知管理器单例
local notificationManager = {
    notifications = {},
    container = nil,
    padding = 10,
    defaultDuration = 5
}

-- 初始化通知管理器
function notificationManager:Init()
    -- 确保只初始化一次
    if self.container then return end
    
    -- 创建通知容器
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationContainer"
    screenGui.IgnoreGuiInset = true  -- 忽略Roblox默认UI留出的空间
    screenGui.Parent = game.Players.LocalPlayer.PlayerGui
    
    -- 设置容器位置在右下角
    local containerFrame = Instance.new("Frame")
    containerFrame.Name = "ContainerFrame"
    containerFrame.Size = UDim2.new(0, 300, 0, 0)
    containerFrame.Position = UDim2.new(1, -10, 1, -10)
    containerFrame.AnchorPoint = Vector2.new(1, 1)
    containerFrame.BackgroundTransparency = 1
    containerFrame.Parent = screenGui
    
    self.container = screenGui
end

-- 创建新通知
function notification.new(title, description, duration)
    local self = setmetatable({}, notification)
    
    -- 设置通知属性，添加默认值防止空值
    self.title = title or "Notification"
    self.description = description or ""
    self.duration = duration or notificationManager.defaultDuration
    self.frame = nil
    self.titleText = nil
    self.descText = nil
    
    return self
end

-- 创建通知GUI元素
function notification:CreateGUI()
    -- 确保通知管理器已初始化
    if not notificationManager.container then
        notificationManager:Init()
    end
    
    -- 检查是否已经创建过GUI
    if self.frame then
        warn("Notification GUI already created")
        return
    end
    
    -- 创建通知背景框
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(1, 0, 0, 80)
    frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2) -- 深灰色背景
    frame.BorderColor3 = Color3.new(0, 0, 0) -- 黑色边框
    frame.BorderSizePixel = 1
    frame.CornerRadius = UDim.new(0, 5) -- 轻微圆角
    frame.Position = UDim2.new(1, 0, 0, 0) -- 初始位置在屏幕外
    frame.BackgroundTransparency = 0
    
    -- 添加黑色发光效果
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 10, 1, 10)
    glow.Position = UDim2.new(0, -5, 0, -5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://154967497" -- 光晕效果图片
    glow.ImageColor3 = Color3.new(0, 0, 0)
    glow.ImageTransparency = 0.7
    glow.ZIndex = -1
    glow.Parent = frame
    
    -- 创建标题文本
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -10, 0, 30)
    titleText.Position = UDim2.new(0, 5, 0, 5) -- 稍微靠上
    titleText.BackgroundTransparency = 1
    titleText.Text = self.title
    titleText.TextColor3 = Color3.new(0.8, 1, 0.5) -- 淡绿色
    titleText.TextFont = Enum.Font.SourceSansBold
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextYAlignment = Enum.TextYAlignment.Top
    titleText.Parent = frame
    
    -- 创建描述文本
    local descText = Instance.new("TextLabel")
    descText.Name = "DescriptionText"
    descText.Size = UDim2.new(1, -10, 0, 40)
    descText.Position = UDim2.new(0, 5, 0, 35)
    descText.BackgroundTransparency = 1
    descText.Text = self.description
    descText.TextColor3 = Color3.new(1, 1, 1) -- 白色
    descText.TextFont = Enum.Font.SourceSans
    descText.TextSize = 12
    descText.TextXAlignment = Enum.TextXAlignment.Left
    descText.TextYAlignment = Enum.TextYAlignment.Top
    descText.TextWrapped = true -- 支持多行显示
    descText.Parent = frame
    
    -- 添加到容器
    frame.Parent = notificationManager.container.ContainerFrame
    
    -- 保存引用
    self.frame = frame
    self.titleText = titleText
    self.descText = descText
    
    -- 调整通知位置
    self:UpdatePosition()
end

-- 更新通知位置
function notification:UpdatePosition()
    -- 检查是否有有效的frame
    if not self.frame then
        warn("Notification frame not initialized")
        return
    end
    
    local index = table.find(notificationManager.notifications, self)
    if index then
        local yOffset = (index - 1) * (self.frame.AbsoluteSize.Y + notificationManager.padding)
        self.frame.Position = UDim2.new(1, 0, 0, yOffset)
    end
end

-- 滑入动画
function notification:AnimateIn()
    -- 检查是否有有效的frame
    if not self.frame then
        warn("Notification frame not initialized")
        return
    end
    
    -- 获取TweenService
    local TweenService = game:GetService("TweenService")
    if not TweenService then
        warn("TweenService not found")
        self.frame.Position = UDim2.new(0, 0, self.frame.Position.Y.Scale, self.frame.Position.Y.Offset)
        return
    end
    
    local targetPosition = UDim2.new(0, 0, self.frame.Position.Y.Scale, self.frame.Position.Y.Offset)
    
    -- 使用TweenService创建平滑动画
    local tweenInfo = TweenInfo.new(
        0.3, -- 动画时长
        Enum.EasingStyle.Quad, -- 缓动风格
        Enum.EasingDirection.Out -- 缓动方向
    )
    
    local tween = TweenService:Create(self.frame, tweenInfo, {Position = targetPosition})
    tween:Play()
    
    -- 设置自动关闭
    delay(self.duration, function()
        self:AnimateOut()
    end)
end

-- 滑出动画
function notification:AnimateOut()
    -- 检查是否有有效的frame
    if not self.frame then
        warn("Notification frame not initialized")
        return
    end
    
    -- 获取TweenService
    local TweenService = game:GetService("TweenService")
    if not TweenService then
        warn("TweenService not found")
        self:Destroy()
        return
    end
    
    local targetPosition = UDim2.new(1, 0, self.frame.Position.Y.Scale, self.frame.Position.Y.Offset)
    
    -- 使用TweenService创建平滑动画
    local tweenInfo = TweenInfo.new(
        0.3, -- 动画时长
        Enum.EasingStyle.Quad, -- 缓动风格
        Enum.EasingDirection.In -- 缓动方向
    )
    
    local tween = TweenService:Create(self.frame, tweenInfo, {Position = targetPosition})
    tween:Play()
    
    -- 动画结束后移除通知
    tween.Completed:Connect(function()
        self:Destroy()
    end)
end

-- 销毁通知
function notification:Destroy()
    -- 从管理器中移除
    local index = table.find(notificationManager.notifications, self)
    if index then
        table.remove(notificationManager.notifications, index)
        
        -- 更新其他通知的位置
        for i, notification in ipairs(notificationManager.notifications) do
            notification:UpdatePosition()
        end
    end
    
    -- 销毁GUI元素
    if self.frame then
        self.frame:Destroy()
        self.frame = nil
    end
end

-- 播放通知音效
function notification:PlaySound(soundId)
    if not soundId or soundId == "" then return end
    
    -- 创建音效
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = self.frame or game:GetService("SoundService")
    sound:Play()
    
    -- 2秒后自动移除音效
    game.Debris:AddItem(sound, 2)
end

-- 通知管理器创建通知的方法
function notificationManager:Create(title, description, duration, soundId)
    -- 初始化管理器（如果尚未初始化）
    if not self.container then
        self:Init()
    end
    
    -- 创建新通知
    local newNotification = notification.new(title, description, duration)
    
    -- 创建GUI
    newNotification:CreateGUI()
    
    -- 添加到通知列表
    table.insert(self.notifications, newNotification)
    
    -- 更新所有通知的位置
    for i, notification in ipairs(self.notifications) do
        notification:UpdatePosition()
    end
    
    -- 播放音效
    newNotification:PlaySound(soundId)
    
    -- 开始动画
    newNotification:AnimateIn()
    
    return newNotification
end

-- 初始化通知管理器
notificationManager:Init()

-- 将通知管理器设为全局可访问
_G.Notification = notificationManager