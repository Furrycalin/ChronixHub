if not game:IsLoaded() then
	game.Loaded:Wait()
end

_G.SA_FASTLOADING = true

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
local MainWindow = ChronixUI:MakeWindow({
    Name = "ChronixHub V3",
    ConfigFolder = "ChronixHubConfig",
    SaveConfig = true,
    HidePremium = false,
    CloseCallback = function()
        print("[ChronixUI] 窗口已关闭")
        -- 在这里添加你的清理代码
        -- 例如：PlayerESP:unload()
    end
})

-- ============ 玩家标签页 ============
local PlayerTab = MainWindow:MakeTab({
    Name = "玩家",
    PremiumOnly = false
})

-- 视觉功能分区
local VisualSection = PlayerTab:AddSection("视觉功能")

-- 开关 - 玩家透视
local espToggle = PlayerTab:AddToggle({
    Parent = VisualSection,
    Name = "玩家透视",
    Default = false,
    Flag = "PlayerESP",
    Save = true,
    Callback = function(Value)
        print("[玩家透视] 状态:", Value)
        if Value then
            -- 开启透视的代码
            -- PlayerESP:enable()
        else
            -- 关闭透视的代码
            -- PlayerESP:disable()
        end
    end
})

-- 颜色选择器 - 透视颜色
local espColor = PlayerTab:AddColorpicker({
    Parent = VisualSection,
    Name = "透视颜色",
    Default = Color3.fromRGB(150, 120, 200),
    Flag = "ESPColor",
    Save = true,
    Callback = function(Color)
        print("[透视颜色] R:", Color.R * 255, "G:", Color.G * 255, "B:", Color.B * 255)
        -- 修改透视颜色的代码
    end
})

-- 滑块 - 透视透明度
local espAlpha = PlayerTab:AddSlider({
    Parent = VisualSection,
    Name = "透视透明度",
    Min = 0,
    Max = 100,
    Default = 50,
    Flag = "ESPAlpha",
    Save = true,
    Callback = function(Value)
        print("[透视透明度] 值:", Value, "%")
    end
})

-- 移动功能分区
local MovementSection = PlayerTab:AddSection("移动功能")

-- 滑块 - 移动速度
local walkSpeed = PlayerTab:AddSlider({
    Parent = MovementSection,
    Name = "移动速度",
    Min = 16,
    Max = 100,
    Default = 16,
    Flag = "WalkSpeed",
    Save = true,
    Callback = function(Value)
        print("[移动速度] 值:", Value)
        -- game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end
})

-- 滑块 - 跳跃高度
local jumpPower = PlayerTab:AddSlider({
    Parent = MovementSection,
    Name = "跳跃高度",
    Min = 50,
    Max = 200,
    Default = 50,
    Flag = "JumpPower",
    Save = true,
    Callback = function(Value)
        print("[跳跃高度] 值:", Value)
        -- game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
    end
})

-- 开关 - 无限跳跃
local infiniteJump = PlayerTab:AddToggle({
    Parent = MovementSection,
    Name = "无限跳跃",
    Default = false,
    Flag = "InfiniteJump",
    Save = true,
    Callback = function(Value)
        print("[无限跳跃] 状态:", Value)
    end
})

-- 开关 - 穿墙模式
local noclip = PlayerTab:AddToggle({
    Parent = MovementSection,
    Name = "穿墙模式",
    Default = false,
    Flag = "Noclip",
    Save = true,
    Callback = function(Value)
        print("[穿墙模式] 状态:", Value)
    end
})

-- 战斗功能分区
local CombatSection = PlayerTab:AddSection("战斗功能")

-- 开关 - 自动瞄准
local aimbot = PlayerTab:AddToggle({
    Parent = CombatSection,
    Name = "自动瞄准",
    Default = false,
    Flag = "Aimbot",
    Save = true,
    Callback = function(Value)
        print("[自动瞄准] 状态:", Value)
    end
})

-- 下拉菜单 - 瞄准部位
local aimPart = PlayerTab:AddDropdown({
    Parent = CombatSection,
    Name = "瞄准部位",
    Options = {"头部", "胸部", "腿部"},
    Default = "头部",
    Flag = "AimPart",
    Save = true,
    Callback = function(Value)
        print("[瞄准部位] 选中:", Value)
    end
})

-- 滑块 - 瞄准范围
local aimFov = PlayerTab:AddSlider({
    Parent = CombatSection,
    Name = "瞄准范围",
    Min = 0,
    Max = 360,
    Default = 180,
    Flag = "AimFOV",
    Save = true,
    Callback = function(Value)
        print("[瞄准范围] 值:", Value)
    end
})

-- 开关 - 自动开枪
local triggerbot = PlayerTab:AddToggle({
    Parent = CombatSection,
    Name = "自动开枪",
    Default = false,
    Flag = "Triggerbot",
    Save = true,
    Callback = function(Value)
        print("[自动开枪] 状态:", Value)
    end
})

-- 按键绑定 - 自动瞄准快捷键
local aimbotKey = PlayerTab:AddBind({
    Parent = CombatSection,
    Name = "自动瞄准快捷键",
    Default = "X",
    Hold = false,
    Flag = "AimbotKey",
    Save = true,
    Callback = function(Key)
        print("[自动瞄准快捷键] 按下:", Key)
        -- 切换自动瞄准状态
        aimbot:Set(not aimbot:Get())
    end
})

-- 其他功能分区
local OtherSection = PlayerTab:AddSection("其他功能")

-- 按钮 - 刷新ESP
PlayerTab:AddButton({
    Parent = OtherSection,
    Name = "刷新ESP",
    Callback = function()
        print("[按钮] 刷新ESP")
        ChronixUI:MakeNotification({
            Name = "成功",
            Content = "ESP已刷新",
            Time = 3
        })
    end
})

-- 按钮 - 传送至出生点
PlayerTab:AddButton({
    Parent = OtherSection,
    Name = "传送至出生点",
    Callback = function()
        print("[按钮] 传送至出生点")
        ChronixUI:MakeNotification({
            Name = "提示",
            Content = "已传送至出生点",
            Time = 2
        })
    end
})

-- 文本框 - 执行命令
local commandBox = PlayerTab:AddTextbox({
    Parent = OtherSection,
    Name = "执行命令",
    Placeholder = "输入Lua代码...",
    Default = "",
    Flag = "Command",
    Save = false,
    Callback = function(Text)
        print("[文本框] 输入:", Text)
        if Text ~= "" then
            local success, err = pcall(function()
                loadstring(Text)()
            end)
            if not success then
                ChronixUI:MakeNotification({
                    Name = "错误",
                    Content = "执行失败: " .. tostring(err),
                    Time = 3
                })
            end
        end
    end
})

-- 标签 - 提示信息
PlayerTab:AddLabel("提示：部分功能需要管理员权限")

-- 段落 - 说明
PlayerTab:AddParagraph("关于本菜单", "ChronixHub V3 是一个功能强大的辅助工具。使用前请确保了解相关风险，请勿用于破坏游戏平衡。")

-- ============ 世界标签页 ============
local WorldTab = MainWindow:MakeTab({
    Name = "世界"
})

-- 环境设置分区
local EnvironmentSection = WorldTab:AddSection("环境设置")

-- 下拉菜单 - 天气效果
local weather = WorldTab:AddDropdown({
    Parent = EnvironmentSection,
    Name = "天气效果",
    Options = {"晴天", "雨天", "雾天", "暴风雪", "雷电"},
    Default = "晴天",
    Flag = "Weather",
    Save = true,
    Callback = function(Value)
        print("[天气效果] 选中:", Value)
    end
})

-- 滑块 - 游戏时间
local gameTime = WorldTab:AddSlider({
    Parent = EnvironmentSection,
    Name = "游戏时间",
    Min = 0,
    Max = 24,
    Default = 14,
    Flag = "GameTime",
    Save = true,
    Callback = function(Value)
        print("[游戏时间] 值:", Value)
        -- game:GetService("Lighting").ClockTime = Value
    end
})

-- 开关 - 强制黑夜
local nightMode = WorldTab:AddToggle({
    Parent = EnvironmentSection,
    Name = "强制黑夜",
    Default = false,
    Flag = "NightMode",
    Save = true,
    Callback = function(Value)
        print("[强制黑夜] 状态:", Value)
    end
})

-- 开关 - 彩虹灯光
local rainbowLight = WorldTab:AddToggle({
    Parent = EnvironmentSection,
    Name = "彩虹灯光",
    Default = false,
    Flag = "RainbowLight",
    Save = true,
    Callback = function(Value)
        print("[彩虹灯光] 状态:", Value)
    end
})

-- 物品收集分区
local LootSection = WorldTab:AddSection("物品收集")

-- 开关 - 自动收集
local autoCollect = WorldTab:AddToggle({
    Parent = LootSection,
    Name = "自动收集物品",
    Default = false,
    Flag = "AutoCollect",
    Save = true,
    Callback = function(Value)
        print("[自动收集] 状态:", Value)
    end
})

-- 滑块 - 收集范围
local collectRange = WorldTab:AddSlider({
    Parent = LootSection,
    Name = "收集范围",
    Min = 10,
    Max = 100,
    Default = 30,
    Flag = "CollectRange",
    Save = true,
    Callback = function(Value)
        print("[收集范围] 值:", Value)
    end
})

-- 按钮 - 传送至最近物品
WorldTab:AddButton({
    Parent = LootSection,
    Name = "传送至最近物品",
    Callback = function()
        print("[按钮] 传送至最近物品")
        ChronixUI:MakeNotification({
            Name = "提示",
            Content = "正在寻找最近物品...",
            Time = 2
        })
    end
})

-- ============ 武器标签页 ============
local WeaponTab = MainWindow:MakeTab({
    Name = "武器"
})

-- 武器修改分区
local WeaponModSection = WeaponTab:AddSection("武器修改")

-- 开关 - 无限弹药
local infiniteAmmo = WeaponTab:AddToggle({
    Parent = WeaponModSection,
    Name = "无限弹药",
    Default = false,
    Flag = "InfiniteAmmo",
    Save = true,
    Callback = function(Value)
        print("[无限弹药] 状态:", Value)
    end
})

-- 开关 - 无后坐力
local noRecoil = WeaponTab:AddToggle({
    Parent = WeaponModSection,
    Name = "无后坐力",
    Default = false,
    Flag = "NoRecoil",
    Save = true,
    Callback = function(Value)
        print("[无后坐力] 状态:", Value)
    end
})

-- 开关 - 快速射击
local rapidFire = WeaponTab:AddToggle({
    Parent = WeaponModSection,
    Name = "快速射击",
    Default = false,
    Flag = "RapidFire",
    Save = true,
    Callback = function(Value)
        print("[快速射击] 状态:", Value)
    end
})

-- 滑块 - 伤害倍率
local damageMultiplier = WeaponTab:AddSlider({
    Parent = WeaponModSection,
    Name = "伤害倍率",
    Min = 1,
    Max = 10,
    Default = 1,
    Flag = "DamageMultiplier",
    Save = true,
    Callback = function(Value)
        print("[伤害倍率] 值:", Value, "x")
    end
})

-- ============ 杂项标签页 ============
local MiscTab = MainWindow:MakeTab({
    Name = "杂项"
})

-- UI设置分区
local UISection = MiscTab:AddSection("界面设置")

-- 开关 - 显示FPS
local showFPS = MiscTab:AddToggle({
    Parent = UISection,
    Name = "显示FPS计数器",
    Default = false,
    Flag = "ShowFPS",
    Save = true,
    Callback = function(Value)
        print("[显示FPS] 状态:", Value)
    end
})

-- 开关 - 显示Ping
local showPing = MiscTab:AddToggle({
    Parent = UISection,
    Name = "显示网络延迟",
    Default = false,
    Flag = "ShowPing",
    Save = true,
    Callback = function(Value)
        print("[显示Ping] 状态:", Value)
    end
})

-- 按钮 - 重置窗口位置
MiscTab:AddButton({
    Parent = UISection,
    Name = "重置窗口位置",
    Callback = function()
        print("[按钮] 重置窗口位置")
        -- 重置窗口位置逻辑
        ChronixUI:MakeNotification({
            Name = "提示",
            Content = "窗口位置已重置",
            Time = 2
        })
    end
})

-- 快捷键设置分区
local KeybindSection = MiscTab:AddSection("快捷键设置")

-- 按键绑定 - 飞行模式（按住模式）
local flyBind = MiscTab:AddBind({
    Parent = KeybindSection,
    Name = "飞行模式",
    Default = "F",
    Hold = true,
    Flag = "FlyKey",
    Save = true,
    Callback = function(State)
        if State then
            print("[飞行模式] 按住开启")
            -- 开启飞行
        else
            print("[飞行模式] 松开关闭")
            -- 关闭飞行
        end
    end
})

-- 按键绑定 - 快速传送
local teleportBind = MiscTab:AddBind({
    Parent = KeybindSection,
    Name = "快速传送",
    Default = "Mouse2",
    Hold = false,
    Flag = "TeleportKey",
    Save = true,
    Callback = function(Key)
        print("[快速传送] 按下:", Key)
        -- 传送到鼠标指向的位置
    end
})

-- 脚本控制分区
local ScriptSection = MiscTab:AddSection("脚本控制")

-- 按钮 - 保存配置
MiscTab:AddButton({
    Parent = ScriptSection,
    Name = "保存配置",
    Callback = function()
        print("[按钮] 保存配置")
        ChronixUI:MakeNotification({
            Name = "成功",
            Content = "配置已保存",
            Time = 2
        })
    end
})

-- 按钮 - 加载配置
MiscTab:AddButton({
    Parent = ScriptSection,
    Name = "加载配置",
    Callback = function()
        print("[按钮] 加载配置")
        ChronixUI:MakeNotification({
            Name = "提示",
            Content = "配置已加载",
            Time = 2
        })
    end
})

-- 按钮 - 卸载脚本
MiscTab:AddButton({
    Parent = ScriptSection,
    Name = "卸载所有功能",
    Callback = function()
        print("[按钮] 卸载脚本")
        ChronixUI:Destroy()
    end
})

-- ============ Premium标签页（演示锁定功能） ============
local PremiumTab = MainWindow:MakeTab({
    Name = "高级",
    PremiumOnly = true  -- 这个标签页会被锁定，显示 Premium 提示
})

-- 这些控件在 PremiumOnly 模式下不会显示，而是显示锁屏界面
local PremiumSection = PremiumTab:AddSection("高级功能")

PremiumTab:AddToggle({
    Parent = PremiumSection,
    Name = "高级透视",
    Default = false,
    Flag = "AdvancedESP",
    Callback = function(Value)
        print("[高级透视] 状态:", Value)
    end
})

PremiumTab:AddButton({
    Parent = PremiumSection,
    Name = "高级功能",
    Callback = function()
        print("[高级功能] 按钮被点击")
    end
})

-- ============ 测试通知系统 ============
-- 启动完成通知
task.wait(1)
ChronixUI:MakeNotification({
    Name = "ChronixHub V3",
    Content = "菜单加载完成！共加载 30+ 个功能",
    Time = 3
})

-- 测试其他类型的通知
task.wait(0.5)
ChronixUI:MakeNotification({
    Name = "提示",
    Content = "按 RightShift 可隐藏/显示菜单",
    Time = 4
})

print("========================================")
print("ChronixHub V3 示例菜单已启动")
print("所有控件类型已展示，可根据需求修改")
print("========================================")