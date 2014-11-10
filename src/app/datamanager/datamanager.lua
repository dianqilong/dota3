--
-- Author: yjun
-- Date: 2014-09-24 15:14:33
--
import("..util")
local Effect = import("..module.Effect")
local Skill = import("..module.Skill")

local DataManager = class("DataManager")

function DataManager:ctor()
	self:loadHeroConfig()
	self:loadSkillConfig()
	self:loadEffectConfig()
	self:loadBuffConfig()
	self:loadNpcConfig()

	self.effect = Effect:new()
	self.skill = Skill:new()
	self.index = 0
end

-- 获取全局递增索引
function DataManager:getIncIndex()
	self.index = self.index + 1
	return self.index
end

function DataManager:loadHeroConfig()
	self.heroconfig = loadCsvFile("config/heroconfig.csv")
end

function DataManager:loadSkillConfig()
	self.skillconfig = loadCsvFile("config/skillconfig.csv")
end

function DataManager:loadEffectConfig()
	self.effectconfig = loadCsvFile("config/effectconfig.csv")
end

function DataManager:loadBuffConfig()
	self.buffconfig = loadCsvFile("config/buffconfig.csv")
	-- cclog(self.buffconfig)
end

function DataManager:loadNpcConfig()
	self.npcconfig = loadCsvFile("config/npcconfig.csv")
end

function DataManager:getHeroConf(heroID)
	return self.heroconfig[heroID]
end

function DataManager:getEffectConf(effectID)
	return self.effectconfig[effectID]
end

function DataManager:getSkillConf(skillID)
	return self.skillconfig[skillID]
end

function DataManager:getBuffConf(buffID)
	return self.buffconfig[buffID]
end

function DataManager:setBuffConf(buffID, config)
	self.buffconfig[buffID] = config
end

function DataManager:getNpcConf(npcID)
	return self.npcconfig[npcID]
end

return DataManager