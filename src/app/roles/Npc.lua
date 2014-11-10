--
-- Author: yjun
-- Date: 2014-10-31 13:43:32
--
local Buff = import("..module.Buff")
local Effect = import("..module.Effect")
local scheduler = require("framework.scheduler")

local Npc = class("Npc", function()
        return display.newNode()
    end)

function Npc:ctor(npcID)
	local config = DataManager:getNpcConf(npcID)
	if not config then
		print("no npc config")
		return
	end
	self.u_index = DataManager:getIncIndex()
	self.config = config
	self.buffs = {}     -- buff集合

	-- 添加特效
	if config.Armature then
		local manager = ccs.ArmatureDataManager:getInstance()
	    manager:addArmatureFileInfo("armature/" .. config.Armature .. ".ExportJson")
	    self.armature = ccs.Armature:create(config.Armature)
	    self:addChild(self.armature)
	    self.armature:getAnimation():play("idle")
	end

	-- 添加buff
	if config.Buff then
		Buff:AddBuff(self, config.Buff)
	end

	-- 生存时间
	if config.LifeTime > 0 then
		scheduler.performWithDelayGlobal(function() self:OnDelect() end, config.LifeTime)
	end
end

function Npc:getIndex()
    return self.u_index
end

function Npc:OnDelect()
	Buff:ClearAllBuff(self)
	self:removeSelf()
end

return Npc