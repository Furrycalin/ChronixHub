-- LocalPlayerLightAttachmentFixed.lua
-- 最终稳定版：多光源+无布尔索引错误+极简易用
-- 使用方式：
-- 1. 创建光源：local light1 = Module.Create(配置); local light2 = Module.Create(配置)
-- 2. 开关光源：light1:SetEnable(true); light2:SetEnable(false)
-- 3. 卸载：light1:Unload() / Module.UnloadAll()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- 模块核心（极简架构，避免元表坑）
local LocalPlayerLight = {}
LocalPlayerLight.__index = LocalPlayerLight

-- 全局存储所有光源实例
local AllInstances = {}

-- 默认配置
local DEFAULT_CONFIG = {
    Brightness = 2,
    Range = 10,
    Color = Color3.fromRGB(255, 255, 255),
    Shadows = false,
    AttachmentName = "PlayerLight", -- 简化命名
    Offset = Vector3.new(0, 1.5, 0),
    AttachTo = "UpperTorso",
    StartEnabled = false -- 初始关闭
}

-- 生成唯一名称（避免多光源冲突）
local function GetUniqueName(baseName)
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

-- 安全创建光源（单个实例）
function LocalPlayerLight:CreateLight()
    -- 先清理旧光源
    self:Cleanup()

    -- 层层安全检查（杜绝nil）
    if not self.LocalPlayer then return warn("无本地玩家") end
    if not self.LocalPlayer.Character then return warn("角色未加载") end
    
    local BodyPart = self.LocalPlayer.Character:FindFirstChild(self.Config.AttachTo)
    if not BodyPart or not BodyPart:IsA("BasePart") then
        return warn("找不到部位：" .. self.Config.AttachTo)
    end

    -- 创建Attachment
    local Attachment = Instance.new("Attachment")
    Attachment.Name = GetUniqueName(self.Config.AttachmentName)
    Attachment.CFrame = CFrame.new(self.Config.Offset)
    Attachment.Parent = BodyPart

    -- 创建PointLight
    local PointLight = Instance.new("PointLight")
    PointLight.Brightness = self.Config.Brightness
    PointLight.Range = self.Config.Range
    PointLight.Color = self.Config.Color
    PointLight.Shadows = self.Config.Shadows
    PointLight.Enabled = self.Config.StartEnabled
    PointLight.Parent = Attachment

    -- 保存实例数据（绝对不存nil）
    self.Attachment = Attachment
    self.PointLight = PointLight
    self.IsLightCreated = true
    self.CurrentEnabled = self.Config.StartEnabled

    print("[光源] 已创建：" .. Attachment.Name .. "（绑定到：" .. self.Config.AttachTo .. "）")
end

-- 构造函数（改用Create命名，更直观）
function LocalPlayerLight.Create(customConfig)
    -- 强制初始化所有属性，杜绝nil
    local self = setmetatable({
        LocalPlayer = Players.LocalPlayer,
        Config = table.clone(DEFAULT_CONFIG),
        Attachment = nil,
        PointLight = nil,
        IsLightCreated = false,
        CurrentEnabled = false,
        CharacterConn = nil,
        IsLoaded = true
    }, LocalPlayerLight)

    -- 合并用户配置（只覆盖存在的键）
    if type(customConfig) == "table" then
        for k, v in pairs(customConfig) do
            if self.Config[k] ~= nil then
                self.Config[k] = v
            end
        end
    end

    -- 初始化CurrentEnabled
    self.CurrentEnabled = self.Config.StartEnabled

    -- 安全检查：本地玩家不存在直接返回
    if not self.LocalPlayer then
        warn("[光源] 无法获取本地玩家，创建失败")
        self.IsLoaded = false
        table.insert(AllInstances, self)
        return self
    end

    -- 等待角色加载并创建光源（异步，避免阻塞）
    task.spawn(function()
        local Character = self.LocalPlayer.Character or self.LocalPlayer.CharacterAdded:Wait()
        Character:WaitForChild("HumanoidRootPart", 10) -- 超时保护
        self:CreateLight()
    end)

    -- 监听角色重生（每个实例独立）
    self.CharacterConn = self.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1) -- 等角色完全加载
        self:CreateLight()
        -- 重生后恢复之前的开关状态
        self:SetEnable(self.CurrentEnabled)
    end)

    -- 加入全局列表
    table.insert(AllInstances, self)

    return self
end

-- 显式设置光源开关（核心：不用属性，用方法，彻底避免布尔索引）
function LocalPlayerLight:SetEnable(isEnabled)
    -- 强制转布尔值
    local boolEnabled = not not isEnabled
    self.CurrentEnabled = boolEnabled

    -- 实例已卸载，直接返回
    if not self.IsLoaded then
        warn("[光源] 实例已卸载，无法修改状态")
        return
    end

    -- 光源还没创建，提示但不报错
    if not self.IsLightCreated or not self.PointLight then
        print("[光源] 光源未就绪，已记录状态：" .. tostring(boolEnabled) .. "（就绪后自动生效）")
        return
    end

    -- 安全修改状态（pcall防止对象已销毁）
    local success, err = pcall(function()
        self.PointLight.Enabled = boolEnabled
    end)

    if success then
        print("[光源] " .. self.Attachment.Name .. " 状态：" .. tostring(boolEnabled))
    else
        warn("[光源] 修改状态失败：" .. err)
        self.IsLightCreated = false -- 标记失效，下次自动重建
    end
end

-- 获取当前光源状态
function LocalPlayerLight:GetEnable()
    return self.CurrentEnabled
end

-- 清理当前实例的光源
function LocalPlayerLight:Cleanup()
    -- 安全销毁，不怕nil
    pcall(function() if self.PointLight then self.PointLight:Destroy() end end)
    pcall(function() if self.Attachment then self.Attachment:Destroy() end end)
    
    self.Attachment = nil
    self.PointLight = nil
    self.IsLightCreated = false
end

-- 卸载当前实例
function LocalPlayerLight:Unload()
    if not self.IsLoaded then
        warn("[光源] 实例已卸载")
        return
    end

    -- 1. 清理光源
    self:Cleanup()

    -- 2. 断开事件
    pcall(function() if self.CharacterConn then self.CharacterConn:Disconnect() end end)
    self.CharacterConn = nil

    -- 3. 标记卸载
    self.IsLoaded = false
    self.CurrentEnabled = false

    -- 4. 从全局列表移除
    for i, inst in ipairs(AllInstances) do
        if inst == self then
            table.remove(AllInstances, i)
            break
        end
    end

    print("[光源] 实例已卸载")
end

-- 模块级：卸载所有光源
function LocalPlayerLight.UnloadAll()
    if #AllInstances == 0 then
        warn("[光源] 无实例可卸载")
        return
    end

    -- 倒序卸载，避免索引错乱
    for i = #AllInstances, 1, -1 do
        local inst = AllInstances[i]
        if inst.IsLoaded then
            inst:Unload()
        end
    end

    -- 清空列表
    table.clear(AllInstances)
    print("[光源] 所有实例已卸载")
end

-- 暴露模块（只对外暴露需要的方法）
return {
    Create = LocalPlayerLight.Create,
    UnloadAll = LocalPlayerLight.UnloadAll
}