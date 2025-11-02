-- NotificationSystem.lua
-- 一个从屏幕右下角滑入滑出的通知系统，支持多条通知叠加显示

local NotificationSystem = {}

-- 服务引用
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

-- 配置
local CONFIG = {
    -- 通知框样式
    BACKGROUND_COLOR = Color3.fromRGB(50, 50, 50), -- 深灰色背景
    BORDER_COLOR = Color3.fromRGB(0, 0, 0),        -- 纯黑色边框
    BORDER_SIZE = 2,                               -- 2像素边框
    CORNER_RADIUS = 8,                             -- 8像素圆角
    PADDING = 10,                                  -- 内边距
    
    -- 文本样式
    TITLE_COLOR = Color3.fromRGB(204, 255, 128),   -- 淡绿色 (0.8,1,0.5)
    TITLE_FONT_SIZE = 18,                          -- 18号字体
    DESCRIPTION_COLOR = Color3.fromRGB(255, 255, 255), -- 白色
    DESCRIPTION_FONT_SIZE = 14,                    -- 14号字体
    TEXT_INDENT = 2,                               -- 首行缩进2字符
    
    -- 布局
    NOTIFICATION_SPACING = 5,                      -- 通知间距5像素
    BOTTOM_OFFSET = 50,                            -- 从底部往上调整50像素
    MAX_NOTIFICATIONS = 5,                         -- 最大显示通知数量
    
    -- 动画
    SLIDE_IN_DURATION = 0.5,                       -- 滑入动画时长
    SLIDE_OUT_DURATION = 0.5,                      -- 滑出动画时长
    DISPLAY_DURATION = 5,                          -- 显示时长（秒）
    
    -- 音效
    ENABLE_SOUND = true,                           -- 是否启用音效
    SOUND_ID = "rbxassetid://122220006",           -- 通知音效ID
}

-- 存储当前显示的通知
local activeNotifications = {}

-- 创建UI容器
local function createUIContainer(player)
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- 创建主ScreenGui
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationSystem"
    notificationGui.IgnoreGuiInset = true  -- 忽略屏幕边缘 inset
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notificationGui.Parent = playerGui
    
    -- 创建通知容器
    local notificationContainer = Instance.new("Frame")
    notificationContainer.Name = "NotificationContainer"
    notificationContainer.BackgroundTransparency = 1
    notificationContainer.Size = UDim2.new(1, 0, 1, 0)
    notificationContainer.Position = UDim2.new(0, 0, 0, 0)
    notificationContainer.Parent = notificationGui
    
    return notificationContainer
end

-- 创建通知音效
local function createNotificationSound()
    local sound = Instance.new("Sound")
    sound.Name = "NotificationSound"
    sound.SoundId = CONFIG.SOUND_ID
    sound.Volume = 0.5
    sound.Parent = SoundService
    
    return sound
end

-- 创建单个通知UI
local function createNotificationUI(title, description)
    -- 创建通知背景框
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    notificationFrame.BorderColor3 = CONFIG.BORDER_COLOR
    notificationFrame.BorderSizePixel = CONFIG.BORDER_SIZE
    notificationFrame.BackgroundTransparency = 0
    notificationFrame.Size = UDim2.new(0, 300, 0, 0)  -- 宽度固定，高度自动
    notificationFrame.Position = UDim2.new(1, 0, 1, 0)  -- 初始位置在屏幕外
    notificationFrame.AutomaticSize = Enum.AutomaticSize.Y
    notificationFrame.ZIndex = 100  -- 确保在最上层
    
    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CONFIG.CORNER_RADIUS)
    corner.Parent = notificationFrame
    
    -- 创建标题文本
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Text = title
    titleText.TextColor3 = CONFIG.TITLE_COLOR
    titleText.Font = Enum.Font.SourceSansBold
    titleText.TextSize = CONFIG.TITLE_FONT_SIZE
    titleText.BackgroundTransparency = 1
    titleText.Size = UDim2.new(1, -CONFIG.PADDING * 2, 0, CONFIG.TITLE_FONT_SIZE + 4)
    titleText.Position = UDim2.new(0, CONFIG.PADDING, 0, CONFIG.PADDING)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextYAlignment = Enum.TextYAlignment.Top
    titleText.TextWrapped = false
    titleText.ZIndex = 101
    
    -- 添加首行缩进
    local titleIndent = CONFIG.TEXT_INDENT * CONFIG.TITLE_FONT_SIZE / 2
    titleText.Text = string.rep(" ", CONFIG.TEXT_INDENT) .. title
    titleText.Parent = notificationFrame
    
    -- 创建描述文本
    local descriptionText = Instance.new("TextLabel")
    descriptionText.Name = "DescriptionText"
    descriptionText.Text = description
    descriptionText.TextColor3 = CONFIG.DESCRIPTION_COLOR
    descriptionText.Font = Enum.Font.SourceSans
    descriptionText.TextSize = CONFIG.DESCRIPTION_FONT_SIZE
    descriptionText.BackgroundTransparency = 1
    descriptionText.Size = UDim2.new(1, -CONFIG.PADDING * 2, 0, 0)
    descriptionText.Position = UDim2.new(0, CONFIG.PADDING, 0, CONFIG.PADDING + CONFIG.TITLE_FONT_SIZE + 4)
    descriptionText.TextXAlignment = Enum.TextXAlignment.Left
    descriptionText.TextYAlignment = Enum.TextYAlignment.Top
    descriptionText.TextWrapped = true
    descriptionText.AutomaticSize = Enum.AutomaticSize.Y
    descriptionText.ZIndex = 101
    
    -- 添加首行缩进
    local descIndent = CONFIG.TEXT_INDENT * CONFIG.DESCRIPTION_FONT_SIZE / 2
    descriptionText.Text = string.rep(" ", CONFIG.TEXT_INDENT) .. description
    descriptionText.Parent = notificationFrame
    
    return notificationFrame
end

-- 更新通知位置
local function updateNotificationPositions()
    for i, notification in ipairs(activeNotifications) do
        local frame = notification.frame
        local targetPosition
        
        -- 计算每个通知的位置
        -- 新通知在底部，旧通知往上移动
        local totalHeight = 0
        for j = i, #activeNotifications do
            totalHeight += activeNotifications[j].frame.AbsoluteSize.Y + CONFIG.NOTIFICATION_SPACING
        end
        
        targetPosition = UDim2.new(
            1, -frame.AbsoluteSize.X - 10,  -- 右边距10像素
            1, -totalHeight - CONFIG.BOTTOM_OFFSET  -- 底部偏移
        )
        
        -- 应用位置动画
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(frame, tweenInfo, {Position = targetPosition})
        tween:Play()
    end
end

-- 移除通知
local function removeNotification(notification)
    -- 找到通知在列表中的索引
    local index = table.find(activeNotifications, notification)
    if not index then return end
    
    -- 从列表中移除
    table.remove(activeNotifications, index)
    
    -- 创建滑出动画
    local tweenInfo = TweenInfo.new(
        CONFIG.SLIDE_OUT_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In
    )
    
    local targetPosition = UDim2.new(
        1, 0,
        notification.frame.Position.Y.Scale,
        notification.frame.Position.Y.Offset
    )
    
    local tween = TweenService:Create(notification.frame, tweenInfo, {
        Position = targetPosition,
        BackgroundTransparency = 1
    })
    
    -- 动画结束后销毁通知
    tween.Completed:Connect(function()
        notification.frame:Destroy()
    end)
    
    tween:Play()
    
    -- 更新剩余通知的位置
    updateNotificationPositions()
end

-- 显示通知
function NotificationSystem:ShowNotification(title, description, duration)
    -- 获取本地玩家
    local player = Players.LocalPlayer
    if not player then return end
    
    -- 确保UI容器存在
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local notificationContainer = playerGui:FindFirstChild("NotificationSystem")
    if not notificationContainer then
        notificationContainer = createUIContainer(player)
    else
        notificationContainer = notificationContainer:FindFirstChild("NotificationContainer")
        if not notificationContainer then
            notificationContainer = createUIContainer(player)
        end
    end
    
    -- 创建通知UI
    local notificationFrame = createNotificationUI(title, description)
    notificationFrame.Parent = notificationContainer
    
    -- 等待UI大小计算完成
    task.wait()
    
    -- 添加到活动通知列表
    local newNotification = {
        frame = notificationFrame,
        startTime = os.clock()
    }
    
    -- 将新通知添加到列表末尾（底部）
    table.insert(activeNotifications, newNotification)
    
    -- 如果超过最大通知数量，移除最旧的通知
    if #activeNotifications > CONFIG.MAX_NOTIFICATIONS then
        removeNotification(activeNotifications[1])
    end
    
    -- 先将通知放在屏幕外右侧
    notificationFrame.Position = UDim2.new(
        1, notificationFrame.AbsoluteSize.X + 10,
        1, -notificationFrame.AbsoluteSize.Y - CONFIG.BOTTOM_OFFSET
    )
    
    -- 更新所有通知位置
    updateNotificationPositions()
    
    -- 创建滑入动画
    local targetPosition = notificationFrame.Position
    local tweenInfo = TweenInfo.new(
        CONFIG.SLIDE_IN_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(notificationFrame, tweenInfo, {
        Position = targetPosition
    })
    tween:Play()
    
    -- 播放通知音效
    if CONFIG.ENABLE_SOUND then
        local sound = SoundService:FindFirstChild("NotificationSound")
        if not sound then
            sound = createNotificationSound()
        end
        
        sound:Play()
    end
    
    -- 设置自动移除
    local displayDuration = duration or CONFIG.DISPLAY_DURATION
    task.delay(displayDuration, function()
        removeNotification(newNotification)
    end)
    
    return newNotification
end

-- 初始化
local function init()
    -- 在客户端初始化
    if RunService:IsClient() then
        -- 预创建UI容器
        local player = Players.LocalPlayer
        if player then
            player.PlayerGui.ChildAdded:Connect(function(child)
                if child:IsA("ScreenGui") then
                    -- 确保通知系统UI在最上层
                    local notificationSystem = player.PlayerGui:FindFirstChild("NotificationSystem")
                    if notificationSystem then
                        notificationSystem.DisplayOrder = 1000
                    end
                end
            end)
        end
    end
end

-- 启动初始化
init()

return NotificationSystem
