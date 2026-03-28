-- SystemNotification.lua (必须放在 LocalScript 中)
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

local SystemNotification = {}

-- HTML 转义（防止用户输入破坏标签）
local function escape(text)
    return text:gsub("[<>&]", {
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["&"] = "&amp;"
    })
end

-- 新版聊天系统发送富文本
local function sendNew(message, font, size, colorRGB)
    local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if not channel then return end
    local escaped = escape(message)
    local r, g, b = colorRGB.R * 255, colorRGB.G * 255, colorRGB.B * 255
    local rich = string.format(
        '<font color="rgb(%d,%d,%d)" face="%s" size="%d">%s</font>',
        r, g, b, font, size, escaped
    )
    channel:DisplaySystemMessage(rich)
end

-- 旧版聊天系统发送（仅颜色）
local function sendOld(message, colorRGB)
    local player = Players.LocalPlayer
    if not player then return end
    local gui = player:WaitForChild("PlayerGui")
    pcall(function()
        gui:SetCore("ChatMakeSystemMessage", {
            Text = message,
            Color = colorRGB
        })
    end)
end

-- 统一发送入口
local function send(message, colorRGB, font, size)
    if isLegacyChat then
        sendOld(message, colorRGB)
    else
        sendNew(message, font, size, colorRGB)
    end
end

-- 预设方法
function SystemNotification.Success(message)
    send(message, Color3.fromRGB(0, 255, 0), "GothamBold", 18)
end

function SystemNotification.Warning(message)
    send(message, Color3.fromRGB(255, 200, 0), "SourceSansBold", 16)
end

function SystemNotification.Error(message)
    send(message, Color3.fromRGB(255, 0, 0), "GothamBold", 20)
end

function SystemNotification.Info(message)
    send(message, Color3.fromRGB(100, 150, 255), "SourceSans", 14)
end

-- 新增：加载成功（欢迎消息）
function SystemNotification.Loaded(message)
    -- 样式：亮绿色，大号 GothamBold 斜体
    send(message, Color3.fromRGB(80, 255, 80), "GothamBold", 20)
end

-- 新增：卸载成功
function SystemNotification.Unloaded(message)
    -- 样式：橙黄色，中等大小 SourceSansBold
    send(message, Color3.fromRGB(255, 180, 60), "SourceSansBold", 16)
end

-- 完全自定义（颜色、字体、字号）
function SystemNotification.Custom(message, colorRGB, font, size)
    send(message, colorRGB, font, size)
end

return SystemNotification