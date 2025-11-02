if not game:IsLoaded() then
	game.Loaded:Wait()
end

if _G.ChronixHubisLoaded then
    warn("⛔ ChronixHub Already loaded! Please do not repeat the execution.")
    return
end

_G.ChronixHubisLoaded = true

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")

local ModularDropdown = loadstring(game:HttpGet("https://raw.gitcode.com/Furrycalin/ChronixHub/raw/main/modules/dropmenu.lua"))()
local NotificationSystem = loadstring(game:HttpGet("https://raw.gitcode.com/Furrycalin/ChronixHub/raw/main/modules/notification.lua"))()
local LoadAnimationModule = loadstring(game:HttpGet("https://raw.gitcode.com/Furrycalin/ChronixHub/raw/main/modules/start_animation.lua"))()
local tpWalk = loadstring(game:HttpGet("https://raw.gitcode.com/Furrycalin/RobloxScripts/raw/main/tpWalk.lua"))()

local iscancel = false

LoadAnimationModule:LoadAnimation(2, {
    titleText = "ChronixHub V3",
    loadingText = "加载中... ",
    backgroundColor = Color3.new(0, 0, 0),
    textColor = Color3.new(1, 1, 1),
    language = "zh",
    onComplete = function(isCancelled)
        if isCancelled then
            iscancel = true
        end
    end,
    showCancelButton = true
})

wait(15.1)
if iscancel then
    _G.ChronixHubisLoaded = false
    return
end

local cc = game:service'Players'.LocalPlayer.Idled:connect(function()bb:CaptureController()bb:ClickButton2(Vector2.new())end)

-- 创建基础部件
-- 点击音效
local uiclicker = Instance.new("Sound")
uiclicker.SoundId = "rbxassetid://535716488"
uiclicker.Volume = 0.3
uiclicker.Parent = SoundService

-- 创建主ScreenGui
local Gui = Instance.new("ScreenGui")
Gui.Name = "ChronixHubGui"
Gui.Parent = game.CoreGui
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.ResetOnSpawn = false

-- 创建全屏黑色覆盖层
local overlay = Instance.new("Frame")
overlay.Name = "FullscreenOverlay"
overlay.Size = UDim2.new(1, 0, 1.08, 0) -- 全屏
overlay.Position = UDim2.new(0, 0, -0.08, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0) -- 纯黑色
overlay.BackgroundTransparency = 0.4 -- 40%透明度
overlay.ZIndex = 1
overlay.Parent = Gui

-- 创建标题容器
local titleContainer = Instance.new("Frame")
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.new(0, 150, 0, 50) -- 固定大小
titleContainer.Position = UDim2.new(1, 100, 1, 1) -- 顶部居中，与顶部有20像素距离
titleContainer.BackgroundTransparency = 1 -- 透明背景
titleContainer.ZIndex = 2
titleContainer.Parent = overlay

-- 创建"Chronix"文本
local chronixText = Instance.new("TextLabel")
chronixText.Name = "ChronixText"
chronixText.Text = "ChronixHub"
chronixText.Font = Enum.Font.SourceSansBold
chronixText.FontSize = Enum.FontSize.Size36
chronixText.TextColor3 = Color3.new(1, 1, 1) -- 纯白色
chronixText.BackgroundTransparency = 1
chronixText.ZIndex = 3
chronixText.Parent = titleContainer

-- 创建"V3"文本
local v3Text = Instance.new("TextLabel")
v3Text.Name = "V3Text"
v3Text.Text = "V3"
v3Text.Font = Enum.Font.SourceSansBold
v3Text.FontSize = Enum.FontSize.Size36
v3Text.TextColor3 = Color3.new(0.8, 1, 0.5) -- 浅绿色
v3Text.BackgroundTransparency = 1
v3Text.ZIndex = 3

-- 计算V3文本的位置，使其紧挨着Chronix文本
local chronixTextSize = chronixText.TextBounds.X - 50
v3Text.Position = UDim2.new(0, chronixTextSize, 0, 0)
v3Text.Parent = titleContainer

-- 调整标题容器大小以适应文本
titleContainer.Size = UDim2.new(0, chronixTextSize + v3Text.TextBounds.X, 0, 50)
titleContainer.Position = UDim2.new(0.53, -(chronixTextSize + v3Text.TextBounds.X)/2, 0, 50)

local basicMenu = ModularDropdown.new("       基础       ", Vector2.new(150, 100), overlay)
local combatMenu = ModularDropdown.new("       战斗       ", Vector2.new(350, 100), overlay)
local moveMenu = ModularDropdown.new("       移动       ", Vector2.new(550, 100), overlay)
local visualMenu = ModularDropdown.new("       视觉       ", Vector2.new(750, 100), overlay)
local scriptsMenu = ModularDropdown.new("       脚本       ", Vector2.new(950, 100), overlay)
local exploitMenu = ModularDropdown.new("       漏洞       ", Vector2.new(1150, 100), overlay)
local settingMenu = ModularDropdown.new("       设置       ", Vector2.new(1350, 100), overlay)


local isProcessing = true

local bkvm = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightShift then
        if overlay.Visible then
            if not isProcessing then
                overlay.Visible = false
                NotificationSystem:CreateNotification("ChronixHub已隐藏", "按下右SHIFT重新打开", 5, "rbxassetid://4590662766")
            else
                isProcessing = false
            end
        else
            overlay.Visible = true
        end
    end
end)

local function unloadChronixHub()
    cc:Disconnect()
    bkvm:Disconnect()
    overlay:Destroy()
	Gui:Destroy()
    ModularDropdown:Destroy()
    NotificationSystem:Destroy()
    tpWalk:Destroy()
	script:Destroy()
	_G.ChronixHubisLoaded = false
end

settingMenu:AddMenuItem("卸载脚本", function()
    unloadChronixHub()
end, 1)

overlay.Visible = false

NotificationSystem:CreateNotification("ChronixHubv3已启动", "防挂机系统已自动开启\n按下右SHIFT开关界面.", 10, "rbxassetid://4590662766")