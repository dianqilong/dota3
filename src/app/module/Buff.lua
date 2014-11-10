--
-- Author: yjun
-- Date: 2014-09-27 11:06:48
--
local scheduler = require("framework.scheduler")
local Effect = import("..module.Effect")
local Buff = class("Buff")

function Buff:ctor(buffID)
	self.id = buffID
	self.buffConf = DataManager:getBuffConf(buffID)
	if not self.buffConf then
		return nil
	end
	self.triggers = {}

	local trigger = self.buffConf.Trigger

	if trigger == 1 then -- 添加时触发
		self.triggers = {"OnAdd"}
	elseif trigger == 2 then
	elseif trigger == 3 then
	elseif trigger == 4 then -- 被攻击
		self.triggers = {"ReduceHp"}
	elseif trigger == 5 then -- 时间间隔
		self.triggers = {"Interval"}
		self.timer = scheduler.scheduleGlobal(function() self:UpdateBuff("Interval") end, self.buffConf.Interval)
	end
end

-- 添加buff
function Buff:AddBuff(target, buffID)
	Buff:DelBuff(target, buffID)

	local buff = Buff.new(buffID)
	buff.master = target

	local config = buff.buffConf
	if not config then
		print("buff config not exist")
		return
	end

	-- 添加buff到对象
	target.buffs[buffID] = buff

	buff:UpdateBuff("OnAdd")

	return buff
end

-- 删除buff	
function Buff:DelBuff(target, buffID)
	local buff = target.buffs[buffID]
	if not buff then
		return
	end

	if buff.timer then
		scheduler.unscheduleGlobal(buff.timer)
	end

	if buff["OnDel"] then
		buff["OnDel"](buff)
	end

	buff:UpdateBuff("OnDel")

	target.buffs[buffID] = nil
end

-- 清除所有buff
function Buff:ClearAllBuff(target)
	for key, buff in pairs(target.buffs) do
		if buff.timer then
			scheduler.unscheduleGlobal(buff.timer)
		end

		if buff["OnDel"] then
			buff["OnDel"](buff)
		end

		buff:UpdateBuff("OnDel")
	end

	target.buffs = {}
end

-- 更新buff状态
function Buff:UpdateBuff(type, ...)
	if not ValueExist(self.triggers, type) then
		return
	end

	local config = self.buffConf

	if config.ExecFunc and self[config.ExecFunc] then
		self[config.ExecFunc](self, type, ...)
	elseif self[self.id] then
		self[self.id](self, type, ...)
	else
		print("no buff function")
	end
end

-- 反伤buff
function Buff:buff_return(type, num, attacker)
	attacker:ReduceHp(num/2)
end

-- 增加属性
function Buff:add_prop()
	local prop = self.buffConf.Prop
	local value = self.buffConf.Value
	self.master:IncProp(prop, value)
end

-- 减少属性
function Buff:reduce_prop()
	local prop = self.buffConf.Prop
	local value = self.buffConf.Value
	self.master:ReduceProp(prop, value)
end

-- 获取敌方阵营活着的单位
local function getMembers(master)
	if master.side == 2 then
		return display.getRunningScene().rights
	else
		return display.getRunningScene().lefts
	end
end

-- 范围加血
function Buff:aoe_add_hp()
	local config = self.buffConf
	local masterPos = cc.p(self.master:getPosition())
	-- 确定范围
	local rect = cc.rect(masterPos.x-config.EffSpring/2, 
						masterPos.y-config.EffWidth/2, 
						config.EffSpring, 
						config.EffWidth)
	-- 获取友军
	local targets = getMembers(self.master)
	for i = 1, #targets do
		if cc.rectContainsPoint(rect, cc.p(targets[i]:getPosition())) then
			targets[i]:IncHp(config.Value)
		end
	end
end

-- 是否存在眩晕buff
function Buff:FindHoldBuff(target, buff)
	for key, value in pairs(target.buffs) do
		if string.find(key, "buff_hold") and value ~= buff then
			return value
		end
	end

	return nil
end

-- 删除眩晕buff
function Buff:ClearHoldBuff(target)
	for key, value in pairs(target.buffs) do
		if string.find(key, "buff_hold") then
			Buff:DelBuff(target, key)
		end
	end
end

-- 定身
function Buff:hold()
	local master = self.master
	local durationTime = self.buffConf.DurationTime

	master:Hold(durationTime)
	self.timer = scheduler.performWithDelayGlobal(function() Buff:DelBuff(master, self.id) end, durationTime)

	self.OnDel = function()
		master:EndHold()
	end
end

-- 添加定身buff
function Buff:DoHold(master, time)
	if time < master.holdtime then
		return
	end

	local buffID = "buff_hold_"..time
	local config = DataManager:getBuffConf(buffID)
	if not config then
		config = {["ID"]=buffID, ["Trigger"]=1, ["DurationTime"]=time, ["ExecFunc"]="hold"}
		DataManager:setBuffConf(buffID, config)
	end

	Buff:ClearHoldBuff(master)
	Buff:AddBuff(master, buffID)
end

-- 眩晕
function Buff:stop()
	local master = self.master
	local durationTime = self.buffConf.DurationTime
	Effect:createEffect("e_stun", master, master)
	-- 添加定身buff
	Buff:DoHold(master, durationTime)
	self.timer = scheduler.performWithDelayGlobal(function() Buff:DelBuff(master, self.id) end, durationTime)
	self.OnDel = function()
		Effect:removeEffect("e_stun", master)
		end
end

-- 击飞
function Buff:do_jump()
	local master = self.master
	local action = cc.JumpTo:create(0.7, cc.p(master:getPosition()), 100, 1)
	master:runAction(action)
	self:stop()
end

-- 变羊
function Buff:sheep()
	local master = self.master
	-- 隐藏本体
	master.armature:setVisible(false)
	master.armature:getAnimation():stop()

	local pos = cc.p(master.armature:getPosition())

	-- 显示绵羊
	if master.subs then
		master.subs:removeSelf()
		master.subs = nil
	end

	master.subs = display.newSprite("image/sheep.png", pos.x, pos.y+30)
	master.subs:setScale(0.4)
	if master.side == 1 then
		master.subs:setScaleX(-0.4)
	end
	master:addChild(master.subs)
	local durationTime = self.buffConf.DurationTime
	Buff:DoHold(master, durationTime)
	self.timer = scheduler.performWithDelayGlobal(function() Buff:DelBuff(master, self.id) end, durationTime)
	self.OnDel = function()
		master.armature:setVisible(true)
		if master.subs then
			master.subs:removeSelf()
			master.subs = nil
		end
	end
end

-- 冰封
function Buff:freeze()
	local master = self.master
	local effect = Effect:NewEffect("e_frostbite")
	effect:setLocalZOrder(master:getLocalZOrder()+1)
	effect:setPosition(master:getPosition())

	local durationTime = self.buffConf.DurationTime
	Buff:DoHold(master, durationTime)
	master.armature:getAnimation():stop()
	self.timer = scheduler.performWithDelayGlobal(function() Buff:DelBuff(master, self.id) end, durationTime)
	self.OnDel = function()
		effect:removeSelf()
	end
end

return Buff