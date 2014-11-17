--
-- Author: yjun
-- Date: 2014-10-16 10:46:49
--

local Skill = import("..module.Skill")

local AI = class("AI")

function AI:ctor()
end

function AI:SetMaster(master)
	self.master = master
end

-- 捕获事件,更新指令
function AI:CatchEvent(eventName)
	local master = self.master
	local state = master:getState()
	if state == "idle" then
		local target = Skill:GetSufferer(nil, master, "closest")
		if not target then
			return
		end

		-- 判断攻击范围
		local distance = math.abs(master:getPositionX() - target:getPositionX())
		if distance <= master.atkRange then
			-- 尝试释放技能
			local index = self:getReadySkill()
			if not master.IsUseAI then
				index = nil
			end

			if master:CheckAtkCD() then
				if index and Skill:CanUseSkill(master, index) and 
					target.type ~= "building" then
					Skill:UseSkill(master, index)
				else
					master:DoAttack()
				end
			end
		elseif master.type ~= "building" then
			master:WalkTo(cc.p(target:getPositionX(), master:getPositionY()))
		end
	elseif state == "walk" then
		local target = Skill:GetSufferer(nil, master, "closest")
		if target then
			local distance = math.abs(master:getPositionX() - target:getPositionX())
			if distance <= master.atkRange then
				master:Stop()
			end
		end
	end
end

-- 获取一个准备好的技能
function AI:getReadySkill()
	for i = 1, 4 do
		if self.master.skillsReady[i] then
			return i
		end
	end

	return nil
end

return AI