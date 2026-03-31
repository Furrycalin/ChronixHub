-- ChronixUI
-- 毛玻璃质感 + 白淡紫配色 + 会员名高亮

local ChronixUI = {}

-- 服务
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

-- 检查是否为 Premium 会员
local function isPremium()
    return LocalPlayer.MembershipType == Enum.MembershipType.Premium
end

-- 主题配置：白淡紫配色 + 毛玻璃
local Theme = {
    -- 颜色
    MainBg = Color3.fromRGB(245, 240, 255),      -- 淡紫色背景
    GlassBg = Color3.fromRGB(255, 255, 255),     -- 白色毛玻璃底
    GlassTransparency = 0.75,                     -- 毛玻璃透明度
    SidebarBg = Color3.fromRGB(235, 225, 250),    -- 左侧栏淡紫
    SidebarHover = Color3.fromRGB(215, 200, 240), -- 左侧栏悬停
    SidebarActive = Color3.fromRGB(180, 160, 220),-- 左侧栏选中
    AccentColor = Color3.fromRGB(150, 120, 200),  -- 强调色（紫色）
    SuccessColor = Color3.fromRGB(120, 200, 120), -- 成功绿色
    ErrorColor = Color3.fromRGB(220, 120, 120),   -- 错误红色
    TextColor = Color3.fromRGB(50, 40, 70),       -- 深紫色文字
    TextSecondary = Color3.fromRGB(100, 90, 120), -- 次要文字
    PremiumColor = Color3.fromRGB(220, 180, 80),  -- 会员金色
    
    -- 字体
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    TextSize = 14,
    TitleSize = 18,
    SidebarTextSize = 15,  -- 左侧栏文字放大
    
    -- 尺寸
    WindowWidth = 615,
    WindowHeight = 344,
    SidebarWidth = 150,
    RowHeight = 38,
    
    -- 动画
    TweenTime = 0.2,
}

-- 存储实例
local activeWindows = {}
local activeNotifications = {}
local windowHideKey = Enum.KeyCode.RightShift

-- ============ 工具函数 ============

local function AddConnection(Signal, Function)
    if not ChronixUI:IsRunning() then return end
    local SignalConnect = Signal:Connect(Function)
    table.insert(ChronixUI.Connections, SignalConnect)
    return SignalConnect
end

local function Create(Name, Properties, Children)
    local Object = Instance.new(Name)
    for i, v in next, Properties or {} do
        Object[i] = v
    end
    for i, v in next, Children or {} do
        v.Parent = Object
    end
    return Object
end

local function CreateElement(ElementName, ElementFunction)
    ChronixUI.Elements[ElementName] = function(...)
        return ElementFunction(...)
    end
end

local function MakeElement(ElementName, ...)
    return ChronixUI.Elements[ElementName](...)
end

local function SetProps(Element, Props)
    table.foreach(Props, function(Property, Value)
        Element[Property] = Value
    end)
    return Element
end

local function SetChildren(Element, Children)
    table.foreach(Children, function(_, Child)
        Child.Parent = Element
    end)
    return Element
end

local function ReturnProperty(Object)
    if Object:IsA("Frame") or Object:IsA("TextButton") then
        return "BackgroundColor3"
    end
    if Object:IsA("ScrollingFrame") then
        return "ScrollBarImageColor3"
    end
    if Object:IsA("UIStroke") then
        return "Color"
    end
    if Object:IsA("TextLabel") or Object:IsA("TextBox") then
        return "TextColor3"
    end
    if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
        return "ImageColor3"
    end
end

local function AddThemeObject(Object, Type)
    if not ChronixUI.ThemeObjects[Type] then
        ChronixUI.ThemeObjects[Type] = {}
    end
    table.insert(ChronixUI.ThemeObjects[Type], Object)
    Object[ReturnProperty(Object)] = ChronixUI.Themes[ChronixUI.SelectedTheme][Type]
    return Object
end

local function MakeDraggable(DragPoint, Main)
    pcall(function()
        local Dragging, DragInput, MousePos, FramePos = false
        AddConnection(DragPoint.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging = true
                MousePos = Input.Position
                FramePos = Main.Position
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)
        AddConnection(DragPoint.InputChanged, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement then
                DragInput = Input
            end
        end)
        AddConnection(UserInputService.InputChanged, function(Input)
            if Input == DragInput and Dragging then
                local Delta = Input.Position - MousePos
                Main.Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
            end
        end)
    end)
end

local function Round(Number, Factor)
    local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
    if Result < 0 then Result = Result + Factor end
    return Result
end

local function PackColor(Color)
    return { R = Color.R * 255, G = Color.G * 255, B = Color.B * 255 }
end

local function UnpackColor(Color)
    return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function SaveCfg(Name)
    local Data = {}
    for i, v in pairs(ChronixUI.Flags) do
        if v.Save then
            if v.Type == "Colorpicker" then
                Data[i] = PackColor(v.Value)
            else
                Data[i] = v.Value
            end
        end
    end
    writefile(ChronixUI.Folder .. "/" .. Name .. ".txt", tostring(HttpService:JSONEncode(Data)))
end

-- ============ 基础元素创建 ============

CreateElement("Corner", function(Scale, Offset)
    return Create("UICorner", { CornerRadius = UDim.new(Scale or 0, Offset or 10) })
end)

CreateElement("Stroke", function(Color, Thickness)
    return Create("UIStroke", { Color = Color or Color3.fromRGB(200, 200, 200), Thickness = Thickness or 1 })
end)

CreateElement("List", function(Scale, Offset)
    return Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(Scale or 0, Offset or 0) })
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
    return Create("UIPadding", {
        PaddingBottom = UDim.new(0, Bottom or 4),
        PaddingLeft = UDim.new(0, Left or 4),
        PaddingRight = UDim.new(0, Right or 4),
        PaddingTop = UDim.new(0, Top or 4)
    })
end)

CreateElement("TFrame", function()
    return Create("Frame", { BackgroundTransparency = 1 })
end)

CreateElement("Frame", function(Color)
    return Create("Frame", { BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 })
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
    return Create("Frame", { BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 }, {
        Create("UICorner", { CornerRadius = UDim.new(Scale, Offset) })
    })
end)

CreateElement("Button", function()
    return Create("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0 })
end)

CreateElement("ScrollFrame", function(Color, Width)
    return Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        MidImage = "rbxassetid://7445543667",
        BottomImage = "rbxassetid://7445543667",
        TopImage = "rbxassetid://7445543667",
        ScrollBarImageColor3 = Color,
        BorderSizePixel = 0,
        ScrollBarThickness = Width,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
end)

CreateElement("Image", function(ImageID)
    return Create("ImageLabel", { Image = ImageID, BackgroundTransparency = 1 })
end)

CreateElement("Label", function(Text, TextSize, Transparency)
    return Create("TextLabel", {
        Text = Text or "",
        TextColor3 = Theme.TextColor,
        TextTransparency = Transparency or 0,
        TextSize = TextSize or Theme.TextSize,
        Font = Enum.Font.Gotham,
        RichText = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end)

-- ============ 通知系统 ============

local NotificationHolder = nil

function ChronixUI:MakeNotification(NotificationConfig)
    spawn(function()
        NotificationConfig.Name = NotificationConfig.Name or "Notification"
        NotificationConfig.Content = NotificationConfig.Content or "Test"
        NotificationConfig.Time = NotificationConfig.Time or 5

        if not NotificationHolder or not NotificationHolder.Parent then
            NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
                SetProps(MakeElement("List"), {
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Bottom,
                    Padding = UDim.new(0, 5)
                })
            }), {
                Position = UDim2.new(1, -25, 1, -25),
                Size = UDim2.new(0, 300, 1, -25),
                AnchorPoint = Vector2.new(1, 1),
                Parent = ChronixUI.Gui
            })
        end

        local NotificationParent = SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = NotificationHolder
        })

        local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Theme.SidebarBg, 0, 10), {
            Parent = NotificationParent,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(1, -55, 0, 0),
            BackgroundTransparency = 0,
            AutomaticSize = Enum.AutomaticSize.Y
        }), {
            MakeElement("Stroke", Theme.AccentColor, 1),
            MakeElement("Padding", 12, 12, 12, 12),
            SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
                Size = UDim2.new(1, -30, 0, 20),
                Position = UDim2.new(0, 30, 0, 0),
                Font = Enum.Font.GothamBold,
                Name = "Title",
                TextColor3 = Theme.AccentColor
            }),
            SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 25),
                Font = Enum.Font.GothamSemibold,
                Name = "Content",
                AutomaticSize = Enum.AutomaticSize.Y,
                TextColor3 = Theme.TextColor,
                TextWrapped = true
            })
        })

        TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        wait(NotificationConfig.Time - 0.88)
        TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), { BackgroundTransparency = 0.6 }):Play()
        wait(0.3)
        TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), { Transparency = 0.9 }):Play()
        TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), { TextTransparency = 0.4 }):Play()
        TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), { TextTransparency = 0.5 }):Play()
        wait(0.05)
        NotificationFrame:TweenPosition(UDim2.new(1, 20, 0, 0), 'In', 'Quint', 0.8, true)
        wait(1.35)
        NotificationFrame:Destroy()
    end)
end

-- ============ 加载动画 ============

local function PlayLoadingAnimation(config)
    config = config or {}
    local duration = config.Duration or 2.5
    task.wait(duration)
end

-- ============ 主窗口 ============

function ChronixUI:MakeWindow(WindowConfig)
    local FirstTab = true
    local Minimized = false
    local UIHidden = false

    WindowConfig = WindowConfig or {}
    WindowConfig.Name = WindowConfig.Name or "ChronixHub"
    WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
    WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
    WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end

    ChronixUI.Folder = WindowConfig.ConfigFolder
    ChronixUI.SaveCfg = WindowConfig.SaveConfig

    if WindowConfig.SaveConfig then
        if not isfolder(WindowConfig.ConfigFolder) then
            makefolder(WindowConfig.ConfigFolder)
        end
    end

    -- 开场动画
    if WindowConfig.IntroEnabled ~= false then
        local LoadAnimation = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/start_animation.lua"))()
        LoadAnimation:LoadAnimation(2.5, {
            titleText = WindowConfig.Name,
            loadingText = "加载中... ",
            backgroundColor = Color3.new(0.95, 0.92, 1),
            textColor = Theme.TextColor,
            language = "zh",
            onComplete = function() end,
            showCancelButton = true
        })
        task.wait(2.5)
    end

    -- 创建 GUI
    local Gui = Instance.new("ScreenGui")
    Gui.Name = "ChronixUI"
    Gui.ResetOnSpawn = false
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if syn then
        syn.protect_gui(Gui)
        Gui.Parent = game.CoreGui
    else
        Gui.Parent = gethui() or game.CoreGui
    end
    ChronixUI.Gui = Gui

    -- 毛玻璃背景效果
    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Size = 8
    blurEffect.Parent = Gui

    -- 主窗口（毛玻璃效果）
    local MainWindow = Create("Frame", {
        BackgroundColor3 = Theme.GlassBg,
        BackgroundTransparency = Theme.GlassTransparency,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -307, 0.5, -172),
        Size = UDim2.new(0, 615, 0, 344),
        ClipsDescendants = true,
        Parent = Gui
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Create("UIStroke", { Color = Theme.AccentColor, Thickness = 1, Transparency = 0.5 })
    })

    -- 标题栏
    local TopBar = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50),
        Parent = MainWindow
    })

    -- 窗口标题
    local WindowName = Create("TextLabel", {
        Text = WindowConfig.Name,
        TextColor3 = Theme.TextColor,
        TextSize = Theme.TitleSize,
        Font = Theme.FontBold,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 25, 0, -24),
        Size = UDim2.new(1, -30, 2, 0),
        Parent = TopBar
    })

    -- 标题栏线条
    local TitleLine = Create("Frame", {
        BackgroundColor3 = Theme.AccentColor,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundTransparency = 0.5,
        Parent = TopBar
    })

    -- 按钮容器
    local ButtonContainer = Create("RoundFrame", Theme.SidebarBg, 0, 7, {
        Size = UDim2.new(0, 70, 0, 30),
        Position = UDim2.new(1, -90, 0, 10),
        Parent = TopBar
    }, {
        Create("UIStroke", { Color = Theme.AccentColor, Thickness = 1, Transparency = 0.5 }),
        Create("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundColor3 = Theme.AccentColor, BackgroundTransparency = 0.5 })
    })

    -- 关闭按钮
    local CloseBtn = Create("TextButton", {
        Text = "×",
        TextColor3 = Theme.TextColor,
        TextSize = 20,
        Font = Theme.FontBold,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Parent = ButtonContainer
    })

    -- 最小化按钮
    local MinimizeBtn = Create("TextButton", {
        Text = "−",
        TextColor3 = Theme.TextColor,
        TextSize = 20,
        Font = Theme.FontBold,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = ButtonContainer
    })

    -- 拖拽区域
    local DragPoint = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50),
        Parent = MainWindow
    })

    -- 左侧栏（不透明）
    local Sidebar = Create("RoundFrame", Theme.SidebarBg, 0, 0, {
        Size = UDim2.new(0, Theme.SidebarWidth, 1, -50),
        Position = UDim2.new(0, 0, 0, 50),
        Parent = MainWindow
    }, {
        Create("UIStroke", { Color = Theme.AccentColor, Thickness = 1, Transparency = 0.5 })
    })

    -- 左侧栏滚动容器
    local TabHolder = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -50),
        Position = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.AccentColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = Sidebar
    })

    local TabList = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = TabHolder
    })

    AddConnection(TabList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabList.AbsoluteContentSize.Y + 10)
    end)

    -- 底部用户信息栏
    local BottomBar = Create("Frame", {
        BackgroundColor3 = Theme.SidebarBg,
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 1, -50),
        Parent = Sidebar
    }, {
        Create("UIStroke", { Color = Theme.AccentColor, Thickness = 1, Transparency = 0.5, Position = Enum.UIStrokePosition.Inside })
    })

    -- 玩家头像
    local AvatarFrame = Create("Frame", {
        BackgroundColor3 = Theme.AccentColor,
        BackgroundTransparency = 0.3,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 10, 0.5, -16),
        AnchorPoint = Vector2.new(0, 0.5),
        Parent = BottomBar
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    local AvatarImage = Create("ImageLabel", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundTransparency = 1,
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png",
        Parent = AvatarFrame
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    -- 玩家名（Premium 高亮）
    local PlayerNameLabel = Create("TextLabel", {
        Text = LocalPlayer.DisplayName,
        TextColor3 = isPremium() and Theme.PremiumColor or Theme.TextColor,
        TextSize = Theme.SidebarTextSize,
        Font = Theme.FontBold,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0.5, -10),
        Size = UDim2.new(0.6, 0, 0, 20),
        Parent = BottomBar
    })

    -- Premium 标识
    if isPremium() then
        local PremiumIcon = Create("TextLabel", {
            Text = "⭐",
            TextColor3 = Theme.PremiumColor,
            TextSize = 14,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 50, 0.5, 8),
            Size = UDim2.new(0, 20, 0, 20),
            Parent = BottomBar
        })
    end

    -- 右侧内容区域
    local ContentArea = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -Theme.SidebarWidth, 1, -50),
        Position = UDim2.new(0, Theme.SidebarWidth, 0, 50),
        Parent = MainWindow
    })

    local ContentScroller = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.AccentColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = ContentArea
    })

    local ContentLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ContentScroller
    })

    local function updateCanvas()
        task.wait()
        ContentScroller.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
    end
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

    MakeDraggable(DragPoint, MainWindow)

    -- 窗口状态
    local isMinimized = false

    -- 关闭按钮功能
    AddConnection(CloseBtn.MouseButton1Up, function()
        MainWindow.Visible = false
        WindowConfig.CloseCallback()
    end)

    -- 最小化功能
    AddConnection(MinimizeBtn.MouseButton1Up, function()
        if isMinimized then
            TweenService:Create(MainWindow, TweenInfo.new(0.3), { Size = UDim2.new(0, 615, 0, 344) }):Play()
            MinimizeBtn.Text = "−"
            wait(0.05)
            MainWindow.ClipsDescendants = false
            Sidebar.Visible = true
            ContentArea.Visible = true
        else
            MainWindow.ClipsDescendants = true
            MinimizeBtn.Text = "□"
            TweenService:Create(MainWindow, TweenInfo.new(0.3), { Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50) }):Play()
            wait(0.1)
            Sidebar.Visible = false
            ContentArea.Visible = false
        end
        isMinimized = not isMinimized
    end)

    -- 隐藏/显示快捷键 (RightShift)
    local hideConnection
    hideConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == windowHideKey then
            if MainWindow.Visible then
                MainWindow.Visible = false
                UIHidden = true
            else
                MainWindow.Visible = true
                UIHidden = false
            end
        end
    end)

    -- 标签页创建函数
    local TabFunction = {}
    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "Tab"

        local TabBtn = Create("TextButton", {
            Text = TabConfig.Name,
            TextColor3 = Theme.TextSecondary,
            TextSize = Theme.SidebarTextSize,
            Font = Theme.Font,
            BackgroundColor3 = Theme.SidebarBg,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -10, 0, 40),
            Position = UDim2.new(0, 5, 0, 0),
            Parent = TabHolder
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) })
        })

        local Container = Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -150, 1, -50),
            Position = UDim2.new(0, 150, 0, 50),
            Parent = MainWindow,
            Visible = false,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.AccentColor,
            CanvasSize = UDim2.new(0, 0, 0, 0)
        }, {
            Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
            Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15) })
        })

        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
        end)

        if FirstTab then
            FirstTab = false
            TabBtn.TextColor3 = Theme.TextColor
            TabBtn.BackgroundColor3 = Theme.SidebarActive
            Container.Visible = true
        end

        AddConnection(TabBtn.MouseButton1Click, function()
            for _, child in pairs(TabHolder:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = Theme.TextSecondary
                    child.BackgroundColor3 = Theme.SidebarBg
                end
            end
            for _, cont in pairs(MainWindow:GetChildren()) do
                if cont:IsA("ScrollingFrame") and cont ~= ContentScroller and cont ~= TabHolder then
                    cont.Visible = false
                end
            end
            TabBtn.TextColor3 = Theme.TextColor
            TabBtn.BackgroundColor3 = Theme.SidebarActive
            Container.Visible = true
        end)

        -- 控件创建函数
        local function GetElements(ItemParent)
            local ElementFunction = {}

            function ElementFunction:AddSection(SectionConfig)
                local sectionName = type(SectionConfig) == "table" and SectionConfig.Name or SectionConfig or "Section"

                local SectionFrame = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 26),
                    Parent = ItemParent
                })

                local SectionTitle = Create("TextLabel", {
                    Text = sectionName,
                    TextColor3 = Theme.AccentColor,
                    TextSize = 14,
                    Font = Theme.FontBold,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 3),
                    Size = UDim2.new(1, -12, 0, 16),
                    Parent = SectionFrame
                })

                local SectionHolder = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, -24),
                    Position = UDim2.new(0, 0, 0, 23),
                    Parent = SectionFrame
                }, {
                    Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
                })

                local function updateSectionHeight()
                    task.wait()
                    SectionFrame.Size = UDim2.new(1, 0, 0, SectionHolder.UIListLayout.AbsoluteContentSize.Y + 31)
                    SectionHolder.Size = UDim2.new(1, 0, 0, SectionHolder.UIListLayout.AbsoluteContentSize.Y)
                end
                SectionHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSectionHeight)
                updateSectionHeight()

                local SectionFunction = {}
                for i, v in next, GetElements(SectionHolder) do
                    SectionFunction[i] = v
                end
                return SectionFunction
            end

            function ElementFunction:AddLabel(Text)
                return Create("TextLabel", {
                    Text = Text,
                    TextColor3 = Theme.TextSecondary,
                    TextSize = Theme.TextSize - 2,
                    Font = Theme.Font,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = ItemParent
                })
            end

            function ElementFunction:AddButton(ButtonConfig)
                ButtonConfig = ButtonConfig or {}
                local btn = Create("TextButton", {
                    Text = ButtonConfig.Name or "Button",
                    TextColor3 = Theme.TextColor,
                    TextSize = Theme.TextSize,
                    Font = Theme.Font,
                    BackgroundColor3 = Theme.SidebarBg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 33),
                    Parent = ItemParent
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) })
                })

                btn.MouseEnter:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.SidebarHover }):Play()
                end)
                btn.MouseLeave:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.SidebarBg }):Play()
                end)
                btn.MouseButton1Click:Connect(function()
                    if ButtonConfig.Callback then ButtonConfig.Callback() end
                end)

                return btn
            end

            function ElementFunction:AddToggle(ToggleConfig)
                ToggleConfig = ToggleConfig or {}
                local toggled = ToggleConfig.Default or false

                local container = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ItemParent
                })

                local label = Create("TextLabel", {
                    Text = ToggleConfig.Name or "Toggle",
                    TextColor3 = Theme.TextColor,
                    TextSize = Theme.TextSize,
                    Font = Theme.Font,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(1, -70, 1, 0),
                    Parent = container
                })

                local toggleBtn = Create("TextButton", {
                    Text = toggled and "ON" or "OFF",
                    TextColor3 = Theme.TextColor,
                    TextSize = Theme.TextSize - 2,
                    Font = Theme.FontBold,
                    BackgroundColor3 = toggled and Theme.AccentColor or Theme.SidebarBg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 50, 0, 28),
                    Position = UDim2.new(1, -60, 0.5, -14),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = container
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 14) })
                })

                local function update(value)
                    toggled = value
                    toggleBtn.Text = toggled and "ON" or "OFF"
                    toggleBtn.BackgroundColor3 = toggled and Theme.AccentColor or Theme.SidebarBg
                    if ToggleConfig.Callback then ToggleConfig.Callback(toggled) end
                    if ToggleConfig.Flag then ChronixUI.Flags[ToggleConfig.Flag] = { Value = toggled, Save = ToggleConfig.Save, Type = "Toggle", Set = update } end
                end

                toggleBtn.MouseButton1Click:Connect(function() update(not toggled) end)

                return { Set = update, Get = function() return toggled end }
            end

            function ElementFunction:AddSlider(SliderConfig)
                SliderConfig = SliderConfig or {}
                local min = SliderConfig.Min or 0
                local max = SliderConfig.Max or 100
                local value = SliderConfig.Default or min

                local container = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 65),
                    Parent = ItemParent
                })

                local label = Create("TextLabel", {
                    Text = SliderConfig.Name or "Slider",
                    TextColor3 = Theme.TextColor,
                    TextSize = Theme.TextSize,
                    Font = Theme.Font,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 10),
                    Size = UDim2.new(1, -24, 0, 20),
                    Parent = container
                })

                local valueLabel = Create("TextLabel", {
                    Text = tostring(value),
                    TextColor3 = Theme.AccentColor,
                    TextSize = Theme.TextSize,
                    Font = Theme.FontBold,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -60, 0, 10),
                    Size = UDim2.new(0, 50, 0, 20),
                    Parent = container
                })

                local track = Create("Frame", {
                    BackgroundColor3 = Theme.SidebarBg,
                    Size = UDim2.new(1, -24, 0, 4),
                    Position = UDim2.new(0, 12, 0, 40),
                    BorderSizePixel = 0,
                    Parent = container
                }, { Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

                local fill = Create("Frame", {
                    BackgroundColor3 = Theme.AccentColor,
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    BorderSizePixel = 0,
                    Parent = track
                }, { Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

                local thumb = Create("TextButton", {
                    Text = "",
                    BackgroundColor3 = Theme.TextColor,
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new((value - min) / (max - min), -8, 0, -6),
                    BorderSizePixel = 0,
                    Parent = container
                }, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })

                local dragging = false

                local function update(val)
                    value = math.clamp(val, min, max)
                    local percent = (value - min) / (max - min)
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    thumb.Position = UDim2.new(percent, -8, 0, -6)
                    valueLabel.Text = tostring(math.floor(value))
                    if SliderConfig.Callback then SliderConfig.Callback(value) end
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

                return { Set = update, Get = function() return value end }
            end

            function ElementFunction:AddDropdown(DropdownConfig)
                DropdownConfig = DropdownConfig or {}
                local options = DropdownConfig.Options or {}
                local selected = DropdownConfig.Default or options[1]
                local isOpen = false

                local container = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ItemParent
                })

                local label = Create("TextLabel", {
                    Text = DropdownConfig.Name or "Dropdown",
                    TextColor3 = Theme.TextColor,
                    TextSize = Theme.TextSize,
                    Font = Theme.Font,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(0.4, 0, 1, 0),
                    Parent = container
                })

                local dropdownBtn = Create("TextButton", {
                    Text = selected,
                    TextColor3 = Theme.TextColor,
                    TextSize = Theme.TextSize,
                    Font = Theme.Font,
                    BackgroundColor3 = Theme.SidebarBg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0.6, -25, 0, 28),
                    Position = UDim2.new(0.4, 5, 0.5, -14),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = container
                }, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })

                local dropdownList = nil

                local function closeList()
                    if dropdownList then
                        TweenService:Create(dropdownList, TweenInfo.new(0.2), { Size = UDim2.new(0.6, -25, 0, 0) }):Play()
                        task.wait(0.2)
                        dropdownList:Destroy()
                        dropdownList = nil
                    end
                    isOpen = false
                end

                dropdownBtn.MouseButton1Click:Connect(function()
                    if isOpen then closeList() return end
                    isOpen = true

                    dropdownList = Create("ScrollingFrame", {
                        BackgroundColor3 = Theme.SidebarBg,
                        Size = UDim2.new(0.6, -25, 0, 0),
                        Position = UDim2.new(0.4, 5, 0, 38),
                        ScrollBarThickness = 4,
                        ClipsDescendants = true,
                        Parent = container
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                        Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
                    })

                    local totalHeight = 0
                    for _, opt in ipairs(options) do
                        local optBtn = Create("TextButton", {
                            Text = opt,
                            TextColor3 = Theme.TextSecondary,
                            TextSize = Theme.TextSize,
                            Font = Theme.Font,
                            BackgroundColor3 = Theme.SidebarBg,
                            Size = UDim2.new(1, 0, 0, 32),
                            Parent = dropdownList
                        })
                        optBtn.MouseEnter:Connect(function()
                            optBtn.BackgroundColor3 = Theme.SidebarHover
                            optBtn.TextColor3 = Theme.TextColor
                        end)
                        optBtn.MouseLeave:Connect(function()
                            optBtn.BackgroundColor3 = Theme.SidebarBg
                            optBtn.TextColor3 = Theme.TextSecondary
                        end)
                        optBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            dropdownBtn.Text = selected
                            if DropdownConfig.Callback then DropdownConfig.Callback(selected) end
                            closeList()
                        end)
                        totalHeight = totalHeight + 34
                    end

                    local maxHeight = math.min(totalHeight, 200)
                    dropdownList.Size = UDim2.new(0.6, -25, 0, maxHeight)
                    dropdownList.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

                    local clickConn = UserInputService.InputBegan:Connect(function(input)
                        if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
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

                return { Set = function(val) selected = val; dropdownBtn.Text = val end, Get = function() return selected end }
            end

            function ElementFunction:AddTextbox(TextboxConfig)
                TextboxConfig = TextboxConfig or {}
                local container = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ItemParent
                })

                local label = Create("TextLabel", {
                    Text = TextboxConfig.Name or "Input",
                    TextColor3 = Theme.TextColor,
                    TextSize = Theme.TextSize,
                    Font = Theme.Font,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(0.4, 0, 1, 0),
                    Parent = container
                })

                local input = Create("TextBox", {
                    Text = TextboxConfig.Default or "",
                    PlaceholderText = TextboxConfig.Placeholder or "",
                    TextColor3 = Theme.TextColor,
                    TextSize = Theme.TextSize,
                    Font = Theme.Font,
                    BackgroundColor3 = Theme.SidebarBg,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0.6, -25, 0, 28),
                    Position = UDim2.new(0.4, 5, 0.5, -14),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = container
                }, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })

                input.FocusLost:Connect(function()
                    if TextboxConfig.Callback then TextboxConfig.Callback(input.Text) end
                end)

                return input
            end

            return ElementFunction
        end

        local ElementFunction = {}
        for i, v in next, GetElements(Container) do
            ElementFunction[i] = v
        end

        return ElementFunction
    end

    return TabFunction
end

function ChronixUI:IsRunning()
    return self.Gui and self.Gui.Parent ~= nil
end

function ChronixUI:Destroy()
    if self.Gui then
        self.Gui:Destroy()
    end
    for _, Connection in next, self.Connections do
        Connection:Disconnect()
    end
    self.Connections = {}
end

return ChronixUI