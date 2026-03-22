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
        bindKey = Enum.KeyCode.C,           -- 默认绑定C键
        tweenTime = 0.15,                   -- 动画时间（秒）
        scrollSensitivity = 5,              -- 滚轮灵敏度（越大调整越快）
        minZoomFOV = 15,                    -- 最小缩放视野（数值越小放大倍数越大）
    }
    
    -- 状态变量
    self.isEnabled = false                  -- 模块是否启用
    self.isZooming = false                  -- 是否正在缩放状态
    self.normalFOV = 70                     -- 正常视野，启用时从相机获取
    self.currentZoomFOV = 30                -- 当前缩放视野（可通过滚轮调整）
    self.originalCameraType = nil           -- 保存原始摄像机类型
    
    -- 连接对象
    self.connections = {
        inputBegan = nil,
        inputEnded = nil,
    }
    
    self.camera = workspace.CurrentCamera
    return self
end

-- 获取正常视野
function ZoomModule:GetNormalFOV()
    return self.normalFOV
end

-- 设置正常视野（谨慎使用）
function ZoomModule:SetNormalFOV(fov)
    self.normalFOV = fov
    if not self.isZooming and self.isEnabled then
        self.camera.FieldOfView = self.normalFOV
    end
end

-- 更新视野（带动画）
function ZoomModule:UpdateCameraFOV(targetFOV)
    local tween = TweenService:Create(self.camera, TweenInfo.new(self.config.tweenTime), {FieldOfView = targetFOV})
    tween:Play()
end

-- 处理滚轮缩放（仅在缩放状态下调用）
function ZoomModule:OnMouseWheel(input)
    if not self.isZooming or not self.isEnabled then return end
    
    local scrollDelta = input.Position.Z
    if scrollDelta == 0 then return end
    
    -- 计算新的缩放视野
    local newZoomFOV = self.currentZoomFOV - (scrollDelta * self.config.scrollSensitivity)
    newZoomFOV = math.clamp(newZoomFOV, self.config.minZoomFOV, self.normalFOV)
    
    if newZoomFOV == self.currentZoomFOV then return end
    
    self.currentZoomFOV = newZoomFOV
    self:UpdateCameraFOV(self.currentZoomFOV)
    
    -- 标记事件已处理，防止引擎进一步响应
    input:Processed()
end

-- 开始缩放
function ZoomModule:StartZoom()
    if not self.isEnabled then return end
    
    self.isZooming = true
    
    -- 保存原始摄像机类型并设置为脚本控制（阻止引擎滚轮行为）
    self.originalCameraType = self.camera.CameraType
    self.camera.CameraType = Enum.CameraType.Scriptable
    -- 确保鼠标行为不被锁定（避免不必要的干扰）
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    -- 确保当前缩放视野在合理范围内
    if self.currentZoomFOV > self.normalFOV then
        self.currentZoomFOV = math.min(30, self.normalFOV - 10)
    end
    self:UpdateCameraFOV(self.currentZoomFOV)
end

-- 结束缩放
function ZoomModule:StopZoom()
    if not self.isEnabled then return end
    
    self.isZooming = false
    self:UpdateCameraFOV(self.normalFOV)
    
    -- 恢复原始摄像机类型
    if self.originalCameraType then
        self.camera.CameraType = self.originalCameraType
        self.originalCameraType = nil
    end
end

-- 设置绑定按键
function ZoomModule:SetBindKey(keyType)
    self.config.bindKey = keyType
end

-- 获取绑定按键
function ZoomModule:GetBindKey()
    return self.config.bindKey
end

-- 设置最小缩放视野
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

-- 检查输入是否匹配绑定按键
function ZoomModule:IsMatchingInput(input)
    return input.UserInputType == self.config.bindKey or input.KeyCode == self.config.bindKey
end

-- 启用模块
function ZoomModule:Enable()
    if self.isEnabled then return end
    
    self.normalFOV = self.camera.FieldOfView
    local defaultZoomFOV = math.max(15, self.normalFOV - 10)
    self.currentZoomFOV = math.min(defaultZoomFOV, self.normalFOV)
    
    self.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if self:IsMatchingInput(input) then
            self:StartZoom()
        end
        
        if input.UserInputType == Enum.UserInputType.MouseWheel then
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

-- 完全卸载模块
function ZoomModule:Unload()
    self:Disable()
    self.camera = nil
    self.config = nil
    self.connections = nil
    self.isEnabled = nil
    self.isZooming = nil
    self.normalFOV = nil
    self.currentZoomFOV = nil
    self.originalCameraType = nil
end

return ZoomModule