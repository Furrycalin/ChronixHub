-- ChronixUI
-- 一个现代化、支持手机/电脑的UI库
-- 完整版：开场动画 + 窗口最小化 + 设置标签页 + 快捷键隐藏

local ChronixUI = {}

-- 服务
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- 检测设备
local isMobile = UserInputService.TouchEnabled
local isDesktop = not isMobile

-- 主题配置（ChronixHub风格 - 墨蓝色 + 毛玻璃）
local Theme = {
    -- 颜色
    GlassBg = Color3.fromRGB(25, 25, 40),
    GlassTransparency = 0.85,
    SidebarBg = Color3.fromRGB(20, 20, 35),
    SidebarHover = Color3.fromRGB(45, 45, 70),
    SidebarActive = Color3.fromRGB(80, 80, 130),
    AccentColor = Color3.fromRGB(100, 100, 180),
    SuccessColor = Color3.fromRGB(0, 200, 100),
    ErrorColor = Color3.fromRGB(220, 60, 60),
    TextColor = Color3.fromRGB(240, 240, 255),
    TextSecondary = Color3.fromRGB(160, 160, 200),
    
    -- 字体
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    TextSize = isMobile and 16 or 14,
    TitleSize = isMobile and 20 or 18,
    
    -- 尺寸
    WindowWidth = isMobile and 360 or 400,
    WindowHeight = isMobile and 600 or 550,
    SidebarWidth = isMobile and 70 or 80,
    RowHeight = isMobile and 50 or 38,
    
    -- 动画
    TweenTime = 0.2,
}

-- 存储实例
local activeWindows = {}
local activeNotifications = {}
local windowHideKey = Enum.KeyCode.RightShift

-- ============ 工具函数 ============

local function playClickSound()
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://535716488"
        sound.Volume = 0.2
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 1)
    end)
end

local function applyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
end

local function applyGlassEffect(frame)
    frame.BackgroundTransparency = Theme.GlassTransparency
    applyCorner(frame, 12)
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.9
    stroke.Thickness = 1
    stroke.Parent = frame
end

local function makeDraggable(frame, dragHandle)
    local dragData = { dragging = false, startPos = nil, frameStart = nil }
    local handle = dragHandle or frame
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragData.dragging = true
            dragData.startPos = input.Position
            dragData.frameStart = frame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragData.dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragData.startPos
                frame.Position = UDim2.new(
                    dragData.frameStart.X.Scale,
                    dragData.frameStart.X.Offset + delta.X,
                    dragData.frameStart.Y.Scale,
                    dragData.frameStart.Y.Offset + delta.Y
                )
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragData.dragging = false
        end
    end)
end

-- ============ 开场动画 ============

local function playIntro(config)
    config = config or {}
    local introText = config.Text or "ChronixHub V3"
    local introIcon = config.Icon or "rbxassetid://8834748103"
    local duration = config.Duration or 2.5
    
    local introGui = Instance.new("ScreenGui")
    introGui.Name = "ChronixIntro"
    introGui.ResetOnSpawn = false
    introGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    introGui.Parent = CoreGui
    
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    overlay.BackgroundTransparency = 0
    overlay.Parent = introGui
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0.5, -30, 0.4, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Image = introIcon
    icon.ImageColor3 = Theme.AccentColor
    icon.BackgroundTransparency = 1
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = overlay
    applyCorner(icon, 15)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0.5, 0, 0.5, 30)
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Text = introText
    title.TextColor3 = Theme.TextColor
    title.TextSize = Theme.TitleSize + 4
    title.Font = Theme.FontBold
    title.TextTransparency = 1
    title.BackgroundTransparency = 1
    title.Parent = overlay
    
    -- 动画序列
    icon.ImageTransparency = 1
    icon.Size = UDim2.new(0, 80, 0, 80)
    
    TweenService:Create(icon, TweenInfo.new(0.5), {ImageTransparency = 0, Size = UDim2.new(0, 60, 0, 60)}):Play()
    task.wait(0.3)
    TweenService:Create(title, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    
    task.wait(duration - 1)
    
    TweenService:Create(title, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(icon, TweenInfo.new(0.4), {ImageTransparency = 1}):Play()
    TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    
    task.wait(0.6)
    introGui:Destroy()
end

-- ============ 主窗口类 ============

local Window = {}
Window.__index = Window

function ChronixUI:CreateWindow(config)
    config = config or {}
    local title = config.Title or "ChronixHub"
    local showIntro = config.ShowIntro ~= false
    local introText = config.IntroText or title
    local introIcon = config.IntroIcon
    
    -- 播放开场动画
    if showIntro then
        playIntro({Text = introText, Icon = introIcon, Duration = config.IntroDuration or 2.5})
    end
    
    -- 创建GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "ChronixUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui
    
    -- 主窗口
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, Theme.WindowWidth, 0, Theme.WindowHeight)
    mainFrame.Position = UDim2.new(0.5, -Theme.WindowWidth/2, 0.5, -Theme.WindowHeight/2)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Theme.GlassBg
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = true
    mainFrame.Parent = gui
    applyGlassEffect(mainFrame)
    
    -- 窗口状态
    local isMinimized = false
    local isHidden = false
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextColor
    titleLabel.TextSize = Theme.TitleSize
    titleLabel.Font = Theme.FontBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = titleBar
    
    -- 设置按钮
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.new(0, 35, 0, 35)
    settingsBtn.Position = UDim2.new(1, -115, 0, 5)
    settingsBtn.Text = "⚙️"
    settingsBtn.TextColor3 = Theme.TextColor
    settingsBtn.TextSize = 18
    settingsBtn.Font = Theme.Font
    settingsBtn.BackgroundColor3 = Theme.SidebarBg
    settingsBtn.BorderSizePixel = 0
    settingsBtn.Parent = titleBar
    applyCorner(settingsBtn, 8)
    
    -- 最小化按钮
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
    minimizeBtn.Position = UDim2.new(1, -75, 0, 5)
    minimizeBtn.Text = "−"
    minimizeBtn.TextColor3 = Theme.TextColor
    minimizeBtn.TextSize = 20
    minimizeBtn.Font = Theme.Font
    minimizeBtn.BackgroundColor3 = Theme.SidebarBg
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Parent = titleBar
    applyCorner(minimizeBtn, 8)
    
    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.TextColor
    closeBtn.TextSize = 18
    closeBtn.Font = Theme.Font
    closeBtn.BackgroundColor3 = Theme.SidebarBg
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    applyCorner(closeBtn, 8)
    
    -- 侧边栏
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, Theme.SidebarWidth, 1, -45)
    sidebar.Position = UDim2.new(0, 0, 0, 45)
    sidebar.BackgroundColor3 = Theme.SidebarBg
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame
    applyCorner(sidebar, 0)
    
    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 5)
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Parent = sidebar
    
    -- 内容区域
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -Theme.SidebarWidth, 1, -45)
    contentArea.Position = UDim2.new(0, Theme.SidebarWidth, 0, 45)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame
    
    local contentScroller = Instance.new("ScrollingFrame")
    contentScroller.Size = UDim2.new(1, -20, 1, -20)
    contentScroller.Position = UDim2.new(0, 10, 0, 10)
    contentScroller.BackgroundTransparency = 1
    contentScroller.BorderSizePixel = 0
    contentScroller.ScrollBarThickness = isMobile and 0 or 4
    contentScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroller.Parent = contentArea
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentScroller
    
    local function updateCanvas()
        task.wait()
        contentScroller.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
    
    -- 窗口对象
    local windowObj = {
        gui = gui,
        mainFrame = mainFrame,
        sidebar = sidebar,
        sidebarLayout = sidebarLayout,
        contentScroller = contentScroller,
        contentLayout = contentLayout,
        updateCanvas = updateCanvas,
        tabs = {},
        currentTab = nil,
        theme = Theme,
        flags = {},
        isMinimized = false,
        isHidden = false,
        minimizeBtn = minimizeBtn,
        settingsBtn = settingsBtn
    }
    
    makeDraggable(mainFrame, titleBar)
    
    -- 最小化功能
    minimizeBtn.MouseButton1Click:Connect(function()
        playClickSound()
        if isMinimized then
            -- 恢复
            TweenService:Create(mainFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, Theme.WindowWidth, 0, Theme.WindowHeight)
            }):Play()
            minimizeBtn.Text = "−"
            task.wait(0.15)
            sidebar.Visible = true
            contentArea.Visible = true
        else
            -- 最小化
            sidebar.Visible = false
            contentArea.Visible = false
            TweenService:Create(mainFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 200, 0, 45)
            }):Play()
            minimizeBtn.Text = "□"
        end
        isMinimized = not isMinimized
    end)

    -- 在 Window 对象中添加 SetCloseCallback 方法
    function windowObj:SetCloseCallback(callback)
        -- 修正1: 标题栏名称是 "titleBar"（小写t，大写B）
        -- 修正2: 关闭按钮名称是 "closeBtn"（小写c，小写b，大写B）
        local titleBar = self.mainFrame:FindFirstChild("titleBar")
        local closeBtn = titleBar and titleBar:FindFirstChild("closeBtn")
    
        if closeBtn then
            -- 先断开原有的关闭连接（避免重复绑定）
            -- 注意：原有的 closeBtn.MouseButton1Click 连接在下面已经存在
            -- 我们需要确保不会同时执行两个关闭逻辑
            
            -- 方法：创建一个新的连接，并保存原有的连接以便断开（如果需要）
            closeBtn.MouseButton1Click:Connect(function()
                if callback then callback() end
                -- 只销毁当前窗口，而不是所有窗口
                self.gui:Destroy()
                -- 从活跃窗口列表中移除
                for i, w in ipairs(activeWindows) do
                    if w == self then
                        table.remove(activeWindows, i)
                        break
                    end
                end
            end)
        else
            warn("ChronixUI: 未找到关闭按钮，无法设置 CloseCallback")
        end
    end
    
    -- 隐藏/显示快捷键
    local hideConnection
    hideConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == windowHideKey then
            playClickSound()
            isHidden = not isHidden
            if isHidden then
                mainFrame.Visible = false
            else
                mainFrame.Visible = true
            end
        end
    end)
    
    table.insert(activeWindows, windowObj)
    
    updateCanvas()
    
    return windowObj
end

-- ============ 标签页类 ============

local Tab = {}
Tab.__index = Tab

function Window:CreateTab(config)
    local name = config.Name or "Tab"
    local icon = config.Icon or "📁"
    
    local tabObj = {
        name = name,
        icon = icon,
        container = nil,
        button = nil,
        window = self,
        sections = {}
    }
    
    -- 创建标签页容器
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.Visible = false
    container.Parent = self.contentScroller
    tabObj.container = container
    
    local containerLayout = Instance.new("UIListLayout")
    containerLayout.Padding = UDim.new(0, 8)
    containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    containerLayout.Parent = container
    
    containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.Size = UDim2.new(1, 0, 0, containerLayout.AbsoluteContentSize.Y)
        self.updateCanvas()
    end)
    
    -- 创建侧边栏按钮
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 45)
    btn.Position = UDim2.new(0, 5, 0, 0)
    btn.Text = icon .. "  " .. name
    btn.TextColor3 = Theme.TextSecondary
    btn.TextSize = Theme.TextSize
    btn.Font = Theme.Font
    btn.BackgroundColor3 = Theme.SidebarBg
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = self.sidebar
    applyCorner(btn, 8)
    
    btn.MouseEnter:Connect(function()
        if self.currentTab ~= tabObj then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.SidebarHover}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.currentTab ~= tabObj then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.SidebarBg}):Play()
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        playClickSound()
        self:SwitchToTab(tabObj)
    end)
    
    tabObj.button = btn
    table.insert(self.tabs, tabObj)
    
    if #self.tabs == 1 then
        self:SwitchToTab(tabObj)
    end
    
    setmetatable(tabObj, Tab)
    return tabObj
end

function Window:SwitchToTab(tab)
    if self.currentTab == tab then return end
    
    if self.currentTab then
        self.currentTab.container.Visible = false
        TweenService:Create(self.currentTab.button, TweenInfo.new(0.15), {BackgroundColor3 = Theme.SidebarBg}):Play()
        self.currentTab.button.TextColor3 = Theme.TextSecondary
    end
    
    self.currentTab = tab
    tab.container.Visible = true
    TweenService:Create(tab.button, TweenInfo.new(0.15), {BackgroundColor3 = Theme.SidebarActive}):Play()
    tab.button.TextColor3 = Theme.TextColor
    
    self.updateCanvas()
end

-- ============ 设置标签页（内置） ============

function Window:CreateSettingsTab()
    local settingsTab = self:CreateTab({Name = "设置", Icon = "⚙️"})
    local section = settingsTab:CreateSection("界面设置")
    
    -- 隐藏/显示快捷键设置
    local bindKey = settingsTab:AddBind({
        Parent = section,
        Name = "隐藏/显示快捷键",
        Default = "RightShift",
        Hold = false,
        Flag = "HideKey",
        Callback = function(key)
            windowHideKey = key
            ChronixUI:NotifySuccess("设置", "隐藏快捷键已更改为: " .. tostring(key))
        end
    })
    
    -- 主题切换（可选）
    settingsTab:AddButton({
        Parent = section,
        Name = "重置窗口位置",
        Callback = function()
            self.mainFrame.Position = UDim2.new(0.5, -self.theme.WindowWidth/2, 0.5, -self.theme.WindowHeight/2)
            ChronixUI:NotifyInfo("提示", "窗口位置已重置")
        end
    })
    
    return settingsTab
end

-- ============ 分区类 ============

function Tab:CreateSection(title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 0)
    section.Position = UDim2.new(0, 10, 0, 0)
    section.BackgroundTransparency = 1
    section.Parent = self.container
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundColor3 = self.window.theme.SidebarBg
    header.BorderSizePixel = 0
    header.Parent = section
    applyCorner(header, 6)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.Text = title
    titleLabel.TextColor3 = self.window.theme.AccentColor
    titleLabel.TextSize = self.window.theme.TextSize
    titleLabel.Font = self.window.theme.FontBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = header
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 0, 0)
    content.Position = UDim2.new(0, 0, 0, 40)
    content.BackgroundTransparency = 1
    content.Parent = section
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 5)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = content
    
    local function updateHeight()
        task.wait()
        section.Size = UDim2.new(1, -20, 0, contentLayout.AbsoluteContentSize.Y + 45)
    end
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight)
    updateHeight()
    
    return content, updateHeight
end

-- ============ 控件类 ============

function Tab:AddButton(config)
    local parent = config.Parent or self.container
    local name = config.Name or "Button"
    local callback = config.Callback or function() end
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, Theme.RowHeight)
    btn.Position = UDim2.new(0, 10, 0, 0)
    btn.Text = name
    btn.TextColor3 = Theme.TextColor
    btn.TextSize = Theme.TextSize
    btn.Font = Theme.Font
    btn.BackgroundColor3 = Theme.SidebarBg
    btn.BorderSizePixel = 0
    btn.Parent = parent
    applyCorner(btn, 8)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.SidebarHover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.SidebarBg}):Play()
    end)
    
    btn.MouseButton1Click:Connect(function()
        playClickSound()
        callback()
    end)
    
    return btn
end

function Tab:AddToggle(config)
    local parent = config.Parent or self.container
    local name = config.Name or "Toggle"
    local default = config.Default or false
    local flag = config.Flag or name
    local callback = config.Callback or function() end
    
    self.window.flags[flag] = default
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, Theme.RowHeight)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Text = name
    label.TextColor3 = Theme.TextColor
    label.TextSize = Theme.TextSize
    label.Font = Theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, Theme.RowHeight - 10)
    toggleBtn.Position = UDim2.new(1, -60, 0, 5)
    toggleBtn.Text = default and "ON" or "OFF"
    toggleBtn.TextColor3 = Theme.TextColor
    toggleBtn.TextSize = Theme.TextSize - 2
    toggleBtn.Font = Theme.FontBold
    toggleBtn.BackgroundColor3 = default and Theme.SuccessColor or Theme.SidebarHover
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = container
    applyCorner(toggleBtn, 15)
    
    local function update(value)
        self.window.flags[flag] = value
        toggleBtn.Text = value and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = value and Theme.SuccessColor or Theme.SidebarHover
        callback(value)
    end
    
    toggleBtn.MouseButton1Click:Connect(function()
        playClickSound()
        update(not self.window.flags[flag])
    end)
    
    return {
        set = function(val) update(val) end,
        get = function() return self.window.flags[flag] end
    }
end

function Tab:AddSlider(config)
    local parent = config.Parent or self.container
    local name = config.Name or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local flag = config.Flag or name
    local callback = config.Callback or function() end
    
    self.window.flags[flag] = default
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, Theme.RowHeight + 10)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, -10, 0, 25)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Text = name
    label.TextColor3 = Theme.TextColor
    label.TextSize = Theme.TextSize
    label.Font = Theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, -20, 0, 25)
    valueLabel.Position = UDim2.new(0.6, 5, 0, 0)
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Theme.AccentColor
    valueLabel.TextSize = Theme.TextSize
    valueLabel.Font = Theme.FontBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.BackgroundTransparency = 1
    valueLabel.Parent = container
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 4)
    track.Position = UDim2.new(0, 10, 0, 35)
    track.BackgroundColor3 = Theme.SidebarHover
    track.BorderSizePixel = 0
    track.Parent = container
    applyCorner(track, 2)
    
    local fill = Instance.new("Frame")
    local percent = (default - min) / (max - min)
    fill.Size = UDim2.new(percent, 0, 1, 0)
    fill.BackgroundColor3 = Theme.AccentColor
    fill.BorderSizePixel = 0
    fill.Parent = track
    applyCorner(fill, 2)
    
    local thumb = Instance.new("TextButton")
    thumb.Size = UDim2.new(0, 20, 0, 20)
    thumb.Position = UDim2.new(percent, -10, 0, -8)
    thumb.BackgroundColor3 = Theme.TextColor
    thumb.Text = ""
    thumb.BorderSizePixel = 0
    thumb.Parent = container
    applyCorner(thumb, 10)
    
    local dragging = false
    
    local function update(value)
        value = math.clamp(value, min, max)
        self.window.flags[flag] = value
        local newPercent = (value - min) / (max - min)
        fill.Size = UDim2.new(newPercent, 0, 1, 0)
        thumb.Position = UDim2.new(newPercent, -10, 0, -8)
        valueLabel.Text = tostring(math.floor(value))
        callback(value)
    end
    
    thumb.MouseButton1Down:Connect(function(input)
        dragging = true
        local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        update(min + (max - min) * percent)
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            update(min + (max - min) * percent)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return {
        set = function(val) update(val) end,
        get = function() return self.window.flags[flag] end
    }
end

function Tab:AddDropdown(config)
    local parent = config.Parent or self.container
    local name = config.Name or "Dropdown"
    local options = config.Options or {}
    local default = config.Default or options[1]
    local flag = config.Flag or name
    local callback = config.Callback or function() end
    
    self.window.flags[flag] = default
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, Theme.RowHeight)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, -10, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Text = name
    label.TextColor3 = Theme.TextColor
    label.TextSize = Theme.TextSize
    label.Font = Theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0.6, -25, 0, Theme.RowHeight - 10)
    dropdownBtn.Position = UDim2.new(0.4, 5, 0, 5)
    dropdownBtn.Text = default
    dropdownBtn.TextColor3 = Theme.TextColor
    dropdownBtn.TextSize = Theme.TextSize
    dropdownBtn.Font = Theme.Font
    dropdownBtn.BackgroundColor3 = Theme.SidebarBg
    dropdownBtn.BorderSizePixel = 0
    dropdownBtn.Parent = container
    applyCorner(dropdownBtn, 8)
    
    local listOpen = false
    local dropdownList = nil
    
    local function closeList()
        if dropdownList then
            TweenService:Create(dropdownList, TweenInfo.new(0.2), {Size = UDim2.new(0.6, -25, 0, 0)}):Play()
            task.wait(0.2)
            dropdownList:Destroy()
            dropdownList = nil
        end
        listOpen = false
    end
    
    dropdownBtn.MouseButton1Click:Connect(function()
        playClickSound()
        if listOpen then closeList() return end
        
        dropdownList = Instance.new("ScrollingFrame")
        dropdownList.Size = UDim2.new(0.6, -25, 0, 0)
        dropdownList.Position = UDim2.new(0.4, 5, 0, Theme.RowHeight - 5)
        dropdownList.BackgroundColor3 = Theme.SidebarBg
        dropdownList.BorderSizePixel = 0
        dropdownList.ScrollBarThickness = isMobile and 0 or 3
        dropdownList.Parent = container
        applyCorner(dropdownList, 8)
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = dropdownList
        
        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 35)
            optBtn.Text = opt
            optBtn.TextColor3 = Theme.TextSecondary
            optBtn.TextSize = Theme.TextSize
            optBtn.Font = Theme.Font
            optBtn.BackgroundColor3 = Theme.SidebarBg
            optBtn.BorderSizePixel = 0
            optBtn.Parent = dropdownList
            
            optBtn.MouseEnter:Connect(function()
                TweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.SidebarHover}):Play()
                optBtn.TextColor3 = Theme.TextColor
            end)
            optBtn.MouseLeave:Connect(function()
                TweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.SidebarBg}):Play()
                optBtn.TextColor3 = Theme.TextSecondary
            end)
            
            optBtn.MouseButton1Click:Connect(function()
                playClickSound()
                self.window.flags[flag] = opt
                dropdownBtn.Text = opt
                callback(opt)
                closeList()
            end)
        end
        
        local totalHeight = math.min(#options * 37, 200)
        dropdownList.Size = UDim2.new(0.6, -25, 0, totalHeight)
        dropdownList.CanvasSize = UDim2.new(0, 0, 0, #options * 37)
        listOpen = true
        
        local clickConn
        clickConn = UserInputService.InputBegan:Connect(function(input)
            if listOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = UserInputService:GetMouseLocation()
                local absPos = dropdownList.AbsolutePosition
                local absSize = dropdownList.AbsoluteSize
                if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or
                   mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
                    closeList()
                    clickConn:Disconnect()
                end
            end
        end)
    end)
    
    return {
        set = function(val) 
            self.window.flags[flag] = val
            dropdownBtn.Text = val
        end,
        get = function() return self.window.flags[flag] end,
        refresh = function(newOptions)
            options = newOptions
            if not table.find(options, self.window.flags[flag]) then
                self.window.flags[flag] = options[1]
                dropdownBtn.Text = options[1]
            end
        end
    }
end

function Tab:AddInput(config)
    local parent = config.Parent or self.container
    local name = config.Name or "Input"
    local placeholder = config.Placeholder or ""
    local flag = config.Flag or name
    local callback = config.Callback or function() end
    
    self.window.flags[flag] = ""
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, Theme.RowHeight)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, -10, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Text = name
    label.TextColor3 = Theme.TextColor
    label.TextSize = Theme.TextSize
    label.Font = Theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.6, -25, 0, Theme.RowHeight - 10)
    input.Position = UDim2.new(0.4, 5, 0, 5)
    input.PlaceholderText = placeholder
    input.Text = ""
    input.TextColor3 = Theme.TextColor
    input.TextSize = Theme.TextSize
    input.Font = Theme.Font
    input.BackgroundColor3 = Theme.SidebarBg
    input.BorderSizePixel = 0
    input.Parent = container
    applyCorner(input, 8)
    
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            self.window.flags[flag] = input.Text
            callback(input.Text)
        end
    end)
    
    return input
end

function Tab:AddLabel(config)
    local parent = config.Parent or self.container
    local text = config.Text or ""
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 30)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Text = text
    label.TextColor3 = Theme.TextSecondary
    label.TextSize = Theme.TextSize - 2
    label.Font = Theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.BackgroundTransparency = 1
    label.Parent = parent
    
    return label
end

function Tab:AddBind(config)
    local parent = config.Parent or self.container
    local name = config.Name or "按键绑定"
    local default = config.Default or "None"
    local holdMode = config.Hold or false
    local callback = config.Callback or function() end
    local flag = config.Flag or name
    
    self.window.flags[flag] = default
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, Theme.RowHeight)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -10, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Text = name
    label.TextColor3 = Theme.TextColor
    label.TextSize = Theme.TextSize
    label.Font = Theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0.4, -15, 0, Theme.RowHeight - 10)
    bindBtn.Position = UDim2.new(0.6, 5, 0, 5)
    bindBtn.Text = default
    bindBtn.TextColor3 = Theme.TextColor
    bindBtn.TextSize = Theme.TextSize
    bindBtn.Font = Theme.Font
    bindBtn.BackgroundColor3 = Theme.SidebarBg
    bindBtn.BorderSizePixel = 0
    bindBtn.Parent = container
    applyCorner(bindBtn, 8)
    
    local isBinding = false
    local currentKey = default
    local isHolding = false
    
    local blacklistedKeys = {
        Unknown = true, W = true, A = true, S = true, D = true,
        Up = true, Left = true, Down = true, Right = true,
        Tab = true, Backspace = true, Escape = true
    }
    
    local function getKeyName(key)
        if key.UserInputType == Enum.UserInputType.Keyboard then
            return key.KeyCode.Name
        elseif key.UserInputType == Enum.UserInputType.MouseButton1 then
            return "Mouse1"
        elseif key.UserInputType == Enum.UserInputType.MouseButton2 then
            return "Mouse2"
        elseif key.UserInputType == Enum.UserInputType.MouseButton3 then
            return "Mouse3"
        end
        return "None"
    end
    
    bindBtn.MouseButton1Click:Connect(function()
        playClickSound()
        isBinding = true
        bindBtn.Text = "..."
    end)
    
    local inputConn
    inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if isBinding then
            local keyName = getKeyName(input)
            if keyName ~= "None" and not blacklistedKeys[keyName] then
                isBinding = false
                currentKey = keyName
                bindBtn.Text = currentKey
                self.window.flags[flag] = currentKey
                callback(currentKey)
            else
                isBinding = false
                bindBtn.Text = currentKey
            end
        elseif not isBinding and currentKey ~= "None" then
            local pressedKey = getKeyName(input)
            if pressedKey == currentKey then
                if holdMode then
                    isHolding = true
                    callback(true)
                else
                    callback()
                end
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if holdMode and isHolding then
            local releasedKey = getKeyName(input)
            if releasedKey == currentKey then
                isHolding = false
                callback(false)
            end
        end
    end)
    
    return {
        set = function(key)
            currentKey = key
            bindBtn.Text = currentKey
            self.window.flags[flag] = currentKey
        end,
        get = function() return currentKey end
    }
end

function Tab:AddColorpicker(config)
    local parent = config.Parent or self.container
    local name = config.Name or "颜色选择"
    local default = config.Default or Color3.fromRGB(255, 255, 255)
    local callback = config.Callback or function() end
    local flag = config.Flag or name
    
    self.window.flags[flag] = default
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, Theme.RowHeight)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -10, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Text = name
    label.TextColor3 = Theme.TextColor
    label.TextSize = Theme.TextSize
    label.Font = Theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0, 40, 0, Theme.RowHeight - 10)
    colorBtn.Position = UDim2.new(1, -50, 0, 5)
    colorBtn.Text = ""
    colorBtn.BackgroundColor3 = default
    colorBtn.BorderSizePixel = 0
    colorBtn.Parent = container
    applyCorner(colorBtn, 8)
    
    local isOpen = false
    local pickerFrame = nil
    
    local function closePicker()
        if pickerFrame then
            TweenService:Create(pickerFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.6, -15, 0, 0)}):Play()
            task.wait(0.2)
            pickerFrame:Destroy()
            pickerFrame = nil
        end
        isOpen = false
    end
    
    colorBtn.MouseButton1Click:Connect(function()
        playClickSound()
        if isOpen then closePicker() return end
        
        isOpen = true
        pickerFrame = Instance.new("Frame")
        pickerFrame.Size = UDim2.new(0.6, -15, 0, 0)
        pickerFrame.Position = UDim2.new(0.4, 5, 0, Theme.RowHeight - 5)
        pickerFrame.BackgroundColor3 = Theme.SidebarBg
        pickerFrame.BorderSizePixel = 0
        pickerFrame.Parent = container
        applyCorner(pickerFrame, 8)
        
        local colorDisplay = Instance.new("Frame")
        colorDisplay.Size = UDim2.new(1, -20, 0, 40)
        colorDisplay.Position = UDim2.new(0, 10, 0, 10)
        colorDisplay.BackgroundColor3 = colorBtn.BackgroundColor3
        colorDisplay.BorderSizePixel = 0
        colorDisplay.Parent = pickerFrame
        applyCorner(colorDisplay, 5)
        
        -- 简单的 RGB 滑块
        local rSlider = self:AddSliderInternal(pickerFrame, "红", 0, 255, default.R * 255, function(v)
            local newColor = Color3.fromRGB(v, colorBtn.BackgroundColor3.G * 255, colorBtn.BackgroundColor3.B * 255)
            colorBtn.BackgroundColor3 = newColor
            colorDisplay.BackgroundColor3 = newColor
            self.window.flags[flag] = newColor
            callback(newColor)
        end)
        
        local gSlider = self:AddSliderInternal(pickerFrame, "绿", 0, 255, default.G * 255, function(v)
            local newColor = Color3.fromRGB(colorBtn.BackgroundColor3.R * 255, v, colorBtn.BackgroundColor3.B * 255)
            colorBtn.BackgroundColor3 = newColor
            colorDisplay.BackgroundColor3 = newColor
            self.window.flags[flag] = newColor
            callback(newColor)
        end)
        
        local bSlider = self:AddSliderInternal(pickerFrame, "蓝", 0, 255, default.B * 255, function(v)
            local newColor = Color3.fromRGB(colorBtn.BackgroundColor3.R * 255, colorBtn.BackgroundColor3.G * 255, v)
            colorBtn.BackgroundColor3 = newColor
            colorDisplay.BackgroundColor3 = newColor
            self.window.flags[flag] = newColor
            callback(newColor)
        end)
        
        rSlider.Position = UDim2.new(0, 10, 0, 60)
        gSlider.Position = UDim2.new(0, 10, 0, 110)
        bSlider.Position = UDim2.new(0, 10, 0, 160)
        
        pickerFrame.Size = UDim2.new(0.6, -15, 0, 210)
        
        local clickConn
        clickConn = UserInputService.InputBegan:Connect(function(input)
            if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = UserInputService:GetMouseLocation()
                local absPos = pickerFrame.AbsolutePosition
                local absSize = pickerFrame.AbsoluteSize
                if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or
                   mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
                    closePicker()
                    clickConn:Disconnect()
                end
            end
        end)
    end)
    
    return {
        set = function(color)
            colorBtn.BackgroundColor3 = color
            self.window.flags[flag] = color
            callback(color)
        end,
        get = function() return colorBtn.BackgroundColor3 end
    }
end

function Tab:AddSliderInternal(parent, name, min, max, defaultVal, callback)
    local value = defaultVal or min
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = name
    label.TextColor3 = Theme.TextColor
    label.TextSize = Theme.TextSize
    label.Font = Theme.Font
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = parent
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.2, 0, 0, 25)
    valueLabel.Position = UDim2.new(0.8, 0, 0, 0)
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = Theme.AccentColor
    valueLabel.TextSize = Theme.TextSize
    valueLabel.Font = Theme.FontBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.BackgroundTransparency = 1
    valueLabel.Parent = parent
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.new(0, 0, 0, 28)
    track.BackgroundColor3 = Theme.SidebarHover
    track.BorderSizePixel = 0
    track.Parent = parent
    applyCorner(track, 2)
    
    local fill = Instance.new("Frame")
    local percent = (value - min) / (max - min)
    fill.Size = UDim2.new(percent, 0, 1, 0)
    fill.BackgroundColor3 = Theme.AccentColor
    fill.BorderSizePixel = 0
    fill.Parent = track
    applyCorner(fill, 2)
    
    local thumb = Instance.new("TextButton")
    thumb.Size = UDim2.new(0, 16, 0, 16)
    thumb.Position = UDim2.new(percent, -8, 0, -6)
    thumb.BackgroundColor3 = Theme.TextColor
    thumb.Text = ""
    thumb.BorderSizePixel = 0
    thumb.Parent = parent
    applyCorner(thumb, 8)
    
    local dragging = false
    
    local function update(val)
        value = math.clamp(val, min, max)
        local newPercent = (value - min) / (max - min)
        fill.Size = UDim2.new(newPercent, 0, 1, 0)
        thumb.Position = UDim2.new(newPercent, -8, 0, -6)
        valueLabel.Text = tostring(math.floor(value))
        callback(value)
    end
    
    thumb.MouseButton1Down:Connect(function(input)
        dragging = true
        local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        update(min + (max - min) * percent)
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            update(min + (max - min) * percent)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return parent
end

-- ============ 通知系统 ============

function ChronixUI:Notify(config)
    local title = config.Title or "提示"
    local message = config.Message or ""
    local duration = config.Duration or 3
    local type = config.Type or "info"
    
    local color = type == "success" and Theme.SuccessColor or 
                  type == "error" and Theme.ErrorColor or 
                  Theme.AccentColor
    
    local yOffset = 0.1 + (#activeNotifications * 0.12)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ChronixNotification"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, isMobile and 300 or 280, 0, isMobile and 80 or 70)
    frame.Position = UDim2.new(1, 20, yOffset, 0)
    frame.BackgroundColor3 = Theme.GlassBg
    frame.BackgroundTransparency = Theme.GlassTransparency
    frame.BorderSizePixel = 0
    frame.Parent = gui
    applyCorner(frame, 10)
    
    local colorBar = Instance.new("Frame")
    colorBar.Size = UDim2.new(0, 4, 1, 0)
    colorBar.BackgroundColor3 = color
    colorBar.BorderSizePixel = 0
    colorBar.Parent = frame
    applyCorner(colorBar, 0)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 15, 0, 8)
    titleLabel.Text = title
    titleLabel.TextColor3 = color
    titleLabel.TextSize = Theme.TextSize
    titleLabel.Font = Theme.FontBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = frame
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -20, 0, 30)
    msgLabel.Position = UDim2.new(0, 15, 0, 33)
    msgLabel.Text = message
    msgLabel.TextColor3 = Theme.TextColor
    msgLabel.TextSize = Theme.TextSize - 2
    msgLabel.Font = Theme.Font
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.BackgroundTransparency = 1
    msgLabel.Parent = frame
    
    local notifData = {gui = gui, frame = frame, yOffset = yOffset}
    table.insert(activeNotifications, notifData)
    
    local inTween = TweenService:Create(frame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -frame.AbsoluteSize.X - 20, yOffset, 0)
    })
    inTween:Play()
    
    task.wait(duration)
    
    local outTween = TweenService:Create(frame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, 20, yOffset, 0)
    })
    outTween:Play()
    outTween.Completed:Connect(function()
        gui:Destroy()
        for i, data in ipairs(activeNotifications) do
            if data == notifData then
                table.remove(activeNotifications, i)
                break
            end
        end
        for i, data in ipairs(activeNotifications) do
            local newY = 0.1 + (i - 1) * 0.12
            TweenService:Create(data.frame, TweenInfo.new(0.3), {
                Position = UDim2.new(1, -data.frame.AbsoluteSize.X - 20, newY, 0)
            }):Play()
        end
    end)
end

function ChronixUI:NotifySuccess(title, message, duration)
    self:Notify({Title = title, Message = message, Duration = duration, Type = "success"})
end

function ChronixUI:NotifyError(title, message, duration)
    self:Notify({Title = title, Message = message, Duration = duration, Type = "error"})
end

function ChronixUI:NotifyInfo(title, message, duration)
    self:Notify({Title = title, Message = message, Duration = duration, Type = "info"})
end

function ChronixUI:Unload()
    for _, window in ipairs(activeWindows) do
        if window.gui then
            window.gui:Destroy()
        end
    end
    activeWindows = {}
    activeNotifications = {}
end

return ChronixUI