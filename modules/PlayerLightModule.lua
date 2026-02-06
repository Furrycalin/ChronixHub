-- PlayerLightModuleFinalFixed.lua
-- 一个用于为本地玩家创建和管理绑定光源的模块 (带启用/禁用和全局卸载功能 - 已修复)

local Players = game:GetService("Players")

local PlayerLightModule = {}

-- 存储所有活动的光源实例，用于全局卸载
local ActiveLights = {}

-- 配置表模板：定义光源的所有参数
local DefaultLightConfig = {
    -- PointLight 属性
    Enabled = true, -- 这个是PointLight组件本身的Enabled状态
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
    self.isEnabled = false -- 内部状态标志，记录模块层面是否启用

    -- 将当前实例添加到活动列表中
    table.insert(ActiveLights, self)

    -- 内部方法：创建光源结构
    local function _createLightStructure(char)
        -- 总是先销毁旧的结构，以应对角色重生等情况
        if self.attachment then self.attachment:Destroy() end
        if self.pointLight then self.pointLight:Destroy() end

        local bodyPart = char:FindFirstChild(self.config.AttachToBodyPart)
        if not bodyPart or not bodyPart:IsA("BasePart") then
            warn("无法在角色上找到身体部位: " .. self.config.AttachToBodyPart)
            return
        end

        self.attachment = Instance.new("Attachment")
        self.attachment.Name = self.config.Attachment_Name
        self.attachment.CFrame = CFrame.new(self.config.Offset_Position) * CFrame.Angles(
            math.rad(self.config.Offset_Rotation.X),
            math.rad(self.config.Offset_Rotation.Y),
            math.rad(self.config.Offset_Rotation.Z)
        )
        self.attachment.Parent = bodyPart

        self.pointLight = Instance.new("PointLight")
        -- 初始状态设置为禁用，等待enable()调用
        self.pointLight.Enabled = false 
        self.pointLight.Brightness = self.config.Brightness
        self.pointLight.Range = self.config.Range
        self.pointLight.Color = self.config.Color
        self.pointLight.Shadows = self.config.Shadows
        self.pointLight.Parent = self.attachment
    end

    -- 内部方法：应用光源到角色 (创建结构)
    local function _applyLight(char)
        _createLightStructure(char)
    end

    -- 公共方法：初始化（但不启用）
    self.init = function()
        local localPlayer = Players.LocalPlayer
        if not localPlayer then
            -- 如果在服务器端运行，等待本地玩家出现
            Players.LocalPlayerAdded:Connect(function(player)
                if player == Players.LocalPlayer then
                    self:_attachToCharacter(player)
                end
            end)
            return
        end
        self:_attachToCharacter(localPlayer)
    end

    -- 内部辅助方法：处理角色加载和重生
    self._attachToCharacter = function(player)
        -- 1. 获取角色：如果角色已存在就直接用，否则等待它加载
        local char = player.Character
        if not char then
            -- 等待 CharacterAdded 信号触发
            char = player.CharacterAdded:Wait()
        end
        self.character = char
        
        -- 2. 等待角色的基础部件加载完成，然后应用光源
        local humanoidRootPart = char:WaitForChild("HumanoidRootPart")
        if humanoidRootPart then
            _applyLight(char)
        end

        -- 3. 监听角色重生
        if self.connection then self.connection:Disconnect() end
        self.connection = player.CharacterAdded:Connect(function(newChar)
            wait()
            -- 如果实例已被卸载，则不再处理重生
            if not self.attachment and not self.pointLight then return end
            
            self.character = newChar
            _applyLight(newChar)
        end)
    end

    -- 公共方法：启用光源
    self.enable = function()
        if self.isEnabled then
            print("光源 " .. tostring(self) .. " 已经是启用状态。")
            return
        end

        if self.pointLight then
            self.pointLight.Enabled = true
            self.isEnabled = true
            print("光源 " .. tostring(self) .. " 已启用。")
        else
            -- 如果角色尚未加载，结构未创建，则设置标志，等结构创建后再启用
            self.isEnabled = true
            print("准备启用光源 " .. tostring(self) .. " (等待角色加载)。")
        end
    end

    -- 公共方法：禁用光源
    self.disable = function()
        if not self.isEnabled then
            print("光源 " .. tostring(self) .. " 已经是禁用状态。")
            return
        end

        if self.pointLight then
            self.pointLight.Enabled = false
            self.isEnabled = false
            print("光源 " .. tostring(self) .. " 已禁用。")
        else
            self.isEnabled = false
            print("光源 " .. tostring(self) .. " 已设置为禁用状态 (等待角色加载)。")
        end
    end

    -- 公共方法：卸载光源 (从全局列表中移除自身)
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
        
        -- 从全局活动列表中移除自己
        for i, v in ipairs(ActiveLights) do
            if v == self then
                table.remove(ActiveLights, i)
                break
            end
        end
        
        print("光源实例 " .. tostring(self) .. " 已卸载。")
    end

    -- 初始化光源结构 (但不启用)
    self:init()

    return self
end

-- 模块的入口函数，用于创建新的光源实例
PlayerLightModule.new = function(config)
    -- 确保传入的是一个表，即使是空的
    config = config or {}
    return createLightInstance(config)
end

-- 模块的全局卸载函数，卸载所有由该模块创建的实例
PlayerLightModule.unload = function()
    print("正在卸载所有由 PlayerLightModule 创建的光源...")
    -- 从后往前遍历，安全地移除所有实例
    for i = #ActiveLights, 1, -1 do
        local lightInstance = ActiveLights[i]
        lightInstance.unload() -- 调用实例的unload方法
    end
    print("所有光源已卸载。")
end

return PlayerLightModule