-- 将此脚本放在StarterCharacterScripts中
-- 跳跃落地光环特效模块

local LandingEffect = {}

-- 内部状态
local enabled = false
local connections = {}
local tweenService = game:GetService("TweenService")
local debrisService = game:GetService("Debris")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

-- 特效设置
local PARTICLE_SETTINGS = {
    Color = Color3.fromRGB(100, 150, 255),
    Material = Enum.Material.Neon,
    Transparency = 0.3,
    CanCollide = false,
    Anchored = true,
    CastShadow = false
}

-- 动画设置
local ANIMATION_SETTINGS = {
    StartRadius = 1,
    EndRadius = 6,
    Duration = 1.0
}

-- 内部变量
local player = game.Players.LocalPlayer
local character = nil
local humanoid = nil
local humanoidRootPart = nil
local wasJumping = false
local jumpStartTime = 0

-- 简化版初始化角色
local function initCharacter()
    -- 获取当前角色
    character = player.Character
    
    if character then
        -- 角色已存在，直接设置
        humanoid = character:WaitForChild("Humanoid")
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        print("角色已初始化:", character.Name)
        return true
    else
        -- 角色不存在，等待角色添加
        print("等待角色加载...")
        return false
    end
end

-- 创建特效函数
local function createLandingEffect(position)
    -- 使用TweenService创建平滑动画
    local ring = Instance.new("Part")
    ring.Name = "LandingRing"
    
    -- 应用设置
    for prop, value in pairs(PARTICLE_SETTINGS) do
        ring[prop] = value
    end
    
    -- 设置形状和初始大小
    ring.Shape = Enum.PartType.Cylinder
    local startSize = ANIMATION_SETTINGS.StartRadius * 2
    ring.Size = Vector3.new(0.1, startSize, startSize)
    
    -- 设置位置和旋转
    ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    ring.Parent = workspace
    
    -- 添加发光效果
    local pointLight = Instance.new("PointLight")
    pointLight.Color = PARTICLE_SETTINGS.Color
    pointLight.Brightness = 1.5
    pointLight.Range = 8
    pointLight.Parent = ring
    
    -- 设置Tween动画
    local tweenInfo = TweenInfo.new(
        ANIMATION_SETTINGS.Duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    -- 大小变化目标
    local endSize = ANIMATION_SETTINGS.EndRadius * 2
    local sizeGoal = {Size = Vector3.new(0.1, endSize, endSize)}
    
    -- 透明度变化目标
    local transparencyGoal = {Transparency = 1}
    
    -- 灯光亮度变化目标
    local lightGoal = {Brightness = 0}
    
    -- 创建并播放Tween
    local sizeTween = tweenService:Create(ring, tweenInfo, sizeGoal)
    local transparencyTween = tweenService:Create(ring, tweenInfo, transparencyGoal)
    local lightTween = tweenService:Create(pointLight, tweenInfo, lightGoal)
    
    sizeTween:Play()
    transparencyTween:Play()
    lightTween:Play()
    
    -- 使用Debris服务自动清理
    debrisService:AddItem(ring, ANIMATION_SETTINGS.Duration + 0.5)
end

-- 跳跃检测逻辑
local function setupJumpDetection()
    if not character or not humanoid then
        print("未找到角色或Humanoid，无法设置跳跃检测")
        return false
    end
    
    -- 重置跳跃状态
    wasJumping = false
    jumpStartTime = 0
    
    -- 方法1: 使用Heartbeat检测
    local heartbeatConnection = runService.Heartbeat:Connect(function()
        if not humanoid or not humanoidRootPart then 
            -- 如果humanoid或humanoidRootPart丢失，尝试重新获取
            if character and character.Parent then
                humanoid = character:FindFirstChild("Humanoid")
                humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            end
            if not humanoid or not humanoidRootPart then
                return
            end
        end
        
        local state = humanoid:GetState()
        
        -- 检测跳跃开始
        if state == Enum.HumanoidStateType.Jumping and not wasJumping then
            wasJumping = true
            jumpStartTime = tick()
            
        -- 检测落地（从跳跃状态变为非跳跃状态）
        elseif wasJumping and state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
            local jumpDuration = tick() - jumpStartTime
            
            -- 确保是真正的跳跃（不是摔倒或其他动作）
            if jumpDuration > 0.2 and jumpDuration < 2 then
                createLandingEffect(humanoidRootPart.Position - Vector3.new(0, 3, 0))
            end
            
            wasJumping = false
        end
    end)
    
    table.insert(connections, heartbeatConnection)
    
    -- 方法2: 使用StateChanged事件作为备用
    local stateChangedConnection = humanoid.StateChanged:Connect(function(oldState, newState)
        -- 当从跳跃状态变为站立或跑步时，触发特效
        if oldState == Enum.HumanoidStateType.Jumping and 
           (newState == Enum.HumanoidStateType.Running or 
            newState == Enum.HumanoidStateType.RunningNoPhysics or
            newState == Enum.HumanoidStateType.Climbing or
            newState == Enum.HumanoidStateType.Seated or
            newState == Enum.HumanoidStateType.Landed) then
            
            local jumpDuration = tick() - jumpStartTime
            
            if jumpDuration > 0.2 and jumpDuration < 2 then
                createLandingEffect(humanoidRootPart.Position - Vector3.new(0, 3, 0))
            end
        end
        
        -- 更新跳跃状态
        if newState == Enum.HumanoidStateType.Jumping then
            wasJumping = true
            jumpStartTime = tick()
        end
    end)
    
    table.insert(connections, stateChangedConnection)
    
    -- 监听角色死亡事件，以便重新初始化
    local diedConnection = humanoid.Died:Connect(function()
        print("角色死亡，等待重生...")
        wasJumping = false
        
        -- 重置引用
        character = nil
        humanoid = nil
        humanoidRootPart = nil
        
        -- 等待新角色
        local charAddedConnection
        charAddedConnection = player.CharacterAdded:Connect(function(newCharacter)
            -- 等待一小段时间让角色完全加载
            wait(0.5)
            
            character = newCharacter
            humanoid = character:WaitForChild("Humanoid")
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            
            print("角色重生完成:", character.Name)
            
            -- 重新设置跳跃检测
            if enabled then
                -- 先清理旧的连接
                for _, conn in ipairs(connections) do
                    if conn.Connected then
                        conn:Disconnect()
                    end
                end
                connections = {}
                
                -- 重新设置
                setupJumpDetection()
            end
            
            -- 断开这个一次性连接
            if charAddedConnection then
                charAddedConnection:Disconnect()
            end
        end)
    end)
    
    table.insert(connections, diedConnection)
    
    print("跳跃检测已设置")
    return true
end

-- 开启特效功能
function LandingEffect.enable()
    if enabled then
        print("特效功能已经开启")
        return
    end
    
    print("开启跳跃落地特效...")
    
    -- 初始化角色
    local charInitialized = initCharacter()
    
    if not charInitialized then
        -- 角色不存在，等待角色加载
        print("等待角色加载...")
        local charAddedConnection
        charAddedConnection = player.CharacterAdded:Connect(function(newCharacter)
            character = newCharacter
            humanoid = character:WaitForChild("Humanoid")
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            
            print("角色加载完成:", character.Name)
            
            -- 设置跳跃检测
            setupJumpDetection()
            
            -- 断开这个一次性连接
            if charAddedConnection then
                charAddedConnection:Disconnect()
            end
        end)
        
        -- 暂时保存这个连接，以便在disable时清理
        table.insert(connections, charAddedConnection)
    else
        -- 角色已存在，直接设置跳跃检测
        setupJumpDetection()
    end
    
    -- 设置手动测试快捷键
    local testConnection = userInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.G and character and humanoidRootPart then
            print("手动触发特效")
            createLandingEffect(humanoidRootPart.Position - Vector3.new(0, 3, 0))
        end
    end)
    
    table.insert(connections, testConnection)
    
    enabled = true
    print("跳跃落地特效已开启")
end

-- 关闭特效功能
function LandingEffect.disable()
    if not enabled then
        print("特效功能已经关闭")
        return
    end
    
    print("关闭跳跃落地特效...")
    
    -- 断开所有连接
    for _, connection in ipairs(connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    
    -- 清空连接表
    connections = {}
    
    -- 重置状态
    wasJumping = false
    enabled = false
    
    print("跳跃落地特效已关闭")
end

-- 完全卸载脚本
function LandingEffect.unload()
    print("卸载跳跃落地特效脚本...")
    
    -- 先禁用
    LandingEffect.disable()
    
    -- 清除所有引用
    character = nil
    humanoid = nil
    humanoidRootPart = nil
    
    -- 清空模块函数
    for key in pairs(LandingEffect) do
        LandingEffect[key] = nil
    end
    
    -- 设置模块为已卸载
    setmetatable(LandingEffect, {
        __index = function()
            error("LandingEffect模块已被卸载")
        end
    })
    
    print("跳跃落地特效脚本已完全卸载")
end

-- 添加一个检查状态的方法
function LandingEffect.isEnabled()
    return enabled
end

-- 添加一个测试方法
function LandingEffect.test()
    if character and humanoidRootPart then
        print("测试特效...")
        createLandingEffect(humanoidRootPart.Position - Vector3.new(0, 3, 0))
    else
        print("无法测试: 角色未加载")
    end
end

print("跳跃落地特效模块加载完成（默认关闭）")
print("使用方法: LandingEffect.enable() 开启特效")
print("按G键可以手动触发特效")

return LandingEffect