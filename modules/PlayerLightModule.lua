-- LocalPlayerLightAttachmentFixed.lua
-- 多实例模块化封装：修复布尔索引错误，支持安全创建多个光源
-- 使用方式：
-- 1. 创建多光源：local light1 = Module.new(配置1); local light2 = Module.new(配置2)
-- 2. 开关光源：light1.enable = true; light2.enable = false
-- 3. 卸载：light1:unload() / Module:unloadAll()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 模块核心（支持多实例）
local LocalPlayerLight = {}
LocalPlayerLight.__index = LocalPlayerLight

-- 模块全局：存储所有创建的光源实例
LocalPlayerLight._allInstances = {}

-- 默认配置表（默认关闭光源）
local DEFAULT_CONFIG = {
    Enabled = false,         -- 默认关闭
    Brightness = 2,          -- 亮度
    Range = 10,              -- 光照范围
    Color = Color3.fromRGB(255, 255, 255), -- 白色
    Shadows = false,         -- 不产生阴影
    Attachment_Name = "PlayerLightAttachment",
    Offset_Position = Vector3.new(0, 1.5, 0),
    Offset_Rotation = Vector3.new(0, 0, 0),
    AttachToBodyPart = "UpperTorso",
}

-- 私有方法：合并配置
local function mergeConfig(customConfig)
    local merged = table.clone(DEFAULT_CONFIG)
    if type(customConfig) == "table" then
        for k, v in pairs(customConfig) do
            if merged[k] ~= nil then
                merged[k] = v
            end
        end
    end
    return merged
end

-- 私有方法：生成唯一Attachment名称（避免冲突）
local function getUniqueAttachmentName(baseName)
    local suffix = 1
    local newName = baseName
    local localPlayer = Players.LocalPlayer
    
    -- 安全检查：角色未加载时直接返回带后缀的名称
    if not localPlayer or not localPlayer.Character then
        return baseName .. "_" .. suffix
    end

    -- 避免重名
    while localPlayer.Character:FindFirstChild(newName, true) do
        newName = baseName .. "_" .. suffix
        suffix += 1
    end
    return newName
end

-- 私有方法：安全创建光源（增加空值检查）
local function attachLightToCharacter(instance)
    instance:cleanupLight()

    -- 多层安全检查：避免空值
    if not instance.localPlayer or not instance.localPlayer.Character then
        warn("角色未加载，跳过光源创建！")
        return
    end

    local bodyPart = instance.localPlayer.Character:FindFirstChild(instance.config.AttachToBodyPart)
    if not bodyPart or not bodyPart:IsA("BasePart") then
        warn("无法找到身体部位: " .. instance.config.AttachToBodyPart)
        return
    end

    -- 创建Attachment
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
    pointLight.Enabled = instance.config.Enabled
    pointLight.Brightness = instance.config.Brightness
    pointLight.Range = instance.config.Range
    pointLight.Color = instance.config.Color
    pointLight.Shadows = instance.config.Shadows
    pointLight.Parent = attachment

    -- 保存光源数据
    instance.lightData = {
        Attachment = attachment,
        PointLight = pointLight,
    }

    print(string.format("光源实例 [%s] 创建成功（绑定部位：%s）", attachment.Name, instance.config.AttachToBodyPart))
end

-- 私有方法：等待角色加载（增加超时和重试）
local function waitForCharacterAndAttachLight(instance)
    -- 安全检查：本地玩家不存在直接返回
    if not instance.localPlayer then
        warn("本地玩家不存在，无法创建光源！")
        return
    end

    -- 等待角色加载（最多等待10秒）
    local character = instance.localPlayer.Character or instance.localPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    
    if humanoidRootPart then
        -- 延迟1帧确保部件加载完成
        task.wait()
        attachLightToCharacter(instance)
    else
        warn("HumanoidRootPart 加载超时，光源创建失败！")
    end
end

-- 构造函数：创建单个光源实例（安全版）
function LocalPlayerLight.new(customConfig)
    local self = setmetatable({}, LocalPlayerLight)
    
    -- 实例私有状态（初始化默认值，避免nil）
    self.config = mergeConfig(customConfig)
    self.lightData = nil          -- 初始化为nil，后续赋值
    self.localPlayer = Players.LocalPlayer
    self.characterAddedConnection = nil
    self.isLoaded = true          -- 标记实例是否有效
    self._enableCache = false     -- 缓存enable状态，避免空值
    
    -- 安全检查：本地玩家不存在
    if not self.localPlayer then
        warn("无法获取本地玩家，光源实例创建失败！")
        self.isLoaded = false
        table.insert(LocalPlayerLight._allInstances, self)
        return self
    end

    -- 初始化光源
    task.spawn(waitForCharacterAndAttachLight, self)

    -- 监听角色重生（每个实例独立）
    self.characterAddedConnection = self.localPlayer.CharacterAdded:Connect(function()
        task.wait(1) -- 延迟1秒确保角色完全加载
        attachLightToCharacter(self)
        -- 重生后恢复缓存的enable状态
        if self.lightData and self.lightData.PointLight then
            self.lightData.PointLight.Enabled = self._enableCache
        end
    end)

    -- 加入全局列表
    table.insert(LocalPlayerLight._allInstances, self)

    -- 打印配置
    print("新光源实例创建，配置：")
    for k, v in pairs(self.config) do
        print("  " .. k .. ": " .. tostring(v))
    end

    return self
end

-- 实例方法：清理光源
function LocalPlayerLight:cleanupLight()
    if self.lightData then
        -- 销毁光源和附件
        pcall(function() self.lightData.PointLight:Destroy() end)
        pcall(function() self.lightData.Attachment:Destroy() end)
        self.lightData = nil
    end
end

-- 修复元方法：避免布尔值索引错误
function LocalPlayerLight:__index(key)
    -- 处理enable属性：优先返回缓存，避免直接返回布尔值
    if key == "enable" then
        -- 如果光源已创建，返回实际状态；否则返回缓存
        if self.lightData and self.lightData.PointLight then
            self._enableCache = self.lightData.PointLight.Enabled
            return self._enableCache
        else
            return self._enableCache
        end
    end

    -- 其他属性/方法：从模块表查找（安全版）
    local value = LocalPlayerLight[key]
    if value then
        return value
    else
        warn("光源实例不存在属性/方法：" .. tostring(key))
        return nil
    end
end

function LocalPlayerLight:__newindex(key, value)
    if key == "enable" then
        -- 强制转为布尔值
        local boolValue = not not value
        -- 更新缓存（即使光源未创建，也先缓存）
        self._enableCache = boolValue

        -- 安全检查：实例已卸载
        if not self.isLoaded then
            warn("光源实例已卸载，无法修改enable状态！")
            return
        end

        -- 光源已创建：直接修改
        if self.lightData and self.lightData.PointLight then
            pcall(function()
                self.lightData.PointLight.Enabled = boolValue
                print(string.format("光源 [%s] 状态：%s", self.lightData.Attachment.Name, tostring(boolValue)))
            end)
        else
            -- 光源未创建：提示并缓存状态
            print(string.format("光源未就绪，已缓存enable状态：%s（就绪后自动生效）", tostring(boolValue)))
        end
    else
        -- 其他属性直接设置
        rawset(self, key, value)
    end
end

-- 实例方法：卸载当前实例
function LocalPlayerLight:unload()
    if not self.isLoaded then
        warn("该光源实例已卸载！")
        return
    end

    -- 清理资源（pcall避免销毁已不存在的对象）
    self:cleanupLight()
    pcall(function() self.characterAddedConnection:Disconnect() end)

    -- 标记为卸载
    self.isLoaded = false
    self.config = nil
    self._enableCache = false

    -- 从全局列表移除
    for i, instance in ipairs(LocalPlayerLight._allInstances) do
        if instance == self then
            table.remove(LocalPlayerLight._allInstances, i)
            break
        end
    end

    print("光源实例已成功卸载！")
end

-- 模块级方法：卸载所有实例
function LocalPlayerLight:unloadAll()
    if #LocalPlayerLight._allInstances == 0 then
        warn("暂无光源实例可卸载！")
        return
    end

    -- 倒序卸载，避免索引错乱
    for i = #LocalPlayerLight._allInstances, 1, -1 do
        local instance = LocalPlayerLight._allInstances[i]
        if instance.isLoaded then
            instance:unload()
        end
    end

    -- 清空列表
    LocalPlayerLight._allInstances = {}
    print("所有光源实例已全部卸载！")
end

return LocalPlayerLight