--
-- Author: yjun
-- Date: 2014-11-15 10:41:42
--
local Tower = class("Tower")

-- 塔状态
local TowerState = {
	SAFE = 1,		-- 安全
	FIGHT = 2,		-- 可攻击/可防守
	DESTROY = 3 	-- 被摧毁
}

function Tower:ctor(btn)
	self.btn = btn
	self.index = self:getBtnIndex(btn)
	self.side = self:getBtnSide(btn)
	-- 记录防御的，兵营，基地的血量
	self.BuildingHP = {}

	if self.index == 3 or self.index == 6 or self.index == 9 then
		self:setState(TowerState.FIGHT)
	else
		self:setState(TowerState.SAFE)
	end
end

-- 获取塔的阵营
function Tower:getBtnSide(btn)
	return tonumber(string.split(btn.name, "_")[2])
end

-- 获取塔的序号
function Tower:getBtnIndex(btn)
	return tonumber(string.split(btn.name, "_")[3])
end

function Tower:setState(state)
	self.state = state
	local playerSide = DataManager.PvPManager:getPlayerSide()
		
	if state == TowerState.FIGHT then
		self.btn:setButtonEnabled(true)
		if self.side == playerSide then
			self.btn:setButtonLabelString("normal", "守")
		else
			self.btn:setButtonLabelString("normal", "攻")
		end
	elseif state == TowerState.DESTROY then
		self.btn:removeSelf()	
	elseif state == TowerState.SAFE and self.index ~= 0 then
		self.btn:setButtonEnabled(false)
		self.btn:setButtonLabelString("normal", "")
	end
end

function Tower:SetFight()
	self:setState(TowerState.FIGHT)
end

function Tower:SetDestroy()
	self:setState(TowerState.DESTROY)
	self:enableNextTower(self.index)
end

function Tower:enableNextTower(index)
	local side = self.side
	-- 爆基地
	if index == 0 then
		-- 战斗结束
		local result = "win"
		if side == DataManager.PvPManager:getPlayerSide() then
			result = "lose"
		end
		display.getRunningScene():ShowEndLayer(result)
		return
	end

	-- 破高地塔
	if index == 1 or index == 4 or index == 7 then
		DataManager.PvPManager:getTower(side, 0):SetFight()
		return
	end

	-- 破外塔
	DataManager.PvPManager:getTower(side, index-1):SetFight()
end

return Tower