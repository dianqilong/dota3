--
-- Author: yjun
-- Date: 2014-11-15 10:36:07
--
local Tower = import("..datamanager.Tower")

local PvPManager = class("PvPManager")

function PvPManager:ctor()
	self.first = true
	self.towers = {[1]={["o"] = nil, ["t"] = {},["m"] = {},["b"] = {}},
				   [2]={["o"] = nil, ["t"] = {},["m"] = {},["b"] = {}}}
end

function PvPManager:setPlayerSide(side)
	self.playerSide = side
end

function PvPManager:getPlayerSide()
	return self.playerSide
end

function PvPManager:addTower(btn)
	if not self.first then
		self:bindingTower(btn)
		return 
	end

	local tower = Tower.new(btn)
	local container = self.towers[tower.side]

	if tower.index == 0 then
		container["o"] = tower
		tower.btn:setButtonLabelString("normal", "本")
	elseif tower.index <= 3 then
		container["t"][4-tower.index] = tower
	elseif tower.index > 3 and tower.index < 7 then
		container["m"][7-tower.index] = tower
	else
		container["b"][10-tower.index] = tower
	end
end

function PvPManager:bindingTower(btn)
	local index = Tower:getBtnIndex(btn)
	local side = Tower:getBtnSide(btn)
	local container = self.towers[side]

	local tower = nil

	if index == 0 then
		tower = container["o"]
	elseif index <= 3 then
		tower = container["t"][4-index]
	elseif index > 3 and index < 7 then
		tower = container["m"][7-index]
	else
		tower = container["b"][10-index]
	end

	tower.btn = btn
	tower:setState(tower.state)

end

function PvPManager:getTower(side, index)
	if index == 0 then
		return self.towers[side]["o"]
	elseif index <= 3 then
		return self.towers[side]["t"][4-index]
	elseif index > 3 and index < 7 then
		return self.towers[side]["m"][7-index]
	else
		return self.towers[side]["b"][10-index]
	end
	return nil
end

-- 战斗场景使用
function PvPManager:destroyTower(tower)
	tower.state = 3
	local index = tower.index
	-- 爆基地
	if index == 0 then
		return
	end

	-- 破高地塔
	if index == 1 or index == 4 or index == 7 then
		DataManager.PvPManager:getTower(tower.side, 0).state = 2
		return
	end

	-- 破外塔
	DataManager.PvPManager:getTower(tower.side, index-1).state = 2
end

return PvPManager