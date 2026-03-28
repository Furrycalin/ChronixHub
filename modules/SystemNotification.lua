-- SystemNotification.lua (必须运行在 LocalScript)
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

local SystemNotification = {}

-- 默认样式表 (新版聊天使用)
local defaultStyles = {
	Success = {
		color = Color3.fromRGB(0, 255, 0),
		font = "GothamBold",
		size = 18,
		bold = true,
		italic = false,
	},
	Warning = {
		color = Color3.fromRGB(255, 200, 0),
		font = "SourceSansBold",
		size = 16,
		bold = true,
		italic = false,
	},
	Error = {
		color = Color3.fromRGB(255, 0, 0),
		font = "GothamBold",
		size = 20,
		bold = true,
		italic = true,
	},
	Info = {
		color = Color3.fromRGB(100, 150, 255),
		font = "SourceSans",
		size = 14,
		bold = false,
		italic = false,
	},
	Default = {
		color = Color3.fromRGB(255, 255, 255),
		font = "SourceSans",
		size = 14,
		bold = false,
		italic = false,
	}
}

-- 构建富文本字符串 (新版聊天)
local function buildRichText(text, style)
	local parts = {}
	
	-- 颜色
	local r = math.floor((style.color.R or 1) * 255)
	local g = math.floor((style.color.G or 1) * 255)
	local b = math.floor((style.color.B or 1) * 255)
	local colorAttr = string.format('color="rgb(%d,%d,%d)"', r, g, b)
	
	-- 字体
	local fontAttr = ""
	if style.font then
		fontAttr = string.format(' face="%s"', style.font)
	end
	
	-- 字号 (支持数字或相对值，如"+2")
	local sizeAttr = ""
	if style.size then
		if type(style.size) == "number" then
			sizeAttr = string.format(' size="%d"', style.size)
		else
			sizeAttr = string.format(' size="%s"', tostring(style.size))
		end
	end
	
	-- 打开 <font> 标签
	parts[#parts+1] = string.format('<font%s%s%s>', colorAttr, fontAttr, sizeAttr)
	
	-- 粗体/斜体
	if style.bold then
		parts[#parts+1] = "<b>"
	end
	if style.italic then
		parts[#parts+1] = "<i>"
	end
	
	-- 文本内容 (转义HTML字符)
	local escapedText = text:gsub("[<>&]", {
		["<"] = "&lt;",
		[">"] = "&gt;",
		["&"] = "&amp;"
	})
	parts[#parts+1] = escapedText
	
	-- 关闭粗体/斜体
	if style.italic then
		parts[#parts+1] = "</i>"
	end
	if style.bold then
		parts[#parts+1] = "</b>"
	end
	
	-- 关闭 </font>
	parts[#parts+1] = "</font>"
	
	return table.concat(parts)
end

-- 内部发送函数 (支持样式表或直接传入样式)
local function sendMessage(text, style)
	if isLegacyChat then
		-- 旧聊天系统：仅使用颜色，忽略字体字号
		local player = Players.LocalPlayer
		if not player then return end
		local gui = player:WaitForChild("PlayerGui")
		pcall(function()
			gui:SetCore("ChatMakeSystemMessage", {
				Text = text,
				Color = style.color or Color3.fromRGB(255, 255, 255)
			})
		end)
	else
		-- 新版聊天系统：使用富文本
		local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
		if channel then
			local richText = buildRichText(text, style)
			channel:DisplaySystemMessage(richText)
		else
			warn("[SystemNotification] 未找到 RBXGeneral 聊天通道")
		end
	end
end

-- 公开接口：基础发送（自定义样式）
function SystemNotification.Send(Text, Style)
	-- Style 可以是颜色 (Color3) 或完整样式表
	local finalStyle = {}
	if typeof(Style) == "Color3" then
		finalStyle = { color = Style, font = defaultStyles.Default.font, size = defaultStyles.Default.size, bold = false, italic = false }
	elseif type(Style) == "table" then
		finalStyle = table.clone(defaultStyles.Default)
		for k, v in pairs(Style) do
			finalStyle[k] = v
		end
	else
		finalStyle = table.clone(defaultStyles.Default)
	end
	sendMessage(Text, finalStyle)
end

-- 预设方法 (支持覆盖样式)
function SystemNotification.Success(Text, overrides)
	local style = table.clone(defaultStyles.Success)
	if overrides then
		for k, v in pairs(overrides) do
			style[k] = v
		end
	end
	sendMessage(Text, style)
end

function SystemNotification.Warning(Text, overrides)
	local style = table.clone(defaultStyles.Warning)
	if overrides then
		for k, v in pairs(overrides) do
			style[k] = v
		end
	end
	sendMessage(Text, style)
end

function SystemNotification.Error(Text, overrides)
	local style = table.clone(defaultStyles.Error)
	if overrides then
		for k, v in pairs(overrides) do
			style[k] = v
		end
	end
	sendMessage(Text, style)
end

function SystemNotification.Info(Text, overrides)
	local style = table.clone(defaultStyles.Info)
	if overrides then
		for k, v in pairs(overrides) do
			style[k] = v
		end
	end
	sendMessage(Text, style)
end

-- 高级自定义 (完全控制样式)
function SystemNotification.Custom(Text, customStyle)
	local finalStyle = table.clone(defaultStyles.Default)
	if customStyle then
		for k, v in pairs(customStyle) do
			finalStyle[k] = v
		end
	end
	sendMessage(Text, finalStyle)
end

return SystemNotification