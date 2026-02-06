-- LocalPlayerLightAttachmentModule.lua
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 核心模块
local PlayerLight = {}
PlayerLight.__index = PlayerLight

-- 存储所有实例
local AllInstances = {}

-- 默认配置
local DEFAULT_CONFIG = {
    Brightness = 2,
    Range = 10,
    Color = Color3.fromRGB(255,255,255),
    Shadows = false,
    AttachmentName = "PlayerLight",
    Offset = Vector3.new(0,1.5,0),
    AttachTo = "UpperTorso"
}

-- 构造函数：new(config)
function PlayerLight.new(customConfig)
    -- 合并配置
    local config = table.clone(DEFAULT_CONFIG)
    if type(customConfig) == "table" then
        for k,v in pairs(customConfig) do
            config[k] = v
        end
    end

    -- 实例对象（所有属性初始化，避免nil）
    local self = setmetatable({}, PlayerLight)
    self.config = config
    self.PlayerLightData = nil  -- 光源数据（初始化为nil）
    self.CharacterAddedConn = nil -- 监听连接（初始化为nil）

    -- 初始化（绑定角色）
    self:_bindToLocalPlayer()

    -- 加入全局列表
    table.insert(AllInstances, self)
    return self
end

-- 内部：绑定到本地玩家
function PlayerLight:_bindToLocalPlayer()
    if not LocalPlayer then return end

    -- 监听角色加载/重生
    local function onCharacterAdded(character)
        -- 等待角色核心部件加载
        local humanoid = character:WaitForChild("Humanoid", 5)
        local bodyPart = character:WaitForChild(self.config.AttachTo, 5)
        if not humanoid or not bodyPart then return end

        -- 先清理旧光源（加前置检查）
        self:_cleanupOldLight()

        -- 创建Attachment和PointLight
        local attachment = Instance.new("Attachment")
        attachment.Name = self.config.AttachmentName
        attachment.Position = self.config.Offset
        attachment.Parent = bodyPart

        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = self.config.Brightness
        pointLight.Range = self.config.Range
        pointLight.Color = self.config.Color
        pointLight.Shadows = self.config.Shadows
        pointLight.Enabled = false -- 默认禁用
        pointLight.Parent = attachment

        -- 赋值PlayerLightData（只有创建成功才赋值）
        self.PlayerLightData = {
            Attachment = attachment,
            PointLight = pointLight
        }
    end

    -- 绑定角色加载事件
    self.CharacterAddedConn = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    -- 立即执行一次（处理已加载的角色）
    if LocalPlayer.Character then
        task.spawn(onCharacterAdded, LocalPlayer.Character)
    end
end

-- 内部：清理旧光源（核心防呆）
function PlayerLight:_cleanupOldLight()
    -- 第一步：检查PlayerLightData是否存在，不存在直接返回（杜绝空值）
    if not self.PlayerLightData then return end

    -- 安全销毁（用pcall防重复销毁）
    pcall(function() self.PlayerLightData.PointLight:Destroy() end)
    pcall(function() self.PlayerLightData.Attachment:Destroy() end)
    
    -- 置空（关键）
    self.PlayerLightData = nil
end

-- 公共方法：开启光源（100%防空值）
function PlayerLight:enable()
    -- 第一步：检查PlayerLightData是否存在
    if not self.PlayerLightData then
        warn("光源尚未创建，无法开启")
        return
    end
    -- 第二步：检查PointLight是否存在
    if not self.PlayerLightData.PointLight then
        warn("光源组件丢失，无法开启")
        return
    end
    -- 执行开启
    self.PlayerLightData.PointLight.Enabled = true
    print("光源已开启")
end

-- 公共方法：关闭光源（100%防空值）
function PlayerLight:disable()
    if not self.PlayerLightData then
        warn("光源尚未创建，无法关闭")
        return
    end
    if not self.PlayerLightData.PointLight then
        warn("光源组件丢失，无法关闭")
        return
    end
    self.PlayerLightData.PointLight.Enabled = false
    print("光源已关闭")
end

-- 公共方法：卸载当前光源（100%防空值）
function PlayerLight:unload()
    -- 1. 清理光源（即使PlayerLightData为nil，_cleanupOldLight也会直接返回）
    self:_cleanupOldLight()

    -- 2. 断开监听（检查连接是否存在）
    if self.CharacterAddedConn then
        pcall(function() self.CharacterAddedConn:Disconnect() end)
        self.CharacterAddedConn = nil
    end

    -- 3. 从全局列表移除
    for i = #AllInstances, 1, -1 do
        if AllInstances[i] == self then
            table.remove(AllInstances, i)
            break
        end
    end

    print("光源实例已卸载")
end

-- 模块全局方法：卸载所有光源
function PlayerLight.unloadAll()
    for _, instance in ipairs(AllInstances) do
        if instance and type(instance.unload) == "function" then
            instance:unload()
        end
    end
    AllInstances = {}
    print("所有光源已卸载")
end

-- 返回模块
return PlayerLight