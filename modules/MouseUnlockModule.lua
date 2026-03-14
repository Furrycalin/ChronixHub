local UserInputService = game:GetService("UserInputService")
local module = {}

-- 内部状态
local isEnabled = false                -- 整体功能开关
local isUnlocked = false               -- 当前是否处于解锁状态
local originalMouseBehavior = nil      -- 保存的原始鼠标行为（在首次解锁时记录）
local keyStates = { K = false, L = false }  -- 记录按键状态
local toggleTriggered = false           -- 防止同一组按键按下多次触发

-- 快捷键处理函数（绑定到 InputBegan/Ended）
local function onInputBegan(input, gameProcessed)
	if not isEnabled then return end
	if gameProcessed then return end
	if UserInputService:GetFocusedTextBox() then return end  -- 忽略聊天输入

	local key = input.KeyCode
	if key == Enum.KeyCode.K then
		keyStates.K = true
	elseif key == Enum.KeyCode.L then
		keyStates.L = true
	end

	-- 检查 K 和 L 是否同时按下
	if keyStates.K and keyStates.L and not toggleTriggered then
		toggleTriggered = true
		-- 切换解锁状态
		if isUnlocked then
			module.Restore()
		else
			module.Unlock()
		end
	end
end

local function onInputEnded(input, gameProcessed)
	if not isEnabled then return end
	local key = input.KeyCode
	if key == Enum.KeyCode.K then
		keyStates.K = false
		toggleTriggered = false
	elseif key == Enum.KeyCode.L then
		keyStates.L = false
		toggleTriggered = false
	end
end

-- 连接事件
local beganConn, endedConn

-- 启用整体功能：开始监听快捷键
function module.Enable()
	if isEnabled then return end
	isEnabled = true
	-- 重置按键状态
	keyStates.K = false
	keyStates.L = false
	toggleTriggered = false
	-- 连接输入事件
	beganConn = UserInputService.InputBegan:Connect(onInputBegan)
	endedConn = UserInputService.InputEnded:Connect(onInputEnded)
end

-- 禁用整体功能：停止监听，并恢复鼠标状态
function module.Disable()
	if not isEnabled then return end
	isEnabled = false
	-- 断开连接
	if beganConn then beganConn:Disconnect() beganConn = nil end
	if endedConn then endedConn:Disconnect() endedConn = nil end
	-- 如果当前处于解锁状态，恢复原始鼠标行为
	if isUnlocked then
		module.Restore()
	end
	-- 重置内部状态
	keyStates.K = false
	keyStates.L = false
	toggleTriggered = false
end

-- 解锁鼠标（设为 Default），首次解锁时保存原始值
function module.Unlock()
	if isUnlocked then return end
	-- 保存当前鼠标行为作为原始值（仅在第一次解锁时保存）
	if originalMouseBehavior == nil then
		originalMouseBehavior = UserInputService.MouseBehavior
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	isUnlocked = true
end

-- 恢复鼠标行为到原始状态（如果已解锁）
function module.Restore()
	if not isUnlocked then return end
	if originalMouseBehavior then
		UserInputService.MouseBehavior = originalMouseBehavior
	else
		-- 如果没有保存过原始值（理论上不会发生），设为默认
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	isUnlocked = false
	-- 注意：不清除 originalMouseBehavior，以便后续再次解锁时还能恢复相同状态
end

-- 可选：获取当前是否处于解锁状态
function module.IsUnlocked()
	return isUnlocked
end

-- 可选：获取整体功能是否启用
function module.IsEnabled()
	return isEnabled
end

return module