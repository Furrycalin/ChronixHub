-- 创建通知系统模块
local Notification = {}
Notification.__index = Notification

-- 通知管理器单例
local NotificationManager = {
    notifications = {},
    container = nil,
    padding = 10,
    defaultDuration = 5
}

-- 初始化通知管理器
function NotificationManager:Init()
    -- 创建通知容器
    self.container = Instance.new("ScreenGui")
    self.container.Name = "NotificationContainer"
    self.container.Parent = game.Players.LocalPlayer.PlayerGui
    
    -- 设置容器位置在右下角
    local containerFrame = Instance.new("Frame")
    containerFrame.Name = "ContainerFrame"
    containerFrame.Size = UDim2.new(0, 300, 0, 0)
    containerFrame.Position = UDim2.new(1, -10, 1, -10)
    containerFrame.AnchorPoint = Vector2.new(1, 1)
    containerFrame.BackgroundTransparency = 1
    containerFrame.Parent = self.container
end

-- 创建新通知
function Notification.new(title, description, duration)
    local self = setmetatable({}, Notification)
    
    -- 设置通知属性
    self.title = title or "Notification"
    self.description = description or ""
    self.duration = duration or NotificationManager.defaultDuration
    
    -- 创建通知GUI
    self:CreateGUI()
    
    return self
end

-- 创建通知GUI元素
function Notification:CreateGUI()
    -- 创建通知背景框
    self.frame = Instance.new("Frame")
    self.frame.Name = "NotificationFrame"
    self.frame.Size = UDim2.new(1, 0, 0, 80)
    self.frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2) -- 深灰色背景
    self.frame.BorderColor3 = Color3.new(0, 0, 0) -- 黑色边框
    self.frame.BorderSizePixel = 1
    self.frame.CornerRadius = UDim.new(0, 5) -- 轻微圆角
    self.frame.Position = UDim2.new(1, 0, 0, 0) -- 初始位置在屏幕外
    self.frame.BackgroundTransparency = 0
    
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
    glow.Parent = self.frame
    
    -- 创建标题文本
    self.titleText = Instance.new("TextLabel")
    self.titleText.Name = "TitleText"
    self.titleText.Size = UDim2.new(1, -10, 0, 30)
    self.titleText.Position = UDim2.new(0, 5, 0, 5) -- 稍微靠上
    self.titleText.BackgroundTransparency = 1
    self.titleText.Text = self.title
    self.titleText.TextColor3 = Color3.new(0.8, 1, 0.5) -- 淡绿色
    self.titleText.TextFont = Enum.Font.SourceSansBold
    self.titleText.TextSize = 16
    self.titleText.TextXAlignment = Enum.TextXAlignment.Left
    self.titleText.TextYAlignment = Enum.TextYAlignment.Top
    self.titleText.Parent = self.frame
    
    -- 创建描述文本
    self.descText = Instance.new("TextLabel")
    self.descText.Name = "DescriptionText"
    self.descText.Size = UDim2.new(1, -10, 0, 40)
    self.descText.Position = UDim2.new(0, 5, 0, 35)
    self.descText.BackgroundTransparency = 1
    self.descText.Text = self.description
    self.descText.TextColor3 = Color3.new(1, 1, 1) -- 白色
    self.descText.TextFont = Enum.Font.SourceSans
    self.descText.TextSize = 12
    self.descText.TextXAlignment = Enum.TextXAlignment.Left
    self.descText.TextYAlignment = Enum.TextYAlignment.Top
    self.descText.TextWrapped = true -- 支持多行显示
    self.descText.Parent = self.frame
    
    -- 添加到容器
    self.frame.Parent = NotificationManager.container.ContainerFrame
    
    -- 调整通知位置
    self:UpdatePosition()
    
    -- 播放弹出音效
    if self.soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = self.soundId
        sound.Volume = 0.5
        sound.Parent = self.frame
        sound:Play()
        game.Debris:AddItem(sound, 2)
    end
    
    -- 开始动画
    self:AnimateIn()
end

-- 更新通知位置
function Notification:UpdatePosition()
    local index = table.find(NotificationManager.notifications, self)
    if index then
        local yOffset = (index - 1) * (self.frame.AbsoluteSize.Y + NotificationManager.padding)
        self.frame.Position = UDim2.new(1, 0, 0, yOffset)
    end
end

-- 滑入动画
function Notification:AnimateIn()
    local targetPosition = self.frame.Position - UDim2.new(1, 0, 0, 0)
    
    -- 使用TweenService创建平滑动画
    local TweenService = game:GetService("TweenService")
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
function Notification:AnimateOut()
    local targetPosition = self.frame.Position + UDim2.new(1, 0, 0, 0)
    
    -- 使用TweenService创建平滑动画
    local TweenService = game:GetService("TweenService")
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
function Notification:Destroy()
    -- 从管理器中移除
    local index = table.find(NotificationManager.notifications, self)
    if index then
        table.remove(notificationManager.notifications, index)
        
        -- 更新其他通知的位置
        for i, notification in ipairs(notificationManager.notifications) do
            notification:UpdatePosition()
        end
    end
    
    -- 销毁GUI元素
    self.frame:Destroy()
end

-- 通知管理器创建通知的方法
function NotificationManager:Create(title, description, duration, soundId)
    -- 初始化管理器（如果尚未初始化）
    if not self.container then
        self:Init()
    end
    
    -- 创建新通知
    local newNotification = notification.new(title, description, duration)
    newNotification.soundId = soundId
    
    -- 添加到通知列表
    table.insert(self.notifications, newNotification)
    
    -- 更新所有通知的位置
    for i, notification in ipairs(self.notifications) do
        notification:UpdatePosition()
    end
    
    return newNotification
end

-- 初始化通知管理器
NotificationManager:Init()

-- 将通知管理器设为全局可访问
_G.Notification = NotificationManager