-- LocalPlayerLightAttachmentFixed.lua
-- 单例模块化封装：仅为本地玩家创建可配置的绑定光源
-- 使用方式：local LightModule = require(此脚本); LightModule.new(自定义配置); LightModule.enable = true; LightModule:unload()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 模块核心（单例）
local LocalPlayerLight = {}
LocalPlayerLight.__index = LocalPlayerLight

-- 模块私有状态（存储全局资源）
local _state = {
    isLoaded = false,          -- 模块是否已加载
    config = nil,              -- 合并后的配置
    lightData = nil,           -- 光源/附件实例
    localPlayer = nil,         -- 本地玩家
    characterAddedConn = nil,  -- 角色重生事件连接
}

-- 默认配置表（默认关闭光源）
local DEFAULT_CONFIG = {
    -- PointLight 属性
    Enabled = false,         -- 默认关闭
    Brightness = 2,          -- 亮度
    Range = 10,              -- 光照范围
    Color = Color3.fromRGB(255, 255, 255), -- 白色
    Shadows = false,         -- 不产生阴影
    
    -- Attachment 属性
    Attachment_Name = "PlayerLightAttachment",
    Offset_Position = Vector3.new(0, 1.5, 0), -- 向上偏移1.5 studs
    Offset_Rotation = Vector3.new(0, 0, 0),   -- 无旋转偏移
    AttachToBodyPart = "UpperTorso",          -- 绑定到上躯干
}

-- 私有方法：合并配置（用户配置覆盖默认）
local function _mergeConfig(customConfig)
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

-- 私有方法：清理光源和附件
local function _cleanupLight()
    if _state.lightData then
        -- 销毁光源
        if _state.lightData.PointLight and _state.lightData.PointLight.Parent then
            _state.lightData.PointLight:Destroy()
        end
        -- 销毁附件
        if _state.lightData.Attachment and _state.lightData.Attachment.Parent then
            _state.lightData.Attachment:Destroy()
        end
        _state.lightData = nil
    end
end

-- 私有方法：创建并附加光源到角色
local function _attachLightToCharacter(character)
    _cleanupLight() -- 先清理旧光源

    -- 查找目标身体部位
    local bodyPart = character:FindFirstChild(_state.config.AttachToBodyPart)
    if not bodyPart or not bodyPart:IsA("BasePart") then
        warn("无法在角色上找到身体部位: " .. _state.config.AttachToBodyPart)
        return
    end

    -- 创建Attachment
    local attachment = Instance.new("Attachment")
    attachment.Name = _state.config.Attachment_Name
    attachment.CFrame = CFrame.new(_state.config.Offset_Position) 
        * CFrame.Angles(
            math.rad(_state.config.Offset_Rotation.X),
            math.rad(_state.config.Offset_Rotation.Y),
            math.rad(_state.config.Offset_Rotation.Z)
        )
    attachment.Parent = bodyPart

    -- 创建PointLight
    local pointLight = Instance.new("PointLight")
    pointLight.Enabled = _state.config.Enabled -- 初始关闭
    pointLight.Brightness = _state.config.Brightness
    pointLight.Range = _state.config.Range
    pointLight.Color = _state.config.Color
    pointLight.Shadows = _state.config.Shadows
    pointLight.Parent = attachment

    -- 保存光源数据
    _state.lightData = {
        Attachment = attachment,
        PointLight = pointLight,
    }

end

-- 私有方法：等待角色加载并附加光源
local function _waitForCharacterAndAttachLight(player)
    local character = player.Character or player.CharacterAdded:Wait()
    -- 等待核心部件加载（5秒超时）
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    if humanoidRootPart then
        _attachLightToCharacter(character)
    else
        warn("未能找到 HumanoidRootPart，无法附加光源（超时）。")
    end
end

-- 模块方法：初始化光源（new方法，仅执行一次）
function LocalPlayerLight.new(customConfig)
    if _state.isLoaded then
        warn("光源模块已初始化，无需重复调用new方法！")
        return LocalPlayerLight
    end

    -- 初始化核心状态
    _state.localPlayer = Players.LocalPlayer
    if not _state.localPlayer then
        warn("无法获取本地玩家，光源模块初始化失败！")
        return LocalPlayerLight
    end

    _state.config = _mergeConfig(customConfig)
    _state.isLoaded = true

    -- 初始化光源
    _waitForCharacterAndAttachLight(_state.localPlayer)

    -- 监听角色重生事件（保存连接以便卸载）
    _state.characterAddedConn = _state.localPlayer.CharacterAdded:Connect(function(character)
        task.wait() -- 等待角色完全加载
        _waitForCharacterAndAttachLight(_state.localPlayer)
    end)

    return LocalPlayerLight
end

-- 模块属性：enable（开关光源）
function LocalPlayerLight:__index(key)
    if key == "enable" then
        -- 获取当前光源启用状态
        return _state.lightData and _state.lightData.PointLight and _state.lightData.PointLight.Enabled or false
    end
    return LocalPlayerLight[key] -- 其他方法/属性走默认逻辑
end

function LocalPlayerLight:__newindex(key, value)
    if key == "enable" then
        -- 设置光源启用状态
        if not _state.isLoaded then
            warn("光源模块未初始化，无法切换状态！")
            return
        end
        if _state.lightData and _state.lightData.PointLight then
            _state.lightData.PointLight.Enabled = not not value -- 强制转为布尔值
        else
            warn("光源尚未创建，无法切换状态！")
        end
    else
        rawset(self, key, value) -- 其他属性直接设置
    end
end

-- 模块方法：卸载整个模块（核心需求）
function LocalPlayerLight:unload()
    if not _state.isLoaded then
        warn("光源模块已卸载，无需重复操作！")
        return
    end

    -- 1. 清理光源和附件
    _cleanupLight()

    -- 2. 断开角色重生事件连接
    if _state.characterAddedConn then
        _state.characterAddedConn:Disconnect()
        _state.characterAddedConn = nil
    end

    -- 3. 重置模块状态
    _state.isLoaded = false
    _state.config = nil
    _state.localPlayer = nil
end

-- 设置元表（让模块本身支持属性和方法调用）
setmetatable(LocalPlayerLight, LocalPlayerLight)

-- 返回模块（单例）
return LocalPlayerLight