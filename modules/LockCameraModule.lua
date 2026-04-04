--[[
    LockCameraModule
    功能：按住指定按键时，锁定相机朝向（跟随角色移动，但世界方向不变），松开恢复。
    提供方法：enable(), disable(), getBindKey(), setBindKey(key), unload()
    默认按键：Enum.KeyCode.Tab（并阻止游戏默认的 Tab 行为）
--]]

local LockCameraModule = {}

-- 私有变量
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local camera = workspace.CurrentCamera

local isEnabled = false          -- 功能是否启用
local isLocking = false          -- 当前是否处于锁定状态
local bindKey = Enum.KeyCode.Tab -- 默认按键
local lockedCameraCFrame = nil   -- 按下瞬间相机的世界 CFrame
local lockedCharacterHRP = nil   -- 按下瞬间角色的 HumanoidRootPart CFrame

-- 事件连接
local inputBeganConn = nil
local inputEndedConn = nil
local renderStepConn = nil
local characterAddedConn = nil

-- 辅助函数：获取角色的 HumanoidRootPart
local function getHRP()
    local char = Players.LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- 每帧更新相机（仅在锁定时调用）
local function updateCamera()
    if not isLocking then return end
    local hrp = getHRP()
    if not hrp or not lockedCharacterHRP or not lockedCameraCFrame then return end

    -- 计算按下瞬间相机相对于角色根部的世界偏移向量
    local offsetVector = lockedCameraCFrame.Position - lockedCharacterHRP.Position
    -- 相机新位置 = 当前角色位置 + 原偏移
    local newPosition = hrp.Position + offsetVector
    -- 相机朝向保持按下瞬间的朝向（绝对方向不变）
    local newCFrame = CFrame.lookAt(newPosition, newPosition + lockedCameraCFrame.LookVector)
    camera.CFrame = newCFrame
end

-- 按键按下回调
local function onInputBegan(input, gameProcessed)
    -- 如果功能未启用，或输入已被游戏处理（如输入框），则忽略
    if not isEnabled or gameProcessed then return end
    if input.KeyCode == bindKey then
        -- 阻止游戏的默认行为（例如 Tab 打开排行榜）
        input.Handled = true

        local hrp = getHRP()
        if hrp then
            lockedCharacterHRP = hrp.CFrame
            lockedCameraCFrame = camera.CFrame
            isLocking = true
            -- 绑定渲染步骤，优先级高于默认相机
            if not renderStepConn then
                renderStepConn = RunService:BindToRenderStep("CameraLock", Enum.RenderPriority.Camera.Value + 1, updateCamera)
            end
        end
    end
end

-- 按键松开回调
local function onInputEnded(input, gameProcessed)
    if not isEnabled or gameProcessed then return end
    if input.KeyCode == bindKey then
        input.Handled = true
        isLocking = false
        lockedCharacterHRP = nil
        lockedCameraCFrame = nil
        if renderStepConn then
            RunService:UnbindFromRenderStep("CameraLock")
            renderStepConn = nil
        end
    end
end

-- 角色重生时重置锁定状态
local function onCharacterAdded()
    if isLocking then
        isLocking = false
        lockedCharacterHRP = nil
        lockedCameraCFrame = nil
        if renderStepConn then
            RunService:UnbindFromRenderStep("CameraLock")
            renderStepConn = nil
        end
    end
end

-- 内部清理所有连接
local function cleanupConnections()
    if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
    if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
    if characterAddedConn then characterAddedConn:Disconnect() characterAddedConn = nil end
    if renderStepConn then
        RunService:UnbindFromRenderStep("CameraLock")
        renderStepConn = nil
    end
end

-- 内部设置监听（根据 isEnabled 状态）
local function setupListeners()
    if not isEnabled then
        -- 如果已禁用，确保清理所有事件和锁定状态
        cleanupConnections()
        isLocking = false
        lockedCharacterHRP = nil
        lockedCameraCFrame = nil
        return
    end
    -- 启用状态：若尚未监听，则创建监听
    if not inputBeganConn then
        inputBeganConn = UserInputService.InputBegan:Connect(onInputBegan)
    end
    if not inputEndedConn then
        inputEndedConn = UserInputService.InputEnded:Connect(onInputEnded)
    end
    if not characterAddedConn then
        characterAddedConn = Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    end
end

-- 公开方法
function LockCameraModule.enable()
    if isEnabled then return end
    isEnabled = true
    setupListeners()
end

function LockCameraModule.disable()
    if not isEnabled then return end
    isEnabled = false
    -- 如果当前正在锁定，先强制解锁
    if isLocking then
        isLocking = false
        lockedCharacterHRP = nil
        lockedCameraCFrame = nil
        if renderStepConn then
            RunService:UnbindFromRenderStep("CameraLock")
            renderStepConn = nil
        end
    end
    setupListeners() -- 这会清理所有连接
end

function LockCameraModule.getBindKey()
    return bindKey
end

function LockCameraModule.setBindKey(newKey)
    if type(newKey) == "string" then
        -- 支持传入字符串，如 "LeftControl"，转换为枚举
        newKey = Enum.KeyCode[newKey]
    end
    if not newKey or not newKey.Name then
        error("无效的按键，请传入 Enum.KeyCode 或字符串名称")
    end
    bindKey = newKey
end

function LockCameraModule.unload()
    -- 禁用功能并彻底清理所有事件和状态
    if isEnabled then
        LockCameraModule.disable()
    end
    cleanupConnections()
    -- 清空模块方法，防止后续调用
    LockCameraModule.enable = nil
    LockCameraModule.disable = nil
    LockCameraModule.getBindKey = nil
    LockCameraModule.setBindKey = nil
    LockCameraModule.unload = nil
end

return LockCameraModule