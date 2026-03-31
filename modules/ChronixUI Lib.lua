-- ChronixUI
-- 基于 OrionLib 架构重写，保留 ChronixHub 墨蓝色主题
-- 完全兼容手机/电脑

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

local ChronixUI = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(30, 30, 46),      -- 墨蓝色主背景
            Second = Color3.fromRGB(40, 40, 56),    -- 深墨蓝次背景
            Stroke = Color3.fromRGB(80, 80, 110),   -- 边框色
            Divider = Color3.fromRGB(60, 60, 90),   -- 分割线色
            Text = Color3.fromRGB(100, 100, 180),   -- 强调文字色
            TextDark = Color3.fromRGB(200, 200, 220) -- 普通文字色
        }
    },
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false
}

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

-- ============ 基础元素创建 ============

CreateElement("Corner", function(Scale, Offset)
    return Create("UICorner", { CornerRadius = UDim.new(Scale or 0, Offset or 10) })
end)

CreateElement("Stroke", function(Color, Thickness)
    return Create("UIStroke", { Color = Color or Color3.fromRGB(255, 255, 255), Thickness = Thickness or 1 })
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

CreateElement("Label", function(Text, TextSize, Transparency)
    return Create("TextLabel", {
        Text = Text or "",
        TextColor3 = ChronixUI.Themes[ChronixUI.SelectedTheme].TextDark,
        TextTransparency = Transparency or 0,
        TextSize = TextSize or 15,
        Font = Enum.Font.Gotham,
        RichText = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end)

-- ============ 通知系统 ============

local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
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
    Parent = nil
})

function ChronixUI:MakeNotification(NotificationConfig)
    spawn(function()
        NotificationConfig.Name = NotificationConfig.Name or "Notification"
        NotificationConfig.Content = NotificationConfig.Content or "Test"
        NotificationConfig.Image = NotificationConfig.Image or "rbxassetid://4384403532"
        NotificationConfig.Time = NotificationConfig.Time or 5

        if not NotificationHolder.Parent then
            NotificationHolder.Parent = self.Gui
        end

        local NotificationParent = SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = NotificationHolder
        })

        local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25, 25, 25), 0, 10), {
            Parent = NotificationParent,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(1, -55, 0, 0),
            BackgroundTransparency = 0,
            AutomaticSize = Enum.AutomaticSize.Y
        }), {
            MakeElement("Stroke", Color3.fromRGB(93, 93, 93), 1.2),
            MakeElement("Padding", 12, 12, 12, 12),
            SetProps(MakeElement("Image", NotificationConfig.Image), {
                Size = UDim2.new(0, 20, 0, 20),
                ImageColor3 = Color3.fromRGB(240, 240, 240),
                Name = "Icon"
            }),
            SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
                Size = UDim2.new(1, -30, 0, 20),
                Position = UDim2.new(0, 30, 0, 0),
                Font = Enum.Font.GothamBold,
                Name = "Title"
            }),
            SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 25),
                Font = Enum.Font.GothamSemibold,
                Name = "Content",
                AutomaticSize = Enum.AutomaticSize.Y,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextWrapped = true
            })
        })

        TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        wait(NotificationConfig.Time - 0.88)
        TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { ImageTransparency = 1 }):Play()
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

-- ============ 主窗口 ============

function ChronixUI:MakeWindow(WindowConfig)
    local FirstTab = true
    local Minimized = false
    local UIHidden = false

    WindowConfig = WindowConfig or {}
    WindowConfig.Name = WindowConfig.Name or "ChronixHub"
    WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
    WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
    if WindowConfig.IntroEnabled == nil then
        WindowConfig.IntroEnabled = true
    end
    WindowConfig.IntroText = WindowConfig.IntroText or WindowConfig.Name
    WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
    WindowConfig.ShowIcon = WindowConfig.ShowIcon or true
    WindowConfig.Icon = WindowConfig.Icon or "rbxassetid://8834748103"
    WindowConfig.IntroIcon = WindowConfig.IntroIcon or "rbxassetid://8834748103"

    ChronixUI.Folder = WindowConfig.ConfigFolder
    ChronixUI.SaveCfg = WindowConfig.SaveConfig

    if WindowConfig.SaveConfig then
        if not isfolder(WindowConfig.ConfigFolder) then
            makefolder(WindowConfig.ConfigFolder)
        end
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
    NotificationHolder.Parent = Gui

    -- 标签页列表容器
    local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Stroke, 4), {
        Size = UDim2.new(1, 0, 1, -50)
    }), {
        MakeElement("List"),
        MakeElement("Padding", 8, 0, 0, 8)
    }), "Divider")

    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
    end)

    -- 关闭按钮
    local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
            Position = UDim2.new(0, 9, 0, 6),
            Size = UDim2.new(0, 18, 0, 18)
        }), "Text")
    })

    -- 最小化按钮
    local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
            Position = UDim2.new(0, 9, 0, 6),
            Size = UDim2.new(0, 18, 0, 18),
            Name = "Ico"
        }), "Text")
    })

    -- 拖拽区域
    local DragPoint = SetProps(MakeElement("TFrame"), {
        Size = UDim2.new(1, 0, 0, 50)
    })

    -- 左侧功能栏
    local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Main, 0, 10), {
        Size = UDim2.new(0, 150, 1, -50),
        Position = UDim2.new(0, 0, 0, 50)
    }), {
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(1, 0, 0, 10),
            Position = UDim2.new(0, 0, 0, 0)
        }), "Second"),
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(0, 10, 1, 0),
            Position = UDim2.new(1, -10, 0, 0)
        }), "Second"),
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, -1, 0, 0)
        }), "Stroke"),
        TabHolder,
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 50),
            Position = UDim2.new(0, 0, 1, -50)
        }), {
            AddThemeObject(SetProps(MakeElement("Frame"), {
                Size = UDim2.new(1, 0, 0, 1)
            }), "Stroke"),
            AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0, 10, 0.5, 0)
            }), {
                SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png"), {
                    Size = UDim2.new(1, 0, 1, 0)
                }),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {
                    Size = UDim2.new(1, 0, 1, 0),
                }), "Second"),
                MakeElement("Corner", 1)
            }), "Divider"),
            SetChildren(SetProps(MakeElement("TFrame"), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0, 10, 0.5, 0)
            }), {
                AddThemeObject(MakeElement("Stroke"), "Stroke"),
                MakeElement("Corner", 1)
            }),
            AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, 13), {
                Size = UDim2.new(1, -60, 0, 13),
                Position = UDim2.new(0, 50, 0, 12),
                Font = Enum.Font.GothamBold,
                ClipsDescendants = true
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", "", 12), {
                Size = UDim2.new(1, -60, 0, 12),
                Position = UDim2.new(0, 50, 1, -25)
            }), "TextDark")
        }),
    }), "Second")

    -- 窗口标题
    local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
        Size = UDim2.new(1, -30, 2, 0),
        Position = UDim2.new(0, 25, 0, -24),
        Font = Enum.Font.GothamBlack,
        TextSize = 20
    }), "Text")

    local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1)
    }), "Stroke")

    -- 主窗口
    local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Main, 0, 10), {
        Parent = Gui,
        Position = UDim2.new(0.5, -307, 0.5, -172),
        Size = UDim2.new(0, 615, 0, 344),
        ClipsDescendants = true,
        Active = true,
        Draggable = true
    }), {
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 50),
            Name = "TopBar"
        }), {
            WindowName,
            WindowTopBarLine,
            AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Second, 0, 7), {
                Size = UDim2.new(0, 70, 0, 30),
                Position = UDim2.new(1, -90, 0, 10)
            }), {
                AddThemeObject(MakeElement("Stroke"), "Stroke"),
                AddThemeObject(SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(0, 1, 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0)
                }), "Stroke"),
                CloseBtn,
                MinimizeBtn
            }), "Second"),
        }),
        DragPoint,
        WindowStuff
    }), "Main")

    if WindowConfig.ShowIcon then
        WindowName.Position = UDim2.new(0, 50, 0, -24)
        local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 25, 0, 15)
        })
        WindowIcon.Parent = MainWindow.TopBar
    end

    MakeDraggable(DragPoint, MainWindow)

    AddConnection(CloseBtn.MouseButton1Up, function()
        MainWindow.Visible = false
        UIHidden = true
        WindowConfig.CloseCallback()
    end)

    AddConnection(UserInputService.InputBegan, function(Input)
        if Input.KeyCode == Enum.KeyCode.RightShift and UIHidden then
            MainWindow.Visible = true
        end
    end)

    AddConnection(MinimizeBtn.MouseButton1Up, function()
        if Minimized then
            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(0, 615, 0, 344) }):Play()
            MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
            wait(0.02)
            MainWindow.ClipsDescendants = false
            WindowStuff.Visible = true
            WindowTopBarLine.Visible = true
        else
            MainWindow.ClipsDescendants = true
            WindowTopBarLine.Visible = false
            MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50) }):Play()
            wait(0.1)
            WindowStuff.Visible = false
        end
        Minimized = not Minimized
    end)

    -- 开场动画
    local function LoadSequence()
        MainWindow.Visible = false
        local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
            Parent = Gui,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.4, 0),
            Size = UDim2.new(0, 28, 0, 28),
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 1
        })

        local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 14), {
            Parent = Gui,
            Size = UDim2.new(1, 0, 1, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 19, 0.5, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.GothamBold,
            TextTransparency = 1
        })

        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
        wait(0.8)
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X / 2), 0.5, 0) }):Play()
        wait(0.3)
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
        wait(2)
        TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 }):Play()
        MainWindow.Visible = true
        LoadSequenceLogo:Destroy()
        LoadSequenceText:Destroy()
    end

    if WindowConfig.IntroEnabled then
        LoadSequence()
    end

    -- 标签页创建函数
    local TabFunction = {}
    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "Tab"
        TabConfig.Icon = TabConfig.Icon or ""

        local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
            Size = UDim2.new(1, 0, 0, 30),
            Parent = TabHolder
        }), {
            AddThemeObject(SetProps(MakeElement("Image", TabConfig.Icon), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 10, 0.5, 0),
                ImageTransparency = 0.4,
                Name = "Ico"
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
                Size = UDim2.new(1, -35, 1, 0),
                Position = UDim2.new(0, 35, 0, 0),
                Font = Enum.Font.GothamSemibold,
                TextTransparency = 0.4,
                Name = "Title"
            }), "Text")
        })

        local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Stroke, 5), {
            Size = UDim2.new(1, -150, 1, -50),
            Position = UDim2.new(0, 150, 0, 50),
            Parent = MainWindow,
            Visible = false,
            Name = "ItemContainer"
        }), {
            MakeElement("List", 0, 6),
            MakeElement("Padding", 15, 10, 10, 15)
        }), "Divider")

        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
        end)

        if FirstTab then
            FirstTab = false
            TabFrame.Ico.ImageTransparency = 0
            TabFrame.Title.TextTransparency = 0
            TabFrame.Title.Font = Enum.Font.GothamBlack
            Container.Visible = true
        end

        AddConnection(TabFrame.MouseButton1Click, function()
            for _, Tab in next, TabHolder:GetChildren() do
                if Tab:IsA("TextButton") then
                    Tab.Title.Font = Enum.Font.GothamSemibold
                    TweenService:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 0.4 }):Play()
                    TweenService:Create(Tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0.4 }):Play()
                end
            end
            for _, ItemContainer in next, MainWindow:GetChildren() do
                if ItemContainer.Name == "ItemContainer" then
                    ItemContainer.Visible = false
                end
            end
            TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 0 }):Play()
            TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
            TabFrame.Title.Font = Enum.Font.GothamBlack
            Container.Visible = true
        end)

        -- 控件创建函数
        local function GetElements(ItemParent)
            local ElementFunction = {}

            function ElementFunction:AddLabel(Text)
                local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Second, 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.7,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")

                local LabelFunction = {}
                function LabelFunction:Set(ToChange)
                    LabelFrame.Content.Text = ToChange
                end
                return LabelFunction
            end

            function ElementFunction:AddButton(ButtonConfig)
                ButtonConfig = ButtonConfig or {}
                ButtonConfig.Name = ButtonConfig.Name or "Button"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end
                ButtonConfig.Icon = ButtonConfig.Icon or "rbxassetid://3944703587"

                local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })

                local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Second, 0, 5), {
                    Size = UDim2.new(1, 0, 0, 33),
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(SetProps(MakeElement("Image", ButtonConfig.Icon), {
                        Size = UDim2.new(0, 20, 0, 20),
                        Position = UDim2.new(1, -30, 0, 7),
                    }), "TextDark"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    Click
                }), "Second")

                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(ChronixUI.Themes[ChronixUI.SelectedTheme].Second.R * 255 + 3, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.G * 255 + 3, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.B * 255 + 3) }):Play()
                end)

                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = ChronixUI.Themes[ChronixUI.SelectedTheme].Second }):Play()
                end)

                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(ChronixUI.Themes[ChronixUI.SelectedTheme].Second.R * 255 + 3, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.G * 255 + 3, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.B * 255 + 3) }):Play()
                    spawn(function() ButtonConfig.Callback() end)
                end)

                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(ChronixUI.Themes[ChronixUI.SelectedTheme].Second.R * 255 + 6, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.G * 255 + 6, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.B * 255 + 6) }):Play()
                end)

                return ButtonFrame
            end

            function ElementFunction:AddToggle(ToggleConfig)
                ToggleConfig = ToggleConfig or {}
                ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Callback = ToggleConfig.Callback or function() end
                ToggleConfig.Color = ToggleConfig.Color or ChronixUI.Themes[ChronixUI.SelectedTheme].Text
                ToggleConfig.Flag = ToggleConfig.Flag or nil
                ToggleConfig.Save = ToggleConfig.Save or false

                local Toggle = { Value = ToggleConfig.Default, Save = ToggleConfig.Save }
                local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })

                local ToggleBox = SetChildren(SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 0, 4), {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -24, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5)
                }), {
                    SetProps(MakeElement("Stroke"), { Color = ToggleConfig.Color, Name = "Stroke", Transparency = 0.5 }),
                    SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
                        Size = UDim2.new(0, 20, 0, 20),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                        Name = "Ico"
                    }),
                })

                local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Second, 0, 5), {
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    ToggleBox,
                    Click
                }), "Second")

                function Toggle:Set(Value)
                    Toggle.Value = Value
                    TweenService:Create(ToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = Toggle.Value and ToggleConfig.Color or ChronixUI.Themes.Default.Divider }):Play()
                    TweenService:Create(ToggleBox.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Color = Toggle.Value and ToggleConfig.Color or ChronixUI.Themes.Default.Stroke }):Play()
                    TweenService:Create(ToggleBox.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = Toggle.Value and 0 or 1, Size = Toggle.Value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8) }):Play()
                    ToggleConfig.Callback(Toggle.Value)
                end

                Toggle:Set(Toggle.Value)

                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(ChronixUI.Themes[ChronixUI.SelectedTheme].Second.R * 255 + 3, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.G * 255 + 3, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.B * 255 + 3) }):Play()
                end)

                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = ChronixUI.Themes[ChronixUI.SelectedTheme].Second }):Play()
                end)

                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(ChronixUI.Themes[ChronixUI.SelectedTheme].Second.R * 255 + 3, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.G * 255 + 3, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.B * 255 + 3) }):Play()
                    Toggle:Set(not Toggle.Value)
                end)

                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(ChronixUI.Themes[ChronixUI.SelectedTheme].Second.R * 255 + 6, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.G * 255 + 6, ChronixUI.Themes[ChronixUI.SelectedTheme].Second.B * 255 + 6) }):Play()
                end)

                if ToggleConfig.Flag then
                    ChronixUI.Flags[ToggleConfig.Flag] = Toggle
                end
                return Toggle
            end

            function ElementFunction:AddSlider(SliderConfig)
                SliderConfig = SliderConfig or {}
                SliderConfig.Name = SliderConfig.Name or "Slider"
                SliderConfig.Min = SliderConfig.Min or 0
                SliderConfig.Max = SliderConfig.Max or 100
                SliderConfig.Increment = SliderConfig.Increment or 1
                SliderConfig.Default = SliderConfig.Default or 50
                SliderConfig.Callback = SliderConfig.Callback or function() end
                SliderConfig.ValueName = SliderConfig.ValueName or ""
                SliderConfig.Color = SliderConfig.Color or ChronixUI.Themes[ChronixUI.SelectedTheme].Text
                SliderConfig.Flag = SliderConfig.Flag or nil
                SliderConfig.Save = SliderConfig.Save or false

                local Slider = { Value = SliderConfig.Default, Save = SliderConfig.Save }
                local Dragging = false

                local function Round(Number, Factor)
                    local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
                    if Result < 0 then Result = Result + Factor end
                    return Result
                end

                local SliderDrag = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundTransparency = 0.3,
                    ClipsDescendants = true
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 12, 0, 6),
                        Font = Enum.Font.GothamBold,
                        Name = "Value",
                        TextTransparency = 0
                    }), "Text")
                })

                local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
                    Size = UDim2.new(1, -24, 0, 26),
                    Position = UDim2.new(0, 12, 0, 30),
                    BackgroundTransparency = 0.9
                }), {
                    SetProps(MakeElement("Stroke"), { Color = SliderConfig.Color }),
                    AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 12, 0, 6),
                        Font = Enum.Font.GothamBold,
                        Name = "Value",
                        TextTransparency = 0.8
                    }), "Text"),
                    SliderDrag
                })

                local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Second, 0, 4), {
                    Size = UDim2.new(1, 0, 0, 65),
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 15), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 12, 0, 10),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SliderBar
                }), "Second")

                SliderBar.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = true
                    end
                end)
                SliderBar.InputEnded:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(Input)
                    if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                        local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                        Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale))
                    end
                end)

                function Slider:Set(Value)
                    self.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                    TweenService:Create(SliderDrag, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromScale((self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1) }):Play()
                    SliderBar.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
                    SliderDrag.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
                    SliderConfig.Callback(self.Value)
                end

                Slider:Set(Slider.Value)
                if SliderConfig.Flag then
                    ChronixUI.Flags[SliderConfig.Flag] = Slider
                end
                return Slider
            end

            function ElementFunction:AddDropdown(DropdownConfig)
                DropdownConfig = DropdownConfig or {}
                DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
                DropdownConfig.Options = DropdownConfig.Options or {}
                DropdownConfig.Default = DropdownConfig.Default or ""
                DropdownConfig.Callback = DropdownConfig.Callback or function() end
                DropdownConfig.Flag = DropdownConfig.Flag or nil
                DropdownConfig.Save = DropdownConfig.Save or false

                local Dropdown = { Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = DropdownConfig.Save }
                local MaxElements = 5

                if not table.find(Dropdown.Options, Dropdown.Value) then
                    Dropdown.Value = "..."
                end

                local DropdownList = MakeElement("List")
                local DropdownContainer = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Stroke, 4), {
                    DropdownList
                }), {
                    Parent = ItemParent,
                    Position = UDim2.new(0, 0, 0, 38),
                    Size = UDim2.new(1, 0, 1, -38),
                    ClipsDescendants = true
                }), "Divider")

                local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })

                local DropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", ChronixUI.Themes[ChronixUI.SelectedTheme].Second, 0, 5), {
                    Size = UDim2.new(1, 0, 0, 38),
                    Parent = ItemParent,
                    ClipsDescendants = true
                }), {
                    DropdownContainer,
                    SetProps(SetChildren(MakeElement("TFrame"), {
                        AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 15), {
                            Size = UDim2.new(1, -12, 1, 0),
                            Position = UDim2.new(0, 12, 0, 0),
                            Font = Enum.Font.GothamBold,
                            Name = "Content"
                        }), "Text"),
                        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {
                            Size = UDim2.new(0, 20, 0, 20),
                            AnchorPoint = Vector2.new(0, 0.5),
                            Position = UDim2.new(1, -30, 0.5, 0),
                            ImageColor3 = Color3.fromRGB(240, 240, 240),
                            Name = "Ico"
                        }), "TextDark"),
                        AddThemeObject(SetProps(MakeElement("Label", "Selected", 13), {
                            Size = UDim2.new(1, -40, 1, 0),
                            Font = Enum.Font.Gotham,
                            Name = "Selected",
                            TextXAlignment = Enum.TextXAlignment.Right
                        }), "TextDark"),
                        AddThemeObject(SetProps(MakeElement("Frame"), {
                            Size = UDim2.new(1, 0, 0, 1),
                            Position = UDim2.new(0, 0, 1, -1),
                            Name = "Line",
                            Visible = false
                        }), "Stroke"),
                        Click
                    }), {
                        Size = UDim2.new(1, 0, 0, 38),
                        ClipsDescendants = true,
                        Name = "F"
                    }),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    MakeElement("Corner")
                }), "Second")

                AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                    DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
                end)

                local function AddOptions(Options)
                    for _, Option in pairs(Options) do
                        local OptionBtn = AddThemeObject(SetProps(SetChildren(MakeElement("Button", ChronixUI.Themes[ChronixUI.SelectedTheme].Second), {
                            MakeElement("Corner", 0, 6),
                            AddThemeObject(SetProps(MakeElement("Label", Option, 13, 0.4), {
                                Position = UDim2.new(0, 8, 0, 0),
                                Size = UDim2.new(1, -8, 1, 0),
                                Name = "Title"
                            }), "Text")
                        }), {
                            Parent = DropdownContainer,
                            Size = UDim2.new(1, 0, 0, 28),
                            BackgroundTransparency = 1,
                            ClipsDescendants = true
                        }), "Divider")

                        AddConnection(OptionBtn.MouseButton1Click, function()
                            Dropdown:Set(Option)
                        end)

                        Dropdown.Buttons[Option] = OptionBtn
                    end
                end

                function Dropdown:Refresh(Options, Delete)
                    if Delete then
                        for _, v in pairs(Dropdown.Buttons) do
                            v:Destroy()
                        end
                        table.clear(Dropdown.Options)
                        table.clear(Dropdown.Buttons)
                    end
                    Dropdown.Options = Options
                    AddOptions(Dropdown.Options)
                end

                function Dropdown:Set(Value)
                    if not table.find(Dropdown.Options, Value) then
                        Dropdown.Value = "..."
                        DropdownFrame.F.Selected.Text = Dropdown.Value
                        for _, v in pairs(Dropdown.Buttons) do
                            TweenService:Create(v, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
                            TweenService:Create(v.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0.4 }):Play()
                        end
                        return
                    end

                    Dropdown.Value = Value
                    DropdownFrame.F.Selected.Text = Dropdown.Value

                    for _, v in pairs(Dropdown.Buttons) do
                        TweenService:Create(v, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
                        TweenService:Create(v.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0.4 }):Play()
                    end
                    TweenService:Create(Dropdown.Buttons[Value], TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
                    TweenService:Create(Dropdown.Buttons[Value].Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
                    return DropdownConfig.Callback(Dropdown.Value)
                end

                AddConnection(Click.MouseButton1Click, function()
                    Dropdown.Toggled = not Dropdown.Toggled
                    DropdownFrame.F.Line.Visible = Dropdown.Toggled
                    TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = Dropdown.Toggled and 180 or 0 }):Play()
                    if #Dropdown.Options > MaxElements then
                        TweenService:Create(DropdownFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Dropdown.Toggled and UDim2.new(1, 0, 0, 38 + (MaxElements * 28)) or UDim2.new(1, 0, 0, 38) }):Play()
                    else
                        TweenService:Create(DropdownFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Dropdown.Toggled and UDim2.new(1, 0, 0, DropdownList.AbsoluteContentSize.Y + 38) or UDim2.new(1, 0, 0, 38) }):Play()
                    end
                end)

                Dropdown:Refresh(Dropdown.Options, false)
                Dropdown:Set(Dropdown.Value)
                if DropdownConfig.Flag then
                    ChronixUI.Flags[DropdownConfig.Flag] = Dropdown
                end
                return Dropdown
            end

            function ElementFunction:AddSection(SectionConfig)
                SectionConfig.Name = SectionConfig.Name or "Section"

                local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
                    Size = UDim2.new(1, 0, 0, 26),
                    Parent = Container
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 0, 16),
                        Position = UDim2.new(0, 0, 0, 3),
                        Font = Enum.Font.GothamSemibold
                    }), "TextDark"),
                    SetChildren(SetProps(MakeElement("TFrame"), {
                        AnchorPoint = Vector2.new(0, 0),
                        Size = UDim2.new(1, 0, 1, -24),
                        Position = UDim2.new(0, 0, 0, 23),
                        Name = "Holder"
                    }), {
                        MakeElement("List", 0, 6)
                    }),
                })

                AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                    SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
                    SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
                end)

                local SectionFunction = {}
                for i, v in next, GetElements(SectionFrame.Holder) do
                    SectionFunction[i] = v
                end
                return SectionFunction
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