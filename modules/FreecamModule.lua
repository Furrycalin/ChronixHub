-- FreeCam 模块 v1.0
-- 提供 enable(), disable(), unload() 三个公共方法

local FreeCam = {}

-- 服务引用
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- 私有变量
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 状态变量
local freecamEnabled = false
local cameraRotation = Vector2.new()
local freecamConnection = nil
local charLock = nil
local moveVector = Vector3.new()

-- 事件连接存储
local eventConnections = {}

-- 配置
local DEFAULT_SPEED = 1.0
local cameraSpeed = DEFAULT_SPEED
local lookSensitivity = 50
local WHEEL_SENSITIVITY = 0.1

-- ========== 私有方法 ==========

local function getRootPart()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function lockCharacter()
    local root = getRootPart()
    if not root or charLock then return end
    
    charLock = Instance.new("BodyPosition")
    charLock.Name = "FreeCamLock"
    charLock.Position = root.Position
    charLock.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    charLock.D = 100
    charLock.P = 5000
    charLock.Parent = root
end

local function unlockCharacter()
    if charLock then
        charLock:Destroy()
        charLock = nil
    end
end

local function adjustSpeedWithMouseWheel(delta)
    if not freecamEnabled then return end
    
    if delta > 0 then
        cameraSpeed = cameraSpeed * (1 + WHEEL_SENSITIVITY)
    else
        cameraSpeed = cameraSpeed * (1 - WHEEL_SENSITIVITY)
    end
    
    cameraSpeed = math.max(0, cameraSpeed)
end

local function updateFreecam(dt)
    if not freecamEnabled then return end
    
    local moveSpeed = cameraSpeed * 50
    local currentMoveVector = moveVector
    
    if UserInputService:IsKeyDown(Enum.KeyCode.E) then
        currentMoveVector += Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
        currentMoveVector += Vector3.new(0, -1, 0)
    end
    
    local mouseDelta = UserInputService:GetMouseDelta()
    local sensitivity = lookSensitivity * 0.004
    
    cameraRotation += Vector2.new(
        -math.rad(mouseDelta.Y * sensitivity),
        -math.rad(mouseDelta.X * sensitivity)
    )
    
    cameraRotation = Vector2.new(
        math.clamp(cameraRotation.X, -math.pi/2, math.pi/2),
        cameraRotation.Y
    )
    
    local rotation = CFrame.fromEulerAnglesYXZ(cameraRotation.X, cameraRotation.Y, 0)
    local position = Camera.CFrame.Position
    
    if currentMoveVector.Magnitude > 0.01 and cameraSpeed > 0 then
        position += rotation:VectorToWorldSpace(currentMoveVector.Unit) * moveSpeed * dt
    end
    
    Camera.CFrame = CFrame.new(position) * rotation
end

local function onKeyPress(input, gameProcessed)
    if gameProcessed or UserInputService:GetFocusedTextBox() then return end
    
    -- F键切换自由相机
    if input.KeyCode == Enum.KeyCode.F then
        if freecamEnabled then
            FreeCam.disable()
        else
            FreeCam.enable()
        end
        return
    end
    
    if not freecamEnabled then return end
    
    local key = input.KeyCode
    if key == Enum.KeyCode.W then
        moveVector += Vector3.new(0, 0, -1)
    elseif key == Enum.KeyCode.S then
        moveVector += Vector3.new(0, 0, 1)
    elseif key == Enum.KeyCode.A then
        moveVector += Vector3.new(-1, 0, 0)
    elseif key == Enum.KeyCode.D then
        moveVector += Vector3.new(1, 0, 0)
    end
end

local function onKeyRelease(input, gameProcessed)
    if gameProcessed or not freecamEnabled then return end
    
    local key = input.KeyCode
    if key == Enum.KeyCode.W then
        moveVector -= Vector3.new(0, 0, -1)
    elseif key == Enum.KeyCode.S then
        moveVector -= Vector3.new(0, 0, 1)
    elseif key == Enum.KeyCode.A then
        moveVector -= Vector3.new(-1, 0, 0)
    elseif key == Enum.KeyCode.D then
        moveVector -= Vector3.new(1, 0, 0)
    end
end

local function onMouseWheel(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        adjustSpeedWithMouseWheel(input.Position.Z)
    end
end

local function onCharacterAdded(character)
    task.wait(0.5)
    
    if freecamEnabled then
        FreeCam.disable()
    else
        unlockCharacter()
    end
    
    local humanoid = character:WaitForChild("Humanoid", 2)
    if humanoid then
        Camera.CameraSubject = humanoid
        Camera.CameraType = Enum.CameraType.Custom
    end
end

local function onCharacterRemoving()
    if freecamEnabled then
        FreeCam.disable()
    else
        unlockCharacter()
    end
end

-- ========== 公共方法 ==========

-- 启用自由相机
function FreeCam.enable()
    if freecamEnabled then return end
    
    freecamEnabled = true
    cameraSpeed = DEFAULT_SPEED
    
    lockCharacter()
    
    local _, yaw, pitch = Camera.CFrame:ToEulerAnglesYXZ()
    cameraRotation = Vector2.new(pitch, yaw)
    
    Camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    
    freecamConnection = RunService.RenderStepped:Connect(updateFreecam)
    
    return true
end

-- 禁用自由相机
function FreeCam.disable()
    if not freecamEnabled then return end
    
    freecamEnabled = false
    
    if freecamConnection then
        freecamConnection:Disconnect()
        freecamConnection = nil
    end
    
    unlockCharacter()
    
    Camera.CameraType = Enum.CameraType.Custom
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    moveVector = Vector3.new()
    
    return true
end

-- 完全卸载模块
function FreeCam.unload()
    -- 先禁用自由相机
    FreeCam.disable()
    
    -- 断开所有事件连接
    for _, connection in pairs(eventConnections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(eventConnections)
    
    -- 清理角色锁定
    unlockCharacter()
    
    -- 重置所有状态变量
    freecamEnabled = false
    cameraRotation = Vector2.new()
    moveVector = Vector3.new()
    cameraSpeed = DEFAULT_SPEED
    
    -- 确保相机控制权交还引擎
    if Camera then
        Camera.CameraType = Enum.CameraType.Custom
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                Camera.CameraSubject = humanoid
            end
        end
    end
    
    -- 恢复鼠标行为
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    print("FreeCam 模块已卸载")
    
    return true
end

-- ========== 模块初始化 ==========

-- 设置事件监听
table.insert(eventConnections, UserInputService.InputBegan:Connect(onKeyPress))
table.insert(eventConnections, UserInputService.InputEnded:Connect(onKeyRelease))
table.insert(eventConnections, UserInputService.InputChanged:Connect(onMouseWheel))
table.insert(eventConnections, LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
table.insert(eventConnections, LocalPlayer.CharacterRemoving:Connect(onCharacterRemoving))

-- 模块信息
FreeCam.version = "1.0"
FreeCam.author = "FreeCam Module"
FreeCam.description = "提供自由相机功能，支持角色锁定和滚轮调速"

print("FreeCam 模块已加载")
print("版本: " .. FreeCam.version)
print("使用方法:")
print("  FreeCam.enable()  -- 启用自由相机")
print("  FreeCam.disable() -- 禁用自由相机")
print("  FreeCam.unload()  -- 完全卸载模块")
print("默认快捷键: F键切换自由相机")

return FreeCam