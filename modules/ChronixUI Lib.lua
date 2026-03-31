-- OrionLib 风格 UI 框架
-- 基于 HTML 设计，实现完整的功能菜单

local OrionUILib = {}
OrionUILib.Version = "1.0.0"
OrionUILib.Elements = {}
OrionUILib.Windows = {}

-- 服务引用
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- 主题颜色配置
OrionUILib.Themes = {
    Default = {
        Background = Color3.fromRGB(30, 30, 46),
        Sidebar = Color3.fromRGB(24, 24, 37),
        Accent = Color3.fromRGB(119, 221, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(170, 170, 170),
        Border = Color3.fromRGB(44, 44, 62),
        Card = Color3.fromRGB(37, 37, 53),
        Input = Color3.fromRGB(37, 37, 53),
        Hover = Color3.fromRGB(45, 45, 65)
    }
}
OrionUILib.CurrentTheme = "Default"

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
local function CreateLabel(parent, text, size, position, color, textSize, font)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.Text = text or ""
    label.Size = size or UDim2.new(1, 0, 1, 0)
    label.Position = position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextSize = textSize or 14
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
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

-- 窗口拖动功能
local function MakeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
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
    
    frame.InputChanged:Connect(function(input)
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
function OrionUILib:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "Orion UI"
    local windowSize = config.Size or UDim2.new(0, 680, 0, 420)
    
    -- 创建 ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "OrionUILib"
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = game.CoreGui
    else
        gui.Parent = gethui and gethui() or game.CoreGui
    end
    
    -- 主窗口
    local mainFrame = CreateFrame(gui, windowSize, UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2), 
                                   OrionUILib.Themes[OrionUILib.CurrentTheme].Background)
    AddStroke(mainFrame, OrionUILib.Themes[OrionUILib.CurrentTheme].Border)
    MakeDraggable(mainFrame)
    
    -- 标题栏
    local titleBar = CreateFrame(mainFrame, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), 
                                  OrionUILib.Themes[OrionUILib.CurrentTheme].Background, 1)
    
    local titleLabel = CreateLabel(titleBar, windowName, UDim2.new(1, -100, 1, 0), UDim2.new(0, 20, 0, 0),
                                    OrionUILib.Themes[OrionUILib.CurrentTheme].Accent, 20, Enum.Font.GothamBold)
    
    -- 关闭按钮
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = titleBar
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.BorderSizePixel = 0
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- 最小化按钮
    local minBtn = Instance.new("TextButton")
    minBtn.Parent = titleBar
    minBtn.Size = UDim2.new(0, 30, 0, 30)
    minBtn.Position = UDim2.new(1, -80, 0, 10)
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextSize = 24
    minBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    minBtn.BorderSizePixel = 0
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 4)
    minCorner.Parent = minBtn
    
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
                {Size = UDim2.new(windowSize.X.Scale, windowSize.X.Offset, 0, 50)}):Play()
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
                {Size = windowSize}):Play()
        end
    end)
    
    -- 侧边栏
    local sidebar = CreateFrame(mainFrame, UDim2.new(0, 160, 1, -50), UDim2.new(0, 0, 0, 50),
                                 OrionUILib.Themes[OrionUILib.CurrentTheme].Sidebar)
    
    local sidebarTitle = CreateLabel(sidebar, "功能菜单", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10),
                                      OrionUILib.Themes[OrionUILib.CurrentTheme].Accent, 16, Enum.Font.GothamBold)
    sidebarTitle.TextXAlignment = Enum.TextXAlignment.Center
    
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Parent = sidebar
    tabContainer.Size = UDim2.new(1, 0, 1, -60)
    tabContainer.Position = UDim2.new(0, 0, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 4
    
    local tabList = AddListLayout(tabContainer, 8)
    
    -- 内容区域
    local contentArea = CreateFrame(mainFrame, UDim2.new(1, -160, 1, -50), UDim2.new(0, 160, 0, 50),
                                     OrionUILib.Themes[OrionUILib.CurrentTheme].Background, 1)
    
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
    
    -- 窗口数据
    local windowData = {
        Gui = gui,
        MainFrame = mainFrame,
        ContentArea = contentScroll,
        ContentLayout = contentLayout,
        Tabs = {},
        CurrentTab = nil
    }
    
    -- 创建 Tab 函数
    function windowData:CreateTab(tabConfig)
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon or ""
        
        -- Tab 按钮
        local tabBtn = Instance.new("TextButton")
        tabBtn.Parent = tabContainer
        tabBtn.Size = UDim2.new(1, -12, 0, 36)
        tabBtn.Position = UDim2.new(0, 6, 0, 0)
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
        tabBtn.Text = "  " .. tabName
        tabBtn.TextColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].TextDark
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
        
        -- 切换 Tab
        local function SelectTab()
            for _, otherTab in pairs(windowData.Tabs) do
                otherTab.Button.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
                otherTab.Button.TextColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].TextDark
                otherTab.Content.Visible = false
            end
            tabBtn.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Accent
            tabBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            tabContent.Visible = true
            windowData.CurrentTab = tabConfig
        end
        
        tabBtn.MouseButton1Click:Connect(SelectTab)
        
        -- 如果是第一个 Tab，默认选中
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
        
        -- 添加 UI 元素的方法
        local elements = {}
        
        -- 添加玩家信息卡片
        function elements:AddPlayerCard(playerName, level, points)
            local card = CreateFrame(tabContent, UDim2.new(1, 0, 0, 70), UDim2.new(0, 0, 0, 0),
                                      OrionUILib.Themes[OrionUILib.CurrentTheme].Card)
            AddStroke(card, OrionUILib.Themes[OrionUILib.CurrentTheme].Border)
            
            local avatar = CreateFrame(card, UDim2.new(0, 48, 0, 48), UDim2.new(0, 12, 0.5, -24),
                                        OrionUILib.Themes[OrionUILib.CurrentTheme].Accent)
            local avatarCorner = Instance.new("UICorner")
            avatarCorner.CornerRadius = UDim.new(0, 8)
            avatarCorner.Parent = avatar
            
            local avatarText = CreateLabel(avatar, "玩", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
                                           Color3.fromRGB(0, 0, 0), 20, Enum.Font.GothamBold)
            avatarText.TextXAlignment = Enum.TextXAlignment.Center
            avatarText.TextYAlignment = Enum.TextYAlignment.Center
            
            local infoContainer = Instance.new("Frame")
            infoContainer.Parent = card
            infoContainer.Size = UDim2.new(1, -72, 1, 0)
            infoContainer.Position = UDim2.new(0, 72, 0, 0)
            infoContainer.BackgroundTransparency = 1
            
            local nameLabel = CreateLabel(infoContainer, playerName or "玩家名称", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 8, 0),
                                           OrionUILib.Themes[OrionUILib.CurrentTheme].Text, 16, Enum.Font.GothamBold)
            
            local infoLabel = CreateLabel(infoContainer, string.format("等级 %s | 积分 %s", level or "1", points or "0"), 
                                           UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 32, 0),
                                           OrionUILib.Themes[OrionUILib.CurrentTheme].TextDark, 12)
            
            return card
        end
        
        -- 添加按钮
        function elements:AddButton(config)
            local btnConfig = config or {}
            local btnText = btnConfig.Text or "按钮"
            local callback = btnConfig.Callback or function() end
            
            local btn = Instance.new("TextButton")
            btn.Parent = tabContent
            btn.Size = UDim2.new(1, 0, 0, 38)
            btn.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Card
            btn.Text = btnText
            btn.TextColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Text
            btn.TextSize = 14
            btn.Font = Enum.Font.GothamSemibold
            btn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn
            AddStroke(btn, OrionUILib.Themes[OrionUILib.CurrentTheme].Border)
            
            btn.MouseButton1Click:Connect(callback)
            
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Hover}):Play()
            end)
            
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Card}):Play()
            end)
            
            return btn
        end
        
        -- 添加下拉框
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
                                           OrionUILib.Themes[OrionUILib.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local dropdownBtn = Instance.new("TextButton")
            dropdownBtn.Parent = container
            dropdownBtn.Size = UDim2.new(1, 0, 0, 36)
            dropdownBtn.Position = UDim2.new(0, 0, 0, 28)
            dropdownBtn.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Input
            dropdownBtn.Text = default
            dropdownBtn.TextColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Text
            dropdownBtn.TextSize = 14
            dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
            dropdownBtn.Font = Enum.Font.Gotham
            dropdownBtn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = dropdownBtn
            AddStroke(dropdownBtn, OrionUILib.Themes[OrionUILib.CurrentTheme].Border)
            
            local dropdownList = Instance.new("Frame")
            dropdownList.Parent = container
            dropdownList.Size = UDim2.new(1, 0, 0, 0)
            dropdownList.Position = UDim2.new(0, 0, 0, 64)
            dropdownList.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Input
            dropdownList.ClipsDescendants = true
            dropdownList.Visible = false
            local listCorner = Instance.new("UICorner")
            listCorner.CornerRadius = UDim.new(0, 4)
            listCorner.Parent = dropdownList
            AddStroke(dropdownList, OrionUILib.Themes[OrionUILib.CurrentTheme].Border)
            
            local listLayout = AddListLayout(dropdownList, 0)
            
            local expanded = false
            for _, option in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = dropdownList
                optBtn.Size = UDim2.new(1, 0, 0, 32)
                optBtn.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Input
                optBtn.Text = option
                optBtn.TextColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Text
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
        
        -- 添加滑块
        function elements:AddSlider(config)
            local sliderConfig = config or {}
            local label = sliderConfig.Label or "音量"
            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local default = sliderConfig.Default or 50
            local callback = sliderConfig.Callback or function() end
            
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 70)
            container.BackgroundTransparency = 1
            
            local labelText = CreateLabel(container, label, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0),
                                           OrionUILib.Themes[OrionUILib.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local valueLabel = CreateLabel(container, tostring(default), UDim2.new(0, 50, 0, 20), UDim2.new(1, -60, 0, 0),
                                            OrionUILib.Themes[OrionUILib.CurrentTheme].Accent, 14, Enum.Font.GothamBold)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            
            local slider = Instance.new("Frame")
            slider.Parent = container
            slider.Size = UDim2.new(1, 0, 0, 4)
            slider.Position = UDim2.new(0, 0, 0, 40)
            slider.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Border
            slider.BorderSizePixel = 0
            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, 2)
            sliderCorner.Parent = slider
            
            local fill = Instance.new("Frame")
            fill.Parent = slider
            fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Accent
            fill.BorderSizePixel = 0
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 2)
            fillCorner.Parent = fill
            
            local handle = Instance.new("Frame")
            handle.Parent = slider
            handle.Size = UDim2.new(0, 12, 0, 12)
            handle.Position = UDim2.new((default - min) / (max - min), -6, 0, -4)
            handle.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Accent
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
        
        -- 添加开关
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
                                           OrionUILib.Themes[OrionUILib.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local toggleBtn = Instance.new("Frame")
            toggleBtn.Parent = container
            toggleBtn.Size = UDim2.new(0, 50, 0, 26)
            toggleBtn.Position = UDim2.new(1, -60, 0, 12)
            toggleBtn.BackgroundColor3 = default and OrionUILib.Themes[OrionUILib.CurrentTheme].Accent or Color3.fromRGB(80, 80, 80)
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
                    local targetColor = toggled and OrionUILib.Themes[OrionUILib.CurrentTheme].Accent or Color3.fromRGB(80, 80, 80)
                    local targetPos = toggled and UDim2.new(1, -26, 0.5, -11) or UDim2.new(0, 4, 0.5, -11)
                    TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                    TweenService:Create(toggleHandle, TweenInfo.new(0.2), {Position = targetPos}):Play()
                    callback(toggled)
                end
            end)
            
            return container
        end
        
        -- 添加输入框
        function elements:AddInput(config)
            local inputConfig = config or {}
            local label = inputConfig.Label or "输入"
            local placeholder = inputConfig.Placeholder or "请输入..."
            local callback = inputConfig.Callback or function() end
            
            local container = Instance.new("Frame")
            container.Parent = tabContent
            container.Size = UDim2.new(1, 0, 0, 70)
            container.BackgroundTransparency = 1
            
            local labelText = CreateLabel(container, label, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0),
                                           OrionUILib.Themes[OrionUILib.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local inputBox = Instance.new("TextBox")
            inputBox.Parent = container
            inputBox.Size = UDim2.new(1, 0, 0, 36)
            inputBox.Position = UDim2.new(0, 0, 0, 28)
            inputBox.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Input
            inputBox.PlaceholderText = placeholder
            inputBox.PlaceholderColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].TextDark
            inputBox.Text = ""
            inputBox.TextColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Text
            inputBox.TextSize = 14
            inputBox.Font = Enum.Font.Gotham
            inputBox.BorderSizePixel = 0
            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 4)
            inputCorner.Parent = inputBox
            AddStroke(inputBox, OrionUILib.Themes[OrionUILib.CurrentTheme].Border)
            
            inputBox.FocusLost:Connect(function()
                callback(inputBox.Text)
            end)
            
            return container
        end
        
        -- 添加按键绑定
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
                                           OrionUILib.Themes[OrionUILib.CurrentTheme].Text, 14, Enum.Font.GothamSemibold)
            
            local keyBtn = Instance.new("TextButton")
            keyBtn.Parent = container
            keyBtn.Size = UDim2.new(1, 0, 0, 36)
            keyBtn.Position = UDim2.new(0, 0, 0, 28)
            keyBtn.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Input
            keyBtn.Text = defaultKey
            keyBtn.TextColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Accent
            keyBtn.TextSize = 14
            keyBtn.Font = Enum.Font.GothamBold
            keyBtn.BorderSizePixel = 0
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = keyBtn
            AddStroke(keyBtn, OrionUILib.Themes[OrionUILib.CurrentTheme].Border)
            
            local listening = false
            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                keyBtn.Text = "按下按键..."
                keyBtn.TextColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Text
                
                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local key = input.KeyCode.Name
                        if key ~= "Unknown" then
                            keyBtn.Text = key
                            keyBtn.TextColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Accent
                            callback(key)
                            listening = false
                            connection:Disconnect()
                        end
                    end
                end)
            end)
            
            return container
        end
        
        -- 添加分隔线
        function elements:AddDivider()
            local divider = Instance.new("Frame")
            divider.Parent = tabContent
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.BackgroundColor3 = OrionUILib.Themes[OrionUILib.CurrentTheme].Border
            divider.BorderSizePixel = 0
            return divider
        end
        
        -- 添加标题
        function elements:AddTitle(text)
            local title = CreateLabel(tabContent, text, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0),
                                       OrionUILib.Themes[OrionUILib.CurrentTheme].Accent, 18, Enum.Font.GothamBold)
            return title
        end
        
        return elements
    end
    
    table.insert(OrionUILib.Windows, windowData)
    return windowData
end

-- 销毁所有窗口
function OrionUILib:Destroy()
    for _, window in pairs(self.Windows) do
        if window.Gui then
            window.Gui:Destroy()
        end
    end
    self.Windows = {}
end

-- 显示通知
function OrionUILib:Notify(config)
    local title = config.Title or "通知"
    local content = config.Content or ""
    local duration = config.Duration or 3
    
    -- 简单实现通知，可根据需要扩展
    warn(string.format("[%s] %s", title, content))
end

return OrionUILib