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

--主体结构
local Gui = Instance.new("ScreenGui")
Gui.Parent = game.CoreGui
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.ResetOnSpawn = true

-- 创建主窗口
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0) -- 中等大小
mainFrame.Position = UDim2.new(0, 0, 0, 0) -- 屏幕中央
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- 墨蓝色
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.9
mainFrame.Parent = Gui