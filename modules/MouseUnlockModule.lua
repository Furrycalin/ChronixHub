local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local module = {}

-- 内部状态
local isEnabled = false
local isUnlocked = false
local originalMouseBehavior = nil
local heartbeatConnection = nil
local keyStates = { K = false, L = false }
local toggleTriggered = false

-- 强制保持解锁状态的循环
local function enforceUnlock()
	if not isUnlocked then return end
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

-- 快捷键处理
local function onInputBegan(input, gameProcessed)
	if not isEnabled or gameProcessed then return end
	if UserInputService:GetFocusedTextBox() then return end

	local key = input.KeyCode
	if key == Enum.KeyCode.K then
		keyStates.K = true
	elseif key == Enum.KeyCode.L then
		keyStates.L = true
	end

	if keyStates.K and keyStates.L and not toggleTriggered then
		toggleTriggered = true
		if isUnlocked then
			module.Restore()
		else
			module.Unlock()
		end
	end
end

local function onInputEnded(input)
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

local beganConn, endedConn

function module.Enable()
	if isEnabled then return end
	isEnabled = true
	keyStates.K = false
	keyStates.L = false
	toggleTriggered = false
	beganConn = UserInputService.InputBegan:Connect(onInputBegan)
	endedConn = UserInputService.InputEnded:Connect(onInputEnded)
end

function module.Disable()
	if not isEnabled then return end
	isEnabled = false
	if beganConn then beganConn:Disconnect() beganConn = nil end
	if endedConn then endedConn:Disconnect() endedConn = nil end
	if isUnlocked then
		module.Restore()
	end
	keyStates.K = false
	keyStates.L = false
	toggleTriggered = false
end

function module.Unlock()
	if isUnlocked then return end
	if originalMouseBehavior == nil then
		originalMouseBehavior = UserInputService.MouseBehavior
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	isUnlocked = true
	if not heartbeatConnection then
		heartbeatConnection = RunService.Heartbeat:Connect(enforceUnlock)
	end
end

function module.Restore()
	if not isUnlocked then return end
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	if originalMouseBehavior then
		UserInputService.MouseBehavior = originalMouseBehavior
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	isUnlocked = false
end

function module.IsUnlocked()
	return isUnlocked
end

function module.IsEnabled()
	return isEnabled
end

return module