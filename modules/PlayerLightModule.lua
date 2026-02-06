-- LocalPlayerLightAttachmentFixed.lua
-- 最终版：保留.new/:unload命名 + 彻底解决布尔索引错误
-- 你的原有调用逻辑完全不变，仅修复底层错误
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayerLight = {}
LocalPlayerLight.__index = LocalPlayerLight

-- 全局存储所有实例（用于批量卸载）
LocalPlayerLight._allInstances = {}

-- 默认配置（保持你原来的字段名）
local DEFAULT_CONFIG = {
    Enabled = false,         -- 你原来的默认关闭
    Brightness = 2,
    Range = 10,
    Color = Color3.fromRGB(255, 255, 255),
    Shadows = false,
    Attachment_Name = "PlayerLightAttachment",
    Offset_Position = Vector3.new(0, 1.5, 0),
    Offset_Rotation = Vector3.new(0, 0, 0),
    AttachToBodyPart = "UpperTorso",
}

-- 生成唯一名称（避免多光源冲突）
local function getUniqueAttachmentName(baseName)
    local suffix = 1
    local newName = baseName
    local char = Players.LocalPlayer and Players.LocalPlayer.Character
    if char then
        while char:FindFirstChild(newName, true) do
            newName = baseName .. "_" .. suffix
            suffix += 1
        end
    end
    return newName
end

-- 安全创建光源（内部方法）
local function attachLightToCharacter(self)
    self:cleanupLight()

    -- 层层空值检查（杜绝nil索引）
    if not self.localPlayer or not self.localPlayer.Character then return end
    local bodyPart = self.localPlayer.Character:FindFirstChild(self.config.AttachToBodyPart)
    if not bodyPart or not bodyPart:IsA("BasePart") then
        warn("找不到身体部位: " .. self.config.AttachToBodyPart)
        return
    end

    -- 创建Attachment
    local attachment = Instance.new("Attachment")
    attachment.Name = getUniqueAttachmentName(self.config.Attachment_Name)
    attachment.CFrame = CFrame.new(self.config.Offset_Position) 
        * CFrame.Angles(
            math.rad(self.config.Offset_Rotation.X),
            math.rad(self.config.Offset_Rotation.Y),
            math.rad(self.config.Offset_Rotation.Z)
        )
    attachment.Parent = bodyPart

    -- 创建PointLight
    local pointLight = Instance.new("PointLight")
    pointLight.Enabled = self._enableCache -- 用缓存值，避免直接依赖配置
    pointLight.Brightness = self.config.Brightness
    pointLight.Range = self.config.Range
    pointLight.Color = self.config.Color
    pointLight.Shadows = self.config.Shadows
    pointLight.Parent = attachment

    -- 保存数据（绝对不存nil）
    self.lightData = {
        Attachment = attachment,
        PointLight = pointLight,
    }
    self._isLightCreated = true

end

-- 构造函数：严格保留 .new 命名（你原来的调用方式不变）
function LocalPlayerLight.new(customConfig)
    local self = setmetatable({}, LocalPlayerLight)

    -- 初始化所有状态（杜绝nil，核心修复点）
    self.config = table.clone(DEFAULT_CONFIG)
    self.localPlayer = Players.LocalPlayer
    self.lightData = nil
    self.characterAddedConnection = nil
    self.isLoaded = true
    self._enableCache = false -- 缓存enable状态，避免布尔索引
    self._isLightCreated = false

    -- 合并用户配置（保持你原来的字段名）
    if type(customConfig) == "table" then
        for k, v in pairs(customConfig) do
            if self.config[k] ~= nil then
                self.config[k] = v
            end
        end
    end

    -- 初始化缓存（同步默认配置的Enabled）
    self._enableCache = self.config.Enabled

    -- 安全检查：本地玩家不存在
    if not self.localPlayer then
        warn("无法获取本地玩家，光源创建失败")
        self.isLoaded = false
        table.insert(LocalPlayerLight._allInstances, self)
        return self
    end

    -- 异步初始化光源（避免时序问题）
    task.spawn(function()
        local character = self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait()
        character:WaitForChild("HumanoidRootPart", 10)
        attachLightToCharacter(self)
    end)

    -- 监听角色重生（保留你原来的逻辑）
    self.characterAddedConnection = self.localPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        attachLightToCharacter(self)
        -- 重生后恢复缓存的enable状态
        if self._isLightCreated then
            self.lightData.PointLight.Enabled = self._enableCache
        end
    end)

    -- 加入全局列表
    table.insert(LocalPlayerLight._allInstances, self)
    return self
end

-- 内部清理方法
function LocalPlayerLight:cleanupLight()
    -- 安全销毁，不怕nil
    pcall(function() if self.lightData and self.lightData.PointLight then self.lightData.PointLight:Destroy() end end)
    pcall(function() if self.lightData and self.lightData.Attachment then self.lightData.Attachment:Destroy() end end)
    self.lightData = nil
    self._isLightCreated = false
end

-- 修复enable属性：安全的元表逻辑（核心！避免布尔索引）
function LocalPlayerLight:__index(key)
    -- 处理enable属性：只返回缓存值，且先检查实例是否有效
    if key == "enable" then
        return self._enableCache -- 返回缓存（永远是布尔值，但不会触发索引错误）
    end

    -- 其他方法/属性：从模块表安全查找
    local value = LocalPlayerLight[key]
    if value then
        return value
    else
        return nil -- 找不到返回nil，不报错
    end
end

function LocalPlayerLight:__newindex(key, value)
    if key == "enable" then
        -- 强制转布尔值，更新缓存（核心！避免直接操作nil的PointLight）
        local boolValue = not not value
        self._enableCache = boolValue

        -- 实例已卸载，直接返回
        if not self.isLoaded then
            warn("光源实例已卸载，无法修改enable")
            return
        end

        -- 光源已创建：安全修改状态
        if self._isLightCreated and self.lightData and self.lightData.PointLight then
            pcall(function()
                self.lightData.PointLight.Enabled = boolValue
            end)
        else
            -- 光源未创建：提示但不报错，缓存状态
        end
    else
        rawset(self, key, value)
    end
end

-- 实例卸载：严格保留 :unload 命名（你原来的调用方式不变）
function LocalPlayerLight:unload()
    if not self.isLoaded then
        return
    end

    -- 1. 清理光源
    self:cleanupLight()

    -- 2. 断开事件
    pcall(function() if self.characterAddedConnection then self.characterAddedConnection:Disconnect() end end)
    self.characterAddedConnection = nil

    -- 3. 标记卸载
    self.isLoaded = false
    self._enableCache = false

    -- 4. 从全局列表移除
    for i, inst in ipairs(LocalPlayerLight._allInstances) do
        if inst == self then
            table.remove(LocalPlayerLight._allInstances, i)
            break
        end
    end
end

-- 模块级卸载：保留 unloadAll（你可不用，不影响原有代码）
function LocalPlayerLight:unloadAll()
    for i = #LocalPlayerLight._allInstances, 1, -1 do
        local inst = LocalPlayerLight._allInstances[i]
        if inst.isLoaded then
            inst:unload()
        end
    end
    LocalPlayerLight._allInstances = {}
end

-- 保持你原来的返回方式
return LocalPlayerLight