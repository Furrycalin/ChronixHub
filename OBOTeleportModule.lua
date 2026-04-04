local TeleportModule = {}

-- 内部函数：检查角色是否有效
local function isValidCharacter(player)
    local character = player.Character
    if not character then
        return false, nil, nil
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then
        return false, nil, nil
    end
    return true, hrp, character
end

-- 内部函数：收集目标零件
local function collectTargets(partNames)
    local targets = {}
    -- 将输入统一转为字符串数组
    local nameList = {}
    if type(partNames) == "string" then
        nameList = {partNames}
    elseif type(partNames) == "table" then
        nameList = partNames
    else
        return targets
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            for _, targetName in ipairs(nameList) do
                if obj.Name == targetName then
                    table.insert(targets, obj)
                    break
                end
            end
        end
    end
    return targets
end

-- 主函数：传送到所有匹配的零件
-- 参数 partNames: 字符串或字符串数组，如 "Echo" 或 {"AbyssalEnergy", "BigAbyssalEnergy"}
-- 参数 delay: 每次传送后的等待时间（秒），默认 0.1
function TeleportModule.TeleportToParts(partNames, delay)
    delay = delay or 0.1
    local player = game.Players.LocalPlayer
    
    -- 验证角色
    local valid, hrp, character = isValidCharacter(player)
    if not valid then
        warn("角色无效或已死亡")
        return
    end
    
    -- 收集目标
    local targets = collectTargets(partNames)
    if #targets == 0 then
        warn("未找到任何匹配的零件: " .. (type(partNames) == "table" and table.concat(partNames, ", ") or partNames))
        return
    end
    
    print(string.format("找到 %d 个目标，开始传送（间隔 %.2f 秒）", #targets, delay))
    
    for i, part in ipairs(targets) do
        -- 每次传送前重新验证角色
        local validNow, currentHrp = isValidCharacter(player)
        if not validNow then
            warn("传送中断：角色失效")
            break
        end
        hrp = currentHrp
        
        local targetPos = part.Position + Vector3.new(0, 2, 0)
        hrp.CFrame = CFrame.new(targetPos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        
        print(string.format("[%d/%d] 传送至 %s", i, #targets, part.Name))
        task.wait(delay)
    end
    
    print("传送完成")
end

return TeleportModule