-- PlayerLightModuleFromOriginal.lua
-- 基于原始可靠脚本封装的模块

local Players = game:GetService("Players")

local PlayerLightModule = {}

-- 配置表模板：定义光源的所有参数
local DefaultLightConfig = {
    -- PointLight 属性
    Enabled = true,
    Brightness = 2,
    Range = 10,
    Color = Color3.fromRGB(255, 255, 255),
    Shadows = false,

    -- 附加 Attachment 的属性
    Attachment_Name = "PlayerLightAttachment",
    Offset_Position = Vector3.new(0, 1.5, 0),
    Offset_Rotation = Vector3.new(0, 0, 0),

    -- 绑定的目标身体部位
    AttachToBodyPart = "UpperTorso",
}

-- 光源实例的构造函数
local function createLightInstance(config)
    local self = {}
    -- 使用传入的配置覆盖默认配置
    self.config = {}
    for k, v in pairs(DefaultLightConfig) do
        self.config[k] = config[k] ~= nil and config[k] or v
    end

    self.attachment = nil
    self.pointLight = nil
    self.character = nil
    self.connection = nil
    self.isEnabled = false -- 内部状态标志

    -- 内部方法：创建光源结构
    local function _createLightStructure(char)
        -- 总是先销毁旧的结构
        if self.attachment then self.attachment:Destroy() end
        if self.pointLight then self.pointLight:Destroy() end

        -- 修复：等待目标身体部位加载
        local bodyPart = char:WaitForChild(self.config.AttachToBodyPart)
        if not bodyPart or not bodyPart:IsA("BasePart") then
            warn("无法在角色上找到身体部位 (WaitForChild): " .. self.config.AttachToBodyPart)
            return
        end

        -- 1. 创建一个 Attachment 作为光源的载体
        self.attachment = Instance.new("Attachment")
        self.attachment.Name = self.config.Attachment_Name
        self.attachment.CFrame = CFrame.new(self.config.Offset_Position) * CFrame.Angles(
            math.rad(self.config.Offset_Rotation.X),
            math.rad(self.config.Offset_Rotation.Y),
            math.rad(self.config.Offset_Rotation.Z)
        )
        self.attachment.Parent = bodyPart

        -- 2. 在 Attachment 上创建 PointLight 并应用配置
        self.pointLight = Instance.new("PointLight")
        -- 初始状态设置为禁用
        self.pointLight.Enabled = false 
        self.pointLight.Brightness = self.config.Brightness
        self.pointLight.Range = self.config.Range
        self.pointLight.Color = self.config.Color
        self.pointLight.Shadows = self.config.Shadows
        self.pointLight.Parent = self.attachment

        -- 3. 根据内部状态决定是否点亮
        if self.isEnabled then
            self.pointLight.Enabled = true
        end
    end

    -- 内部方法：等待角色加载并附加光源
    local function _waitForCharacterAndAttachLight(player)
        local character = player.Character or player.CharacterAdded:Wait()
        self.character = character
        
        -- 等待角色的基本部分加载完成 (这是一个可靠的信号)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        if humanoidRootPart then
            _createLightStructure(character)
        else
            warn("未能找到 HumanoidRootPart，无法附加光源。")
        end
    end

    -- 公共方法：初始化（但不启用）
    self.init = function()
        local localPlayer = Players.LocalPlayer
        if not localPlayer then
            Players.LocalPlayerAdded:Connect(function(p)
                if p == Players.LocalPlayer then
                    _waitForCharacterAndAttachLight(p)
                end
            end)
            return
        end
        _waitForCharacterAndAttachLight(localPlayer)
    end

    -- 监听角色重生事件
    self._attachRebirthListener = function(player)
        if self.connection then self.connection:Disconnect() end
        self.connection = player.CharacterAdded:Connect(function(newChar)
            wait() -- 等待角色完全加载
            self.character = newChar
            -- 对新角色也执行同样的等待和创建流程
            local newHumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
            if newHumanoidRootPart then
                _createLightStructure(newChar)
            else
                 warn("角色重生后未能找到 HumanoidRootPart，光源未附加。")
            end
        end)
    end

    -- 公共方法：启用光源
    self.enable = function()
        if self.isEnabled then
            print("光源 " .. tostring(self) .. " 已经是启用状态。")
            return
        end
        self.isEnabled = true
        if self.pointLight then
            self.pointLight.Enabled = true
            print("光源 " .. tostring(self) .. " 已启用。")
        else
             print("准备启用光源 " .. tostring(self) .. " (等待角色加载)。")
        end
    end

    -- 公共方法：禁用光源
    self.disable = function()
        if not self.isEnabled then
            print("光源 " .. tostring(self) .. " 已经是禁用状态。")
            return
        end
        self.isEnabled = false
        if self.pointLight then
            self.pointLight.Enabled = false
            print("光源 " .. tostring(self) .. " 已禁用。")
        end
    end

    -- 公共方法：卸载光源
    self.unload = function()
        self:disable() -- 先确保禁用
        if self.attachment then
            self.attachment:Destroy()
            self.attachment = nil
        end
        if self.pointLight then
            self.pointLight:Destroy()
            self.pointLight = nil
        end
        if self.connection then
            self.connection:Disconnect()
            self.connection = nil
        end
        self.character = nil
        print("光源实例 " .. tostring(self) .. " 已卸载。")
    end

    -- 初始化监听器
    local localPlayer = Players.LocalPlayer
    if localPlayer then
        self:_attachRebirthListener(localPlayer)
    else
        Players.LocalPlayerAdded:Connect(function(player)
            if player == Players.LocalPlayer then
                self:_attachRebirthListener(player)
            end
        end)
    end

    -- 初始化光源结构 (但不启用)
    self:init()

    return self
end

-- 模块的入口函数
PlayerLightModule.new = function(config)
    config = config or {}
    return createLightInstance(config)
end

-- 全局卸载函数
PlayerLightModule.unload = function()
    print("PlayerLightModule 不支持全局卸载。请单独调用每个实例的 unload() 方法。")
    -- 如果需要全局卸载，可以像之前的版本一样维护一个 ActiveLights 表。
    -- 这里为了纯粹基于原始逻辑，简化处理。
end

return PlayerLightModule