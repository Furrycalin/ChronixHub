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

-- 辅助：HSV 转 Color3（Hue 0-360, Saturation 0-1, Value 0-1）
local function hsvToColor3(h, s, v)
    local r, g, b
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c

    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return Color3.new(r + m, g + m, b + m)
end

-- 彩虹渐变色（淡雅版）
local function rainbowGradient(text, font, size)
    local len = #text
    if len == 0 then return "" end

    local parts = {}
    for i = 1, len do
        local hue = (i - 1) / (len - 1) * 360  -- 第一个字符0°（红），最后一个字符360°（回到红）→ 实际我们取0~360，最后一个接近360°（红紫之间）
        -- 但为了首尾不重复，可限制最大到 330° 避免回到红，更丝滑。这里保持360°会让首尾颜色相近但不同。
        -- 更丝滑：最大330°，使红-紫范围。用户希望红橙黄绿青蓝紫，0~330覆盖这七色。
        if len > 1 then
            hue = (i - 1) / (len - 1) * 330  -- 0°（红）到330°（紫）
        else
            hue = 0
        end
        local color = hsvToColor3(hue, 0.6, 1)  -- 饱和度0.6，亮度1 → 淡彩虹
        local r = math.floor(color.R * 255)
        local g = math.floor(color.G * 255)
        local b = math.floor(color.B * 255)
        local char = text:sub(i, i)
        local escaped = char:gsub("[<>&]", {
            ["<"] = "&lt;",
            [">"] = "&gt;",
            ["&"] = "&amp;"
        })
        parts[#parts + 1] = string.format('<font color="rgb(%d,%d,%d)" face="%s" size="%d">%s</font>',
            r, g, b, font, size, escaped)
    end
    return table.concat(parts)
end

-- 彩虹色预设
function SystemNotification.Rainbow(message, font, size)
    font = font or "GothamBold"   -- 默认字体，可按需修改
    size = size or 18              -- 默认字号
    if isLegacyChat then
        -- 旧版不支持多色，直接发送原文本（灰色）
        SystemNotification.Send(message, Color3.fromRGB(200,200,200))
    else
        local rich = rainbowGradient(message, font, size)
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            channel:DisplaySystemMessage(rich)
        end
    end
end

-- 红色渐变（从浅红到深红）
local function redGradient(text, font, size)
    local len = #text
    if len == 0 then return "" end

    local parts = {}
    for i = 1, len do
        -- 亮度因子：0~1，从亮(0.9)到暗(0.4)或从亮到暗均可
        local t = (i - 1) / (len - 1)   -- 0~1
        -- 亮红 (255,100,100) 到 深红 (180,0,0)
        local r = math.floor(255 - t * 75)    -- 255 -> 180
        local g = math.floor(100 - t * 100)   -- 100 -> 0
        local b = math.floor(100 - t * 100)   -- 100 -> 0
        local char = text:sub(i, i)
        local escaped = char:gsub("[<>&]", {
            ["<"] = "&lt;",
            [">"] = "&gt;",
            ["&"] = "&amp;"
        })
        parts[#parts + 1] = string.format('<font color="rgb(%d,%d,%d)" face="%s" size="%d">%s</font>',
            r, g, b, font, size, escaped)
    end
    return table.concat(parts)
end

-- 红色渐变预设（卸载专用）
function SystemNotification.UnloadedGradient(message, font, size)
    font = font or "SourceSansBold"
    size = size or 16
    if isLegacyChat then
        SystemNotification.Send(message, Color3.fromRGB(255, 100, 100))
    else
        local rich = redGradient(message, font, size)
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            channel:DisplaySystemMessage(rich)
        end
    end
end

-- 完全自定义（颜色、字体、字号）
function SystemNotification.Custom(message, colorRGB, font, size)
    send(message, colorRGB, font, size)
end

return SystemNotification