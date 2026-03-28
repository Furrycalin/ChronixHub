-- 系统通知模块（必须在 LocalScript 中使用）
local SystemNotification = {}

-- 发送系统通知（仅支持通用参数）
function SystemNotification.Send(Text, Color)
    Color = Color or Color3.fromRGB(255, 255, 255)

    -- 确保在客户端运行
    local player = game.Players.LocalPlayer
    if not player then
        warn("[SystemNotification] 只能在客户端 LocalScript 中使用")
        return
    end

    local gui = player:WaitForChild("PlayerGui")
    pcall(function()
        gui:SetCore("ChatMakeSystemMessage", {
            Text = Text,
            Color = Color
        })
    end)
end

-- 快捷方法
function SystemNotification.Success(Text)
    SystemNotification.Send(Text, Color3.fromRGB(0, 255, 0))
end

function SystemNotification.Warning(Text)
    SystemNotification.Send(Text, Color3.fromRGB(255, 200, 0))
end

function SystemNotification.Error(Text)
    SystemNotification.Send(Text, Color3.fromRGB(255, 0, 0))
end

function SystemNotification.Info(Text)
    SystemNotification.Send(Text, Color3.fromRGB(100, 150, 255))
end

return SystemNotification