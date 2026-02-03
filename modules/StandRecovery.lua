-- 1. 创建封装表（核心，所有功能、属性都挂载在这个表上）
local StandRecovery = {}

-- 2. 封装私有/公有属性（通过 self 访问）
function StandRecovery:init()
    -- 服务引用
    self.Players = game:GetService("Players")
    self.localPlayer = self.Players.LocalPlayer
    if not self.localPlayer then
        warn("[站立恢复模块] 无法获取本地玩家，初始化失败")
        self.initialized = false
        return
    end

    -- 核心配置（可外部修改）
    self.DEFAULT_WALK_SPEED = 16
    self.DEFAULT_JUMP_POWER = 50
    self.CHECK_INTERVAL = 0.05
    self.SPEED_THRESHOLD = 50
    self.RESTORE_REPEAT_TIMES = 3
    self.RESTORE_REPEAT_INTERVAL = 0.05

    -- 状态变量
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
    self.isDetectionEnabled = false -- 默认关闭
    self.initialized = true -- 初始化完成标记

    -- 初始化角色绑定
    self:bindCharacterAndComponents(self.localPlayer.Character)
    self.localPlayer.CharacterAdded:Connect(function(newCharacter)
        self:bindCharacterAndComponents(newCharacter)
    end)

    -- 启动主循环（封装为方法）
    self:startMainLoop()

    print("[站立恢复模块] 初始化完成，检测功能默认关闭（调用 :enableDetection() 开启）")
end

-- 3. 核心方法：绑定角色及核心组件
function StandRecovery:bindCharacterAndComponents(newCharacter)
    if not self.initialized then return end
    if not newCharacter then
        warn("[站立恢复模块] 角色对象为空，绑定失败")
        self.character = nil
        self.humanoid = nil
        self.humanoidRootPart = nil
        return
    end

    -- 更新角色引用
    self.character = newCharacter
    print(string.format("[站立恢复模块] 已绑定角色：%s", self.character.Name))

    -- 等待并获取 Humanoid
    local success1, tempHumanoid = pcall(function()
        return self.character:WaitForChild("Humanoid")
    end)

    -- 等待并获取 HumanoidRootPart
    local success2, tempRootPart = pcall(function()
        return self.character:WaitForChild("HumanoidRootPart")
    end)

    -- 验证并更新组件引用
    if not success1 or not tempHumanoid then
        warn("[站立恢复模块] 无法获取角色 Humanoid 组件")
        self.humanoid = nil
    else
        self.humanoid = tempHumanoid
        self.humanoid.AutoRotate = true
        print("[站立恢复模块] Humanoid 组件绑定成功")
    end

    if not success2 or not tempRootPart then
        warn("[站立恢复模块] 无法获取角色 HumanoidRootPart 组件")
        self.humanoidRootPart = nil
    else
        self.humanoidRootPart = tempRootPart
        print("[站立恢复模块] HumanoidRootPart 组件绑定成功")
    end
end

-- 4. 辅助方法：判定是否失控
function StandRecovery:isUncontrollable()
    if not self.initialized or not self.isDetectionEnabled then
        return false
    end
    if not self.character or not self.humanoid or not self.humanoidRootPart or self.humanoid.Health <= 0 then
        return false
    end

    local abnormalStates = {
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.Flying,
        Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.Seated
    }
    local inAbnormalState = table.find(abnormalStates, self.humanoid:GetState()) ~= nil
    local inHighSpeed = self.humanoidRootPart.Velocity.Magnitude > self.SPEED_THRESHOLD
    local inLockedState = self.humanoid.PlatformStand or self.humanoid.WalkSpeed <= 0

    local isUncontrol = inAbnormalState or inHighSpeed or inLockedState
    if isUncontrol then
        print(string.format("[站立恢复模块] 检测到失控！状态：%s，速度：%.2f", 
            tostring(self.humanoid:GetState()), self.humanoidRootPart.Velocity.Magnitude))
    end
    return isUncontrol
end

-- 5. 辅助方法：单次恢复逻辑
function StandRecovery:singleRestore()
    if not self.initialized or not self.character or not self.humanoid or not self.humanoidRootPart then
        return false
    end

    -- 强制切换站立状态
    pcall(function()
        self.humanoid:ChangeState(Enum.HumanoidStateType.None)
        task.wait(0.001)
        self.humanoid:ChangeState(Enum.HumanoidStateType.Standing)
        self.humanoid:ChangeState(Enum.HumanoidStateType.Standing)
    end)

    -- 恢复移动参数
    self.humanoid.WalkSpeed = self.DEFAULT_WALK_SPEED
    self.humanoid.JumpPower = self.DEFAULT_JUMP_POWER
    self.humanoid.PlatformStand = false
    self.humanoid.AutoRotate = true
    self.humanoid.Health = math.min(self.humanoid.Health + 1, self.humanoid.MaxHealth)

    -- 清空惯性并临时固定位置
    self.humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    self.humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    local bodyPos = Instance.new("BodyPosition")
    bodyPos.Parent = self.humanoidRootPart
    bodyPos.Position = self.humanoidRootPart.Position
    bodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyPos.D = 100
    bodyPos.P = 5000
    task.delay(0.1, function()
        if bodyPos then bodyPos:Destroy() end
    end)

    -- 深度清理物理对象
    local removedCount = 0
    local function clearPhysicsObjects(obj)
        for _, child in pairs(obj:GetChildren()) do
            if child:IsA("BodyVelocity") or child:IsA("BodyForce") or child:IsA("BodyGyro") or child:IsA("BodyPosition") then
                pcall(function() child:Destroy() end)
                removedCount = removedCount + 1
            end
            clearPhysicsObjects(child)
        end
    end
    clearPhysicsObjects(self.character)

    -- 重置角色姿势
    local rootCF = self.humanoidRootPart.CFrame
    pcall(function()
        self.humanoidRootPart.CFrame = CFrame.new(rootCF.Position) * CFrame.Angles(0, rootCF:ToEulerAnglesYXZ().y, 0)
    end)

    if removedCount > 0 then
        print(string.format("[站立恢复模块] 单次恢复：清除 %d 个物理对象", removedCount))
    end
    return true
end

-- 6. 辅助方法：批量恢复逻辑
function StandRecovery:batchRestore()
    if not self.initialized or not self.isDetectionEnabled then
        return false
    end
    print("[站立恢复模块] 开始批量执行恢复逻辑（确保生效）")
    local successCount = 0

    for i = 1, self.RESTORE_REPEAT_TIMES do
        if self:singleRestore() then
            successCount = successCount + 1
        end
        task.wait(self.RESTORE_REPEAT_INTERVAL)
    end

    print(string.format("[站立恢复模块] 批量恢复完成，成功执行 %d 次", successCount))
    return successCount > 0
end

-- 7. 公有方法：开启检测（外部可调用）
function StandRecovery:enableDetection()
    if not self.initialized then
        warn("[站立恢复模块] 未初始化完成，无法开启检测")
        return
    end
    if self.isDetectionEnabled then
        print("[站立恢复模块] 检测功能已处于开启状态，无需重复开启")
        return
    end
    self.isDetectionEnabled = true
    print("[站立恢复模块] 检测功能已开启，将自动监控并恢复角色失控状态")
end

-- 8. 公有方法：关闭检测（外部可调用）
function StandRecovery:disableDetection()
    if not self.initialized then
        warn("[站立恢复模块] 未初始化完成，无法关闭检测")
        return
    end
    if not self.isDetectionEnabled then
        print("[站立恢复模块] 检测功能已处于关闭状态，无需重复关闭")
        return
    end
    self.isDetectionEnabled = false
    print("[站立恢复模块] 检测功能已关闭，不再监控角色失控状态")
end

-- 9. 私有方法：启动主检测循环
function StandRecovery:startMainLoop()
    if not self.initialized then return end
    task.spawn(function() -- 用 task.spawn 开启独立线程，避免阻塞
        while task.wait(self.CHECK_INTERVAL) do
            -- 开关关闭，跳过后续逻辑
            if not self.isDetectionEnabled then
                task.wait(0.1)
                continue
            end

            if not self.character or not self.humanoid or not self.humanoidRootPart then
                task.wait(0.1)
                continue
            end

            -- 检测失控并执行批量恢复
            if self:isUncontrollable() then
                pcall(function() self:batchRestore() end)
                -- 恢复后持续监控防复燃
                local guardTime = 0.5
                local guardStart = tick()
                while tick() - guardStart < guardTime and self.isDetectionEnabled do
                    if self:isUncontrollable() then
                        pcall(function() self:singleRestore() end)
                    end
                    task.wait(0.01)
                end
                task.wait(0.2)
            end
        end
    end)
end

-- 10. 初始化模块（自动执行）
StandRecovery:init()

-- 11. 返回封装表（外部 require 即可获取所有公有方法）
return StandRecovery