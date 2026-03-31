-- ChronixUI v1.0
-- 完整的 OrionLib 风格 UI 框架

local ChronixUI = {}
ChronixUI.Version = "1.0.0"
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
local function CreateNotificationHolder()
    local holder = Instance.new("Frame")
    holder.Name = "NotificationHolder"
    holder.Size = UDim2.new(0, 320, 1, 0)
    holder.Position = UDim2.new(1, -20, 0, 20)
    holder.AnchorPoint = Vector2.new(1, 0)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 1000
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = holder
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    
    local padding = Instance.new("UIPadding")
    padding.Parent = holder
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    
    return holder
end

function ChronixUI:Notify(config)
    local title = config.Title or "通知"
    local content = config.Content or ""
    local duration = config.Duration or 5
    local type = config.Type or "info"
    
    local colors = {
        info = self.Themes[self.CurrentTheme].Info,
        success = self.Themes[self.CurrentTheme].Success,
        warning = self.Themes[self.CurrentTheme].Warning,
        error = self.Themes[self.CurrentTheme].Error
    }
    
    local accentColor = colors[type] or colors.info
    
    -- 获取或创建通知容器
    local holder = nil
    for _, window in pairs(self.Windows) do
        if window.Gui and window.Gui.Parent then
            holder = window.Gui:FindFirstChild("NotificationHolder")
            if not holder then
                holder = CreateNotificationHolder()
                holder.Parent = window.Gui
            end
            break
        end
    end
    
    if not holder then return end
    
    -- 创建通知
    local notification = CreateFrame(holder, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 0), 
                                      Color3.fromRGB(45, 45, 55), 0)
    notification.AutomaticSize = Enum.AutomaticSize.Y
    notification.ClipsDescendants = true
    notification.Position = UDim2.new(1, 50, 0, 0)
    
    -- 左侧颜色条
    local colorBar = Instance.new("Frame")
    colorBar.Parent = notification
    colorBar.Size = UDim2.new(0, 4, 1, 0)
    colorBar.BackgroundColor3 = accentColor
    colorBar.BorderSizePixel = 0
    
    -- 内容容器
    local contentContainer = Instance.new("Frame")
    contentContainer.Parent = notification
    contentContainer.Size = UDim2.new(1, -4, 1, 0)
    contentContainer.Position = UDim2.new(0, 4, 0, 0)
    contentContainer.BackgroundTransparency = 1
    
    local titleLabel = CreateLabel(contentContainer, title, UDim2.new(1, -20, 0, 24), UDim2.new(0, 12, 0, 8),
                                    self.Themes[self.CurrentTheme].Text, 14, Enum.Font.GothamBold)
    
    local contentLabel = CreateLabel(contentContainer, content, UDim2.new(1, -24, 0, 0), UDim2.new(0, 12, 0, 36),
                                      self.Themes[self.CurrentTheme].TextDark, 12, Enum.Font.Gotham)
    contentLabel.TextWrapped = true
    contentLabel.AutomaticSize = Enum.AutomaticSize.Y
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = contentContainer
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -28, 0, 10)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = self.Themes[self.CurrentTheme].TextDark
    closeBtn.TextSize = 12
    closeBtn.BackgroundTransparency = 1
    closeBtn.BorderSizePixel = 0
    
    AddStroke(notification, Color3.fromRGB(60, 60, 70))
    
    -- 动画进入
    notification.Position = UDim2.new(1, 20, 0, 0)
    TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
        {Position = UDim2.new(1, -10, 0, 0)}):Play()
    
    -- 自动消失
    local function DestroyNotification()
        TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
            {Position = UDim2.new(1, 20, 0, 0)}):Play()
        wait(0.3)
        notification:Destroy()
    end
    
    closeBtn.MouseButton1Click:Connect(DestroyNotification)
    task.wait(duration)
    if notification and notification.Parent then
        DestroyNotification()
    end
end

-- 窗口拖动功能（仅标题栏可拖动）
local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput, dragStart, startPos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
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
    
    -- 通知容器
    local notificationHolder = CreateNotificationHolder()
    notificationHolder.Parent = gui
    
    -- 主窗口
    local mainFrame = CreateFrame(gui, windowSize, UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2), 
                                   self.Themes[self.CurrentTheme].Background)
    AddStroke(mainFrame, self.Themes[self.CurrentTheme].Border)
    
    local windowVisible = true
    
    -- 全局开关快捷键
    local toggleConnection
    toggleConnection = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == self.Settings.ToggleKey then
            windowVisible = not windowVisible
            mainFrame.Visible = windowVisible
            if windowVisible then
                ChronixUI:Notify({
                    Title = "菜单",
                    Content = "菜单已显示",
                    Type = "info",
                    Duration = 2
                })
            end
        end
    end)
    
    -- 标题栏
    local titleBar = CreateFrame(mainFrame, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), 
                                  self.Themes[self.CurrentTheme].Background, 1)
    
    -- 标题文字（最小化时也显示）
    local titleLabel = CreateLabel(titleBar, windowName, UDim2.new(1, -140, 1, 0), UDim2.new(0, 20, 0, 0),
                                    self.Themes[self.CurrentTheme].Accent, 18, Enum.Font.GothamBold)
    
    -- 设置按钮
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Parent = titleBar
    settingsBtn.Size = UDim2.new(0, 32, 0, 32)
    settingsBtn.Position = UDim2.new(1, -100, 0, 9)
    settingsBtn.Text = "⚙"
    settingsBtn.TextColor3 = self.Themes[self.CurrentTheme].Text
    settingsBtn.TextSize = 20
    settingsBtn.BackgroundColor3 = self.Themes[self.CurrentTheme].Card
    settingsBtn.BorderSizePixel = 0
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 6)
    settingsCorner.Parent = settingsBtn
    AddStroke(settingsBtn, self.Themes[self.CurrentTheme].Border)
    
    -- 最小化按钮
    local minBtn = Instance.new("TextButton")
    minBtn.Parent = titleBar
    minBtn.Size = UDim2.new(0, 32, 0, 32)
    minBtn.Position = UDim2.new(1, -60, 0, 9)
    minBtn.Text = "−"
    minBtn.TextColor3 = self.Themes[self.CurrentTheme].Text
    minBtn.TextSize = 24
    minBtn.BackgroundColor3 = self.Themes[self.CurrentTheme].Card
    minBtn.BorderSizePixel = 0
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = minBtn
    AddStroke(minBtn, self.Themes[self.CurrentTheme].Border)
    
    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = titleBar
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -20, 0, 9)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = self.Themes[self.CurrentTheme].Text
    closeBtn.TextSize = 18
    closeBtn.BackgroundColor3 = self.Themes[self.CurrentTheme].Card
    closeBtn.BorderSizePixel = 0
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    AddStroke(closeBtn, self.Themes[self.CurrentTheme].Border)
    
    -- 底部玩家信息栏
    local playerBar = CreateFrame(mainFrame, UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 1, -60),
                                   self.Themes[self.CurrentTheme].Card)
    AddStroke(playerBar, self.Themes[self.CurrentTheme].Border)
    
    -- 头像
    local avatar = CreateFrame(playerBar, UDim2.new(0, 40, 0, 40), UDim2.new(0, 12, 0.5, -20),
                                self.Themes[self.CurrentTheme].Accent)
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 8)
    avatarCorner.Parent = avatar
    
    local avatarText = CreateLabel(avatar, "玩", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
                                   Color3.fromRGB(0, 0, 0), 18, Enum.Font.GothamBold)
    avatarText.TextXAlignment = Enum.TextXAlignment.Center
    avatarText.TextYAlignment = Enum.TextYAlignment.Center
    
    -- 玩家信息文字
    local playerNameLabel = CreateLabel(playerBar, LocalPlayer.Name, UDim2.new(0, 200, 0, 24), UDim2.new(0, 64, 0, 12),
                                         self.Themes[self.CurrentTheme].Text, 16, Enum.Font.GothamBold)
    
    local playerInfoLabel = CreateLabel(playerBar, "等级 1 | 积分 0", UDim2.new(0, 200, 0, 20), UDim2.new(0, 64, 0, 36),
                                         self.Themes[self.CurrentTheme].TextDark, 12)
    
    -- 侧边栏
    local sidebar = CreateFrame(mainFrame, UDim2.new(0, 160, 1, -110), UDim2.new(0, 0, 0, 50),
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
    local contentArea = CreateFrame(mainFrame, UDim2.new(1, -160, 1, -110), UDim2.new(0, 160, 0, 50),
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
    
    -- 设置窗口（设置功能栏）
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
        
        -- 快捷键设置
        local keybindLabel = CreateLabel(settingsFrame, "菜单开关按键", UDim2.new(1, -40, 0, 30), UDim2.new(0, 20, 0, 80),
                                          self.Themes[self.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
        
        local keybindBtn = Instance.new("TextButton")
        keybindBtn.Parent = settingsFrame
        keybindBtn.Size = UDim2.new(1, -40, 0, 40)
        keybindBtn.Position = UDim2.new(0, 20, 0, 115)
        keybindBtn.BackgroundColor3 = self.Themes[self.CurrentTheme].Input
        keybindBtn.Text = self.Settings.ToggleKeyName
        keybindBtn.TextColor3 = self.Themes[self.CurrentTheme].Accent
        keybindBtn.TextSize = 14
        keybindBtn.Font = Enum.Font.GothamBold
        keybindBtn.BorderSizePixel = 0
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
                        ChronixUI:Notify({
                            Title = "设置",
                            Content = string.format("菜单开关已设置为: %s", key.Name),
                            Type = "success",
                            Duration = 3
                        })
                    end
                end
            end)
        end)
        
        -- 关闭按钮
        local settingsClose = Instance.new("TextButton")
        settingsClose.Parent = settingsFrame
        settingsClose.Size = UDim2.new(0, 30, 0, 30)
        settingsClose.Position = UDim2.new(1, -40, 0, 10)
        settingsClose.Text = "✕"
        settingsClose.TextColor3 = self.Themes[self.CurrentTheme].Text
        settingsClose.TextSize = 18
        settingsClose.BackgroundTransparency = 1
        settingsClose.BorderSizePixel = 0
        
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
    
    -- 最小化功能
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            -- 缩到左上角，只显示标题栏
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
                {Size = UDim2.new(0, 200, 0, 50), Position = UDim2.new(0, 10, 0, 10)}):Play()
            sidebar.Visible = false
            contentArea.Visible = false
            playerBar.Visible = false
            minBtn.Text = "□"
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
                {Size = windowSize, Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)}):Play()
            sidebar.Visible = true
            contentArea.Visible = true
            playerBar.Visible = true
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
    
    -- 只让标题栏可拖动
    MakeDraggable(mainFrame, titleBar)
    
    -- 创建 Tab 函数
    function windowData:CreateTab(tabConfig)
        local tabName = tabConfig.Name or "Tab"
        
        -- Tab 按钮
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
        
        -- Tab 内容容器
        local tabContent = Instance.new("Frame")
        tabContent.Parent = contentScroll
        tabContent.Size = UDim2.new(1, 0, 0, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.AutomaticSize = Enum.AutomaticSize.Y
        
        local tabLayout = AddListLayout(tabContent, 12)
        
        -- 更新 CanvasSize
        local function UpdateCanvas()
            contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 40)
        end
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
        
        -- 切换 Tab
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
            
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            
            handle.InputEnded:Connect(function()
                dragging = false
            end)
            
            slider.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    UpdateSlider(input)
                    dragging = true
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(input)
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
            container.Size = UDim2.new(1, 0, 0, 70)
            container.BackgroundTransparency = 1
            
            local labelText = CreateLabel(container, label, UDim2.new(1, -80, 0, 20), UDim2.new(0, 0, 0, 0),
                                           ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local colorBtn = Instance.new("Frame")
            colorBtn.Parent = container
            colorBtn.Size = UDim2.new(0, 40, 0, 40)
            colorBtn.Position = UDim2.new(1, -50, 0, 15)
            colorBtn.BackgroundColor3 = default
            colorBtn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = colorBtn
            AddStroke(colorBtn, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            local colorPicker = Instance.new("Frame")
            colorPicker.Parent = container
            colorPicker.Size = UDim2.new(1, 0, 0, 0)
            colorPicker.Position = UDim2.new(0, 0, 0, 70)
            colorPicker.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Card
            colorPicker.ClipsDescendants = true
            colorPicker.Visible = false
            local pickerCorner = Instance.new("UICorner")
            pickerCorner.CornerRadius = UDim.new(0, 6)
            pickerCorner.Parent = colorPicker
            AddStroke(colorPicker, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            local expanded = false
            colorBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    expanded = not expanded
                    colorPicker.Visible = true
                    if expanded then
                        TweenService:Create(colorPicker, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 120)}):Play()
                    else
                        TweenService:Create(colorPicker, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                        wait(0.2)
                        colorPicker.Visible = false
                    end
                end
            end)
            
            return container
        end
        
        function elements:AddSliderWithLabel(config)
            return elements:AddSlider(config)
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
        -- 刷新所有窗口颜色（可扩展）
    end
end

-- 更新玩家信息
function ChronixUI:UpdatePlayerInfo(playerName, level, points)
    for _, window in pairs(self.Windows) do
        -- 查找玩家信息标签并更新（可根据实际需要实现）
    end
end

return ChronixUI