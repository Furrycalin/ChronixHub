-- ZoomModule.lua
-- 一个可扩展的摄像机缩放模块，类似我的世界的缩放功能

local ZoomModule = {}
ZoomModule.__index = ZoomModule

-- 依赖服务
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- 构造函数
function ZoomModule.new()
    local self = setmetatable({}, ZoomModule)
    
    -- 配置参数
    self.config = {
        -- 按键绑定，默认为C键
        bindKey = Enum.KeyCode.C,
        -- 缩放过渡动画时间（秒）
        tweenTime = 0.15,
        -- 滚轮调整灵敏度，数值越小调整越慢
        scrollSensitivity = 5,
        -- 最小缩放视野（数值越小放大倍数越大）
        minZoomFOV = 15,
    }
    
    -- 状态变量
    self.isEnabled = false           -- 模块是否启用
    self.isZooming = false           -- 是否正在缩放状态
    self.normalFOV = 70              -- 正常视野，会在启用时从相机获取
    self.currentZoomFOV = 30         -- 当前缩放时的视野，可通过滚轮调整
    
    -- 连接对象，用于后续断开
    self.connections = {
        inputBegan = nil,
        inputEnded = nil,
    }
    
    -- 相机引用
    self.camera = workspace.CurrentCamera
    
    return self
end

-- 获取当前正常视野
function ZoomModule:GetNormalFOV()
    return self.normalFOV
end

-- 设置正常视野（如果需要在运行时修改）
function ZoomModule:SetNormalFOV(fov)
    self.normalFOV = fov
    -- 如果不在缩放状态，立即应用
    if not self.isZooming and self.isEnabled then
        self.camera.FieldOfView = self.normalFOV
    end
end

-- 更新相机的视野（带动画）
function ZoomModule:UpdateCameraFOV(targetFOV)
    local tween = TweenService:Create(self.camera, TweenInfo.new(self.config.tweenTime), {FieldOfView = targetFOV})
    tween:Play()
end

-- 处理滚轮缩放
function ZoomModule:OnMouseWheel(input)
    if not self.isZooming or not self.isEnabled then return end
    
    -- 获取滚轮滚动量（正值向上，负值向下）
    local scrollDelta = input.Delta.Z
    if scrollDelta == 0 then return end  -- 防止无效滚动
    
    -- 计算新的缩放视野
    local newZoomFOV = self.currentZoomFOV - (scrollDelta * self.config.scrollSensitivity)
    
    -- 限制范围：最小为配置的最小缩放视野，最大为正常视野
    newZoomFOV = math.clamp(newZoomFOV, self.config.minZoomFOV, self.normalFOV)
    
    -- 如果数值没有变化，不更新
    if newZoomFOV == self.currentZoomFOV then return end
    
    -- 更新当前缩放视野
    self.currentZoomFOV = newZoomFOV
    
    -- 应用新的视野
    self:UpdateCameraFOV(self.currentZoomFOV)
    
    -- 关键：标记滚轮事件已处理，阻止摄像机距离调整
    input:Processed()
end

-- 开始缩放
function ZoomModule:StartZoom()
    if not self.isEnabled then return end
    
    self.isZooming = true
    
    -- 确保当前缩放视野在合理范围内（防止超出正常视野）
    if self.currentZoomFOV > self.normalFOV then
        -- 如果当前值大于正常视野，重置为合理的默认值
        self.currentZoomFOV = math.max(self.config.minZoomFOV, self.normalFOV - 10)
        self.currentZoomFOV = math.min(self.currentZoomFOV, self.normalFOV)
    end
    
    self:UpdateCameraFOV(self.currentZoomFOV)
end

-- 结束缩放
function ZoomModule:StopZoom()
    if not self.isEnabled then return end
    
    self.isZooming = false
    self:UpdateCameraFOV(self.normalFOV)
end

-- 设置绑定的按键
function ZoomModule:SetBindKey(keyType)
    self.config.bindKey = keyType
end

-- 获取当前绑定的按键
function ZoomModule:GetBindKey()
    return self.config.bindKey
end

-- 设置最小缩放视野（放大倍数）
function ZoomModule:SetMinZoomFOV(minFOV)
    self.config.minZoomFOV = minFOV
    if self.isZooming and self.currentZoomFOV < minFOV then
        self.currentZoomFOV = minFOV
        self:UpdateCameraFOV(self.currentZoomFOV)
    end
end

-- 获取最小缩放视野
function ZoomModule:GetMinZoomFOV()
    return self.config.minZoomFOV
end

-- 设置滚轮灵敏度
function ZoomModule:SetScrollSensitivity(sensitivity)
    self.config.scrollSensitivity = sensitivity
end

-- 获取滚轮灵敏度
function ZoomModule:GetScrollSensitivity()
    return self.config.scrollSensitivity
end

-- 设置动画时间
function ZoomModule:SetTweenTime(time)
    self.config.tweenTime = time
end

-- 获取动画时间
function ZoomModule:GetTweenTime()
    return self.config.tweenTime
end

-- 检查输入是否匹配绑定的按键
function ZoomModule:IsMatchingInput(input)
    if input.UserInputType == self.config.bindKey then
        return true
    end
    if input.KeyCode == self.config.bindKey then
        return true
    end
    return false
end

-- 启用模块
function ZoomModule:Enable()
    if self.isEnabled then return end
    
    -- 获取当前玩家的正常视野
    self.normalFOV = self.camera.FieldOfView
    
    -- 初始化当前缩放视野为默认值（不超过正常视野）
    local defaultZoomFOV = math.max(15, self.normalFOV - 10)
    defaultZoomFOV = math.min(defaultZoomFOV, self.normalFOV)
    self.currentZoomFOV = defaultZoomFOV
    
    -- 连接输入事件
    self.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- 处理缩放按键开始
        if self:IsMatchingInput(input) then
            self:StartZoom()
        end
        
        -- 处理鼠标滚轮
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            -- 只在缩放状态下处理滚轮，并阻止默认行为
            if self.isZooming then
                self:OnMouseWheel(input)
            end
        end
    end)
    
    self.connections.inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if self:IsMatchingInput(input) then
            self:StopZoom()
        end
    end)
    
    self.isEnabled = true
end

-- 禁用模块
function ZoomModule:Disable()
    if not self.isEnabled then return end
    
    if self.isZooming then
        self:StopZoom()
        self.isZooming = false
    end
    
    if self.connections.inputBegan then
        self.connections.inputBegan:Disconnect()
        self.connections.inputBegan = nil
    end
    
    if self.connections.inputEnded then
        self.connections.inputEnded:Disconnect()
        self.connections.inputEnded = nil
    end
    
    self.isEnabled = false
end

-- 卸载模块，完全清理资源
function ZoomModule:Unload()
    self:Disable()
    self.camera = nil
    self.config = nil
    self.connections = nil
    self.isEnabled = nil
    self.isZooming = nil
    self.normalFOV = nil
    self.currentZoomFOV = nil
end

return ZoomModule