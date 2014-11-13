--
-- Author: yjun
-- Date: 2014-11-12 19:45:34
--
local PvPScene = class("PvPScene", function()
	return display.newScene("PvPScene")
	end)

function PvPScene:ctor()
    self:initScene()
end

function PvPScene:onEnter()
end

function PvPScene:onExit()
end

function PvPScene:initScene()
	-- 背景
	local node = cc.uiloader:load("ui/pvp_main/pvp_main.json")
	self:addChild(node)
end

return PvPScene