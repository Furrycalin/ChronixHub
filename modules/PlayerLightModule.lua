-- LocalPlayerLightAttachmentFixed.lua
-- 多实例模块化封装：支持为本地玩家创建多个独立的绑定光源
-- 使用方式：
-- 1. 创建多个光源实例：local light1 = Module.new(配置1); local light2 = Module.new(配置2)
-- 2. 开关单个光源：light1.enable = true; light2.enable = false
-- 3. 卸载单个光源：light1:unload()
-- 4. 卸载所有光源（模块级）：Module:unloadAll()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 模块核心（支持多实例）
local LocalPlayerLight = {}
LocalPlayerLight.__index = LocalPlayerLight

-- 模块全局：存储所有创建的光源实例（用于批量卸载）
LocalPlayerLight._allInstances = {}

-- 默认配置表（默认关闭光源）
local DEFAULT_CONFIG = {
    -- PointLight 属性
    Enabled = false,         -- 默认关闭
    Brightness = 2,          -- 亮度
    Range = 10,              -- 光照范围
    Color = Color3.fromRGB(255, 255, 255), -- 白色
    Shadows = false,         -- 不产生阴影
    
    -- Attachment 属性
    Attachment_Name = "PlayerLightAttachment", -- 多个光源会自动加后缀区分
    Offset_Position = Vector3.new(0, 1.5, 0), -- 向上偏移1.5 studs
    Offset_Rotation = Vector3.new(0, 0, 0),   -- 无旋转偏移
    AttachToBodyPart = "UpperTorso",          -- 绑定到上躯干
}

-- 私有方法：合并配置（用户配置覆盖默认）
local function mergeConfig(customConfig)
    local merged = table.clone(DEFAULT_CONFIG)
    if type(customConfig) == "table" then
        for k, v in pairs(customConfig) do
            if merged[k] ~= nil then -- 仅覆盖有效配置项
                merged[k] = v
            end
        end
    end
    return merged
end

-- 私有方法：为多个光源生成唯一名称（避免Attachment重名）
local function getUniqueAttachmentName(baseName)
    local suffix = 1
    local newName = baseName
    -- 检查本地玩家角色中是否已有同名Attachment，有则加数字后缀
    local localPlayer = Players.LocalPlayer
    if localPlayer and localPlayer.Character then
        while localPlayer.Character:FindFirstChild(newName, true) do
            newName = baseName .. "_" .. suffix
            suffix += 1
        end
    end
    return newName
end

-- 私有方法：创建并附加单个光源到角色
local function attachLightToCharacter(instance)
    -- 清理该实例旧的光源
    instance:cleanupLight()

    local character = instance.localPlayer.Character
    if not character then
        warn("角色未加载，无法创建光源！")
        return
    end

    -- 查找目标身体部位
    local bodyPart = character:FindFirstChild(instance.config.AttachToBodyPart)
    if not bodyPart or not bodyPart:IsA("BasePart") then
        warn("无法在角色上找到身体部位: " .. instance.config.AttachToBodyPart)
        return
    end

    -- 创建Attachment（自动生成唯一名称，避免多光源冲突）
    local attachment = Instance.new("Attachment")
    attachment.Name = getUniqueAttachmentName(instance.config.Attachment_Name)
    attachment.CFrame = CFrame.new(instance.config.Offset_Position) 
        * CFrame.Angles(
            math.rad(instance.config.Offset_Rotation.X),
            math.rad(instance.config.Offset_Rotation.Y),
            math.rad(instance.config.Offset_Rotation.Z)
        )
    attachment.Parent = bodyPart

    -- 创建PointLight
    local pointLight = Instance.new("PointLight")
    pointLight.Enabled = instance.config.Enabled -- 初始关闭
    pointLight.Brightness = instance.config.Brightness
    pointLight.Range = instance.config.Range
    pointLight.Color = instance.config.Color
    pointLight.Shadows = instance.config.Shadows
    pointLight.Parent = attachment

    -- 保存该实例的光源数据
    instance.lightData = {
        Attachment = attachment,
        PointLight = pointLight,
    }

    print(string.format("已创建光源实例 [%s]，绑定部位：%s", attachment.Name, instance.config.AttachToBodyPart))
end

-- 私有方法：等待角色加载并附加光源
local function waitForCharacterAndAttachLight(instance)
    local character = instance.localPlayer.Character or instance.localPlayer.CharacterAdded:Wait()
    -- 等待核心部件加载（5秒超时）
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    if humanoidRootPart then
        attachLightToCharacter(instance)
    else
        warn("未能找到 HumanoidRootPart，无法创建光源（超时）。")
    end
end

-- 构造函数：创建单个光源实例（支持多次调用，生成多个独立光源）
function LocalPlayerLight.new(customConfig)
    local self = setmetatable({}, LocalPlayerLight)
    
    -- 实例私有状态（每个光源独立）
    self.config = mergeConfig(customConfig)          -- 该实例的配置
    self.lightData = nil                             -- 该实例的光源/附件
    self.localPlayer = Players.LocalPlayer           -- 本地玩家（全局唯一，但光源实例独立）
    self.characterAddedConnection = nil              -- 该实例的角色重生事件连接
    self.isLoaded = true                             -- 该实例是否已加载

    -- 检查本地玩家是否存在
    if not self.localPlayer then
        warn("无法获取本地玩家，光源实例创建失败！")
        self.isLoaded = false
        table.insert(LocalPlayerLight._allInstances, self)
        return self
    end

    -- 初始化该实例的光源
    waitForCharacterAndAttachLight(self)

    -- 监听角色重生事件（每个实例独立监听，避免互相影响）
    self.characterAddedConnection = self.localPlayer.CharacterAdded:Connect(function(character)
        task.wait() -- 等待角色完全加载
        waitForCharacterAndAttachLight(self)
    end)

    -- 将实例加入全局列表（用于批量卸载）
    table.insert(LocalPlayerLight._allInstances, self)

    -- 打印该实例的配置
    print(string.format("光源实例已创建，配置如下："))
    for k, v in pairs(self.config) do
        print("  " .. k .. ": " .. tostring(v))
    end

    return self
end

-- 实例方法：清理当前实例的光源和附件
function LocalPlayerLight:cleanupLight()
    if self.lightData then
        -- 销毁光源
        if self.lightData.PointLight and self.lightData.PointLight.Parent then
            self.lightData.PointLight:Destroy()
        end
        -- 销毁附件
        if self.lightData.Attachment and self.lightData.Attachment.Parent then
            self.lightData.Attachment:Destroy()
        end
        self.lightData = nil
    end
end

-- 实例属性：enable（开关当前实例的光源）
function LocalPlayerLight:__index(key)
    if key == "enable" then
        -- 获取当前实例的光源启用状态
        return self.lightData and self.lightData.PointLight and self.lightData.PointLight.Enabled or false
    end
    return LocalPlayerLight[key] -- 其他方法/属性走默认逻辑
end

function LocalPlayerLight:__newindex(key, value)
    if key == "enable" then
        -- 设置当前实例的光源启用状态
        if not self.isLoaded then
            warn("该光源实例已卸载，无法切换状态！")
            return
        end
        if self.lightData and self.lightData.PointLight then
            self.lightData.PointLight.Enabled = not not value -- 强制转为布尔值
            print(string.format("光源实例 [%s] 状态已切换为：%s", self.lightData.Attachment.Name, tostring(value)))
        else
            warn("该光源实例尚未创建完成，无法切换状态！")
        end
    else
        rawset(self, key, value) -- 其他属性直接设置
    end
end

-- 实例方法：卸载当前光源实例（清理自身资源）
function LocalPlayerLight:unload()
    if not self.isLoaded then
        warn("该光源实例已卸载，无需重复操作！")
        return
    end

    -- 1. 清理当前实例的光源和附件
    self:cleanupLight()

    -- 2. 断开当前实例的角色重生事件连接
    if self.characterAddedConnection then
        self.characterAddedConnection:Disconnect()
        self.characterAddedConnection = nil
    end

    -- 3. 标记实例为已卸载
    self.isLoaded = false
    self.config = nil

    -- 4. 从全局实例列表中移除
    for i, instance in ipairs(LocalPlayerLight._allInstances) do
        if instance == self then
            table.remove(LocalPlayerLight._allInstances, i)
            break
        end
    end

    print(string.format("光源实例 [%s] 已卸载！", self.lightData and self.lightData.Attachment.Name or "未知"))
end

-- 模块级方法：卸载所有光源实例（满足你“模块级unload”的需求）
function LocalPlayerLight:unloadAll()
    if #LocalPlayerLight._allInstances == 0 then
        warn("暂无已创建的光源实例，无需卸载！")
        return
    end

    -- 遍历所有实例并卸载
    for i = #LocalPlayerLight._allInstances, 1, -1 do
        local instance = LocalPlayerLight._allInstances[i]
        if instance.isLoaded then
            instance:unload()
        end
    end

    -- 清空实例列表
    LocalPlayerLight._allInstances = {}
    print("所有光源实例已全部卸载！")
end

-- 返回模块
return LocalPlayerLight