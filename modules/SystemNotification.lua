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

-- HTML 转义 (防止用户输入破坏富文本)
local function escapeHtml(text)
	return text:gsub("[<>&]", {
		["<"] = "&lt;",
		[">"] = "&gt;",
		["&"] = "&amp;"
	})
end

-- 构建富文本字符串 (新版聊天)
local function buildRichText(text, style)
	-- 颜色转换 (Color3 -> 0-255整数)
	local r = math.floor((style.color.R or 1) * 255)
	local g = math.floor((style.color.G or 1) * 255)
	local b = math.floor((style.color.B or 1) * 255)
	local colorAttr = string.format('color="rgb(%d,%d,%d)"', r, g, b)
	
	-- 字体属性
	local fontAttr = style.font and string.format(' face="%s"', style.font) or ""
	
	-- 字号属性 (数字或字符串)
	local sizeAttr = ""
	if style.size then
		if type(style.size) == "number" then
			sizeAttr = string.format(' size="%d"', style.size)
		else
			sizeAttr = string.format(' size="%s"', tostring(style.size))
		end
	end
	
	-- 构建 <font> 标签
	local result = string.format('<font%s%s%s>', colorAttr, fontAttr, sizeAttr)
	
	-- 粗体/斜体
	if style.bold then result = result .. "<b>" end
	if style.italic then result = result .. "<i>" end
	
	-- 文本内容 (转义)
	result = result .. escapeHtml(text)
	
	-- 关闭粗体/斜体
	if style.italic then result = result .. "</i>" end
	if style.bold then result = result .. "</b>" end
	
	-- 关闭 </font>
	result = result .. "</font>"
	
	return result
end

-- 内部发送函数
local function sendMessage(text, style)
	if isLegacyChat then
		-- 旧聊天系统：仅支持颜色，忽略字体/字号/粗斜体
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

-- 公开接口：基础发送（支持自定义样式）
function SystemNotification.Send(Text, Style)
	local finalStyle = {}
	if typeof(Style) == "Color3" then
		-- 仅颜色：合并默认样式
		finalStyle = table.clone(defaultStyles.Default)
		finalStyle.color = Style
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