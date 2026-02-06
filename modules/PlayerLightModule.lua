-- LocalPlayerLightAttachmentModule.lua
-- 模块化封装的本地玩家绑定光源（支持多实例、启停、卸载）
local Players = game:GetService("Players")
local RunService = game:GetService("RunService") -- 虽然此代码未直接使用RunService，但保留服务获取是良好实践

-- 核心模块对象
local LocalPlayerLightModule = {}
LocalPlayerLightModule.__index = LocalPlayerLightModule

-- 存储所有创建的光源实例（用于全局卸载）
LocalPlayerLightModule._instances = {}

-- 默认配置表（可被new方法传入的参数覆盖）
local DEFAULT_CONFIG = {
    -- PointLight 属性
    Brightness = 2,          -- 亮度
    Range = 10,              -- 光照范围
    Color = Color3.fromRGB(255, 255, 255), -- 光源颜色
    Shadows = false,         -- 是否产生阴影
    
    -- 附加 Attachment 的属性
    Attachment_Name = "PlayerLightAttachment", -- Attachment 名称
    Offset_Position = Vector3.new(0, 1.5, 0),  -- 位置偏移（相对于绑定部位）
    Offset_Rotation = Vector3.new(0, 0, 0),    -- 旋转偏移（度）
    AttachToBodyPart = "UpperTorso",           -- 绑定的身体部位
}

-- 构造函数：创建新的光源实例（外部调用 LightModule.new(config)）
function LocalPlayerLightModule.new(customConfig)
    -- 合并自定义配置与默认配置（自定义配置优先级更高）
    local config = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        config[k] = v
    end
    if type(customConfig) == "table" then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    -- 强制默认禁用（满足“创建时默认不生效”的需求）
    config.Enabled = false

    -- 创建实例对象
    local self = setmetatable({}, LocalPlayerLightModule)
    self.config = config                -- 实例专属配置
    self.PlayerLightData = nil          -- 存储光源和附件的引用
    self._characterAddedConn = nil      -- 角色重生监听连接（用于卸载）
    self.localPlayer = Players.LocalPlayer -- 绑定本地玩家

    -- 初始化光源逻辑
    if self.localPlayer then
        self:_init()
    else
        -- 极端情况：LocalPlayer尚未加载时等待
        Players.LocalPlayerAdded:Connect(function(player)
            self.localPlayer = player
            self:_init()
        end)
    end

    -- 将实例加入全局列表，方便全局卸载
    table.insert(LocalPlayerLightModule._instances, self)
    return self
end

-- 内部初始化方法（创建光源、绑定监听）
function LocalPlayerLightModule:_init()
    -- 等待角色加载并创建光源
    self:_waitForCharacterAndAttachLight()

    -- 监听角色重生事件（角色死亡/重生后重新创建光源）
    self._characterAddedConn = self.localPlayer.CharacterAdded:Connect(function()
        task.wait() -- 等待角色完全加载
        self:_waitForCharacterAndAttachLight()
    end)
end

-- 内部方法：等待角色加载并附加光源
function LocalPlayerLightModule:_waitForCharacterAndAttachLight()
    local character = self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait()
    -- 等待核心部件加载
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoidRootPart then
        warn("LocalPlayerLightModule: 未能找到HumanoidRootPart，无法创建光源")
        -- 如果核心部件找不到，不应继续执行，因为角色可能还未完全加载或结构异常
        -- 此处可以考虑更复杂的重试逻辑，但简单起见，直接返回
        return 
    end

    -- 先清理旧光源（防止重复创建）
    self:_cleanupOldLight()

    -- 找到绑定的身体部位
    local bodyPart = character:FindFirstChild(self.config.AttachToBodyPart)
    if not bodyPart or not bodyPart:IsA("BasePart") then
        warn(string.format("LocalPlayerLightModule: 无法找到身体部位 %s", self.config.AttachToBodyPart))
        -- 如果目标身体部位找不到，也不应继续执行
        return
    end

    -- 1. 创建Attachment（光源载体）
    local attachment = Instance.new("Attachment")
    attachment.Name = self.config.Attachment_Name
    attachment.CFrame = CFrame.new(self.config.Offset_Position) 
        * CFrame.Angles(
            math.rad(self.config.Offset_Rotation.X),
            math.rad(self.config.Offset_Rotation.Y),
            math.rad(self.config.Offset_Rotation.Z)
        )
    attachment.Parent = bodyPart

    -- 2. 创建PointLight并应用配置（默认禁用）
    local pointLight = Instance.new("PointLight")
    pointLight.Enabled = self.config.Enabled  -- 初始为false（禁用）
    pointLight.Brightness = self.config.Brightness
    pointLight.Range = self.config.Range
    pointLight.Color = self.config.Color
    pointLight.Shadows = self.config.Shadows
    pointLight.Parent = attachment

    -- 只有在所有创建操作都成功后，才存储引用
    -- 这确保了 PlayerLightData 不会是 nil，且其成员也是有效的实例
    self.PlayerLightData = {
        Attachment = attachment,
        PointLight = pointLight,
    }

    print(string.format("LocalPlayerLightModule: 已为本地玩家创建光源实例（%s）", self.config.Attachment_Name))
end

-- 内部方法：清理旧的光源和附件
function LocalPlayerLightModule:_cleanupOldLight()
    -- 添加一个检查，确保 PlayerLightData 不为 nil 且其成员存在
    if self.PlayerLightData then
        if self.PlayerLightData.PointLight then
            self.PlayerLightData.PointLight:Destroy()
            self.PlayerLightData.PointLight = nil -- 销毁后置为nil
        end
        if self.PlayerLightData.Attachment then
            self.PlayerLightData.Attachment:Destroy()
            self.PlayerLightData.Attachment = nil -- 销毁后置为nil
        end
        -- 将 PlayerLightData 本身也置为 nil
        self.PlayerLightData = nil
    end
    -- 如果 PlayerLightData 本身就是 nil，则无需任何操作
end

-- 公共方法：启用光源
function LocalPlayerLightModule:enable()
    -- 在访问前进行检查
    if self.PlayerLightData and self.PlayerLightData.PointLight then
        self.PlayerLightData.PointLight.Enabled = true
        print(string.format("LocalPlayerLightModule: 光源 %s 已启用", self.config.Attachment_Name))
    else
        warn(string.format("LocalPlayerLightModule: 光源尚未创建或已卸载，无法启用 (%s)", self.config.Attachment_Name))
    end
end

-- 公共方法：禁用光源
function LocalPlayerLightModule:disable()
    -- 在访问前进行检查
    if self.PlayerLightData and self.PlayerLightData.PointLight then
        self.PlayerLightData.PointLight.Enabled = false
        print(string.format("LocalPlayerLightModule: 光源 %s 已禁用", self.config.Attachment_Name))
    else
        warn(string.format("LocalPlayerLightModule: 光源尚未创建或已卸载，无法禁用 (%s)", self.config.Attachment_Name))
    end
end

-- 公共方法：卸载当前光源实例（销毁光源、断开监听）
function LocalPlayerLightModule:unload()
    -- 清理光源和附件
    -- _cleanupOldLight 内部已有安全检查
    self:_cleanupOldLight()
    
    -- 断开角色重生监听
    if self._characterAddedConn then
        self._characterAddedConn:Disconnect()
        self._characterAddedConn = nil
    end
    
    -- 从全局实例列表移除
    for i, instance in ipairs(LocalPlayerLightModule._instances) do
        if instance == self then
            table.remove(LocalPlayerLightModule._instances, i)
            break
        end
    end
    print(string.format("LocalPlayerLightModule: 光源实例 %s 已卸载", self.config.Attachment_Name))
end

-- 模块全局方法：卸载所有光源实例（整个脚本级别的卸载）
function LocalPlayerLightModule.unloadAll()
    -- 遍历所有实例并调用各自的unload
    -- 注意：在遍历过程中修改原表可能会有风险，建议反向遍历或先复制一份键值
    -- 这里采用反向遍历，因为unload方法会修改_instances表
    for i = #LocalPlayerLightModule._instances, 1, -1 do
        local instance = LocalPlayerLightModule._instances[i]
        -- 调用实例的unload方法，该方法内部会负责将其从_instances中移除
        instance:unload()
    end
    -- 清空实例列表（虽然上面的循环应该已经清空了，但再次确认）
    LocalPlayerLightModule._instances = {}
    print("LocalPlayerLightModule: 所有光源实例已全部卸载")
end

-- 返回模块对象（供外部调用）
return LocalPlayerLightModule