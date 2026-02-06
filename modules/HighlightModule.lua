-- 高亮功能核心模块 | 语义化命名 | 独立封装 | 跨脚本调用
local HighlightModule = {}

-- ================================= 可自定义配置区 =================================
-- 颜色预设表：key为预设名称（调用时传入），value为轮廓/填充色
-- 支持 Color3.fromRGB(255,255,255)（推荐，0-255）/ Color3.new(1,1,1)（0-1）
local ColorPresets = {
    player = {
        OutlineColor = Color3.fromRGB(255, 0, 0),   -- 玩家红轮廓
        FillColor = Color3.fromRGB(255, 100, 100)   -- 玩家浅红填充
    },
    item = {
        OutlineColor = Color3.fromRGB(0, 255, 0),   -- 物品绿轮廓
        FillColor = Color3.fromRGB(100, 255, 100)   -- 物品浅绿填充
    }
}

-- 允许添加高亮的实例类型（过滤无效实例，避免给Camera/Terrain加高亮）
local ValidInstanceClasses = {
    Model = true,
    BasePart = true,   -- 包含Part/WedgePart/圆角Part等所有基础部件
    MeshPart = true,
    UnionOperation = true
}

-- 新模型检测延迟（避免实例未完全加载导致获取不到名称，可微调）
local NewInstanceDetectDelay = 0.1
-- ==================================================================================

-- 模块私有状态（外部不可直接访问，保证封装性）
local _private = {
    activeTasks = {},   -- 存储所有活跃高亮任务：{[taskId] = 任务数据, ...}
    taskSequenceId = 0, -- 任务自增唯一ID
    workspaceRef = game:GetService("Workspace"), -- 缓存Workspace，减少重复获取
    defaultColorPreset = "player" -- 颜色预设兜底，避免传参错误
}

-- ================================= 私有辅助函数（模块内部使用）=================================
-- 1. 查找Workspace中所有匹配的实例
-- @param targetName 目标模型名 | @param matchMode 匹配模式：only(全字)/other(模糊) | @return 匹配实例列表
local function _findMatchingInstances(targetName, matchMode)
    local matchingList = {}
    -- 遍历Workspace所有层级（改GetChildren()可仅遍历直接子级，提升性能）
    for _, inst in ipairs(_private.workspaceRef:GetDescendants()) do
        -- 过滤：有效类型 + 有名称
        if ValidInstanceClasses[inst.ClassName] and inst.Name and inst.Name ~= "" then
            local isMatched = false
            if matchMode == "only" then
                isMatched = (inst.Name == targetName) -- 全字完全匹配
            elseif matchMode == "other" then
                -- 模糊匹配：包含目标字段，plain=true关闭正则，避免特殊字符转义
                isMatched = string.find(inst.Name, targetName, 1, true) ~= nil
            end
            if isMatched then
                table.insert(matchingList, inst)
            end
        end
    end
    return matchingList
end

-- 2. 为单个实例创建/更新高亮（原生Highlight，性能最优，避免重复创建）
-- @param inst 目标实例 | @param presetName 颜色预设名 | @return 创建的Highlight实例
local function _createHighlight(inst, presetName)
    -- 颜色预设兜底：传参错误时用默认预设
    local colorConfig = ColorPresets[presetName] or ColorPresets[_private.defaultColorPreset]
    if not colorConfig then
        warn(string.format("[高亮模块] 颜色预设%s不存在，已使用默认预设", presetName))
    end

    -- 避免重复创建：实例已有高亮则直接更新颜色
    local highlight = inst:FindFirstChild("ModuleHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ModuleHighlight" -- 专属名称，区分其他自定义高亮
        highlight.Parent = inst            -- 跟随实例移动，无需额外绑定
    end

    -- 配置高亮样式
    highlight.OutlineColor = colorConfig.OutlineColor
    highlight.FillColor = colorConfig.FillColor
    highlight.Enabled = true -- 启用高亮
    return highlight
end

-- 3. 生成唯一任务ID（保证每个高亮任务独立）
local function _generateUniqueTaskId()
    _private.taskSequenceId = _private.taskSequenceId + 1
    return _private.taskSequenceId
end

-- ================================= 核心公有方法：创建高亮任务 =================================
-- 函数名：CreateHighlightTask | 外部调用入口，创建独立的高亮任务
-- 入参：
--  modelName: 字符串 → 要匹配的模型名称
--  matchMode: 字符串 → 匹配模式（only=全字匹配 / other=模糊匹配）
--  colorPreset: 字符串 → 颜色预设名（对应ColorPresets的key，如player/item）
-- 出参：任务对象 → 包含apply/destroy/unload方法，支持loop属性开关
function HighlightModule.CreateHighlightTask(modelName, matchMode, colorPreset)
    -- 严格参数校验，避免传参错误导致脚本崩溃
    if type(modelName) ~= "string" or modelName == "" then
        error("[高亮模块] 模型名称必须为非空字符串！", 2)
    end
    if matchMode ~= "only" and matchMode ~= "other" then
        error(string.format("[高亮模块] 匹配模式%s无效，仅支持only/other", tostring(matchMode)), 2)
    end
    if type(colorPreset) ~= "string" then
        warn("[高亮模块] 颜色预设名必须为字符串，已使用默认预设")
        colorPreset = _private.defaultColorPreset
    end

    -- 初始化任务数据（私有，仅模块内部访问）
    local taskId = _generateUniqueTaskId()
    local taskData = {
        id = taskId,
        targetName = modelName,
        matchMode = matchMode,
        colorPreset = colorPreset,
        isLoop = false,               -- 初始关闭自动检测新模型
        createdHighlights = {},       -- 存储当前任务创建的所有Highlight实例
        childAddedConnection = nil    -- 存储Workspace.ChildAdded连接（loop开启时创建）
    }
    _private.activeTasks[taskId] = taskData -- 加入活跃任务列表

    -- ==================== 任务对象公有方法（外部可调用）====================
    local taskObject = {}

    -- 方法1：apply → 执行高亮，查找匹配模型并添加高亮（可多次调用，新增模型会自动补高亮）
    function taskObject.apply()
        local currentTask = _private.activeTasks[taskId]
        if not currentTask then
            warn(string.format("[高亮模块] 任务%d已卸载，无法执行apply", taskId))
            return
        end

        -- 查找所有匹配实例
        local matchedInstances = _findMatchingInstances(currentTask.targetName, currentTask.matchMode)
        if #matchedInstances == 0 then
            warn(string.format("[高亮模块] 任务%d未找到匹配[%s]的模型（模式：%s）", taskId, currentTask.targetName, currentTask.matchMode))
            return
        end

        -- 为每个实例创建/更新高亮，并记录到任务列表
        for _, inst in ipairs(matchedInstances) do
            local highlight = _createHighlight(inst, currentTask.colorPreset)
            if highlight and not table.find(currentTask.createdHighlights, highlight) then
                table.insert(currentTask.createdHighlights, highlight)
            end
        end

        print(string.format("[高亮模块] 任务%d执行完成，共高亮%d个模型", taskId, #currentTask.createdHighlights))
    end

    -- 方法2：destroy → 清除当前任务的所有高亮（不卸载任务，可再次调用apply重新高亮）
    function taskObject.destroy()
        local currentTask = _private.activeTasks[taskId]
        if not currentTask then
            warn(string.format("[高亮模块] 任务%d已卸载，无法执行destroy", taskId))
            return
        end

        -- 销毁所有Highlight实例，清空列表
        for _, highlight in ipairs(currentTask.createdHighlights) do
            if highlight:IsA("Highlight") and highlight.Parent then
                highlight:Destroy()
            end
        end
        table.clear(currentTask.createdHighlights)

        print(string.format("[高亮模块] 任务%d的所有高亮已清除", taskId))
    end

    -- 方法3：unload → 完全卸载当前任务（清除高亮+断开连接+释放资源，不可再使用）
    function taskObject.unload()
        local currentTask = _private.activeTasks[taskId]
        if not currentTask then return end

        -- 1. 先清除当前所有高亮
        taskObject.destroy()
        -- 2. 断开自动检测的连接，避免内存泄漏
        if currentTask.childAddedConnection then
            currentTask.childAddedConnection:Disconnect()
            currentTask.childAddedConnection = nil
        end
        -- 3. 从活跃任务列表移除，释放内存
        _private.activeTasks[taskId] = nil

        print(string.format("[高亮模块] 任务%d已完全卸载", taskId))
    end

    -- ==================== loop属性开关（直接赋值true/false生效）====================
    -- 通过元表实现：赋值loop时自动创建/断开新模型检测连接
    local taskMetatable = {
        -- 读取loop属性时返回任务的实际状态
        __index = function(_, key)
            if key == "loop" then
                return _private.activeTasks[taskId]?.isLoop
            end
            return taskObject[key]
        end,
        -- 赋值loop时执行连接/断开逻辑
        __newindex = function(_, key, value)
            if key ~= "loop" then return end
            local currentTask = _private.activeTasks[taskId]
            if not currentTask then
                warn(string.format("[高亮模块] 任务%d已卸载，无法修改loop", taskId))
                return
            end
            if type(value) ~= "boolean" then
                warn("[高亮模块] loop属性仅支持赋值true/false")
                return
            end
            if currentTask.isLoop == value then return end -- 状态未变，不执行操作

            -- 更新任务loop状态
            currentTask.isLoop = value
            if value then
                -- 开启loop：创建ChildAdded连接，自动检测新添加的模型
                currentTask.childAddedConnection = _private.workspaceRef.ChildAdded:Connect(function(inst)
                    -- 延迟检测，避免实例未完全加载
                    task.wait(NewInstanceDetectDelay)
                    -- 过滤有效实例并判断是否匹配
                    if ValidInstanceClasses[inst.ClassName] and inst.Name then
                        local isMatched = false
                        if currentTask.matchMode == "only" then
                            isMatched = (inst.Name == currentTask.targetName)
                        else
                            isMatched = string.find(inst.Name, currentTask.targetName, 1, true) ~= nil
                        end
                        -- 匹配则创建高亮并记录
                        if isMatched then
                            local highlight = _createHighlight(inst, currentTask.colorPreset)
                            if highlight and not table.find(currentTask.createdHighlights, highlight) then
                                table.insert(currentTask.createdHighlights, highlight)
                            end
                        end
                    end
                end)
                print(string.format("[高亮模块] 任务%d已开启自动检测新模型", taskId))
            else
                -- 关闭loop：断开连接，停止检测
                if currentTask.childAddedConnection then
                    currentTask.childAddedConnection:Disconnect()
                    currentTask.childAddedConnection = nil
                end
                print(string.format("[高亮模块] 任务%d已关闭自动检测新模型", taskId))
            end
        end
    }
    setmetatable(taskObject, taskMetatable)

    -- 返回任务对象，外部通过该对象操作高亮
    return taskObject
end

-- ================================= 全局公有方法：卸载整个模块 =================================
-- 函数名：Unload | 外部调用 → 一键卸载所有高亮任务，清除所有资源，无内存泄漏
function HighlightModule.Unload()
    -- 遍历所有活跃任务，逐个完全卸载
    for taskId, _ in pairs(_private.activeTasks) do
        local currentTask = _private.activeTasks[taskId]
        if currentTask then
            -- 断开连接
            if currentTask.childAddedConnection then
                currentTask.childAddedConnection:Disconnect()
            end
            -- 销毁所有Highlight实例
            for _, highlight in ipairs(currentTask.createdHighlights) do
                if highlight:IsA("Highlight") and highlight.Parent then
                    highlight:Destroy()
                end
            end
            -- 移除任务
            _private.activeTasks[taskId] = nil
        end
    end

    -- 重置模块状态
    table.clear(_private.activeTasks)
    _private.taskSequenceId = 0
    print("[高亮模块] 已完全卸载，所有高亮任务和资源已清除")
end

-- 暴露模块接口，供其他脚本通过require调用
return HighlightModule