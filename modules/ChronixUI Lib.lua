-- ChronixUI v1.1
-- 完整的 OrionLib 风格 UI 框架

local ChronixUI = {}
ChronixUI.Version = "1.1.0"
ChronixUI.Windows = {}
ChronixUI.Notifications = {}
ChronixUI.Settings = {
    ToggleKey = Enum.KeyCode.RightShift,
    ToggleKeyName = "RightShift"
}

-- 服务引用
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- 主题颜色配置
ChronixUI.Themes = {
    Default = {
        Background = Color3.fromRGB(30, 30, 46),
        Sidebar = Color3.fromRGB(24, 24, 37),
        Accent = Color3.fromRGB(119, 221, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(170, 170, 170),
        Border = Color3.fromRGB(44, 44, 62),
        Card = Color3.fromRGB(37, 37, 53),
        Input = Color3.fromRGB(37, 37, 53),
        Hover = Color3.fromRGB(45, 45, 65),
        Success = Color3.fromRGB(76, 175, 80),
        Error = Color3.fromRGB(244, 67, 54),
        Warning = Color3.fromRGB(255, 152, 0),
        Info = Color3.fromRGB(33, 150, 243)
    }
}
ChronixUI.CurrentTheme = "Default"

-- 获取玩家头像
local function GetPlayerAvatar(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
end

-- 辅助函数：创建圆角 Frame
local function CreateFrame(parent, size, position, color, transparency)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = size
    frame.Position = position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = transparency or 0
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    return frame
end

-- 辅助函数：创建文本标签
local function CreateLabel(parent, text, size, position, color, textSize, font, alignment)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.Text = text or ""
    label.Size = size or UDim2.new(1, 0, 1, 0)
    label.Position = position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextSize = textSize or 14
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = alignment or Enum.TextXAlignment.Left
    return label
end

-- 辅助函数：添加描边
local function AddStroke(obj, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(44, 44, 62)
    stroke.Thickness = thickness or 1
    stroke.Parent = obj
    return stroke
end

-- 辅助函数：添加列表布局
local function AddListLayout(parent, padding, order)
    local layout = Instance.new("UIListLayout")
    layout.Parent = parent
    layout.Padding = UDim.new(0, padding or 12)
    layout.SortOrder = order or Enum.SortOrder.LayoutOrder
    return layout
end

-- 通知系统
local NotificationSystem = {}
local notifications = {}
local notificationScreenGui = nil

local function initNotificationScreenGui()
    if notificationScreenGui then return true end
    
    notificationScreenGui = Instance.new("ScreenGui")
    notificationScreenGui.Name = "ChronixNotifications"
    notificationScreenGui.IgnoreGuiInset = true
    notificationScreenGui.DisplayOrder = 10000
    notificationScreenGui.Parent = game.CoreGui
    notificationScreenGui.ResetOnSpawn = false
    
    return true
end

local function updateNotificationPositions()
    for index = 1, #notifications do
        local notification = notifications[index]
        if not notification or not notification.frame or not notification.frame.Parent then
            table.remove(notifications, index)
            break
        end
        
        local yOffset = (index - 1) * 95
        local targetPosition = UDim2.new(1, -330, 1, -yOffset - 95)
        
        TweenService:Create(notification.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = targetPosition
        }):Play()
    end
end

local function playNotificationSound(soundType)
    local soundId = nil
    if soundType == "info" then
        soundId = "rbxassetid://9120931828"
    elseif soundType == "success" then
        soundId = "rbxassetid://9120931822"
    elseif soundType == "warning" then
        soundId = "rbxassetid://9120931843"
    elseif soundType == "error" then
        soundId = "rbxassetid://9120931849"
    end
    
    if not soundId then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    game.Debris:AddItem(sound, 2)
end

function ChronixUI:Notify(config)
    local title = config.Title or "通知"
    local content = config.Content or ""
    local duration = config.Duration or 5
    local type = config.Type or "info"
    
    if not initNotificationScreenGui() then return end
    
    local colors = {
        info = self.Themes[self.CurrentTheme].Info,
        success = self.Themes[self.CurrentTheme].Success,
        warning = self.Themes[self.CurrentTheme].Warning,
        error = self.Themes[self.CurrentTheme].Error
    }
    
    local accentColor = colors[type] or colors.info
    
    -- 创建通知框
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.new(0, 320, 0, 85)
    notificationFrame.Position = UDim2.new(1, 20, 1, -95)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.ClipsDescendants = true
    notificationFrame.BackgroundTransparency = 1
    notificationFrame.Parent = notificationScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 70)
    stroke.Thickness = 1
    stroke.Parent = notificationFrame
    
    -- 左侧颜色条
    local colorBar = Instance.new("Frame")
    colorBar.Size = UDim2.new(0, 4, 1, 0)
    colorBar.BackgroundColor3 = accentColor
    colorBar.BorderSizePixel = 0
    colorBar.Parent = notificationFrame
    
    -- 内容容器
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -4, 1, 0)
    contentContainer.Position = UDim2.new(0, 4, 0, 0)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = notificationFrame
    
    -- 标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -30, 0, 28)
    titleLabel.Position = UDim2.new(0, 12, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = self.Themes[self.CurrentTheme].Text
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Top
    titleLabel.Parent = contentContainer
    
    -- 内容
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Size = UDim2.new(1, -30, 0, 40)
    contentLabel.Position = UDim2.new(0, 12, 0, 36)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = content
    contentLabel.TextColor3 = self.Themes[self.CurrentTheme].TextDark
    contentLabel.TextSize = 12
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.TextWrapped = true
    contentLabel.Parent = contentContainer
    
    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -28, 0, 8)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = self.Themes[self.CurrentTheme].TextDark
    closeBtn.TextSize = 12
    closeBtn.BackgroundTransparency = 1
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = contentContainer
    
    -- 动画进入
    notificationFrame.BackgroundTransparency = 0
    notificationFrame.Position = UDim2.new(1, 20, 1, -95)
    TweenService:Create(notificationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, -10, 1, -95)
    }):Play()
    
    -- 添加到通知列表
    local notificationData = { frame = notificationFrame }
    table.insert(notifications, notificationData)
    updateNotificationPositions()
    
    -- 播放音效
    playNotificationSound(type)
    
    -- 自动消失
    local function destroyNotification()
        local index = table.find(notifications, notificationData)
        if index then
            table.remove(notifications, index)
        end
        
        TweenService:Create(notificationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, 20, 1, -95),
            BackgroundTransparency = 1
        }):Play()
        wait(0.3)
        notificationFrame:Destroy()
        updateNotificationPositions()
    end
    
    closeBtn.MouseButton1Click:Connect(destroyNotification)
    task.wait(duration)
    if notificationFrame and notificationFrame.Parent then
        destroyNotification()
    end
end

-- 窗口拖动功能（仅标题栏可拖动）
local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart, startPos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    dragHandle.InputEnded:Connect(function()
        dragging = false
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- 创建主窗口
function ChronixUI:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "Chronix UI"
    local windowSize = config.Size or UDim2.new(0, 720, 0, 480)
    local closeCallback = config.OnClose or function() end
    
    -- 创建 ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ChronixUI_" .. tostring(#self.Windows + 1)
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = game.CoreGui
    else
        gui.Parent = gethui and gethui() or game.CoreGui
    end
    
    -- 主窗口
    local mainFrame = CreateFrame(gui, windowSize, UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
                                   self.Themes[self.CurrentTheme].Background)
    AddStroke(mainFrame, self.Themes[self.CurrentTheme].Border)
    
    local windowVisible = true
    local minimized = false
    local originalSize = windowSize
    local originalPosition = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
    
    -- 全局开关快捷键
    local toggleConnection
    toggleConnection = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == self.Settings.ToggleKey then
            windowVisible = not windowVisible
            mainFrame.Visible = windowVisible
            if windowVisible then
                self:Notify({
                    Title = "菜单",
                    Content = "菜单已显示",
                    Type = "info",
                    Duration = 2
                })
            end
        end
    end)
    
    -- 标题栏（可拖动）
    local titleBar = CreateFrame(mainFrame, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0),
                                  self.Themes[self.CurrentTheme].Background, 1)
    MakeDraggable(mainFrame, titleBar)
    
    -- 标题文字
    local titleLabel = CreateLabel(titleBar, windowName, UDim2.new(1, -140, 1, 0), UDim2.new(0, 20, 0, 0),
                                    self.Themes[self.CurrentTheme].Accent, 18, Enum.Font.GothamBold)
    
    -- 按钮容器（右侧按钮组）
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0, 100, 1, 0)
    buttonContainer.Position = UDim2.new(1, -110, 0, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = titleBar
    
    -- 设置按钮
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.new(0, 32, 0, 32)
    settingsBtn.Position = UDim2.new(0, 0, 0.5, -16)
    settingsBtn.Text = "⚙"
    settingsBtn.TextColor3 = self.Themes[self.CurrentTheme].Text
    settingsBtn.TextSize = 20
    settingsBtn.BackgroundColor3 = self.Themes[self.CurrentTheme].Card
    settingsBtn.BorderSizePixel = 0
    settingsBtn.Parent = buttonContainer
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 6)
    settingsCorner.Parent = settingsBtn
    AddStroke(settingsBtn, self.Themes[self.CurrentTheme].Border)
    
    -- 最小化按钮
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 32, 0, 32)
    minBtn.Position = UDim2.new(0, 34, 0.5, -16)
    minBtn.Text = "−"
    minBtn.TextColor3 = self.Themes[self.CurrentTheme].Text
    minBtn.TextSize = 24
    minBtn.BackgroundColor3 = self.Themes[self.CurrentTheme].Card
    minBtn.BorderSizePixel = 0
    minBtn.Parent = buttonContainer
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = minBtn
    AddStroke(minBtn, self.Themes[self.CurrentTheme].Border)
    
    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(0, 68, 0.5, -16)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = self.Themes[self.CurrentTheme].Text
    closeBtn.TextSize = 18
    closeBtn.BackgroundColor3 = self.Themes[self.CurrentTheme].Card
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = buttonContainer
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    AddStroke(closeBtn, self.Themes[self.CurrentTheme].Border)
    
    -- 底部玩家信息栏（OrionLib 样式）
    local playerBar = CreateFrame(mainFrame, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 1, -50),
                                   self.Themes[self.CurrentTheme].Card)
    AddStroke(playerBar, self.Themes[self.CurrentTheme].Border)
    
    -- 玩家头像（带边框和圆角）
    local avatarContainer = Instance.new("Frame")
    avatarContainer.Size = UDim2.new(0, 36, 0, 36)
    avatarContainer.Position = UDim2.new(0, 12, 0.5, -18)
    avatarContainer.BackgroundColor3 = self.Themes[self.CurrentTheme].Border
    avatarContainer.BorderSizePixel = 0
    avatarContainer.Parent = playerBar
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 8)
    avatarCorner.Parent = avatarContainer
    
    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(1, -2, 1, -2)
    avatarImage.Position = UDim2.new(0, 1, 0, 1)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = GetPlayerAvatar(LocalPlayer.UserId)
    avatarImage.Parent = avatarContainer
    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, 6)
    imageCorner.Parent = avatarImage
    
    -- 玩家名称
    local playerNameLabel = CreateLabel(playerBar, LocalPlayer.DisplayName, UDim2.new(0, 200, 0, 24), UDim2.new(0, 60, 0, 8),
                                         self.Themes[self.CurrentTheme].Text, 16, Enum.Font.GothamBold)
    
    -- 玩家信息（等级和积分）
    local playerInfoLabel = CreateLabel(playerBar, "等级 1 | 积分 0", UDim2.new(0, 200, 0, 20), UDim2.new(0, 60, 0, 32),
                                         self.Themes[self.CurrentTheme].TextDark, 12)
    
    -- 侧边栏
    local sidebar = CreateFrame(mainFrame, UDim2.new(0, 160, 1, -100), UDim2.new(0, 0, 0, 50),
                                 self.Themes[self.CurrentTheme].Sidebar)
    
    local sidebarTitle = CreateLabel(sidebar, "功能菜单", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10),
                                      self.Themes[self.CurrentTheme].Accent, 16, Enum.Font.GothamBold)
    sidebarTitle.TextXAlignment = Enum.TextXAlignment.Center
    
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Parent = sidebar
    tabContainer.Size = UDim2.new(1, 0, 1, -60)
    tabContainer.Position = UDim2.new(0, 0, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 4
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local tabList = AddListLayout(tabContainer, 8)
    
    -- 内容区域
    local contentArea = CreateFrame(mainFrame, UDim2.new(1, -160, 1, -100), UDim2.new(0, 160, 0, 50),
                                     self.Themes[self.CurrentTheme].Background, 1)
    
    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Parent = contentArea
    contentScroll.Size = UDim2.new(1, 0, 1, 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 6
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local contentLayout = AddListLayout(contentScroll, 16)
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, 20)
    contentPadding.PaddingRight = UDim.new(0, 20)
    contentPadding.PaddingTop = UDim.new(0, 20)
    contentPadding.PaddingBottom = UDim.new(0, 20)
    contentPadding.Parent = contentScroll
    
    -- 设置窗口
    local settingsWindow = nil
    local settingsVisible = false
    
    -- 窗口数据
    local windowData = {
        Gui = gui,
        MainFrame = mainFrame,
        ContentArea = contentScroll,
        ContentLayout = contentLayout,
        Tabs = {},
        CurrentTab = nil,
        ToggleConnection = toggleConnection,
        CloseCallback = closeCallback
    }
    
    -- 创建设置窗口
    local function CreateSettingsWindow()
        local settingsFrame = CreateFrame(mainFrame, UDim2.new(0, 400, 0, 300), UDim2.new(0.5, -200, 0.5, -150),
                                           self.Themes[self.CurrentTheme].Background)
        settingsFrame.ZIndex = 100
        settingsFrame.Visible = false
        AddStroke(settingsFrame, self.Themes[self.CurrentTheme].Border)
        
        local settingsTitle = CreateLabel(settingsFrame, "设置", UDim2.new(1, 0, 0, 50), UDim2.new(0, 20, 0, 15),
                                           self.Themes[self.CurrentTheme].Accent, 18, Enum.Font.GothamBold)
        
        local keybindLabel = CreateLabel(settingsFrame, "菜单开关按键", UDim2.new(1, -40, 0, 30), UDim2.new(0, 20, 0, 80),
                                          self.Themes[self.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
        
        local keybindBtn = Instance.new("TextButton")
        keybindBtn.Size = UDim2.new(1, -40, 0, 40)
        keybindBtn.Position = UDim2.new(0, 20, 0, 115)
        keybindBtn.BackgroundColor3 = self.Themes[self.CurrentTheme].Input
        keybindBtn.Text = self.Settings.ToggleKeyName
        keybindBtn.TextColor3 = self.Themes[self.CurrentTheme].Accent
        keybindBtn.TextSize = 14
        keybindBtn.Font = Enum.Font.GothamBold
        keybindBtn.BorderSizePixel = 0
        keybindBtn.Parent = settingsFrame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = keybindBtn
        AddStroke(keybindBtn, self.Themes[self.CurrentTheme].Border)
        
        local listening = false
        keybindBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            keybindBtn.Text = "按下按键..."
            keybindBtn.TextColor3 = self.Themes[self.CurrentTheme].Text
            
            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    local key = input.KeyCode
                    if key ~= Enum.KeyCode.Unknown then
                        self.Settings.ToggleKey = key
                        self.Settings.ToggleKeyName = key.Name
                        keybindBtn.Text = key.Name
                        keybindBtn.TextColor3 = self.Themes[self.CurrentTheme].Accent
                        listening = false
                        connection:Disconnect()
                        self:Notify({
                            Title = "设置",
                            Content = string.format("菜单开关已设置为: %s", key.Name),
                            Type = "success",
                            Duration = 3
                        })
                    end
                end
            end)
        end)
        
        local settingsClose = Instance.new("TextButton")
        settingsClose.Size = UDim2.new(0, 30, 0, 30)
        settingsClose.Position = UDim2.new(1, -40, 0, 10)
        settingsClose.Text = "✕"
        settingsClose.TextColor3 = self.Themes[self.CurrentTheme].Text
        settingsClose.TextSize = 18
        settingsClose.BackgroundTransparency = 1
        settingsClose.BorderSizePixel = 0
        settingsClose.Parent = settingsFrame
        
        settingsClose.MouseButton1Click:Connect(function()
            settingsFrame.Visible = false
            settingsVisible = false
        end)
        
        return settingsFrame
    end
    
    -- 设置按钮点击事件
    settingsBtn.MouseButton1Click:Connect(function()
        if not settingsWindow then
            settingsWindow = CreateSettingsWindow()
        end
        settingsVisible = not settingsVisible
        settingsWindow.Visible = settingsVisible
    end)
    
    -- 最小化功能（缩到菜单左上角，类似 OrionLib）
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            -- 缩到菜单左上角，只显示标题栏
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 200, 0, 50),
                Position = mainFrame.Position
            }):Play()
            sidebar.Visible = false
            contentArea.Visible = false
            playerBar.Visible = false
            buttonContainer.Visible = false
            minBtn.Text = "□"
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = originalSize,
                Position = originalPosition
            }):Play()
            sidebar.Visible = true
            contentArea.Visible = true
            playerBar.Visible = true
            buttonContainer.Visible = true
            minBtn.Text = "−"
        end
    end)
    
    -- 关闭按钮
    closeBtn.MouseButton1Click:Connect(function()
        closeCallback()
        gui:Destroy()
        toggleConnection:Disconnect()
        for i, window in pairs(self.Windows) do
            if window == windowData then
                table.remove(self.Windows, i)
                break
            end
        end
    end)
    
    -- 创建 Tab 函数
    function windowData:CreateTab(tabConfig)
        local tabName = tabConfig.Name or "Tab"
        
        local tabBtn = Instance.new("TextButton")
        tabBtn.Parent = tabContainer
        tabBtn.Size = UDim2.new(1, -12, 0, 36)
        tabBtn.Position = UDim2.new(0, 6, 0, 0)
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
        tabBtn.Text = "  " .. tabName
        tabBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark
        tabBtn.TextSize = 14
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.BorderSizePixel = 0
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = tabBtn
        
        local tabContent = Instance.new("Frame")
        tabContent.Parent = contentScroll
        tabContent.Size = UDim2.new(1, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.AutomaticSize = Enum.AutomaticSize.Y
        
        local tabLayout = AddListLayout(tabContent, 12)
        
        local function UpdateCanvas()
            contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 40)
        end
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
        
        local function SelectTab()
            for _, otherTab in pairs(windowData.Tabs) do
                otherTab.Button.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
                otherTab.Button.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark
                otherTab.Content.Visible = false
            end
            tabBtn.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
            tabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            tabContent.Visible = true
            windowData.CurrentTab = tabConfig
            UpdateCanvas()
        end
        
        tabBtn.MouseButton1Click:Connect(SelectTab)
        
        if #windowData.Tabs == 0 then
            SelectTab()
        end
        
        local tabData = {
            Button = tabBtn,
            Content = tabContent,
            Layout = tabLayout,
            Name = tabName
        }
        
        table.insert(windowData.Tabs, tabData)
        
        -- UI 元素创建函数
        local elements = {}
        
        function elements:AddButton(config)
            local btnConfig = config or {}
            local btnText = btnConfig.Text or "按钮"
            local callback = btnConfig.Callback or function() end
            
            local btn = Instance.new("TextButton")
            btn.Parent = tabContent
            btn.Size = UDim2.new(1, 0, 0, 38)
            btn.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Card
            btn.Text = btnText
            btn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
            btn.TextSize = 14
            btn.Font = Enum.Font.GothamSemibold
            btn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn
            AddStroke(btn, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            btn.MouseButton1Click:Connect(callback)
            
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Hover}):Play()
            end)
            
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Card}):Play()
            end)
            
            return btn
        end
        
        function elements:AddDropdown(config)
            local dropdownConfig = config or {}
            local label = dropdownConfig.Label or "选项"
            local options = dropdownConfig.Options or {"选项1", "选项2", "选项3"}
            local default = dropdownConfig.Default or options[1]
            local callback = dropdownConfig.Callback or function() end
            
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 70)
            container.BackgroundTransparency = 1
            container.AutomaticSize = Enum.AutomaticSize.Y
            
            local labelText = CreateLabel(container, label, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0),
                                           ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local dropdownBtn = Instance.new("TextButton")
            dropdownBtn.Parent = container
            dropdownBtn.Size = UDim2.new(1, 0, 0, 36)
            dropdownBtn.Position = UDim2.new(0, 0, 0, 28)
            dropdownBtn.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Input
            dropdownBtn.Text = default
            dropdownBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
            dropdownBtn.TextSize = 14
            dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
            dropdownBtn.Font = Enum.Font.Gotham
            dropdownBtn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = dropdownBtn
            AddStroke(dropdownBtn, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            local dropdownList = Instance.new("Frame")
            dropdownList.Parent = container
            dropdownList.Size = UDim2.new(1, 0, 0, 0)
            dropdownList.Position = UDim2.new(0, 0, 0, 64)
            dropdownList.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Input
            dropdownList.ClipsDescendants = true
            dropdownList.Visible = false
            local listCorner = Instance.new("UICorner")
            listCorner.CornerRadius = UDim.new(0, 4)
            listCorner.Parent = dropdownList
            AddStroke(dropdownList, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            local listLayout = AddListLayout(dropdownList, 0)
            
            local expanded = false
            for _, option in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = dropdownList
                optBtn.Size = UDim2.new(1, 0, 0, 32)
                optBtn.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Input
                optBtn.Text = option
                optBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
                optBtn.TextSize = 14
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.Font = Enum.Font.Gotham
                optBtn.BorderSizePixel = 0
                
                optBtn.MouseButton1Click:Connect(function()
                    dropdownBtn.Text = option
                    callback(option)
                    expanded = false
                    TweenService:Create(dropdownList, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    wait(0.2)
                    dropdownList.Visible = false
                end)
            end
            
            dropdownBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                dropdownList.Visible = true
                local totalHeight = #options * 32
                if expanded then
                    TweenService:Create(dropdownList, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, totalHeight)}):Play()
                else
                    TweenService:Create(dropdownList, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    wait(0.2)
                    dropdownList.Visible = false
                end
            end)
            
            return container
        end
        
        function elements:AddSlider(config)
            local sliderConfig = config or {}
            local label = sliderConfig.Label or "滑块"
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local default = sliderConfig.Default or 50
            local callback = sliderConfig.Callback or function() end
            
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 70)
            container.BackgroundTransparency = 1
            
            local labelText = CreateLabel(container, label, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0),
                                           ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local valueLabel = CreateLabel(container, tostring(default), UDim2.new(0, 50, 0, 20), UDim2.new(1, -60, 0, 0),
                                            ChronixUI.Themes[ChronixUI.CurrentTheme].Accent, 14, Enum.Font.GothamBold)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            
            local slider = Instance.new("Frame")
            slider.Parent = container
            slider.Size = UDim2.new(1, 0, 0, 4)
            slider.Position = UDim2.new(0, 0, 0, 40)
            slider.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Border
            slider.BorderSizePixel = 0
            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, 2)
            sliderCorner.Parent = slider
            
            local fill = Instance.new("Frame")
            fill.Parent = slider
            fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
            fill.BorderSizePixel = 0
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 2)
            fillCorner.Parent = fill
            
            local handle = Instance.new("Frame")
            handle.Parent = slider
            handle.Size = UDim2.new(0, 12, 0, 12)
            handle.Position = UDim2.new((default - min) / (max - min), -6, 0, -4)
            handle.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
            handle.BorderSizePixel = 0
            local handleCorner = Instance.new("UICorner")
            handleCorner.CornerRadius = UDim.new(0, 6)
            handleCorner.Parent = handle
            
            local dragging = false
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * pos)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                handle.Position = UDim2.new(pos, -6, 0, -4)
                valueLabel.Text = tostring(value)
                callback(value)
            end
            
            -- 扩大点击范围：监听整个 slider 区域
            local sliderHitbox = Instance.new("TextButton")
            sliderHitbox.Parent = container
            sliderHitbox.Size = UDim2.new(1, 0, 0, 30)
            sliderHitbox.Position = UDim2.new(0, 0, 0, 35)
            sliderHitbox.BackgroundTransparency = 1
            sliderHitbox.Text = ""
            sliderHitbox.AutoButtonColor = false
            
            sliderHitbox.MouseButton1Down:Connect(function(input)
                dragging = true
                UpdateSlider({Position = Mouse})
            end)
            
            sliderHitbox.MouseButton1Up:Connect(function()
                dragging = false
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider({Position = Mouse})
                end
            end)
            
            return container
        end
        
        function elements:AddToggle(config)
            local toggleConfig = config or {}
            local label = toggleConfig.Label or "开关"
            local default = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end
            
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 50)
            container.BackgroundTransparency = 1
            
            local labelText = CreateLabel(container, label, UDim2.new(1, -60, 0, 30), UDim2.new(0, 0, 0, 10),
                                           ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local toggleBtn = Instance.new("Frame")
            toggleBtn.Parent = container
            toggleBtn.Size = UDim2.new(0, 50, 0, 26)
            toggleBtn.Position = UDim2.new(1, -60, 0, 12)
            toggleBtn.BackgroundColor3 = default and ChronixUI.Themes[ChronixUI.CurrentTheme].Accent or Color3.fromRGB(80, 80, 80)
            toggleBtn.BorderSizePixel = 0
            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 13)
            toggleCorner.Parent = toggleBtn
            
            local toggleHandle = Instance.new("Frame")
            toggleHandle.Parent = toggleBtn
            toggleHandle.Size = UDim2.new(0, 22, 0, 22)
            toggleHandle.Position = default and UDim2.new(1, -26, 0.5, -11) or UDim2.new(0, 4, 0.5, -11)
            toggleHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleHandle.BorderSizePixel = 0
            local handleCorner = Instance.new("UICorner")
            handleCorner.CornerRadius = UDim.new(0, 11)
            handleCorner.Parent = toggleHandle
            
            local toggled = default
            toggleBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    toggled = not toggled
                    local targetColor = toggled and ChronixUI.Themes[ChronixUI.CurrentTheme].Accent or Color3.fromRGB(80, 80, 80)
                    local targetPos = toggled and UDim2.new(1, -26, 0.5, -11) or UDim2.new(0, 4, 0.5, -11)
                    TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                    TweenService:Create(toggleHandle, TweenInfo.new(0.2), {Position = targetPos}):Play()
                    callback(toggled)
                end
            end)
            
            return container
        end
        
        function elements:AddInput(config)
            local inputConfig = config or {}
            local label = inputConfig.Label or "输入框"
            local placeholder = inputConfig.Placeholder or "请输入..."
            local callback = inputConfig.Callback or function() end
            
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 70)
            container.BackgroundTransparency = 1
            
            local labelText = CreateLabel(container, label, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0),
                                           ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local inputBox = Instance.new("TextBox")
            inputBox.Parent = container
            inputBox.Size = UDim2.new(1, 0, 0, 36)
            inputBox.Position = UDim2.new(0, 0, 0, 28)
            inputBox.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Input
            inputBox.PlaceholderText = placeholder
            inputBox.PlaceholderColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark
            inputBox.Text = ""
            inputBox.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
            inputBox.TextSize = 14
            inputBox.Font = Enum.Font.Gotham
            inputBox.BorderSizePixel = 0
            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 4)
            inputCorner.Parent = inputBox
            AddStroke(inputBox, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            inputBox.FocusLost:Connect(function()
                callback(inputBox.Text)
            end)
            
            return container
        end
        
        function elements:AddKeybind(config)
            local keybindConfig = config or {}
            local label = keybindConfig.Label or "按键绑定"
            local defaultKey = keybindConfig.Default or "未设置"
            local callback = keybindConfig.Callback or function() end
            
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 70)
            container.BackgroundTransparency = 1
            
            local labelText = CreateLabel(container, label, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0),
                                           ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local keyBtn = Instance.new("TextButton")
            keyBtn.Parent = container
            keyBtn.Size = UDim2.new(1, 0, 0, 36)
            keyBtn.Position = UDim2.new(0, 0, 0, 28)
            keyBtn.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Input
            keyBtn.Text = defaultKey
            keyBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
            keyBtn.TextSize = 14
            keyBtn.Font = Enum.Font.GothamBold
            keyBtn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = keyBtn
            AddStroke(keyBtn, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            local listening = false
            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                keyBtn.Text = "按下按键..."
                keyBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
                
                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local key = input.KeyCode.Name
                        if key ~= "Unknown" then
                            keyBtn.Text = key
                            keyBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
                            callback(key)
                            listening = false
                            connection:Disconnect()
                        end
                    end
                end)
            end)
            
            return container
        end
        
        function elements:AddColorPicker(config)
            local colorConfig = config or {}
            local label = colorConfig.Label or "颜色选择"
            local default = colorConfig.Default or Color3.fromRGB(119, 221, 255)
            local callback = colorConfig.Callback or function() end
            
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 200)
            container.BackgroundTransparency = 1
            container.AutomaticSize = Enum.AutomaticSize.Y
            
            local labelText = CreateLabel(container, label, UDim2.new(1, -80, 0, 30), UDim2.new(0, 0, 0, 0),
                                           ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local colorPreview = Instance.new("Frame")
            colorPreview.Parent = container
            colorPreview.Size = UDim2.new(0, 40, 0, 40)
            colorPreview.Position = UDim2.new(1, -50, 0, 0)
            colorPreview.BackgroundColor3 = default
            colorPreview.BorderSizePixel = 0
            local previewCorner = Instance.new("UICorner")
            previewCorner.CornerRadius = UDim.new(0, 6)
            previewCorner.Parent = colorPreview
            AddStroke(colorPreview, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            -- 颜色选择器面板
            local pickerPanel = Instance.new("Frame")
            pickerPanel.Parent = container
            pickerPanel.Size = UDim2.new(1, 0, 0, 150)
            pickerPanel.Position = UDim2.new(0, 0, 0, 50)
            pickerPanel.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Card
            pickerPanel.Visible = false
            pickerPanel.ClipsDescendants = true
            local panelCorner = Instance.new("UICorner")
            panelCorner.CornerRadius = UDim.new(0, 6)
            panelCorner.Parent = pickerPanel
            AddStroke(pickerPanel, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            -- 色相条
            local hueBar = Instance.new("Frame")
            hueBar.Parent = pickerPanel
            hueBar.Size = UDim2.new(0, 20, 1, -20)
            hueBar.Position = UDim2.new(1, -30, 0, 10)
            hueBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            hueBar.BorderSizePixel = 0
            local hueCorner = Instance.new("UICorner")
            hueCorner.CornerRadius = UDim.new(0, 4)
            hueCorner.Parent = hueBar
            
            local hueGradient = Instance.new("UIGradient")
            hueGradient.Rotation = 270
            hueGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            }
            hueGradient.Parent = hueBar
            
            local hueSelector = Instance.new("Frame")
            hueSelector.Size = UDim2.new(1, 0, 0, 4)
            hueSelector.Position = UDim2.new(0, 0, 0, 0)
            hueSelector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            hueSelector.BorderSizePixel = 0
            hueSelector.Parent = hueBar
            
            -- 颜色方块
            local colorSquare = Instance.new("Frame")
            colorSquare.Parent = pickerPanel
            colorSquare.Size = UDim2.new(1, -50, 1, -20)
            colorSquare.Position = UDim2.new(0, 10, 0, 10)
            colorSquare.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            colorSquare.BorderSizePixel = 0
            local squareCorner = Instance.new("UICorner")
            squareCorner.CornerRadius = UDim.new(0, 4)
            squareCorner.Parent = colorSquare
            
            local saturationGradient = Instance.new("UIGradient")
            saturationGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            }
            saturationGradient.Parent = colorSquare
            
            local brightnessGradient = Instance.new("UIGradient")
            brightnessGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
            }
            brightnessGradient.Transparency = NumberSequence.new(1, 0)
            brightnessGradient.Parent = colorSquare
            
            local colorSelector = Instance.new("Frame")
            colorSelector.Size = UDim2.new(0, 8, 0, 8)
            colorSelector.Position = UDim2.new(0, 0, 0, 0)
            colorSelector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            colorSelector.BorderSizePixel = 0
            local selectorCorner = Instance.new("UICorner")
            selectorCorner.CornerRadius = UDim.new(0, 4)
            selectorCorner.Parent = colorSelector
            colorSelector.Parent = colorSquare
            
            local expanded = false
            local currentHue = 0
            local currentSat = 1
            local currentVal = 1
            
            colorPreview.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    expanded = not expanded
                    pickerPanel.Visible = true
                    if expanded then
                        TweenService:Create(pickerPanel, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 150)}):Play()
                    else
                        TweenService:Create(pickerPanel, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                        wait(0.2)
                        pickerPanel.Visible = false
                    end
                end
            end)
            
            -- 更新颜色
            local function updateColor()
                local color = Color3.fromHSV(currentHue, currentSat, currentVal)
                colorPreview.BackgroundColor3 = color
                callback(color)
            end
            
            -- 色相选择
            hueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local y = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                    currentHue = 1 - y
                    hueSelector.Position = UDim2.new(0, 0, y, -2)
                    colorSquare.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
                    updateColor()
                    
                    local connection
                    connection = UserInputService.InputChanged:Connect(function(input2)
                        if input2.UserInputType == Enum.UserInputType.MouseMovement then
                            local newY = math.clamp((input2.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                            currentHue = 1 - newY
                            hueSelector.Position = UDim2.new(0, 0, newY, -2)
                            colorSquare.BackgroundColor3 = Color3.fromHSV(currentHue, 1, 1)
                            updateColor()
                        end
                    end)
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            connection:Disconnect()
                        end
                    end)
                end
            end)
            
            -- 颜色方块选择
            colorSquare.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local x = math.clamp((input.Position.X - colorSquare.AbsolutePosition.X) / colorSquare.AbsoluteSize.X, 0, 1)
                    local y = math.clamp((input.Position.Y - colorSquare.AbsolutePosition.Y) / colorSquare.AbsoluteSize.Y, 0, 1)
                    currentSat = x
                    currentVal = 1 - y
                    colorSelector.Position = UDim2.new(x, -4, y, -4)
                    updateColor()
                    
                    local connection
                    connection = UserInputService.InputChanged:Connect(function(input2)
                        if input2.UserInputType == Enum.UserInputType.MouseMovement then
                            local newX = math.clamp((input2.Position.X - colorSquare.AbsolutePosition.X) / colorSquare.AbsoluteSize.X, 0, 1)
                            local newY = math.clamp((input2.Position.Y - colorSquare.AbsolutePosition.Y) / colorSquare.AbsoluteSize.Y, 0, 1)
                            currentSat = newX
                            currentVal = 1 - newY
                            colorSelector.Position = UDim2.new(newX, -4, newY, -4)
                            updateColor()
                        end
                    end)
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            connection:Disconnect()
                        end
                    end)
                end
            end)
            
            -- 初始位置
            local h, s, v = Color3.toHSV(default)
            currentHue = h
            currentSat = s
            currentVal = v
            hueSelector.Position = UDim2.new(0, 0, 1 - h, -2)
            colorSelector.Position = UDim2.new(s, -4, 1 - v, -4)
            colorSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            
            return container
        end
        
        function elements:AddParagraph(config)
            local paraConfig = config or {}
            local title = paraConfig.Title or "标题"
            local content = paraConfig.Content or "内容"
            
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 0)
            container.BackgroundTransparency = 1
            container.AutomaticSize = Enum.AutomaticSize.Y
            
            local titleLabel = CreateLabel(container, title, UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0),
                                            ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 16, Enum.Font.GothamBold)
            
            local contentLabel = CreateLabel(container, content, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 28),
                                              ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark, 13, Enum.Font.Gotham)
            contentLabel.TextWrapped = true
            contentLabel.AutomaticSize = Enum.AutomaticSize.Y
            
            return container
        end
        
        function elements:AddDivider()
            local divider = Instance.new("Frame")
            divider.Parent = tabContent
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Border
            divider.BorderSizePixel = 0
            return divider
        end
        
        function elements:AddTitle(text)
            local title = CreateLabel(tabContent, text, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0),
                                       ChronixUI.Themes[ChronixUI.CurrentTheme].Accent, 20, Enum.Font.GothamBold)
            return title
        end
        
        function elements:AddLabel(text)
            local label = CreateLabel(tabContent, text, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0),
                                       ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14, Enum.Font.Gotham)
            return label
        end
        
        return elements
    end
    
    table.insert(self.Windows, windowData)
    return windowData
end

-- 销毁所有窗口
function ChronixUI:Destroy()
    for _, window in pairs(self.Windows) do
        if window.Gui then
            if window.ToggleConnection then
                window.ToggleConnection:Disconnect()
            end
            window.Gui:Destroy()
        end
    end
    self.Windows = {}
end

-- 设置主题
function ChronixUI:SetTheme(themeName)
    if self.Themes[themeName] then
        self.CurrentTheme = themeName
    end
end

-- 更新玩家信息
function ChronixUI:UpdatePlayerInfo(level, points)
    for _, window in pairs(self.Windows) do
        -- 查找玩家信息标签并更新
        for _, child in ipairs(window.MainFrame:GetDescendants()) do
            if child.Name == "PlayerInfoLabel" and child:IsA("TextLabel") then
                child.Text = string.format("等级 %s | 积分 %s", level or "1", points or "0")
            end
        end
    end
end

return ChronixUI