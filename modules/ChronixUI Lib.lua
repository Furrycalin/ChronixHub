-- ChronixUI v1.8
-- 完整的 OrionLib 风格 UI 框架

local ChronixUI = {}
ChronixUI.Version = "1.8.0"
ChronixUI.Windows = {}
ChronixUI.Notifications = {}
ChronixUI.Settings = {
    ToggleKey = Enum.KeyCode.RightShift,
    ToggleKeyName = "RightShift",
    FirstHide = true
}

-- 服务引用
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")
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

-- 音效
local function PlayClickSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://535716488"
    sound.Volume = 0.3
    sound.Parent = SoundService
    sound:Play()
    game.Debris:AddItem(sound, 2)
end

-- 获取玩家头像
local function GetPlayerAvatar(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
end

-- 辅助函数
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

local function AddStroke(obj, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(44, 44, 62)
    stroke.Thickness = thickness or 1
    stroke.Parent = obj
    return stroke
end

local function AddListLayout(parent, padding, order)
    local layout = Instance.new("UIListLayout")
    layout.Parent = parent
    layout.Padding = UDim.new(0, padding or 12)
    layout.SortOrder = order or Enum.SortOrder.LayoutOrder
    return layout
end

-- 通知系统
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

local function playNotificationSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://4590662766"
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
    
    local colorBar = Instance.new("Frame")
    colorBar.Size = UDim2.new(0, 4, 1, 0)
    colorBar.BackgroundColor3 = accentColor
    colorBar.BorderSizePixel = 0
    colorBar.Parent = notificationFrame
    
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -4, 1, 0)
    contentContainer.Position = UDim2.new(0, 4, 0, 0)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = notificationFrame
    
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
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -28, 0, 8)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = self.Themes[self.CurrentTheme].TextDark
    closeBtn.TextSize = 14
    closeBtn.BackgroundTransparency = 1
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = contentContainer
    
    notificationFrame.BackgroundTransparency = 0
    notificationFrame.Position = UDim2.new(1, 20, 1, -95)
    TweenService:Create(notificationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, -10, 1, -95)
    }):Play()
    
    local notificationData = { frame = notificationFrame }
    table.insert(notifications, notificationData)
    updateNotificationPositions()
    
    playNotificationSound()
    
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

-- 窗口拖动功能
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
    local windowSize = config.Size or UDim2.new(0, 680, 0, 420)
    local initialCloseCallback = config.OnClose or function() end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ChronixUI_" .. tostring(#self.Windows + 1)
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = game.CoreGui
    else
        gui.Parent = gethui and gethui() or game.CoreGui
    end
    
    local mainFrame = CreateFrame(gui, windowSize, UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
                                   self.Themes[self.CurrentTheme].Background)
    AddStroke(mainFrame, self.Themes[self.CurrentTheme].Border)
    
    local windowVisible = true
    local minimized = false
    local originalSize = windowSize
    local savedPosition = mainFrame.Position
    
    -- 使用 ContextActionService 绑定快捷键，阻止游戏默认行为
    local toggleActionName = "ChronixUIToggle_" .. tostring(#self.Windows + 1)
    ContextActionService:BindAction(toggleActionName, function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            if inputObject.KeyCode == self.Settings.ToggleKey then
                windowVisible = not windowVisible
                mainFrame.Visible = windowVisible
                if not windowVisible and self.Settings.FirstHide then
                    self.Settings.FirstHide = false
                    self:Notify({
                        Title = "菜单已隐藏",
                        Content = string.format("按 %s 重新打开菜单", self.Settings.ToggleKeyName),
                        Type = "info",
                        Duration = 10
                    })
                end
                return Enum.ContextActionResult.Sink
            end
        end
        return Enum.ContextActionResult.Pass
    end, false, self.Settings.ToggleKey)
    
    -- 标题栏
    local titleBar = CreateFrame(mainFrame, UDim2.new(1, 0, 0, 45), UDim2.new(0, 0, 0, 0),
                                  self.Themes[self.CurrentTheme].Background, 1)
    MakeDraggable(mainFrame, titleBar)
    
    -- 监听拖动，保存位置
    local function savePosition()
        if not minimized then
            savedPosition = mainFrame.Position
        end
    end
    mainFrame:GetPropertyChangedSignal("Position"):Connect(savePosition)
    
    local titleLabel = CreateLabel(titleBar, windowName, UDim2.new(1, -140, 1, 0), UDim2.new(0, 20, 0, 0),
                                    self.Themes[self.CurrentTheme].Accent, 18, Enum.Font.GothamBold)
    
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0, 120, 1, 0)
    buttonContainer.Position = UDim2.new(1, -130, 0, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = titleBar
    
    -- 设置按钮
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.new(0, 32, 0, 32)
    settingsBtn.Position = UDim2.new(0, 0, 0.5, -16)
    settingsBtn.Text = "⚙️"
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
    minBtn.Position = UDim2.new(0, 38, 0.5, -16)
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
    closeBtn.Position = UDim2.new(0, 76, 0.5, -16)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = self.Themes[self.CurrentTheme].Text
    closeBtn.TextSize = 20
    closeBtn.BackgroundColor3 = self.Themes[self.CurrentTheme].Card
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = buttonContainer
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    AddStroke(closeBtn, self.Themes[self.CurrentTheme].Border)
    
    -- 底部玩家信息栏
    local playerBar = CreateFrame(mainFrame, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 1, -50),
                                   self.Themes[self.CurrentTheme].Card)
    AddStroke(playerBar, self.Themes[self.CurrentTheme].Border)
    
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
    
    local playerNameLabel = CreateLabel(playerBar, LocalPlayer.DisplayName, UDim2.new(0, 200, 0, 24), UDim2.new(0, 60, 0, 8),
                                         self.Themes[self.CurrentTheme].Text, 16, Enum.Font.GothamBold)
    
    local playerInfoLabel = CreateLabel(playerBar, "等级 1 | 积分 0", UDim2.new(0, 200, 0, 20), UDim2.new(0, 60, 0, 30),
                                         self.Themes[self.CurrentTheme].TextDark, 12)
    playerInfoLabel.Name = "PlayerInfoLabel"
    
    -- 玩家信息更新方法
    local function UpdatePlayerInfo(level, points)
        playerInfoLabel.Text = string.format("等级 %s | 积分 %s", tostring(level or "1"), tostring(points or "0"))
    end
    
    -- 侧边栏
    local sidebar = CreateFrame(mainFrame, UDim2.new(0, 160, 1, -95), UDim2.new(0, 0, 0, 45),
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
    tabContainer.ScrollBarThickness = 6
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local tabList = AddListLayout(tabContainer, 8)
    
    -- 更新侧边栏滚动区域
    local function updateSidebarCanvas()
        tabContainer.CanvasSize = UDim2.new(0, 0, 0, tabList.AbsoluteContentSize.Y + 20)
    end
    tabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSidebarCanvas)
    
    -- 内容区域
    local contentArea = CreateFrame(mainFrame, UDim2.new(1, -160, 1, -95), UDim2.new(0, 160, 0, 45),
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
    
    -- 窗口数据对象
    local windowData = {
        Gui = gui,
        MainFrame = mainFrame,
        ContentArea = contentScroll,
        ContentLayout = contentLayout,
        Tabs = {},
        CurrentTab = nil,
        CloseCallback = initialCloseCallback,
        SettingsTabContent = nil,
        Minimized = false,
        UpdatePlayerInfo = UpdatePlayerInfo,
        
        -- 动态设置关闭回调的方法
        SetCloseCallback = function(callback)
            windowData.CloseCallback = callback
        end,
        
        -- 关闭窗口的方法
        Close = function()
            PlayClickSound()
            if windowData.CloseCallback then
                local success, err = pcall(windowData.CloseCallback)
                if not success then
                    warn("Close callback error: ", err)
                end
            end
            ContextActionService:UnbindAction(toggleActionName)
            if gui then
                gui:Destroy()
            end
            for i, window in pairs(self.Windows) do
                if window == windowData then
                    table.remove(self.Windows, i)
                    break
                end
            end
        end
    }
    
    -- 最小化功能
    minBtn.MouseButton1Click:Connect(function()
        PlayClickSound()
        windowData.Minimized = not windowData.Minimized
        if windowData.Minimized then
            savedPosition = mainFrame.Position
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 280, 0, 45),
                Position = savedPosition
            }):Play()
            sidebar.Visible = false
            contentArea.Visible = false
            playerBar.Visible = false
            settingsBtn.Visible = false
            minBtn.Text = "+"
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = originalSize,
                Position = savedPosition
            }):Play()
            sidebar.Visible = true
            contentArea.Visible = true
            playerBar.Visible = true
            settingsBtn.Visible = true
            minBtn.Text = "−"
        end
    end)
    
    -- 关闭按钮点击事件
    closeBtn.MouseButton1Click:Connect(function()
        if windowData and windowData.Close then
            windowData:Close()
        end
    end)
    
    -- 创建 Tab 函数
    function windowData:CreateTab(tabConfig)
        local tabName = tabConfig.Name or "Tab"
        local isSettings = tabConfig.IsSettings or false
        
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
        
        tabBtn.MouseButton1Click:Connect(function()
            PlayClickSound()
        end)
        
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
        
        if isSettings then
            windowData.SettingsTabContent = tabContent
            tabBtn.Visible = false
        end
        
        if #windowData.Tabs == 0 and not isSettings then
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
            
            btn.MouseButton1Click:Connect(function()
                PlayClickSound()
                callback()
            end)
            
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
            dropdownBtn.Text = "  " .. default
            dropdownBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
            dropdownBtn.TextSize = 14
            dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
            dropdownBtn.Font = Enum.Font.Gotham
            dropdownBtn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = dropdownBtn
            AddStroke(dropdownBtn, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            local arrowIcon = Instance.new("TextLabel")
            arrowIcon.Parent = dropdownBtn
            arrowIcon.Size = UDim2.new(0, 20, 1, 0)
            arrowIcon.Position = UDim2.new(1, -25, 0, 0)
            arrowIcon.BackgroundTransparency = 1
            arrowIcon.Text = "▼"
            arrowIcon.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark
            arrowIcon.TextSize = 12
            arrowIcon.Font = Enum.Font.Gotham
            arrowIcon.TextXAlignment = Enum.TextXAlignment.Center
            arrowIcon.TextYAlignment = Enum.TextYAlignment.Center
            
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
                optBtn.Text = "  " .. option
                optBtn.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Text
                optBtn.TextSize = 14
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.Font = Enum.Font.Gotham
                optBtn.BorderSizePixel = 0
                
                optBtn.MouseButton1Click:Connect(function()
                    PlayClickSound()
                    dropdownBtn.Text = "  " .. option
                    callback(option)
                    expanded = false
                    TweenService:Create(dropdownList, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    wait(0.2)
                    dropdownList.Visible = false
                end)
            end
            
            dropdownBtn.MouseButton1Click:Connect(function()
                PlayClickSound()
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
            
            local sliderHitbox = Instance.new("TextButton")
            sliderHitbox.Parent = container
            sliderHitbox.Size = UDim2.new(1, 0, 0, 30)
            sliderHitbox.Position = UDim2.new(0, 0, 0, 35)
            sliderHitbox.BackgroundTransparency = 1
            sliderHitbox.Text = ""
            sliderHitbox.AutoButtonColor = false
            
            local dragConnection = nil
            
            sliderHitbox.MouseButton1Down:Connect(function()
                dragging = true
                UpdateSlider({Position = Mouse})
                
                dragConnection = UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlider({Position = Mouse})
                    end
                end)
            end)
            
            local function stopDrag()
                dragging = false
                if dragConnection then
                    dragConnection:Disconnect()
                    dragConnection = nil
                end
            end
            
            sliderHitbox.MouseButton1Up:Connect(stopDrag)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    stopDrag()
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
                    PlayClickSound()
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
                PlayClickSound()
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
                            if callback then
                                callback(key)
                            end
                            listening = false
                            connection:Disconnect()
                        end
                    end
                end)
            end)
            
            return container
        end
        
        -- 颜色选择器
        function elements:AddColorPicker(config)
            local colorConfig = config or {}
            local label = colorConfig.Label or "颜色选择"
            local default = colorConfig.Default or Color3.fromRGB(119, 221, 255)
            local callback = colorConfig.Callback or function() end
            
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 38)
            container.BackgroundTransparency = 1
            container.AutomaticSize = Enum.AutomaticSize.Y
            
            local ColorH, ColorS, ColorV = Color3.toHSV(default)
            local toggled = false
            
            -- 颜色选择器控件
            local ColorSelection = Instance.new("ImageLabel")
            ColorSelection.Size = UDim2.new(0, 12, 0, 12)
            ColorSelection.ScaleType = Enum.ScaleType.Fit
            ColorSelection.AnchorPoint = Vector2.new(0.5, 0.5)
            ColorSelection.BackgroundTransparency = 1
            ColorSelection.Image = "http://www.roblox.com/asset/?id=4805639000"
            
            local HueSelection = Instance.new("ImageLabel")
            HueSelection.Size = UDim2.new(0, 12, 0, 12)
            HueSelection.ScaleType = Enum.ScaleType.Fit
            HueSelection.AnchorPoint = Vector2.new(0.5, 0.5)
            HueSelection.BackgroundTransparency = 1
            HueSelection.Image = "http://www.roblox.com/asset/?id=4805639000"
            
            local ColorSquare = Instance.new("ImageLabel")
            ColorSquare.Size = UDim2.new(1, -25, 1, 0)
            ColorSquare.Visible = false
            ColorSquare.Image = "rbxassetid://4155801252"
            ColorSquare.BackgroundTransparency = 1
            
            local HueBar = Instance.new("Frame")
            HueBar.Size = UDim2.new(0, 20, 1, 0)
            HueBar.Position = UDim2.new(1, -20, 0, 0)
            HueBar.Visible = false
            HueBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            
            local HueGradient = Instance.new("UIGradient")
            HueGradient.Rotation = 270
            HueGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            }
            HueGradient.Parent = HueBar
            
            local PickerContainer = Instance.new("Frame")
            PickerContainer.Position = UDim2.new(0, 0, 0, 38)
            PickerContainer.Size = UDim2.new(1, 0, 1, -38)
            PickerContainer.BackgroundTransparency = 1
            PickerContainer.ClipsDescendants = true
            
            ColorSquare.Parent = PickerContainer
            HueBar.Parent = PickerContainer
            ColorSelection.Parent = ColorSquare
            HueSelection.Parent = HueBar
            
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 35)
            padding.PaddingRight = UDim.new(0, 35)
            padding.PaddingBottom = UDim.new(0, 10)
            padding.PaddingTop = UDim.new(0, 17)
            padding.Parent = PickerContainer
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 5)
            corner.Parent = ColorSquare
            
            local hueCorner = Instance.new("UICorner")
            hueCorner.CornerRadius = UDim.new(0, 5)
            hueCorner.Parent = HueBar
            
            -- 标题栏
            local header = Instance.new("Frame")
            header.Size = UDim2.new(1, 0, 0, 38)
            header.BackgroundTransparency = 1
            header.Parent = container
            
            local labelText = CreateLabel(header, label, UDim2.new(1, -50, 1, 0), UDim2.new(0, 12, 0, 0),
                                           ChronixUI.Themes[ChronixUI.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local colorPreview = Instance.new("Frame")
            colorPreview.Size = UDim2.new(0, 30, 0, 30)
            colorPreview.Position = UDim2.new(1, -40, 0.5, -15)
            colorPreview.BackgroundColor3 = default
            colorPreview.BorderSizePixel = 0
            colorPreview.Parent = header
            local previewCorner = Instance.new("UICorner")
            previewCorner.CornerRadius = UDim.new(0, 6)
            previewCorner.Parent = colorPreview
            AddStroke(colorPreview, ChronixUI.Themes[ChronixUI.CurrentTheme].Border)
            
            local expandBtn = Instance.new("TextButton")
            expandBtn.Size = UDim2.new(1, 0, 1, 0)
            expandBtn.BackgroundTransparency = 1
            expandBtn.Text = ""
            expandBtn.Parent = header
            
            PickerContainer.Parent = container
            
            local function UpdateColorPicker()
                local color = Color3.fromHSV(ColorH, ColorS, ColorV)
                colorPreview.BackgroundColor3 = color
                ColorSquare.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
                if callback then
                    callback(color)
                end
            end
            
            local function UpdatePositions()
                ColorSelection.Position = UDim2.new(ColorS, -6, ColorV, -6)
                HueSelection.Position = UDim2.new(0.5, 0, 1 - ColorH, -6)
            end
            
            -- 色相选择
            local HueInput = nil
            HueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local HueY = math.clamp((input.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                    ColorH = 1 - HueY
                    HueSelection.Position = UDim2.new(0.5, 0, HueY, -6)
                    UpdateColorPicker()
                    
                    if HueInput then HueInput:Disconnect() end
                    HueInput = RunService.RenderStepped:Connect(function()
                        local newY = math.clamp((Mouse.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                        ColorH = 1 - newY
                        HueSelection.Position = UDim2.new(0.5, 0, newY, -6)
                        UpdateColorPicker()
                    end)
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            if HueInput then HueInput:Disconnect() end
                        end
                    end)
                end
            end)
            
            -- 颜色方块选择
            local ColorInput = nil
            ColorSquare.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local ColorX = math.clamp((input.Position.X - ColorSquare.AbsolutePosition.X) / ColorSquare.AbsoluteSize.X, 0, 1)
                    local ColorY = math.clamp((input.Position.Y - ColorSquare.AbsolutePosition.Y) / ColorSquare.AbsoluteSize.Y, 0, 1)
                    ColorS = ColorX
                    ColorV = 1 - ColorY
                    ColorSelection.Position = UDim2.new(ColorX, -6, ColorY, -6)
                    UpdateColorPicker()
                    
                    if ColorInput then ColorInput:Disconnect() end
                    ColorInput = RunService.RenderStepped:Connect(function()
                        local newX = math.clamp((Mouse.X - ColorSquare.AbsolutePosition.X) / ColorSquare.AbsoluteSize.X, 0, 1)
                        local newY = math.clamp((Mouse.Y - ColorSquare.AbsolutePosition.Y) / ColorSquare.AbsoluteSize.Y, 0, 1)
                        ColorS = newX
                        ColorV = 1 - newY
                        ColorSelection.Position = UDim2.new(newX, -6, newY, -6)
                        UpdateColorPicker()
                    end)
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            if ColorInput then ColorInput:Disconnect() end
                        end
                    end)
                end
            end)
            
            -- 展开/收起
            expandBtn.MouseButton1Click:Connect(function()
                PlayClickSound()
                toggled = not toggled
                if toggled then
                    TweenService:Create(container, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 150)}):Play()
                    PickerContainer.Visible = true
                    ColorSquare.Visible = true
                    HueBar.Visible = true
                else
                    TweenService:Create(container, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 38)}):Play()
                    wait(0.15)
                    PickerContainer.Visible = false
                    ColorSquare.Visible = false
                    HueBar.Visible = false
                end
            end)
            
            -- 初始设置
            UpdatePositions()
            UpdateColorPicker()
            PickerContainer.Visible = false
            ColorSquare.Visible = false
            HueBar.Visible = false
            
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
    
    -- 创建内置设置 Tab（不在侧边栏显示）
    local settingsElements = windowData:CreateTab({ Name = "设置", IsSettings = true })
    
    settingsElements:AddTitle("UI 设置")
    settingsElements:AddDivider()
    
    settingsElements:AddKeybind({
        Label = "菜单开关按键",
        Default = self.Settings.ToggleKeyName,
        Callback = function(key)
            local newKey = Enum.KeyCode[key]
            if newKey then
                self.Settings.ToggleKey = newKey
                self.Settings.ToggleKeyName = key
                ContextActionService:UnbindAction(toggleActionName)
                ContextActionService:BindAction(toggleActionName, function(actionName, inputState, inputObject)
                    if inputState == Enum.UserInputState.Begin then
                        if inputObject.KeyCode == self.Settings.ToggleKey then
                            windowVisible = not windowVisible
                            mainFrame.Visible = windowVisible
                            if not windowVisible and self.Settings.FirstHide then
                                self.Settings.FirstHide = false
                                self:Notify({
                                    Title = "菜单已隐藏",
                                    Content = string.format("按 %s 重新打开菜单", self.Settings.ToggleKeyName),
                                    Type = "info",
                                    Duration = 10
                                })
                            end
                            return Enum.ContextActionResult.Sink
                        end
                    end
                    return Enum.ContextActionResult.Pass
                end, false, self.Settings.ToggleKey)
                self:Notify({
                    Title = "设置",
                    Content = string.format("菜单开关已设置为: %s", key),
                    Type = "success",
                    Duration = 3
                })
            end
        end
    })
    
    settingsElements:AddDivider()
    settingsElements:AddLabel("其他设置即将推出...")
    
    -- 设置按钮打开设置 Tab
    settingsBtn.MouseButton1Click:Connect(function()
        PlayClickSound()
        if windowData.SettingsTabContent then
            for _, tab in pairs(windowData.Tabs) do
                if tab.Name == "设置" then
                    tab.Button.BackgroundColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].Accent
                    tab.Button.TextColor3 = Color3.fromRGB(0, 0, 0)
                    for _, otherTab in pairs(windowData.Tabs) do
                        if otherTab ~= tab then
                            otherTab.Button.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
                            otherTab.Button.TextColor3 = ChronixUI.Themes[ChronixUI.CurrentTheme].TextDark
                            otherTab.Content.Visible = false
                        end
                    end
                    windowData.SettingsTabContent.Visible = true
                    windowData.CurrentTab = { Name = "设置" }
                    break
                end
            end
        end
    end)
    
    table.insert(self.Windows, windowData)
    return windowData
end

-- 销毁所有窗口
function ChronixUI:Destroy()
    for _, window in pairs(self.Windows) do
        if window.Gui then
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

return ChronixUI