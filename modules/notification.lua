-- 通知系统模块
local NotificationSystem = {}

-- 服务引用
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- 模块配置
local config = {
    notificationWidth = 320,      -- 通知宽度
    notificationHeight = 85,      -- 通知高度
    padding = 5,                  -- 通知间距（缩小一半）
    defaultDuration = 5,          -- 默认显示时间
    glowImageId = "rbxassetid://154967497",
    cornerRadius = 8,             -- 圆角半径（增大）
    zIndex = 10000,               -- 确保通知显示在最上层
    borderSize = 2,               -- 边框大小
    borderColor = Color3.new(0, 0, 0), -- 纯黑色边框
    titleSize = 18,               -- 标题字体大小（增大）
    descSize = 14,                -- 描述字体字体大小（增大）
    textIndent = "  "             -- 首行缩进（2个空格）
}

-- 全局变量
local LocalPlayer = Players.LocalPlayer
local PlayerGui = nil
local notifications = {}
local notificationScreenGui = nil

-- 初始化函数
local function init()
    -- 确保LocalPlayer存在
    if not LocalPlayer then
        warn("LocalPlayer not found")
        return false
    end
    
    -- 等待PlayerGui加载
    PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
    if not PlayerGui then
        warn("PlayerGui not found")
        return false
    end
    
    return true
end

-- 初始化通知ScreenGui
local function initNotificationScreenGui()
    -- 检查是否已初始化
    if notificationScreenGui then return true end
    
    -- 确保基础服务已初始化
    if not init() then return false end
    
    -- 创建ScreenGui，确保显示在最上层
    notificationScreenGui = Instance.new("ScreenGui")
    notificationScreenGui.Name = "NotificationSystem"
    notificationScreenGui.IgnoreGuiInset = true -- 忽略Roblox默认UI留出的空间
    notificationScreenGui.DisplayOrder = config.zIndex -- 设置显示顺序
    notificationScreenGui.Parent = PlayerGui
    
    return true
end

-- 更新所有通知的位置
local function updateNotificationPositions()
    -- 检查是否有通知需要更新
    if #notifications == 0 then return end
    
    -- 遍历所有通知并更新位置
    for index = #notifications, 1, -1 do
        local notification = notifications[index]
        
        -- 检查通知对象是否有效
        if not notification or not notification.frame or not notification.frame.Parent then
            table.remove(notifications, index)
            continue
        end
        
        -- 计算Y轴偏移量，新通知在最下面
        local yOffset = (index - 1) * (config.notificationHeight + config.padding)
        
        -- 设置目标位置，往上调整一些
        local targetPosition = UDim2.new(1, -config.notificationWidth - 15, 1, -yOffset - config.notificationHeight - 50)
        
        -- 创建位置动画
        local tween = TweenService:Create(notification.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = targetPosition
        })
        tween:Play()
    end
end

-- 创建单个通知
local function createNotificationFrame(title, description)
    -- 确保通知内容有效
    title = title or "Notification"
    description = description or ""
    
    -- 创建通知背景框
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(0, config.notificationWidth, 0, config.notificationHeight)
    notificationFrame.Position = UDim2.new(1, 0, 1, -config.notificationHeight - 50) -- 初始位置在屏幕右侧，往上调整
    notificationFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2) -- 深灰色背景
    notificationFrame.BorderColor3 = config.borderColor -- 纯黑色边框
    notificationFrame.BorderSizePixel = config.borderSize -- 边框大小
    notificationFrame.BackgroundTransparency = 0
    notificationFrame.ZIndex = config.zIndex -- 确保显示在最上层
    
    -- 添加圆角效果
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, config.cornerRadius)
    corner.Parent = notificationFrame
    
    -- 添加黑色发光效果（使用条件时检查图片是否是否存在）
    if config.glowImageId and config.glowImageId ~= "" then
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
    end
    
    -- 创建标题文本，添加首行缩进
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -20, 0, 35) -- 增加左右边距
    titleText.Position = UDim2.new(0, 10, 0, 5) -- 稍微靠上，增加左边距
    titleText.BackgroundTransparency = 1
    titleText.Text = config.textIndent .. title -- 添加首行缩进
    titleText.TextColor3 = Color3.new(0.8, 1, 0.5) -- 淡绿色
    titleText.Font = Enum.Font.SourceSansBold
    titleText.TextSize = config.titleSize -- 增大字体
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextYAlignment = Enum.TextYAlignment.Top
    titleText.ZIndex = config.zIndex
    titleText.Parent = notificationFrame
    
    -- 创建描述文本，添加首行缩进
    local descText = Instance.new("TextLabel")
    descText.Name = "DescriptionText"
    descText.Size = UDim2.new(1, -20, 0, 45) -- 增加左右边距
    descText.Position = UDim2.new(0, 10, 0, 35) -- 增加左边距
    descText.BackgroundTransparency = 1
    descText.Text = config.textIndent .. description -- 添加首行缩进
    descText.TextColor3 = Color3.new(1, 1, 1) -- 白色
    descText.Font = Enum.Font.SourceSans
    descText.TextSize = config.descSize -- 增大字体
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
    
    -- 检查SoundService是否可用
    if not SoundService then
        warn("SoundService not found")
        return
    end
    
    -- 创建音效
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    
    -- 播放音效并处理可能的错误
    local success, err = pcall(function()
        sound:Play()
    end)
    
    if not success then
        warn("Failed to play sound: " .. err)
        sound:Destroy()
        return
    end
    
    -- 2秒后自动移除音效
    game.Debris:AddItem(sound, 2)
end

-- 创建通知的主函数
function NotificationSystem:CreateNotification(title, description, duration, soundId)
    -- 确保通知ScreenGui已初始化
    if not initNotificationScreenGui() then
        warn("Failed to initialize notification system")
        return nil
    end
    
    -- 确保通知ScreenGui有效
    if not notificationScreenGui or not notificationScreenGui.Parent then
        warn("NotificationScreenGui is not valid")
        return nil
    end
    
    -- 创建通知框
    local notificationFrame = createNotificationFrame(title, description)
    if not notificationFrame then
        warn("Failed to create notification frame")
        return nil
    end
    
    -- 将通知框添加到ScreenGui
    notificationFrame.Parent = notificationScreenGui
    
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
        
        -- 检查通知框是否仍然有效
        if not notificationFrame or not notificationFrame.Parent then
            -- 从列表中移除
            local index = table.find(notifications, notification)
            if index then
                table.remove(notifications, index)
            end
            return
        end
        
        -- 滑出动画
        local tweenOut = TweenService:Create(notificationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, 0, notificationFrame.Position.Y.Scale, notificationFrame.Position.Y.Offset)
        })
        
        -- 播放动画并等待完成
        local success, err = pcall(function()
            tweenOut:Play()
            tweenOut.Completed:Wait()
        end)
        
        -- 移除元素并更新队列
        local index = table.find(notifications, notification)
        if index then
            table.remove(notifications, index)
        end
        
        -- 确保通知框仍然存在再销毁
        if notificationFrame and notificationFrame.Parent then
            notificationFrame:Destroy()
        end
        
        -- 更新位置
        updateNotificationPositions()
    end)()
    
    return notification
end

-- 初始化通知系统
initNotificationScreenGui()

return NotificationSystem