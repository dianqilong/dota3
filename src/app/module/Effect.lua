--
-- Author: yjun
-- Date: 2014-09-25 18:18:55
--
local scheduler = require("framework.scheduler")

local Effect = class("Effect")

function Effect:ctor()
	self.effectList = {}
end

-- 创建普通特效
function Effect:NewEffect(effectID)
	local effectInfo = DataManager:getEffectConf(effectID)
	if effectInfo == nil then
		print("effect config not exit")
		return nil
	end
	-- 准备特效文件
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(effectInfo.ConfigName)
	-- 创建特效
	local effect = ccs.Armature:create(effectInfo.ArmatureName)
	display.getRunningScene():addChild(effect)
	effect:getAnimation():play(effectInfo.AnimationName)

	-- 播放完成后自动删除
	if effectInfo.C_Remove > 0 then
		local function animationEvent(armatureBack,movementType,movementID)
			if movementType == ccs.MovementEventType.complete then				
				effect:removeSelf()
			end
		end
		effect:getAnimation():setMovementEventCallFunc(animationEvent)
	end

	return effect
end

-- 特殊特效
function Effect:createEffect(effectID, master, target, ...)
	local effectInfo = DataManager:getEffectConf(effectID)
	if effectInfo == nil then
		print("effect config not exit")
		return nil
	end

	local switch = {
		[1] = function(effectInfo, master, target) return self:ptpLineEffect(effectInfo, master, target) end,

		[2] = function(...) return self:ptpFlyEffect() end,

		[3] = function(...) return self:ptpLineEffect(unpack(...)) end,

		[4] = function(effectInfo, master, target) return self:PositionEffect(effectInfo, master, target) end,

		[5] = function(effectInfo, master, target) return self:BuffEffect(effectInfo, master, target) end
	}

	-- 特效事件分发
	local func = switch[effectInfo.Type]
	if func then
		return func(effectInfo, master, target)
	else
		print("no Effect function")
		return nil
	end

	return nil
end

-- 删除特效
function Effect:removeEffect(effectID, master)
	local key = master:getIndex() .. effectID;
	local effect = DataManager.effect.effectList[key]
	if effect == nil then
		-- print(effectID .. " not exist")
		return
	end

	effect:removeSelf()
	DataManager.effect.effectList[key] = nil
end

-- 点到点的线性特效
function Effect:ptpLineEffect(effectInfo, master, target, ...)
	self:removeEffect(effectInfo.ID, master)
	-- 准备特效文件
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(effectInfo.ConfigName)
	-- 创建特效，添加到场景
	local effect = ccs.Armature:create(effectInfo.ArmatureName)
	-- 播放完成后自动删除
	if effectInfo.C_Remove > 0 then
		local function animationEvent(armatureBack,movementType,movementID)
			if movementType == ccs.MovementEventType.complete then				
				effect:removeSelf()
			end
		end

		effect:getAnimation():setMovementEventCallFunc(animationEvent)
	else
		-- 记录特效到特效列表
		DataManager.effect.effectList[master:getIndex() .. effectInfo.ID] = effect
	end
	local scene = display.getRunningScene()
	scene:addChild(effect)
	-- 调整特效位置和角度
	effect:setLocalZOrder(master:getLocalZOrder())
	local masterPos = cc.p(master:getPosition())
	masterPos.y = masterPos.y + 50
	local targetPos = cc.p(target:getPosition())
	targetPos.y = targetPos.y + 50
	local distance = cc.pGetDistance(masterPos, targetPos)
	effect:setScaleX(distance/effect:getContentSize().width)
	if effectInfo.ScaleY ~= 0 then
		effect:setScaleY(effectInfo.ScaleY)
	end
	local angle = cc.pToAngleSelf(cc.pSub(targetPos, masterPos))
	effect:setPosition(cc.pMidpoint(masterPos, targetPos))
	effect:setRotation(-math.deg(angle))
	effect:getAnimation():play(effectInfo.AnimationName)

	return effect
end

function Effect:updatePtPLineEffect(effect, master, target)
	local masterPos = cc.p(master:getPosition())
	masterPos.y = masterPos.y + 50
	local targetPos = cc.p(target:getPosition())
	targetPos.y = targetPos.y + 50
	local distance = cc.pGetDistance(masterPos, targetPos)
	effect:setScaleX(distance/effect:getContentSize().width)
	local angle = cc.pToAngleSelf(cc.pSub(targetPos, masterPos))
	effect:setPosition(cc.pMidpoint(masterPos, targetPos))
	effect:setRotation(-math.deg(angle))
end

-- 点到点飞行特效
function Effect:ptpFlyEffect(effectInfo, master, target)
	-- 准备特效文件
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(effectInfo.ConfigName)

	-- 创建特效，添加到场景
	local effect = ccs.Armature:create(effectInfo.ArmatureName)

	-- 播放完成后自动删除
	if effectInfo.C_Remove > 0 then
		local function animationEvent(armatureBack,movementType,movementID)
			if movementType == ccs.MovementEventType.complete then				
				effect:removeSelf()
			end
		end
		effect:getAnimation():setMovementEventCallFunc(animationEvent)
	else
		-- 记录特效到特效列表
		DataManager.effect.effectList[master:getIndex() .. effectInfo.ID] = effect
	end

	local starPos = master.armature:convertToWorldSpace(cc.p(master.armature:getBone("atkpoint"):getPosition()))
    local targetPos = cc.p(target:getPosition())
    display.getRunningScene():addChild(effect)
    effect:setLocalZOrder(master:getLocalZOrder())
    local angle = cc.pToAngleSelf(cc.pSub(targetPos, starPos))
    effect:setRotation(-math.deg(angle))
    local distance = cc.pGetDistance(starPos, targetPos)
    local action = transition.sequence(
        {cc.MoveTo:create(distance / display.width, targetPos), 
        cc.CallFunc:create(function()
            if target.hp > 0 then
                target:ReduceHp(self:GetAttack(), self)
                self:IncPower(40)
            end
            effect:removeSelf()
            self.atkeff=nil
            end)})
    effect:runAction(action)
end

-- 指定位置的特效
function Effect:PositionEffect(effectInfo, master, target)
	-- 准备特效文件
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(effectInfo.ConfigName)

	-- 创建特效，添加到场景
	local effect = ccs.Armature:create(effectInfo.ArmatureName)
	effect:setScaleX(effectInfo.ScaleX)
	effect:setScaleY(effectInfo.ScaleY)
	-- 播放完成后自动删除
	if effectInfo.C_Remove > 0 then
		local function animationEvent(armatureBack,movementType,movementID)
			if movementType == ccs.MovementEventType.complete then				
				effect:removeSelf()
			end
		end
		effect:getAnimation():setMovementEventCallFunc(animationEvent)
	else
		-- 记录特效到特效列表
		DataManager.effect.effectList[master:getIndex() .. effectInfo.ID] = effect
	end

	local scene = display.getRunningScene()
	scene:addChild(effect)
	effect:setLocalZOrder(master:getLocalZOrder()-100)

	if master.armature:getScaleX() < 0 then
		effect:setScaleX(-1)
	end
	effect:getAnimation():play(effectInfo.AnimationName)

	return effect
end

-- buff特效
function Effect:BuffEffect(effectInfo, master, target)
	self:removeEffect(effectInfo.ID, target)
	-- 准备特效文件
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(effectInfo.ConfigName)

	-- 创建特效，添加到对象
	local effect = ccs.Armature:create(effectInfo.ArmatureName)
	target:addChild(effect)

	local size = target.armature:getContentSize()
    size.height = size.height * math.abs(target.armature:getScaleY())
    
    effect:setPosition(0, size.height)
    effect:getAnimation():play(effectInfo.AnimationName)
    effect:setScaleX(effectInfo.ScaleX)
    effect:setScaleY(effectInfo.ScaleY)
	-- 记录特效到特效列表
	DataManager.effect.effectList[target:getIndex() .. effectInfo.ID] = effect

	return effect
end

-- 头顶飘字
function Effect:HeadFlyText(master, content, font, is_crit)
	local label = cc.ui.UILabel.new({
		UILabelType = 1, 
		text = content, 
		font = "font/" .. font .. ".fnt",
		align = cc.ui.UILabel.TEXT_ALIGN_CENTER})	
	label:setAnchorPoint(cc.p(0.5, 0.5))
	label:setScale(0.1)
	display.getRunningScene():addChild(label)

	label:setPosition(cc.p(master:getPositionX(), master:getPositionY() + 162))
	label:setLocalZOrder(master:getLocalZOrder())

	local action = transition.sequence(
		{cc.ScaleTo:create(0.2, 0.8),
		cc.MoveTo:create(0.5, cc.p(label:getPositionX(), label:getPositionY() + 50)),
		cc.CallFunc:create(function() label:removeSelf() end)})

	if is_crit then
		label:setPosition(cc.p(master:getPositionX(), master:getPositionY() + 167))
		action = transition.sequence(
			{cc.ScaleTo:create(0.2, 1.2),
			cc.MoveTo:create(0.5, cc.p(label:getPositionX(), label:getPositionY())),
			cc.MoveTo:create(1, cc.p(label:getPositionX(), label:getPositionY() + 80)),
			cc.CallFunc:create(function() label:removeSelf() end)})
		label:setLocalZOrder(master:getLocalZOrder()+100)
	end

	label:runAction(action)
end

-- 添加boss脚底特效
function Effect:AddBossEff(target)
	local effect = Effect:createEffect("e_boss_eff", target, target)
	effect:setPosition(cc.p(0, 5))
	effect:zorder(target:getLocalZOrder()-1)
end

return Effect