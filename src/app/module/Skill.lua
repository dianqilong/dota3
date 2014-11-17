--
-- Author: yjun
-- Date: 2014-09-24 16:37:46
--
local Npc = import("..roles.Npc")
local Buff = import("..module.Buff")
local Effect = import("..module.Effect")
local scheduler = require("framework.scheduler")

local Skill = class("Skill")

function Skill:ctor()
end

-- 能否使用技能
function Skill:CanUseSkill(master, index)
	-- 死亡或眩晕状态
	if master:IsHold() or master:IsDead() then
		return false
	end

	local skillID = master.skills[index]
	local skillInfo = DataManager:getSkillConf(skillID)
	if skillInfo == nil then
		return false
	end

	-- 技能乜有准备好
	if not master.skillsReady[i] then
		return false
	end

	-- 没有目标
	local target = Skill:GetSufferer(skillinfo, master, "closest")
	if not target or target.type == "building" then
		return false
	end

	return true
end

-- 使用技能
function Skill:UseSkill(master, index)
	local skillID = master.skills[index]
	local skillInfo = DataManager:getSkillConf(skillID)
	if skillInfo == nil then
		print("skill config not exit. ")
		return
	end

	self.power_index = index

	local switch = {
		[0] = function(info, m) self:PassiveSkill(info, m) end,
		[1] = function(info, m) self:PointSkill(info, m) end,
		[2] = function(info, m) self:AoeSkill(info, m) end,
		[3] = function(info, m) self:CallNpc(info, m) end,
		[4] = function(info, m) self:FlySkill(info, m) end,
	}

	-- 技能事件分发
	local func = switch[skillInfo.Type]
	if func then
		func(skillInfo, master)
	elseif self[skillID] then
		self[skillID](self, skillInfo, master)
	else
		print("no Skill function")
		return
	end

	-- 记录当前技能id
	master.curSkill = skillID
end

-- 结束技能
function Skill:EndSkill(master)
	if master.curSkill == nil then
		return
	end

	local skillInfo = DataManager:getSkillConf(master.curSkill)
	if skillInfo == nil then
		print("skill config not exit")
		return
	end

	-- 持续性技能在结束时删除特效
	if skillInfo.Effect and skillInfo.DurationTime and skillInfo.DurationTime > 0 then
		Effect:removeEffect(skillInfo.Effect, master)
	end

	if master.schedulers["skillhandle"] then
		scheduler.unscheduleGlobal(master.schedulers["skillhandle"])
		master.schedulers["skillhandle"] = nil
	end

	master.curSkill = nil
end

-- 获取技能类型
function Skill:getSkillType(skillID)
	return DataManager:getSkillConf(skillID).Type
end

-- 获取技能能量消耗
function Skill:getNeedPower(skillID)
	local config = DataManager:getSkillConf(skillID)
	if not config then
		return 0
	end
	return config.Power
end

-- 获取敌方阵营活着的单位
local function getAnemys(master)
	if master.side == 1 then
		return display.getRunningScene().rights
	else
		return display.getRunningScene().lefts
	end
end

function getTargetByDistance(master, type, targets)
	local masterPos = cc.p(master:getPosition())
	local targetDistance = 10000
	if type == "farthest" then
		targetDistance = 0
	end
	local target = nil
	for i = 1, #targets do
		if targets[i]:CanBeSelect() then
			local distance = cc.pGetDistance(masterPos, cc.p(targets[i]:getPosition()))
			if (type == "farthest" and distance > targetDistance) or
				(type == "closest" and distance < targetDistance) then
				target = targets[i]
				targetDistance = distance
			end
		end
	end
	return target
end

-- 选取受影响敌人
function Skill:GetSufferer(skillinfo, master, type)
	local targets = getAnemys(master)
	if not targets or #targets == 0 then
		return nil
	end

	target = nil

	if type == "line" then--施法者前方线行范围
		local castDistance = skillinfo.CastDistance
		local masterPos = cc.p(master:getPosition())
		-- 判断朝向
		if master.armature:getScaleX() < 0 then
			castDistance = -castDistance		
		end

		-- 确定范围
		local rect = cc.rect(masterPos.x-skillinfo.EffSpring/2+castDistance, 
							masterPos.y-skillinfo.EffWidth/2, 
							skillinfo.EffSpring, 
							skillinfo.EffWidth)
		-- 记录范围内目标
		target = {}
		for i = 1, #targets do
			if targets[i]:CanBeSelect() and 
				cc.rectContainsPoint(rect, cc.p(targets[i]:getPosition())) and
				targets[i].type ~= "building" then
				target[#target+1] = targets[i]
			end
		end
	elseif type == "closest" or type == "farthest" then -- 最近或最远的敌方单位
		target = getTargetByDistance(master, type, targets)
	elseif type == "random" then -- 随机敌方单位
		if targets[random(1, #targets)]:CanBeSelect() then
			target = targets[random(1, #targets)]
		end
	end

	return target
end

-- 调整朝向，面向敌人
function Skill:TurnFace(master, posX)
	local scale = master.armature:getScaleX()
	if (master:getPositionX() > posX and scale > 0) or 
		(master:getPositionX() < posX and scale < 0) then
		master.armature:setScaleX(-scale)
	end
end

-- 被动技能
function Skill:PassiveSkill(skillinfo, master)
	-- 添加buff
	if skillinfo.AddBuff then
		Buff:AddBuff(master, skillinfo.AddBuff)
	end
end

-- 单体技能
function Skill:PointSkill(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest")
	if not enemy then
		return
	end

	master:ReducePower(10000, self.power_index)
	master:ResetAtkTime()

	--调整朝向
    Skill:TurnFace(master, enemy:getPositionX())

	local function onPointSkillDamage()
		master:DelCallBack("onDamageEvent", onPointSkillDamage)

		--目标死亡，不处理
		if enemy:IsDead() or not enemy:CanBeSelect() then
			return
		end

		-- 添加buff
		if skillinfo.AddBuff then
			Buff:AddBuff(enemy, skillinfo.AddBuff)
		end

		-- 计算伤害
		if skillinfo.EffProp then
			enemy:ReduceHp(skillinfo.Damage, master)
		end

		-- 播放特效
		if skillinfo.Effect then
			Effect:createEffect(skillinfo.Effect, master, enemy)
		end
	end

	if skillinfo.PreAction then
		master:DoMagic()
		master:AddCallBack("onDamageEvent", onPointSkillDamage)
	else
		onPointSkillDamage()
	end
end

-- 根据技能施法距离获取特效位置偏移量
function getEffectOffset(skillinfo, master)
	if skillinfo.CastDistance == 0 then
		return 0
	end

	-- 左方阵营
	if master.side == 1 then
		return skillinfo.CastDistance
	else
		return -skillinfo.CastDistance
	end

	return 0
end

-- AOE
function Skill:AoeSkill(skillinfo, master)
	master:ReducePower(10000, self.power_index)
	master:ResetAtkTime()

	local function onDamage()
		master:DelCallBack("onDamageEvent", onDamage)

		-- 播放特效
		if skillinfo.Effect then
			local effect = Effect:createEffect(skillinfo.Effect, master, master)
			if effect then
				effect:setPosition(master:getPositionX() + getEffectOffset(skillinfo, master), master:getPositionY())
			end
		end

		-- 获取受影响敌人
		local enemys = self:GetSufferer(skillinfo, master, "line") or {}
		for i = 1, #enemys do
			-- 添加buff
			if skillinfo.AddBuff then
				Buff:AddBuff(enemys[i], skillinfo.AddBuff)
			end

			enemys[i]:ReduceHp(skillinfo.Damage, master)			
		end
	end

	if skillinfo.PreAction then
		master:DoMagic()
		master:AddCallBack("onDamageEvent", onDamage)
	else
		onDamage()
	end
end

-- 抽蓝
function Skill:s_stealmp(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest")

	master:ReducePower(10000, self.power_index)
	master:ResetAtkTime()

	--调整朝向
	Skill:TurnFace(master, enemy:getPositionX())

	local function onDamage()
		master:DelCallBack("onDamageEvent", onDamage)
		local scene = display.getRunningScene()

		-- 计算伤害
		local function stealPower()
			--目标死亡，不处理
			if enemy:IsDead() then
				master:doEvent("stop")
				return
			end
			Effect:updatePtPLineEffect(master.temp_effect, master, enemy)
			master.stealPowerTimer = master.stealPowerTimer + 0.1
			if master.stealPowerTimer > skillinfo.DurationTime then
				master:doEvent("stop")
				return
			end

			master:IncPower(1)
			enemy:ReducePowerAll(1)
		end

		-- 播放特效
		if skillinfo.Effect then
			master.temp_effect = Effect:createEffect(skillinfo.Effect, master, enemy)
		end

		if skillinfo.DurationTime and skillinfo.DurationTime > 0 then
			master.schedulers["skillhandle"] = scheduler.scheduleGlobal(stealPower, 0.1)
			master.stealPowerTimer = 0
			stealPower()
		end
	end

	if skillinfo.PreAction then
		master:DoMagic("attack2")
		master:AddCallBack("onDamageEvent", onDamage)
	else
		onDamage()
	end
end

-- 穿刺
function Skill:s_puncture(skillinfo, master)
	-- 获取距离最近的敌人
	local enemys = self:GetSufferer(skillinfo, master, "line") or {}

	master:ReducePower(10000, self.power_index)
	master:ResetAtkTime()

	local function onDamage()
		master:DelCallBack("onDamageEvent", onDamage)
		local scene = display.getRunningScene()
		-- 播放特效
		if skillinfo.Effect and string.len(skillinfo.Effect) > 0 then
			local effect = Effect:createEffect(skillinfo.Effect, master)
			if effect then
				effect:setPosition(master:getPositionX() + getEffectOffset(skillinfo, master), master:getPositionY())
			end
		end

		local masterPos = cc.p(master:getPosition())
		for i = 1, #enemys do
			local enemyPos = cc.p(enemys[i]:getPosition())
			local distance = math.abs(masterPos.x - enemyPos.x)
			local delay = math.floor(distance/(skillinfo.EffSpring/3))

			local function doEffect()
				--目标死亡，不处理
				if enemys[i]:IsDead() or not enemys[i]:CanBeSelect() then
					return
				end
				-- 加buff
				Buff:AddBuff(enemys[i], skillinfo.AddBuff)
				-- 计算伤害
				enemys[i]:ReduceHp(skillinfo.Damage, master)
			end

			if delay > 0 then
				scheduler.performWithDelayGlobal(doEffect, delay*0.2)
			else
				doEffect()
			end
		end
	end

	if skillinfo.PreAction then
		master:DoMagic()
		master:AddCallBack("onDamageEvent", onDamage)
	else
		onDamage()
	end
end

-- 变羊
function Skill:s_sheep(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest")
	master:ReducePower(10000, self.power_index)
	master:ResetAtkTime()
	--调整朝向
    Skill:TurnFace(master, enemy:getPositionX())

	local function onDamage()
		master:DelCallBack("onDamageEvent", onDamage)
		--目标死亡，不处理
		if enemy:IsDead() or not enemy:CanBeSelect() then
			return
		end

		Buff:AddBuff(enemy, skillinfo.AddBuff)
	end

	if skillinfo.PreAction then
		master:DoMagic()
		master:AddCallBack("onDamageEvent", onDamage)
	else
		onDamage()
	end
end

-- 无敌斩
function Skill:s_omnislash(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest")

	master:ReducePower(10000, self.power_index)
	master:ResetAtkTime()

	-- 动作角度序列
	local angles = {0, 30, -30, -30, 30, 0}
	local repeatTimes = 0

	local function endFunction()
		master:DelCallBack("AnimationEvent", repeatFunction)
		master:setPositionX(master:getPositionX() - 100)
		master:setRotation(0)
		master:SetCanBeSelect(true)
		if repeatTimes > 3 then
			master:setScaleX(-master:getScaleX())
		end
	end

	local function repeatFunction(movementID, movementType)
		if movementID ~= skillinfo.PreAction or 
			movementType ~= ccs.MovementEventType.complete then
			return
		end
		-- 计数
		repeatTimes = repeatTimes + 1
		if repeatTimes > 6 then
			endFunction()
			return
		end

		if repeatTimes > 3 then
			master:setScaleX(-master:getScaleX())
		end 

		--技能逻辑
		if repeatTimes > 1 then
			enemy = self:GetSufferer(skillinfo, master, "random")
			if not enemy then
				endFunction()
				return
			end
		end
		-- 隐藏血条
		master.progress:setVisible(false)
		-- 移动到目标位置
		master:setPosition(enemy:getPosition())
		master:setRotation(angles[repeatTimes])
		-- 播发施法动作
		master:DoMagic(skillinfo.PreAction)
		master:SetCanBeSelect(false)
		local function onDamage()
			--目标死亡，不处理
			if enemy:IsDead() then
				return
			end
			enemy:ReduceHp(master:GetAttack(), master)
		end
		master:AddCallBack("onDamageEvent", onDamage)
	end
	master:AddCallBack("AnimationEvent", repeatFunction)

	repeatFunction(skillinfo.PreAction, ccs.MovementEventType.complete)
	
end

-- 剑刃风暴
function Skill:s_bladefury(skillinfo, master)
	local target = Skill:GetSufferer(skillinfo, master, "farthest")
	-- 持续时间
	local time = skillinfo.DurationTime
	if time <= 0 then
		return
	end

	master:ReducePower(10000, self.power_index)
	master:ResetAtkTime()

	local endPos = cc.p(master:getPosition())

	local action = transition.sequence(
		{cc.MoveTo:create(time/2, cc.p(target:getPosition())), 
		cc.MoveTo:create(time/2, endPos), 
		cc.CallFunc:create(function() 
			master:Stop()
			master:SetCanBeSelect(true)
			end)})

	master:SetCanBeSelect(false)
	master:runAction(action)
	master:DoMagic(skillinfo.PreAction)

	-- 计算伤害
	function DoDamage()
		local enemys = Skill:GetSufferer(skillinfo, master, "line") or {}
		for i = 1, #enemys do
			enemys[i]:ReduceHp(skillinfo.Damage/2, master)
		end
	end

	master.schedulers["skillhandle"] = scheduler.scheduleGlobal(DoDamage, 0.5)
end

-- 召唤NPC
function Skill:CallNpc(skillinfo, master)
	master:ReducePower(10000, self.power_index)
	master:ResetAtkTime()

	local function onDamage()
		master:DelCallBack("onDamageEvent", onDamage)
		local scene = display.getRunningScene()
		local npc = Npc.new(skillinfo.Effect)
		npc.side = master.side
		npc:setPosition(cc.p(master:getPositionX() + skillinfo.CastDistance, master:getPositionY()))
		npc:setLocalZOrder(master:getLocalZOrder())
		scene:addChild(npc)
	end

	if skillinfo.PreAction then
		master:DoMagic()
		master:AddCallBack("onDamageEvent", onDamage)
	else
		onDamage()
	end
end

-- 远程攻击
function FlyEffect(skillinfo, master, target, func)
    local starPos = master.armature:convertToWorldSpace(cc.p(master.armature:getBone("atkpoint"):getPosition()))
    local targetPos = cc.p(target:getPositionX(), target:getPositionY()+100)
    local effect = Effect:NewEffect(skillinfo.Effect)
    effect:setPosition(master:getPosition())
    effect:setLocalZOrder(master:getLocalZOrder())
    local angle = cc.pToAngleSelf(cc.pSub(targetPos, starPos))
    effect:setRotation(-math.deg(angle))
    local distance = cc.pGetDistance(starPos, targetPos)
    local action = transition.sequence(
        {cc.MoveTo:create(distance / display.width, targetPos), 
        cc.CallFunc:create(function()
            func()
            effect:removeSelf()
            end)})
    effect:runAction(action)
end

-- 飞行技能
function Skill:FlySkill(skillinfo, master)
	local target = Skill:GetSufferer(skillinfo, master, "closest")
	master:ReducePower(10000, self.power_index)
	master:ResetAtkTime()

	local function BeginEffect()
		master:DelCallBack("onDamageEvent", BeginEffect)
		
		local function OnDamage()
			-- 添加buff
			if skillinfo.AddBuff then
				Buff:AddBuff(target, skillinfo.AddBuff)
			end
			-- 计算伤害
			target:ReduceHp(skillinfo.Damage, master)
		end

		FlyEffect(skillinfo, master, target, OnDamage)
	end

	if skillinfo.PreAction then
		master:DoMagic()
		master:AddCallBack("onDamageEvent", BeginEffect)
	else
		BeginEffect()
	end
end

return Skill