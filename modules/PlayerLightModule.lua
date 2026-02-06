-- LocalPlayerLightAttachmentFixed.lua
-- 模块化封装：仅为本地玩家创建可配置的绑定光源 (修复版)
-- 使用方式：local LightModule = require(此脚本); local playerLight = LightModule.new(自定义配置); playerLight.enable = true; playerLight:unload()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 定义模块核心类
local LocalPlayerLight = {}
LocalPlayerLight.__index = LocalPlayerLight

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

-- 私有方法：合并配置（用户配置覆盖默认配置）
local function mergeConfig(customConfig)
    local merged = {}
    -- 先复制默认配置
    for k, v in pairs(DEFAULT_CONFIG) do
        merged[k] = v
    end
    -- 用用户配置覆盖
    if type(customConfig) == "table" then
        for k, v in pairs(customConfig) do
            if merged[k] ~= nil then -- 只覆盖存在的配置项，避免无效参数
                merged[k] = v
            end
        end
    end
    return merged
end

-- 私有方法：创建并附加光源到角色
local function attachLightToCharacter(self, character)
    -- 清理旧光源
    self:cleanupLight()

    -- 查找目标身体部位
    local bodyPart = character:FindFirstChild(self.config.AttachToBodyPart)
    if not bodyPart or not bodyPart:IsA("BasePart") then
        warn("无法在角色上找到身体部位: " .. self.config.AttachToBodyPart)
        return
    end

    -- 创建Attachment
    local attachment = Instance.new("Attachment")
    attachment.Name = self.config.Attachment_Name
    attachment.CFrame = CFrame.new(self.config.Offset_Position) 
        * CFrame.Angles(
            math.rad(self.config.Offset_Rotation.X),
            math.rad(self.config.Offset_Rotation.Y),
            math.rad(self.config.Offset_Rotation.Z)
        )
    attachment.Parent = bodyPart

    -- 创建PointLight
    local pointLight = Instance.new("PointLight")
    pointLight.Enabled = self.config.Enabled -- 初始状态由配置决定（默认false）
    pointLight.Brightness = self.config.Brightness
    pointLight.Range = self.config.Range
    pointLight.Color = self.config.Color
    pointLight.Shadows = self.config.Shadows
    pointLight.Parent = attachment

    -- 保存光源数据
    self.lightData = {
        Attachment = attachment,
        PointLight = pointLight,
    }

    print("已为本地玩家角色添加光源。")
end

-- 私有方法：等待角色加载并附加光源
local function waitForCharacterAndAttachLight(self, player)
    local character = player.Character or player.CharacterAdded:Wait()
    -- 等待核心部件加载
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5) -- 增加超时
    if humanoidRootPart then
        attachLightToCharacter(self, character)
    else
        warn("未能找到 HumanoidRootPart，无法附加光源（超时）。")
    end
end

-- 构造函数：创建光源实例
function LocalPlayerLight.new(customConfig)
    local self = setmetatable({}, LocalPlayerLight)
    
    -- 初始化核心属性
    self.config = mergeConfig(customConfig)          -- 合并后的配置
    self.lightData = nil                             -- 存储光源/附件实例
    self.localPlayer = Players.LocalPlayer           -- 本地玩家
    self.characterAddedConnection = nil              -- 保存事件连接（用于卸载）
    self.isLoaded = true                             -- 标记是否已加载

    -- 检查本地玩家是否存在
    if not self.localPlayer then
        warn("无法获取本地玩家，光源模块初始化失败！")
        self.isLoaded = false
        return self
    end

    -- 初始化光源
    waitForCharacterAndAttachLight(self, self.localPlayer)

    -- 监听角色重生事件（保存连接以便卸载）
    self.characterAddedConnection = self.localPlayer.CharacterAdded:Connect(function(character)
        task.wait() -- 等待角色完全加载
        waitForCharacterAndAttachLight(self, self.localPlayer)
    end)

    print("本地玩家光源实例已创建，配置如下：")
    for k, v in pairs(self.config) do
        print("  " .. k .. ": " .. tostring(v))
    end

    return self
end

-- 清理光源和附件（私有方法）
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

-- 开关光源的属性（getter/setter）
function LocalPlayerLight:__index(key)
    if key == "enable" then
        -- 获取当前光源启用状态
        return self.lightData and self.lightData.PointLight and self.lightData.PointLight.Enabled or false
    end
    return LocalPlayerLight[key] -- 其他属性/方法走默认逻辑
end

function LocalPlayerLight:__newindex(key, value)
    if key == "enable" then
        -- 设置光源启用状态
        if self.lightData and self.lightData.PointLight then
            self.lightData.PointLight.Enabled = not not value -- 强制转为布尔值
            print("光源状态已切换为：" .. tostring(value))
        else
            warn("光源尚未创建，无法切换状态！")
        end
    else
        rawset(self, key, value) -- 其他属性直接设置
    end
end

-- 卸载整个模块：清理所有资源+断开所有事件
function LocalPlayerLight:unload()
    if not self.isLoaded then
        warn("光源模块已卸载，无需重复操作！")
        return
    end

    -- 1. 清理光源和附件
    self:cleanupLight()

    -- 2. 断开角色重生事件连接
    if self.characterAddedConnection then
        self.characterAddedConnection:Disconnect()
        self.characterAddedConnection = nil
    end

    -- 3. 标记为已卸载
    self.isLoaded = false
    self.config = nil
    self.localPlayer = nil

    print("本地玩家光源模块已完全卸载！")
end

-- 返回模块类
return LocalPlayerLight