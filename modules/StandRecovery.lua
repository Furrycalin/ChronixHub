-- 1. 创建封装表（核心，所有功能、属性都挂载在这个表上）
local StandRecovery = {}

-- 2. 封装私有/公有属性（新增连续攻击/持续压制配置）
function StandRecovery:init()
    -- 服务引用
    self.Players = game:GetService("Players")
    self.localPlayer = self.Players.LocalPlayer
    if not self.localPlayer then
        warn("[站立恢复模块] 无法获取本地玩家，初始化失败")
        self.initialized = false
        return
    end

    -- 核心配置（优化连续攻击/电击压制参数）
    self.DEFAULT_WALK_SPEED = 16
    self.DEFAULT_JUMP_POWER = 50
    self.CHECK_INTERVAL = 0.03 -- 提高检测频率，应对连续攻击
    self.SPEED_THRESHOLD = 50
    self.RESTORE_REPEAT_TIMES = 5 -- 提升批量恢复次数，压过二次巴掌
    self.RESTORE_REPEAT_INTERVAL = 0.03 -- 缩短批量恢复间隔
    self.MOTOR6D_RESTORE_DELAY = 0.05 -- 延长Motor6D恢复延迟，减少冲突
    self.GUARD_TIME = 3.0 -- 延长防复燃窗口，应对连续巴掌（从0.5→3秒）
    self.BODY_POS_FIX_TIME = 0.3 -- 延长位置固定时间，稳定姿势（从0.1→0.3秒）
    self.ELECTRIC_SUPPRESS_TIME = 2.0 -- 电击持续压制时间，对抗持续生效脚本

    -- 状态变量
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
    self.isDetectionEnabled = false -- 默认关闭
    self.initialized = true -- 初始化完成标记
    self.isUnloaded = false -- 卸载状态标记
    self.isLoopRunning = true -- 主循环运行标记
    self.characterAddedConnection = nil -- 角色绑定连接引用
    self.isSuppressing = false -- 新增：是否正在压制（防止重复进入压制逻辑）

    -- 初始化角色绑定（保存连接引用，方便后续断开）
    self:bindCharacterAndComponents(self.localPlayer.Character)
    self.characterAddedConnection = self.localPlayer.CharacterAdded:Connect(function(newCharacter)
        self:bindCharacterAndComponents(newCharacter)
    end)

    -- 启动主检测循环（封装为方法）
    self:startMainLoop()

    print("[站立恢复模块] 初始化完成，检测功能默认关闭（调用 :enableDetection() 开启）")
end

-- 3. 核心方法：绑定角色及核心组件（新增重置压制状态）
function StandRecovery:bindCharacterAndComponents(newCharacter)
    -- 卸载后禁止执行
    if not self.initialized or self.isUnloaded then return end
    if not newCharacter then
        warn("[站立恢复模块] 角色对象为空，绑定失败")
        self.character = nil
        self.humanoid = nil
        self.humanoidRootPart = nil
        self.isSuppressing = false -- 重置压制状态
        return
    end

    -- 更新角色引用
    self.character = newCharacter
    print(string.format("[站立恢复模块] 已绑定角色：%s", self.character.Name))

    -- 等待并获取 Humanoid
    local success1, tempHumanoid = pcall(function()
        return self.character:WaitForChild("Humanoid", 5) -- 延长等待时间，确保获取
    end)

    -- 等待并获取 HumanoidRootPart
    local success2, tempRootPart = pcall(function()
        return self.character:WaitForChild("HumanoidRootPart", 5)
    end)

    -- 验证并更新组件引用
    if not success1 or not tempHumanoid then
        warn("[站立恢复模块] 无法获取角色 Humanoid 组件")
        self.humanoid = nil
    else
        self.humanoid = tempHumanoid
        self.humanoid.AutoRotate = true
        -- 初始化Humanoid状态，防止残留锁定
        self.humanoid.PlatformStand = false
        self.humanoid.WalkSpeed = self.DEFAULT_WALK_SPEED
        print("[站立恢复模块] Humanoid 组件绑定成功")
    end

    if not success2 or not tempRootPart then
        warn("[站立恢复模块] 无法获取角色 HumanoidRootPart 组件")
        self.humanoidRootPart = nil
    else
        self.humanoidRootPart = tempRootPart
        print("[站立恢复模块] HumanoidRootPart 组件绑定成功")
    end

    -- 重置压制状态，确保新角色绑定后检测正常
    self.isSuppressing = false
end

-- 4. 辅助方法：判定是否失控（优化状态检测，提升响应速度）
function StandRecovery:isUncontrollable()
    -- 卸载/压制中/未开启检测，禁止执行
    if not self.initialized or self.isUnloaded or not self.isDetectionEnabled or self.isSuppressing then
        return false
    end
    if not self.character or not self.humanoid or not self.humanoidRootPart or self.humanoid.Health <= 0 then
        return false
    end

    local currentState = self.humanoid:GetState()
    local abnormalStates = {
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.Physics, -- 电击枪核心状态
        Enum.HumanoidStateType.Flying,
        Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.Seated
    }
    
    -- 快速检测状态（优先返回，提升响应）
    local inAbnormalState = table.find(abnormalStates, currentState) ~= nil
    if inAbnormalState then return true end

    -- 检测禁用Motor6D（电击枪）
    local hasDisabledMotor6D = false
    pcall(function()
        -- 只检测关键骨骼Motor6D，提升检测速度，减少冲突
        local keyBones = {"Head", "Torso", "RightUpperLeg", "LeftUpperLeg", "RightUpperArm", "LeftUpperArm"}
        for _, boneName in pairs(keyBones) do
            local bone = self.character:FindFirstChild(boneName, true)
            if bone then
                for _, motor in pairs(bone:GetChildren()) do
                    if motor:IsA("Motor6D") and not motor.Enabled then
                        hasDisabledMotor6D = true
                        break
                    end
                end
            end
            if hasDisabledMotor6D then break end
        end
    end)

    -- 检测巴掌的高速/锁定状态
    local inHighSpeed = self.humanoidRootPart.Velocity.Magnitude > self.SPEED_THRESHOLD
    local inLockedState = self.humanoid.PlatformStand or self.humanoid.WalkSpeed <= 0

    return hasDisabledMotor6D or inHighSpeed or inLockedState
end

-- 5. 核心方法：单次强力恢复（优化优先级，减少冲突）
function StandRecovery:singleRestore()
    if not self.initialized or self.isUnloaded then return false end
    if not self.character or not self.humanoid or not self.humanoidRootPart then return false end

    -- 步骤1：强制锁定站立状态，优先级拉满
    pcall(function()
        self.humanoid:ChangeState(Enum.HumanoidStateType.Standing)
        -- 锁定Humanoid属性，防止被覆盖
        self.humanoid.PlatformStand = false
        self.humanoid.WalkSpeed = self.DEFAULT_WALK_SPEED
        self.humanoid.JumpPower = self.DEFAULT_JUMP_POWER
    end)

    -- 步骤2：强制启用关键骨骼Motor6D（不记录初始状态，直接启用，对抗电击脚本）
    local restoredCount = 0
    pcall(function()
        local keyBones = {"Head", "Torso", "RightUpperLeg", "LeftUpperLeg", "RightUpperArm", "LeftUpperArm"}
        for _, boneName in pairs(keyBones) do
            local bone = self.character:FindFirstChild(boneName, true)
            if bone then
                for _, motor in pairs(bone:GetChildren()) do
                    if motor:IsA("Motor6D") then
                        motor.Enabled = true -- 强制启用，不依赖历史记录，避免失效
                        restoredCount = restoredCount + 1
                    end
                end
            end
            task.wait(self.MOTOR6D_RESTORE_DELAY) -- 分批恢复，减少和电击脚本冲突
        end
    end)

    -- 步骤3：清空惯性，延长位置固定，稳定姿势
    pcall(function()
        self.humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        self.humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)

        -- 延长位置固定时间，让姿势稳定后再释放
        local bodyPos = Instance.new("BodyPosition")
        bodyPos.Parent = self.humanoidRootPart
        bodyPos.Position = self.humanoidRootPart.Position
        bodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyPos.D = 200 -- 提高阻尼，减少抖动
        bodyPos.P = 8000 -- 提高力度，稳定姿势
        task.delay(self.BODY_POS_FIX_TIME, function()
            if bodyPos and bodyPos.Parent then bodyPos:Destroy() end
        end)
    end)

    -- 步骤4：深度清理物理对象，重复清理避免残留
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
    -- 重复清理2次，应对巴掌二次攻击的物理残留
    for i = 1, 2 do
        clearPhysicsObjects(self.character)
        task.wait(0.01)
    end

    -- 步骤5：小幅回血，避免濒死状态被持续攻击
    self.humanoid.Health = math.min(self.humanoid.Health + 2, self.humanoid.MaxHealth)

    -- 输出日志（简化，减少性能开销）
    if restoredCount > 0 then
        print(string.format("[站立恢复模块] 恢复 %d 个关键Motor6D", restoredCount))
    end
    if removedCount > 0 then
        print(string.format("[站立恢复模块] 清理 %d 个物理对象", removedCount))
    end

    return true
end

-- 6. 新增：持续压制逻辑（对抗电击枪持续生效脚本）
function StandRecovery:startSuppress()
    if self.isSuppressing or self.isUnloaded or not self.isDetectionEnabled then return end
    self.isSuppressing = true
    print("[站立恢复模块] 检测到持续失控（电击/连续巴掌），进入持续压制模式")

    local suppressStart = tick()
    local lastNormalStateTime = tick()

    -- 压制循环：在压制时间内，高频率小幅恢复，压制游戏脚本
    while tick() - suppressStart < self.ELECTRIC_SUPPRESS_TIME and not self.isUnloaded do
        -- 每帧检测是否恢复正常
        local currentState = self.humanoid:GetState()
        local isNormal = (currentState == Enum.HumanoidStateType.Standing) and (self.humanoid.WalkSpeed > 0)

        if isNormal then
            lastNormalStateTime = tick()
            -- 连续0.5秒正常，提前退出压制
            if tick() - lastNormalStateTime > 0.5 then
                break
            end
        else
            -- 异常状态，立即执行单次恢复，压制游戏脚本
            self:singleRestore()
        end

        task.wait(0.05) -- 压制频率，平衡效果和性能
    end

    -- 退出压制，重置状态
    self.isSuppressing = false
    print("[站立恢复模块] 持续压制结束，恢复正常监控")
end

-- 7. 批量恢复逻辑（强化，应对二次巴掌）
function StandRecovery:batchRestore()
    if not self.initialized or self.isUnloaded or not self.isDetectionEnabled then return false end
    print("[站立恢复模块] 开始批量恢复（应对强力失控）")
    local successCount = 0

    -- 提升恢复次数，压过二次巴掌的优先级
    for i = 1, self.RESTORE_REPEAT_TIMES do
        if self:singleRestore() then
            successCount = successCount + 1
        end
        task.wait(self.RESTORE_REPEAT_INTERVAL)
    end

    print(string.format("[站立恢复模块] 批量恢复完成，成功执行 %d 次", successCount))
    return successCount > 0
end

-- 8. 公有方法：开启检测（保持不变，新增压制说明）
function StandRecovery:enableDetection()
    if not self.initialized or self.isUnloaded then
        warn("[站立恢复模块] 模块已卸载，无法开启检测")
        return
    end
    if self.isDetectionEnabled then
        print("[站立恢复模块] 检测功能已处于开启状态，无需重复开启")
        return
    end
    self.isDetectionEnabled = true
    print("[站立恢复模块] 检测功能已开启（支持连续巴掌+电击枪压制，包含3秒防复燃窗口）")
end

-- 9. 公有方法：关闭检测（保持不变）
function StandRecovery:disableDetection()
    if not self.initialized or self.isUnloaded then
        warn("[站立恢复模块] 模块已卸载，无法关闭检测")
        return
    end
    if not self.isDetectionEnabled then
        print("[站立恢复模块] 检测功能已处于关闭状态，无需重复关闭")
        return
    end
    self.isDetectionEnabled = false
    self.isSuppressing = false -- 关闭时终止压制
    print("[站立恢复模块] 检测功能已关闭，不再监控角色失控状态")
end

-- 10. 公有方法：卸载脚本/模块（保持不变，重置压制状态）
function StandRecovery:unload()
    if self.isUnloaded then
        print("[站立恢复模块] 模块已卸载，无需重复卸载")
        return
    end
    if not self.initialized then
        warn("[站立恢复模块] 模块未初始化完成，无需卸载")
        return
    end

    print("[站立恢复模块] 开始执行卸载流程...")

    -- 步骤1：标记为已卸载，终止压制
    self.isUnloaded = true
    self.isDetectionEnabled = false
    self.isSuppressing = false

    -- 步骤2：终止主检测循环
    self.isLoopRunning = false
    print("[站立恢复模块] 主检测循环已终止")

    -- 步骤3：断开角色新增监听（防止内存泄漏）
    if self.characterAddedConnection and self.characterAddedConnection.Connected then
        self.characterAddedConnection:Disconnect()
        self.characterAddedConnection = nil
        print("[站立恢复模块] 角色新增监听已断开")
    end

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

-- 11. 主检测循环（重构，新增压制触发逻辑）
function StandRecovery:startMainLoop()
    if not self.initialized then return end
    task.spawn(function()
        while self.isLoopRunning do
            task.wait(self.CHECK_INTERVAL)

            -- 卸载/开关关闭，跳过后续逻辑
            if self.isUnloaded or not self.isDetectionEnabled then
                continue
            end

            if not self.character or not self.humanoid or not self.humanoidRootPart then
                continue
            end

            -- 检测到失控，执行「批量恢复+持续压制」
            if self:isUncontrollable() then
                -- 第一步：批量恢复，快速压制初始失控
                pcall(function() self:batchRestore() end)

                -- 第二步：进入持续压制，对抗电击/连续巴掌的持续生效
                pcall(function() self:startSuppress() end)

                -- 第三步：延长防复燃等待，避免立即触发下一次检测
                task.wait(0.5)
            end
        end
    end)
end

-- 12. 初始化模块（自动执行）
StandRecovery:init()

-- 13. 返回封装表（外部 require 即可获取所有公有方法）
return StandRecovery