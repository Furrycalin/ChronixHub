local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local module = {}

local enabled = false
local moveDistance = 10
local connection = nil

-- 辅助函数：获取角色根部件
local function getRootPart(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
end

-- 处理输入
local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end -- 如果已经被游戏处理（比如聊天输入），忽略
    if not enabled then return end
    if UserInputService:GetFocusedTextBox() then return end -- 如果正在输入文本，忽略
    
    local keyCode = input.KeyCode
    if not (keyCode == Enum.KeyCode.Up or keyCode == Enum.KeyCode.Down or
            keyCode == Enum.KeyCode.Left or keyCode == Enum.KeyCode.Right) then
        return
    end
    
    local character = localPlayer.Character
    if not character then return end
    local rootPart = getRootPart(character)
    if not rootPart then return end
    
    local moveVec
    if keyCode == Enum.KeyCode.Up then
        moveVec = rootPart.CFrame.LookVector * moveDistance
    elseif keyCode == Enum.KeyCode.Down then
        moveVec = -rootPart.CFrame.LookVector * moveDistance
    elseif keyCode == Enum.KeyCode.Left then
        moveVec = -rootPart.CFrame.RightVector * moveDistance
    elseif keyCode == Enum.KeyCode.Right then
        moveVec = rootPart.CFrame.RightVector * moveDistance
    end
    
    -- 保持Y轴不变
    moveVec = Vector3.new(moveVec.X, 0, moveVec.Z)
    
    -- 移动根部件
    rootPart.CFrame = rootPart.CFrame + moveVec
end

-- 启用功能
function module.Enable()
    if enabled then return end
    enabled = true
    if not connection then
        connection = UserInputService.InputBegan:Connect(onInputBegan)
    end
end

-- 禁用功能
function module.Disable()
    enabled = false
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

-- 设置移动距离
function module.SetDistance(distance)
    assert(type(distance) == "number" and distance >= 0, "Distance must be a non-negative number")
    moveDistance = distance
end

-- 获取移动距离
function module.GetDistance()
    return moveDistance
end

return module