-- 通知系统模块
local NotificationSystem = {}

-- 模块配置
local config = {
    notificationWidth = 300,
    notificationHeight = 80,
    padding = 10,
    defaultDuration = 5,
    glowImageId = "rbxassetid://154967497",
    cornerRadius = 5 -- 圆角半径（像素）
}

-- 通知管理器
local notificationManager = {
    container = nil,
    notifications = {}
}

-- 初始化通知管理器
local function initNotificationManager()
    -- 防止重复初始化
    if notificationManager.container then return end
    
    -- 创建通知容器
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationSystem"
    screenGui.IgnoreGuiInset = true  -- 忽略Roblox默认UI留出的空间
    screenGui.Parent = game.Players.LocalPlayer.PlayerGui
    
    -- 设置容器位置在右下角
    local containerFrame = Instance.new("Frame")
    containerFrame.Name = "NotificationContainer"
    containerFrame.Size = UDim2.new(0, config.notificationWidth, 0, 0)
    containerFrame.Position = UDim2.new(1, -10, 1, -10)
    containerFrame.AnchorPoint = Vector2.new(1, 1)
    containerFrame.BackgroundTransparency = 1
    containerFrame.Parent = screenGui
    
    notificationManager.container = screenGui
end

-- 创建单个通知
local function createNotificationObject(title, description, duration, soundId)
    -- 确保管理器已初始化
    initNotificationManager()
    
    -- 创建通知背景框
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(1, 0, 0, config.notificationHeight)
    notificationFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2) -- 深灰色背景
    notificationFrame.BorderColor3 = Color3.new(0, 0, 0) -- 黑色边框
    notificationFrame.BorderSizePixel = 1
    notificationFrame.Position = UDim2.new(1, 0, 0, 0) -- 初始位置在屏幕外
    notificationFrame.BackgroundTransparency = 0
    notificationFrame.Parent = notificationManager.container.NotificationContainer
    
    -- 添加圆角效果（替代直接设置CornerRadius属性）
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, config.cornerRadius)
    corner.Parent = notificationFrame
    
    -- 添加黑色发光效果
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 10, 1, 10)
    glow.Position = UDim2.new(0, -5, 0, -5)
    glow.BackgroundTransparency = 1
    glow.Image = config.glowImageId
    glow.ImageColor3 = Color3.new(0, 0, 0)
    glow.ImageTransparency = 0.7
    glow.ZIndex = -1
    glow.Parent = notificationFrame
    
    -- 创建标题文本
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -10, 0, 30)
    titleText.Position = UDim2.new(0, 5, 0, 5) -- 稍微靠上
    titleText.BackgroundTransparency = 1
    titleText.Text = title or "Notification"
    titleText.TextColor3 = Color3.new(0.8, 1, 0.5) -- 淡绿色
    titleText.Font = Enum.Font.SourceSansBold -- 替换TextFont为Font
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextYAlignment = Enum.TextYAlignment.Top
    titleText.Parent = notificationFrame
    
    -- 创建描述文本
    local descText = Instance.new("TextLabel")
    descText.Name = "DescriptionText"
    descText.Size = UDim2.new(1, -10, 0, 40)
    descText.Position = UDim2.new(0, 5, 0, 35)
    descText.BackgroundTransparency = 1
    descText.Text = description or ""
    descText.TextColor3 = Color3.new(1, 1, 1) -- 白色
    descText.Font = Enum.Font.SourceSans -- 替换TextFont为Font
    descText.TextSize = 12
    descText.TextXAlignment = Enum.TextXAlignment.Left
    descText.TextYAlignment = Enum.TextYAlignment.Top
    descText.TextWrapped = true -- 支持多行显示
    descText.Parent = notificationFrame
    
    -- 创建通知对象
    local notification = {
        frame = notificationFrame,
        titleText = titleText,
        descText = descText,
        duration = duration or config.defaultDuration,
        soundId = soundId
    }
    
    -- 添加到通知列表
    table.insert(notificationManager.notifications, notification)
    
    return notification
end

-- 更新所有通知的位置
local function updateNotificationPositions()
    for i, notification in ipairs(notificationManager.notifications) do
        if notification.frame and notification.frame.Parent then
            local yOffset = (i - 1) * (config.notificationHeight + config.padding)
            notification.frame.Position = UDim2.new(1, 0, 0, yOffset)
        end
    end
end

-- 播放通知音效
local function playNotificationSound(soundId)
    if not soundId or soundId == "" then return end
    
    -- 创建音效
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = game:GetService("SoundService")
    sound:Play()
    
    -- 2秒后自动移除音效
    game.Debris:AddItem(sound, 2)
end

-- 滑入动画
local function animateNotificationIn(notification)
    if not notification or not notification.frame then return end
    
    -- 获取TweenService
    local TweenService = game:GetService("TweenService")
    if not TweenService then
        warn("TweenService not found, notification will appear immediately")
        notification.frame.Position = UDim2.new(0, 0, notification.frame.Position.Y.Scale, notification.frame.Position.Y.Offset)
        return
    end
    
    local targetPosition = UDim2.new(0, 0, notification.frame.Position.Y.Scale, notification.frame.Position.Y.Offset)
    
    -- 创建滑入动画
    local tweenInfo = TweenInfo.new(
        0.3, -- 动画时长
        Enum.EasingStyle.Quad, -- 缓动风格
        Enum.EasingDirection.Out -- 缓动方向
    )
    
    local tween = TweenService:Create(notification.frame, tweenInfo, {Position = targetPosition})
    tween:Play()
    
    return tween
end

-- 滑出动画
local function animateNotificationOut(notification, onComplete)
    if not notification or not notification.frame then 
        if onComplete then onComplete() end
        return 
    end
    
    -- 获取TweenService
    local TweenService = game:GetService("TweenService")
    if not TweenService then
        warn("TweenService not found, notification will be removed immediately")
        if notification.frame and notification.frame.Parent then
            notification.frame:Destroy()
        end
        if onComplete then onComplete() end
        return
    end
    
    local targetPosition = UDim2.new(1, 0, notification.frame.Position.Y.Scale, notification.frame.Position.Y.Offset)
    
    -- 创建滑出动画
    local tweenInfo = TweenInfo.new(
        0.3, -- 动画时长
        Enum.EasingStyle.Quad, -- 缓动风格
        Enum.EasingDirection.In -- 缓动方向
    )
    
    local tween = TweenService:Create(notification.frame, tweenInfo, {Position = targetPosition})
    tween:Play()
    
    -- 动画结束后移除通知
    tween.Completed:Connect(function()
        if notification.frame and notification.frame.Parent then
            notification.frame:Destroy()
        end
        if onComplete then onComplete() end
    end)
    
    return tween
end

-- 移除通知并更新位置
local function removeNotification(notification)
    if not notification then return end
    
    -- 从列表中移除
    local index = table.find(notificationManager.notifications, notification)
    if index then
        table.remove(notificationManager.notifications, index)
        
        -- 更新其他通知的位置
        updateNotificationPositions()
    end
end

-- 创建通知的主函数
function NotificationSystem:CreateNotification(title, description, duration, soundId)
    -- 创建通知对象
    local notification = createNotificationObject(title, description, duration, soundId)
    
    -- 更新所有通知的位置
    updateNotificationPositions()
    
    -- 播放音效
    playNotificationSound(soundId)
    
    -- 启动滑入动画
    local slideInTween = animateNotificationIn(notification)
    
    -- 设置自动关闭
    delay(notification.duration, function()
        -- 启动滑出动画
        animateNotificationOut(notification, function()
            -- 移除通知
            removeNotification(notification)
        end)
    end)
    
    return notification
end

-- 初始化通知系统
initNotificationManager()

return NotificationSystem