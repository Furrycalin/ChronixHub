if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- if _G.ChronixHubisLoaded then
--     warn("⛔ ChronixHub Already loaded! Please do not repeat the execution.")
--     return
-- end

-- _G.ChronixHubisLoaded = true

-- local CoreGui = game:GetService("CoreGui")
-- local UserInputService = game:GetService("UserInputService")
-- local TweenService = game:GetService("TweenService")
-- local Players = game:GetService("Players")
-- local LocalPlayer = Players.LocalPlayer
-- local RunService = game:GetService("RunService")
-- local TweenService = game:GetService("TweenService")
-- local SoundService = game:GetService("SoundService")
-- local Lighting = game:GetService("Lighting")
-- local MarketplaceService = game:GetService("MarketplaceService")
-- local Workspace = game:GetService("Workspace")
-- local player = Players.LocalPlayer
-- local character = player.Character or player.CharacterAdded:Wait()
-- local humanoid = character:WaitForChild("Humanoid")
-- local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
-- local VirtualInputManager = game:GetService("VirtualInputManager")
-- local StarterGui = game:GetService("StarterGui")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local TextChatService = game:GetService("TextChatService")
-- local HttpService = game:GetService("HttpService")

local ChronixUI = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/ChronixUI%20Lib.lua"))()

-- ============ 创建主窗口 ============
local mainWindow = ChronixUI:CreateWindow({
    Title = "ChronixHub V3",
    ShowIntro = true,           -- 是否显示开场动画
    IntroText = "ChronixHub V3", -- 开场动画文字
    IntroDuration = 2.5,        -- 开场动画时长
    CloseCallback = function()   -- 关闭窗口时的回调
        print("窗口已关闭")
    end
})

-- ============ 自动创建设置标签页（包含快捷键设置） ============
mainWindow:CreateSettingsTab()

-- ============ 创建功能标签页 ============

-- 标签页1：玩家功能
local playerTab = mainWindow:CreateTab({Name = "玩家", Icon = "👤"})

-- 标签页2：世界功能
local worldTab = mainWindow:CreateTab({Name = "世界", Icon = "🌍"})

-- 标签页3：杂项功能
local miscTab = mainWindow:CreateTab({Name = "杂项", Icon = "🔧"})

-- ============================================================
-- 玩家标签页 - 所有控件示例
-- ============================================================

-- 分区1：视觉功能
local visualSection = playerTab:CreateSection("视觉功能")

-- 1. 开关 (Toggle)
local espToggle = playerTab:AddToggle({
    Parent = visualSection,
    Name = "玩家透视",
    Default = false,
    Flag = "PlayerESP",
    Callback = function(value)
        print("[玩家透视] 状态:", value)
        if value then
            -- 这里写开启透视的代码
        else
            -- 这里写关闭透视的代码
        end
    end
})

-- 2. 颜色选择器 (Colorpicker)
local espColor = playerTab:AddColorpicker({
    Parent = visualSection,
    Name = "透视颜色",
    Default = Color3.fromRGB(100, 100, 180),
    Flag = "ESPColor",
    Callback = function(color)
        print("[透视颜色] R:", color.R * 255, "G:", color.G * 255, "B:", color.B * 255)
        -- 这里写修改透视颜色的代码
    end
})

-- 3. 滑块 (Slider)
local espSize = playerTab:AddSlider({
    Parent = visualSection,
    Name = "透视大小",
    Min = 1,
    Max = 10,
    Default = 5,
    Flag = "ESPSize",
    Callback = function(value)
        print("[透视大小] 值:", value)
        -- 这里写修改透视大小的代码
    end
})

-- 分区2：移动功能
local movementSection = playerTab:CreateSection("移动功能")

-- 4. 滑块 - 移动速度
local speedSlider = playerTab:AddSlider({
    Parent = movementSection,
    Name = "移动速度",
    Min = 16,
    Max = 100,
    Default = 16,
    Flag = "WalkSpeed",
    Callback = function(value)
        print("[移动速度] 值:", value)
        -- 这里写修改移动速度的代码
        -- 例如: game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})

-- 5. 滑块 - 跳跃高度
local jumpSlider = playerTab:AddSlider({
    Parent = movementSection,
    Name = "跳跃高度",
    Min = 50,
    Max = 200,
    Default = 50,
    Flag = "JumpPower",
    Callback = function(value)
        print("[跳跃高度] 值:", value)
        -- 这里写修改跳跃高度的代码
    end
})

-- 6. 开关 - 无限跳跃
local infJumpToggle = playerTab:AddToggle({
    Parent = movementSection,
    Name = "无限跳跃",
    Default = false,
    Flag = "InfiniteJump",
    Callback = function(value)
        print("[无限跳跃] 状态:", value)
        -- 这里写无限跳跃的代码
    end
})

-- 7. 开关 - 穿墙模式
local noclipToggle = playerTab:AddToggle({
    Parent = movementSection,
    Name = "穿墙模式",
    Default = false,
    Flag = "Noclip",
    Callback = function(value)
        print("[穿墙模式] 状态:", value)
        -- 这里写穿墙模式的代码
    end
})

-- 分区3：战斗功能
local combatSection = playerTab:CreateSection("战斗功能")

-- 8. 开关 - 自动瞄准
local aimbotToggle = playerTab:AddToggle({
    Parent = combatSection,
    Name = "自动瞄准",
    Default = false,
    Flag = "Aimbot",
    Callback = function(value)
        print("[自动瞄准] 状态:", value)
    end
})

-- 9. 下拉菜单 - 瞄准部位
local aimPart = playerTab:AddDropdown({
    Parent = combatSection,
    Name = "瞄准部位",
    Options = {"头部", "胸部", "腿部"},
    Default = "头部",
    Flag = "AimPart",
    Callback = function(value)
        print("[瞄准部位] 选中:", value)
    end
})

-- 10. 滑块 - 瞄准范围
local aimFOV = playerTab:AddSlider({
    Parent = combatSection,
    Name = "瞄准范围",
    Min = 0,
    Max = 360,
    Default = 180,
    Flag = "AimFOV",
    Callback = function(value)
        print("[瞄准范围] 值:", value)
    end
})

-- 11. 开关 - 自动开枪
local triggerbotToggle = playerTab:AddToggle({
    Parent = combatSection,
    Name = "自动开枪",
    Default = false,
    Flag = "Triggerbot",
    Callback = function(value)
        print("[自动开枪] 状态:", value)
    end
})

-- 分区4：其他功能
local otherSection = playerTab:CreateSection("其他功能")

-- 12. 按钮 (Button)
local refreshBtn = playerTab:AddButton({
    Parent = otherSection,
    Name = "刷新ESP",
    Callback = function()
        print("[按钮] 刷新ESP被点击")
        ChronixUI:NotifySuccess("成功", "ESP已刷新", 2)
    end
})

-- 13. 文本框 (Input)
local commandInput = playerTab:AddInput({
    Parent = otherSection,
    Name = "执行命令",
    Placeholder = "输入命令...",
    Flag = "Command",
    Callback = function(text)
        print("[文本框] 输入内容:", text)
        -- 这里写执行命令的代码
    end
})

-- 14. 标签 (Label)
local infoLabel = playerTab:AddLabel({
    Parent = otherSection,
    Text = "提示：点击下方按钮可保存配置"
})

-- 15. 按钮 - 保存配置
local saveBtn = playerTab:AddButton({
    Parent = otherSection,
    Name = "保存当前配置",
    Callback = function()
        print("[按钮] 保存配置被点击")
        ChronixUI:SaveConfig()
        ChronixUI:NotifySuccess("配置已保存", "所有设置已保存到本地", 2)
    end
})

-- 16. 按钮 - 加载配置
local loadBtn = playerTab:AddButton({
    Parent = otherSection,
    Name = "加载上次配置",
    Callback = function()
        print("[按钮] 加载配置被点击")
        ChronixUI:LoadConfig()
        ChronixUI:NotifySuccess("配置已加载", "已加载上次保存的设置", 2)
    end
})

-- ============================================================
-- 世界标签页
-- ============================================================

-- 分区1：环境设置
local environmentSection = worldTab:CreateSection("环境设置")

-- 17. 下拉菜单 - 天气效果
local weatherDropdown = worldTab:AddDropdown({
    Parent = environmentSection,
    Name = "天气效果",
    Options = {"晴天", "雨天", "雾天", "暴风雪"},
    Default = "晴天",
    Flag = "Weather",
    Callback = function(value)
        print("[天气效果] 选中:", value)
        -- 这里写修改天气的代码
    end
})

-- 18. 滑块 - 时间设置
local timeSlider = worldTab:AddSlider({
    Parent = environmentSection,
    Name = "游戏时间",
    Min = 0,
    Max = 24,
    Default = 14,
    Flag = "GameTime",
    Callback = function(value)
        print("[游戏时间] 值:", value)
        -- 这里写修改游戏时间的代码
        -- game:GetService("Lighting").ClockTime = value
    end
})

-- 19. 开关 - 黑夜模式
local nightMode = worldTab:AddToggle({
    Parent = environmentSection,
    Name = "强制黑夜",
    Default = false,
    Flag = "NightMode",
    Callback = function(value)
        print("[强制黑夜] 状态:", value)
    end
})

-- 分区2：物品收集
local itemSection = worldTab:CreateSection("物品收集")

-- 20. 开关 - 自动收集
local autoCollect = worldTab:AddToggle({
    Parent = itemSection,
    Name = "自动收集物品",
    Default = false,
    Flag = "AutoCollect",
    Callback = function(value)
        print("[自动收集] 状态:", value)
    end
})

-- 21. 滑块 - 收集范围
local collectRange = worldTab:AddSlider({
    Parent = itemSection,
    Name = "收集范围",
    Min = 10,
    Max = 100,
    Default = 30,
    Flag = "CollectRange",
    Callback = function(value)
        print("[收集范围] 值:", value)
    end
})

-- 22. 按钮 - 传送至所有物品
local teleportItems = worldTab:AddButton({
    Parent = itemSection,
    Name = "传送至最近物品",
    Callback = function()
        print("[按钮] 传送至最近物品")
        ChronixUI:NotifyInfo("提示", "正在寻找最近物品...", 2)
    end
})

-- ============================================================
-- 杂项标签页
-- ============================================================

-- 分区1：UI设置
local uiSection = miscTab:CreateSection("界面设置")

-- 23. 开关 - 显示FPS
local showFPS = miscTab:AddToggle({
    Parent = uiSection,
    Name = "显示FPS计数器",
    Default = false,
    Flag = "ShowFPS",
    Callback = function(value)
        print("[显示FPS] 状态:", value)
    end
})

-- 24. 开关 - 显示Ping
local showPing = miscTab:AddToggle({
    Parent = uiSection,
    Name = "显示网络延迟",
    Default = false,
    Flag = "ShowPing",
    Callback = function(value)
        print("[显示Ping] 状态:", value)
    end
})

-- 25. 按钮 - 重置窗口位置
local resetWindow = miscTab:AddButton({
    Parent = uiSection,
    Name = "重置窗口位置",
    Callback = function()
        print("[按钮] 重置窗口位置")
        mainWindow.mainFrame.Position = UDim2.new(0.5, -mainWindow.theme.WindowWidth/2, 0.5, -mainWindow.theme.WindowHeight/2)
        ChronixUI:NotifySuccess("窗口位置已重置", "", 1.5)
    end
})

-- 分区2：脚本控制
local scriptSection = miscTab:CreateSection("脚本控制")

-- 26. 按键绑定 (Bind)
local menuBind = miscTab:AddBind({
    Parent = scriptSection,
    Name = "打开/关闭菜单",
    Default = "RightShift",
    Hold = false,
    Flag = "MenuBind",
    Callback = function(key)
        print("[按键绑定] 按下了:", key)
        -- 注意：这个回调是在按键被按下时触发
        -- 实际的隐藏/显示功能已经在主窗口中实现了
    end
})

-- 27. 按钮 - 重新加载脚本
local reloadBtn = miscTab:AddButton({
    Parent = scriptSection,
    Name = "重新加载脚本",
    Callback = function()
        print("[按钮] 重新加载脚本")
        ChronixUI:NotifyWarning("警告", "重新加载功能需要手动实现", 2)
    end
})

-- 28. 按钮 - 卸载脚本
local unloadBtn = miscTab:AddButton({
    Parent = scriptSection,
    Name = "卸载所有功能",
    Callback = function()
        print("[按钮] 卸载脚本")
        ChronixUI:Unload()
    end
})

-- 分区3：关于
local aboutSection = miscTab:CreateSection("关于")

-- 29. 标签 - 版本信息
local versionLabel = miscTab:AddLabel({
    Parent = aboutSection,
    Text = "ChronixHub V2 - 版本 1.0.0"
})

-- 30. 标签 - 作者信息
local authorLabel = miscTab:AddLabel({
    Parent = aboutSection,
    Text = "作者: Furrycalin"
})

-- 31. 按钮 - 显示通知测试
local testNotifBtn = miscTab:AddButton({
    Parent = aboutSection,
    Name = "测试通知系统",
    Callback = function()
        print("[按钮] 测试通知")
        ChronixUI:NotifySuccess("成功通知", "这是成功类型的通知", 3)
        task.wait(0.5)
        ChronixUI:NotifyError("错误通知", "这是错误类型的通知", 3)
        task.wait(0.5)
        ChronixUI:NotifyInfo("信息通知", "这是普通信息通知", 3)
    end
})

-- ============================================================
-- 配置保存与加载
-- ============================================================

-- 设置配置文件夹（可选，用于保存用户设置）
ChronixUI:SetupConfig("ChronixHubConfig")

-- 自动加载上次保存的配置
task.wait(0.5)
ChronixUI:LoadConfig()

-- 启动完成通知
ChronixUI:NotifySuccess("ChronixHub V2", "加载完成！共加载 30+ 个控件示例", 3)

print("========================================")
print("ChronixUI 示例窗口已启动")
print("所有控件都已添加，你可以根据需求修改")
print("========================================")

mainWindow:SetCloseCallback(function()
    print("窗口正在关闭，执行清理...")
    -- 卸载你的其他模块
end)