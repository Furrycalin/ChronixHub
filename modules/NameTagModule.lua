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
	self.customText = customText   -- 可能为 nil，表示使用模型原名
	
	-- 状态
	self.enabled = false
	self.connections = {}          -- 存储所有 RBXScriptConnection
	self.activeTags = {}           -- { [Model] = {billboard, label} }
	
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
	
	-- 1. 为已存在的符合模型添加标签
	self:_scanExistingModels()
	
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
-- 禁用标签：断开监听 + 移除所有已添加标签
-- -------------------------------------------------
function NameTagManager:disable()
	if not self.enabled then return end
	self.enabled = false
	
	-- 断开所有连接
	for _, conn in ipairs(self.connections) do
		conn:Disconnect()
	end
	self.connections = {}
	
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
-- 私有方法：扫描 Workspace 中所有现有模型
-- -------------------------------------------------
function NameTagManager:_scanExistingModels()
	for _, desc in ipairs(Workspace:GetDescendants()) do
		self:_onDescendantAdded(desc)
	end
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
	
	-- 避免重复添加
	if self.activeTags[desc] then return end
	
	self:_addTagToModel(desc)
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
-- 私有方法：为单个模型创建 BillboardGui 标签
-- -------------------------------------------------
function NameTagManager:_addTagToModel(model)
	-- 寻找合适的依附部件（Head > PrimaryPart > 任意BasePart）
	local adornee = model:FindFirstChild("Head") or model.PrimaryPart
	if not adornee then
		for _, child in ipairs(model:GetDescendants()) do
			if child:IsA("BasePart") then
				adornee = child
				break
			end
		end
	end
	if not adornee then
		warn(`[NameTag] 无法为 {model.Name} 添加标签：没有可依附的部件`)
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
	
	-- 文字内容策略：
	-- 若提供了 customText，所有模型显示相同文字
	-- 否则显示模型自身的 Name
	if self.customText then
		label.Text = self.customText
	else
		label.Text = model.Name
	end
	
	-- 字号设置（若指定 fontSize 则关闭自动缩放）
	if self.fontSize then
		label.TextScaled = false
		label.TextSize = self.fontSize
	else
		label.TextScaled = true
	end
	
	-- 存储以便后续更新/移除
	self.activeTags[model] = {
		billboard = billboard,
		label = label
	}
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