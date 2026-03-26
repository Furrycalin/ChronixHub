-- ================================================
-- 文件名：NameTagModule.lua
-- 放置位置：ReplicatedStorage（客户端 require 使用）
-- ================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local NameTagModule = {}
local instances = {}          -- 存储所有创建的实例，用于模块级卸载

-- 本地玩家（仅客户端有效）
local LocalPlayer = Players.LocalPlayer

-- -------------------------------------------------
-- 实例元表
-- -------------------------------------------------
local NameTagManager = {}
NameTagManager.__index = NameTagManager

--[[
	.new(
		modelName: string,                -- 要匹配的模型名称
		matchMode: "精准"|"模糊",         -- 匹配模式
		fontSize: number?,               -- 字号（nil 则自动缩放）
		showDistance: boolean?,          -- 是否显示与本地玩家的距离
		customText: string?             -- 自定义显示文本（nil 则显示模型原名）
	)
	返回值：NameTagManager 实例（默认禁用）
--]]
function NameTagModule.new(modelName, matchMode, fontSize, showDistance, customText)
	local self = setmetatable({}, NameTagManager)
	
	-- 参数
	self.modelName = modelName
	self.matchMode = matchMode == "模糊" and "模糊" or "精准"
	self.fontSize = fontSize
	self.showDistance = showDistance or false
	self.customText = customText
	
	-- 状态
	self.enabled = false
	self.connections = {}          -- 存储所有 RBXScriptConnection
	self.activeTags = {}           -- { [Model] = {billboard, label} }
	self.pendingTasks = {}         -- 存储等待任务句柄，用于取消
	
	-- 添加到全局实例列表
	table.insert(instances, self)
	
	return self
end

-- -------------------------------------------------
-- 启用标签：扫描现有 + 监听新模型
-- -------------------------------------------------
function NameTagManager:enable()
	if self.enabled then return end
	self.enabled = true
	
	-- 1. 为已存在的模型添加标签（异步处理）
	self:_scanExistingModelsAsync()
	
	-- 2. 监听新添加的模型
	local conn = Workspace.DescendantAdded:Connect(function(desc)
		self:_onDescendantAdded(desc)
	end)
	table.insert(self.connections, conn)
	
	-- 3. 若开启距离显示，启动每帧更新
	if self.showDistance then
		local heartbeatConn = RunService.Heartbeat:Connect(function()
			self:_updateDistances()
		end)
		table.insert(self.connections, heartbeatConn)
	end
end

-- -------------------------------------------------
-- 禁用标签：断开监听 + 移除所有已添加标签 + 取消等待任务
-- -------------------------------------------------
function NameTagManager:disable()
	if not self.enabled then return end
	self.enabled = false
	
	-- 断开所有连接
	for _, conn in ipairs(self.connections) do
		conn:Disconnect()
	end
	self.connections = {}
	
	-- 取消所有正在等待的添加任务
	for _, task in pairs(self.pendingTasks) do
		task.cancelled = true
	end
	self.pendingTasks = {}
	
	-- 移除所有已添加的 BillboardGui
	self:_removeAllTags()
end

-- -------------------------------------------------
-- 销毁当前实例（彻底清理，并从模块实例列表移除）
-- -------------------------------------------------
function NameTagManager:destroy()
	self:disable()
	
	-- 从模块实例列表中移除自身
	for i, inst in ipairs(instances) do
		if inst == self then
			table.remove(instances, i)
			break
		end
	end
	
	-- 断开所有可能的外部引用（元表置空，便于GC）
	setmetatable(self, nil)
end

-- -------------------------------------------------
-- 模块级卸载：销毁所有实例，彻底清空功能
-- -------------------------------------------------
function NameTagModule.unload()
	-- 反向遍历，避免索引错误
	for i = #instances, 1, -1 do
		local inst = instances[i]
		if inst and inst.destroy then
			inst:destroy()
		end
	end
	instances = {}
end

-- -------------------------------------------------
-- 私有方法：异步扫描所有现有模型（避免阻塞）
-- -------------------------------------------------
function NameTagManager:_scanExistingModelsAsync()
	task.spawn(function()
		-- 先获取所有模型（GetDescendants 可能较大，但只执行一次）
		local allDescendants = Workspace:GetDescendants()
		for _, desc in ipairs(allDescendants) do
			-- 检查是否已被禁用（可能扫描过程中用户关闭了功能）
			if not self.enabled then return end
			self:_onDescendantAdded(desc)
		end
	end)
end

-- -------------------------------------------------
-- 私有方法：处理单个新加入的对象
-- -------------------------------------------------
function NameTagManager:_onDescendantAdded(desc)
	if not self.enabled then return end
	if not desc:IsA("Model") then return end
	
	-- 排除玩家角色（本地玩家和其他玩家）
	if Players:GetPlayerFromCharacter(desc) then return end
	
	-- 名称匹配
	if not self:_matchName(desc.Name) then return end
	
	-- 避免重复添加（可能已经存在标签）
	if self.activeTags[desc] then return end
	
	-- 异步添加标签（等待模型就绪）
	self:_addTagToModelAsync(desc)
end

-- -------------------------------------------------
-- 私有方法：名称匹配逻辑
-- -------------------------------------------------
function NameTagManager:_matchName(name)
	if self.matchMode == "精准" then
		return name == self.modelName
	else  -- 模糊匹配
		return string.find(name, self.modelName) ~= nil
	end
end

-- -------------------------------------------------
-- 私有方法：异步为模型添加标签（等待可依附部件出现）
-- -------------------------------------------------
function NameTagManager:_addTagToModelAsync(model)
	local taskId = {}
	self.pendingTasks[model] = taskId
	
	task.spawn(function()
		-- 等待超时时间（秒）
		local timeout = 5
		local startTime = tick()
		
		-- 循环等待合适的 Adornee
		local adornee = nil
		while tick() - startTime < timeout do
			-- 如果功能已被禁用或任务被取消，则退出
			if not self.enabled or taskId.cancelled then
				self.pendingTasks[model] = nil
				return
			end
			
			-- 尝试获取 Head
			adornee = model:FindFirstChild("Head")
			if adornee and adornee:IsA("BasePart") then
				break
			end
			
			-- 尝试获取 PrimaryPart
			adornee = model.PrimaryPart
			if adornee and adornee:IsA("BasePart") then
				break
			end
			
			-- 尝试获取任意 BasePart（但不包括不可见的附属物）
			for _, child in ipairs(model:GetDescendants()) do
				if child:IsA("BasePart") then
					adornee = child
					break
				end
			end
			if adornee then break end
			
			-- 等待一帧再重试
			task.wait()
		end
		
		-- 清理 pending 记录
		self.pendingTasks[model] = nil
		
		-- 如果超时或功能已禁用，放弃添加
		if not adornee or not self.enabled then
			return
		end
		
		-- 再次检查是否已被其他任务添加（防止重复）
		if self.activeTags[model] then
			return
		end
		
		-- 创建 BillboardGui
		local billboard = Instance.new("BillboardGui")
		billboard.Name = model.Name .. "_NameTag"
		billboard.Adornee = adornee
		billboard.Size = UDim2.new(0, 200, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0)   -- 头部上方偏移
		billboard.AlwaysOnTop = true
		billboard.Parent = model
		
		-- 创建 TextLabel
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.5
		label.Font = Enum.Font.SourceSansBold
		label.Parent = billboard
		
		-- 文字内容
		if self.customText then
			label.Text = self.customText
		else
			label.Text = model.Name
		end
		
		-- 字号设置
		if self.fontSize then
			label.TextScaled = false
			label.TextSize = self.fontSize
		else
			label.TextScaled = true
		end
		
		-- 存储
		self.activeTags[model] = {
			billboard = billboard,
			label = label
		}
	end)
end

-- -------------------------------------------------
-- 私有方法：移除当前实例所有标签
-- -------------------------------------------------
function NameTagManager:_removeAllTags()
	for model, tag in pairs(self.activeTags) do
		if tag.billboard and tag.billboard.Parent then
			tag.billboard:Destroy()
		end
	end
	self.activeTags = {}
end

-- -------------------------------------------------
-- 私有方法：更新所有已激活标签的距离显示
-- -------------------------------------------------
function NameTagManager:_updateDistances()
	if not self.enabled or not self.showDistance then return end
	
	-- 获取本地玩家角色根部件
	local character = LocalPlayer and LocalPlayer.Character
	local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
	if not rootPart then return end
	
	for model, tag in pairs(self.activeTags) do
		-- 若模型已被删除，清理标签
		if not model or not model.Parent then
			if tag.billboard then tag.billboard:Destroy() end
			self.activeTags[model] = nil
			continue
		end
		
		local adornee = tag.billboard.Adornee
		if adornee then
			local dist = (adornee.Position - rootPart.Position).Magnitude
			local baseText = self.customText or model.Name
			tag.label.Text = string.format("%s (%.1f)", baseText, dist)
		end
	end
end

return NameTagModule