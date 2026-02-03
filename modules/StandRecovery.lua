-- 1. 创建封装表（核心，所有功能、属性都挂载在这个表上）
local StandRecovery = {}

-- 2. 封装私有/公有属性（新增正常跳跃流程标记）
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
    self.isUnloaded = false -- 卸载状态标记
    self.isLoopRunning = true -- 主循环运行标记
    self.characterAddedConnection = nil -- 角色绑定连接引用
    self.isNormalJumpProcess = false -- 新增：标记是否处于正常跳跃→下落的全程流程
    self.humanoidStateChangedConn = nil -- 新增：保存状态变化监听连接，用于后续断开

    -- 初始化角色绑定（保存连接引用，方便后续断开）
    self:bindCharacterAndComponents(self.localPlayer.Character)
    self.characterAddedConnection = self.localPlayer.CharacterAdded:Connect(function(newCharacter)
        self:bindCharacterAndComponents(newCharacter)
    end)

    -- 启动主循环（封装为方法）
    self:startMainLoop()

    print("[站立恢复模块] 初始化完成，检测功能默认关闭（调用 :enableDetection() 开启）")
end

-- 3. 核心方法：绑定角色及核心组件（新增状态变化监听，捕捉跳跃流程）
function StandRecovery:bindCharacterAndComponents(newCharacter)
    -- 卸载后禁止执行
    if not self.initialized or self.isUnloaded then return end
    if not newCharacter then
        warn("[站立恢复模块] 角色对象为空，绑定失败")
        self.character = nil
        self.humanoid = nil
        self.humanoidRootPart = nil
        self.isNormalJumpProcess = false -- 重置跳跃标记
        -- 断开旧的状态监听，防止内存泄漏
        if self.humanoidStateChangedConn then
            self.humanoidStateChangedConn:Disconnect()
            self.humanoidStateChangedConn = nil
        end
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
        -- 断开旧的状态监听
        if self.humanoidStateChangedConn then
            self.humanoidStateChangedConn:Disconnect()
            self.humanoidStateChangedConn = nil
        end
    else
        self.humanoid = tempHumanoid
        self.humanoid.AutoRotate = true
        print("[站立恢复模块] Humanoid 组件绑定成功")

        -- 重置跳跃标记
        self.isNormalJumpProcess = false

        -- 断开旧的状态监听，防止重复监听
        if self.humanoidStateChangedConn then
            self.humanoidStateChangedConn:Disconnect()
        end

        -- 新增：监听Humanoid状态变化，捕捉正常跳跃全程
        self.humanoidStateChangedConn = self.humanoid.StateChanged:Connect(function(oldState, newState)
            -- 防止卸载后继续监听
            if self.isUnloaded then
                self.humanoidStateChangedConn:Disconnect()
                return
            end

            -- 节点1：从站立进入跳跃（开始正常跳跃流程）
            if oldState == Enum.HumanoidStateType.Standing and newState == Enum.HumanoidStateType.Jumping then
                self.isNormalJumpProcess = true
            end

            -- 节点2：从下落回到站立（落地，结束正常跳跃流程）
            if oldState == Enum.HumanoidStateType.Freefall and newState == Enum.HumanoidStateType.Standing then
                self.isNormalJumpProcess = false
            end
        end)
    end

    if not success2 or not tempRootPart then
        warn("[站立恢复模块] 无法获取角色 HumanoidRootPart 组件")
        self.humanoidRootPart = nil
    else
        self.humanoidRootPart = tempRootPart
        print("[站立恢复模块] HumanoidRootPart 组件绑定成功")
    end
end

-- 4. 【核心修改】辅助方法：判定是否失控（排除正常跳跃全程，彻底解决下落检测）
function StandRecovery:isUncontrollable()
    -- 卸载后禁止执行
    if not self.initialized or self.isUnloaded or not self.isDetectionEnabled then
        return false
    end
    if not self.character or not self.humanoid or not self.humanoidRootPart or self.humanoid.Health <= 0 then
        return false
    end

    -- 新增：核心判断——如果处于正常跳跃全程（上升+下落），直接返回false，不检测
    if self.isNormalJumpProcess then
        return false
    end

    local abnormalStates = {
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.Flying,
        Enum.HumanoidStateType.Freefall, -- 保留该状态，仅排除正常跳跃导致的它
        Enum.HumanoidStateType.Seated
    }
    local currentState = self.humanoid:GetState()
    local inAbnormalState = table.find(abnormalStates, currentState) ~= nil
    local inHighSpeed = self.humanoidRootPart.Velocity.Magnitude > self.SPEED_THRESHOLD
    local inLockedState = self.humanoid.PlatformStand or self.humanoid.WalkSpeed <= 0

    local isUncontrol = inAbnormalState or inHighSpeed or inLockedState
    if isUncontrol then
        print(string.format("[站立恢复模块] 检测到失控！状态：%s，速度：%.2f", 
            tostring(currentState), self.humanoidRootPart.Velocity.Magnitude))
    end
    return isUncontrol
end

-- 5. 辅助方法：单次恢复逻辑（保持不变）
function StandRecovery:singleRestore()
    -- 卸载后禁止执行
    if not self.initialized or self.isUnloaded then
        return false
    end
    if not self.character or not self.humanoid or not self.humanoidRootPart then
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

-- 6. 辅助方法：批量恢复逻辑（保持不变）
function StandRecovery:batchRestore()
    -- 卸载后禁止执行
    if not self.initialized or self.isUnloaded or not self.isDetectionEnabled then
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

-- 7. 公有方法：开启检测（外部可调用，保持不变）
function StandRecovery:enableDetection()
    -- 卸载后禁止执行
    if not self.initialized or self.isUnloaded then
        warn("[站立恢复模块] 模块已卸载，无法开启检测")
        return
    end
    if self.isDetectionEnabled then
        print("[站立恢复模块] 检测功能已处于开启状态，无需重复开启")
        return
    end
    self.isDetectionEnabled = true
    print("[站立恢复模块] 检测功能已开启，将自动监控并恢复角色失控状态")
end

-- 8. 公有方法：关闭检测（外部可调用，保持不变）
function StandRecovery:disableDetection()
    -- 卸载后禁止执行
    if not self.initialized or self.isUnloaded then
        warn("[站立恢复模块] 模块已卸载，无法关闭检测")
        return
    end
    if not self.isDetectionEnabled then
        print("[站立恢复模块] 检测功能已处于关闭状态，无需重复关闭")
        return
    end
    self.isDetectionEnabled = false
    print("[站立恢复模块] 检测功能已关闭，不再监控角色失控状态")
end

-- 9. 公有方法：卸载脚本/模块（外部可调用，新增断开状态监听）
function StandRecovery:unload()
    -- 重复卸载提示
    if self.isUnloaded then
        print("[站立恢复模块] 模块已卸载，无需重复卸载")
        return
    end
    if not self.initialized then
        warn("[站立恢复模块] 模块未初始化完成，无需卸载")
        return
    end

    print("[站立恢复模块] 开始执行卸载流程...")

    -- 步骤1：标记为已卸载，禁止所有方法后续执行
    self.isUnloaded = true
    self.isDetectionEnabled = false
    self.isNormalJumpProcess = false -- 重置跳跃标记

    -- 步骤2：终止主检测循环
    self.isLoopRunning = false
    print("[站立恢复模块] 主检测循环已终止")

    -- 步骤3：断开所有监听（新增：断开状态变化监听，防止内存泄漏）
    if self.characterAddedConnection and self.characterAddedConnection.Connected then
        self.characterAddedConnection:Disconnect()
        self.characterAddedConnection = nil
    end
    if self.humanoidStateChangedConn then
        self.humanoidStateChangedConn:Disconnect()
        self.humanoidStateChangedConn = nil
    end
    print("[站立恢复模块] 所有监听已断开")

    -- 步骤4：清空所有核心引用（释放内存）
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
    self.localPlayer = nil
    self.Players = nil
    print("[站立恢复模块] 所有核心引用已清空")

    -- 步骤5：（可选）销毁当前脚本实例（彻底移除脚本，注释可开启）
    -- pcall(function()
    --     script:Destroy()
    --     print("[站立恢复模块] 脚本实例已销毁")
    -- end)

    print("[站立恢复模块] 卸载流程完成，模块所有功能已失效")
end

-- 10. 私有方法：启动主检测循环（保持不变）
function StandRecovery:startMainLoop()
    if not self.initialized then return end
    task.spawn(function() -- 用 task.spawn 开启独立线程，避免阻塞
        while self.isLoopRunning do -- 受 isLoopRunning 控制，卸载时终止循环
            task.wait(self.CHECK_INTERVAL)

            -- 卸载/开关关闭，跳过后续逻辑
            if self.isUnloaded or not self.isDetectionEnabled then
                continue
            end

            if not self.character or not self.humanoid or not self.humanoidRootPart then
                continue
            end

            -- 检测失控并执行批量恢复
            if self:isUncontrollable() then
                pcall(function() self:batchRestore() end)
                -- 恢复后持续监控防复燃
                local guardTime = 0.5
                local guardStart = tick()
                while tick() - guardStart < guardTime and self.isDetectionEnabled and self.isLoopRunning do
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

-- 11. 初始化模块（自动执行）
StandRecovery:init()

-- 12. 返回封装表（外部 require 即可获取所有公有方法）
return StandRecovery