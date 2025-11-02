-- 通知系统模块
local NotificationSystem = {}

-- 服务引用
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- 模块配置
local config = {
    notificationWidth = 300,
    notificationHeight = 80,
    padding = 10,
    defaultDuration = 5,
    glowImageId = "rbxassetid://154967497",
    cornerRadius = 5, -- 圆角半径（像素）
    zIndex = 9999 -- 确保通知显示在最上层
}

-- 全局变量
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local notifications = {}
local notificationContainer = nil

-- 初始化通知容器
local function initNotificationContainer()
    if notificationContainer then return end
    
    -- 创建 创建通知容器
    notificationContainer = Instance.new("ScreenGui")
    notificationContainer.Name = "NotificationSystem"
    notificationContainer.IgnoreGuiInset = true -- 忽略Roblox默认UI留出的空间
    notificationContainer.Parent = PlayerGui
end

-- 更新所有通知的位置
local function updateNotificationPositions()
    for index, notification in ipairs(notifications) do
        if notification.frame and notification.frame.Parent then
            -- 计算Y轴偏移量，新通知在最下面
            local yOffset = (index - 1) * (config.notificationHeight + config.padding)
            
            -- 设置目标位置
            local targetPosition = UDim2.new(1, -config.notificationWidth - 10, 1, -yOffset - config.notificationHeight - 10)
            
            -- 创建位置动画
            local tween = TweenService:Create(notification.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Position = targetPosition
            })
            tween:Play()
        end
    end
end

-- 创建单个通知
local function createNotificationFrame(title, description)
    -- 创建通知背景框
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(0, config.notificationWidth, 0, config.notificationHeight)
    notificationFrame.Position = UDim2.new(1, 0, 1, -config.notificationHeight - 10) -- 初始位置在屏幕右侧
    notificationFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2) -- 深灰色背景
    notificationFrame.BorderColor3 = Color3.new(0, 0, 0) -- 黑色边框
    notificationFrame.BorderSizePixel = 1
    notificationFrame.BackgroundTransparency = 0
    notificationFrame.ZIndex = config.zIndex -- 确保显示在最上层
    notificationFrame.Parent = notificationContainer
    
    -- 添加圆角效果
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
    glow.ZIndex = config.zIndex - 1
    glow.Parent = notificationFrame
    
    -- 创建标题文本
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -10, 0, 30)
    titleText.Position = UDim2.new(0, 5, 0, 5) -- 稍微靠上
    titleText.BackgroundTransparency = 1
    titleText.Text = title or "Notification"
    titleText.TextColor3 = Color3.new(0.8, 1, 0.5) -- 淡绿色
    titleText.Font = Enum.Font.SourceSansBold
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextYAlignment = Enum.TextYAlignment.Top
    titleText.ZIndex = config.zIndex
    titleText.Parent = notificationFrame
    
    -- 创建描述文本
    local descText = Instance.new("TextLabel")
    descText.Name = "DescriptionText"
    descText.Size = UDim2.new(1, -10, 0, 40)
    descText.Position = UDim2.new(0, 5, 0, 35)
    descText.BackgroundTransparency = 1
    descText.Text = description or ""
    descText.TextColor3 = Color3.new(1, 1, 1) -- 白色
    descText.Font = Enum.Font.SourceSans
    descText.TextSize = 12
    descText.TextXAlignment = Enum.TextXAlignment.Left
    descText.TextYAlignment = Enum.TextYAlignment.Top
    descText.TextWrapped = true -- 支持多行显示
    descText.ZIndex = config.zIndex
    descText.Parent = notificationFrame
    
    return notificationFrame
end

-- 播放通知音效
local function playNotificationSound(soundId)
    if not soundId or soundId == "" then return end
    
    -- 创建音效
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    
    -- 2秒后自动移除音效
    game.Debris:AddItem(sound, 2)
end

-- 创建通知的主函数
function NotificationSystem:CreateNotification(title, description, duration, soundId)
    -- 初始化通知容器
    initNotificationContainer()
    
    -- 创建通知框
    local notificationFrame = createNotificationFrame(title, description)
    
    -- 创建通知对象
    local notification = {
        frame = notificationFrame,
        duration = duration or config.defaultDuration
    }
    
    -- 添加到通知列表
    table.insert(notifications, notification)
    
    -- 更新所有通知的位置
    updateNotificationPositions()
    
    -- 播放音效
    playNotificationSound(soundId)
    
    -- 独立协程处理通知生命周期
    coroutine.wrap(function()
        -- 等待显示时间
        wait(notification.duration)
        
        -- 滑出动画
        local tweenOut = TweenService:Create(notificationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, 0, notificationFrame.Position.Y.Scale, notificationFrame.Position.Y.Offset)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        
        -- 移除元素并更新队列
        local index = table.find(notifications, notification)
        if index then
            table.remove(notifications, index)
            notificationFrame:Destroy()
            updateNotificationPositions()
        end
    end)()
    
    return notification
end

-- 初始化通知系统
initNotificationContainer()

return NotificationSystem