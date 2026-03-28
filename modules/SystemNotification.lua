-- SystemNotification.lua (必须运行在 LocalScript)
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

local SystemNotification = {}

-- 内部发送函数
local function sendMessage(text, color)
	if isLegacyChat then
		-- 旧聊天系统：使用 SetCore
		local player = Players.LocalPlayer
		if not player then return end
		local gui = player:WaitForChild("PlayerGui")
		pcall(function()
			gui:SetCore("ChatMakeSystemMessage", {
				Text = text,
				Color = color or Color3.fromRGB(255, 255, 255)
			})
		end)
	else
		-- 新版聊天系统：通过 TextChatService 发送系统消息
		-- 创建一个系统消息源（系统消息显示为灰色且不带头像）
		local systemSource = Instance.new("TextChatSource")
		systemSource.Name = "System"

		-- 发送系统消息（无需等待）
		TextChatService.TextChannels.RBXGeneral:SendAsync(text, systemSource)
	end
end

-- 公开接口
function SystemNotification.Send(Text, Color)
	sendMessage(Text, Color)
end

function SystemNotification.Success(Text)
	sendMessage(Text, Color3.fromRGB(0, 255, 0))
end

function SystemNotification.Warning(Text)
	sendMessage(Text, Color3.fromRGB(255, 200, 0))
end

function SystemNotification.Error(Text)
	sendMessage(Text, Color3.fromRGB(255, 0, 0))
end

function SystemNotification.Info(Text)
	sendMessage(Text, Color3.fromRGB(100, 150, 255))
end

return SystemNotification