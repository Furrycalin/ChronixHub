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

-- -- 创建主窗口
-- local mainWindow = ChronixUI:CreateWindow("ChronixHub V2", {
--     -- 可选：覆盖主题颜色
--     -- MainBg = Color3.fromRGB(30, 30, 46),
--     -- AccentColor = Color3.fromRGB(100, 100, 170),
-- })

-- -- 分区
-- mainWindow:Section("玩家功能")

-- -- 开关
-- local espToggle = mainWindow:Toggle("玩家透视", false, function(state)
--     print("透视状态:", state)
--     -- 这里调用你的ESP模块
--     if state then
--         -- 启用透视
--     else
--         -- 关闭透视
--     end
-- end)

-- -- 按钮
-- mainWindow:Button("刷新ESP", function()
--     print("刷新")
-- end)

-- -- 滑块
-- local speedSlider = mainWindow:Slider("移动速度", 16, 100, 16, function(value)
--     -- 这里修改玩家速度
--     print("速度:", value)
-- end)

-- -- 下拉菜单
-- mainWindow:Dropdown("选择武器", {"AK47", "M4A1", "AWP"}, function(selected)
--     print("选中:", selected)
-- end)

-- -- 文本框
-- mainWindow:InputBox("输入命令", "输入内容", function(text)
--     print("输入:", text)
-- end)

-- -- 标签
-- mainWindow:Label("—— 其他功能 ——")

-- -- 发送通知
-- ChronixUI:Notify("提示", "脚本加载成功！", 3)

-- -- 卸载（可选）
-- -- ChronixUI:Unload()

local ChronixUI = loadstring(game:HttpGet("你的脚本链接"))()

-- 创建窗口
local mainWindow = ChronixUI:CreateWindow({
    Title = "ChronixHub V2"
})

-- 创建标签页
local playerTab = mainWindow:CreateTab({
    Name = "玩家",
    Icon = "👤"
})

local worldTab = mainWindow:CreateTab({
    Name = "世界",
    Icon = "🌍"
})

local settingsTab = mainWindow:CreateTab({
    Name = "设置",
    Icon = "⚙️"
})

-- 在玩家标签页添加功能
local playerSection = playerTab:CreateSection("视觉功能")

playerTab:AddButton({
    Parent = playerSection,
    Name = "刷新ESP",
    Callback = function()
        ChronixUI:NotifySuccess("成功", "ESP已刷新")
    end
})

local espToggle = playerTab:AddToggle({
    Parent = playerSection,
    Name = "玩家透视",
    Default = false,
    Flag = "PlayerESP",
    Callback = function(value)
        print("透视状态:", value)
    end
})

local speedSlider = playerTab:AddSlider({
    Parent = playerSection,
    Name = "移动速度",
    Min = 16,
    Max = 100,
    Default = 16,
    Flag = "WalkSpeed",
    Callback = function(value)
        -- 设置移动速度
    end
})

-- 在世界标签页添加功能
local worldSection = worldTab:CreateSection("环境设置")

worldTab:AddDropdown({
    Parent = worldSection,
    Name = "天气效果",
    Options = {"晴天", "雨天", "雾天", "夜晚"},
    Default = "晴天",
    Flag = "Weather",
    Callback = function(value)
        print("天气改为:", value)
    end
})

-- 发送通知
ChronixUI:NotifySuccess("加载完成", "ChronixHub V2 已启动", 3)
ChronixUI:NotifySuccess("加载完成", "ChronixHub V2 已启动", 3)