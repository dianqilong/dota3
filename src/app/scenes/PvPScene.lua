--
-- Author: yjun
-- Date: 2014-11-12 19:45:34
--
import("..util")
local PvPManager = import("..datamanager.pvpmanager")
local Tower = import("..datamanager.Tower")
-- 塔状态
local TowerState = {
	SAFE = 1,		-- 安全
	FIGHT = 2,		-- 可攻击/可防守
	DESTROY = 3 	-- 被摧毁
}

local PvPScene = class("PvPScene", function()
	return display.newScene("PvPScene")
	end)

function PvPScene:ctor()
	if not DataManager.PvPManager then
		DataManager.PvPManager = PvPManager.new()
		DataManager.PvPManager:setPlayerSide(1)
	else
		DataManager.PvPManager.first = false
	end
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

	self.hero = {side = 1}

	local function onClicked(event)
		local side = Tower:getBtnSide(event.target)
		local index = Tower:getBtnIndex(event.target)
		local args = {hero = "hero_CM", side = 1, 
					  team = {"soldier01","soldier01","soldier01","soldier02"},
					  enemy = {},--{"soldier01","soldier01","soldier01","soldier02"},
					  tower = DataManager.PvPManager:getTower(side, index)}
    	app:enterFightScene(args)
	end

	-- 添加按钮点击事件
	self.btn_root = cc.uiloader:seekNodeByName(node, "map_btns")
	local info = {}
	local container
	for key, btn in pairs(self.btn_root:getChildren()) do
		btn:onButtonClicked(onClicked)
		DataManager.PvPManager:addTower(btn)
	end

	-- 检查比赛是否结束
	self:CheckMatchOver()
end

-- 检查比赛是否结束
function PvPScene:CheckMatchOver()
	local tower = DataManager.PvPManager:getTower(1, 0)
	if tower.state == 3 then
		self:ShowEndLayer(2==DataManager.PvPManager:getPlayerSide())
		return
	end

	tower = DataManager.PvPManager:getTower(2, 0)
	if tower.state == 3 then
		self:ShowEndLayer(1==DataManager.PvPManager:getPlayerSide())
		return
	end
end

-- 战斗结束画面
function PvPScene:ShowEndLayer(win)
    DataManager.PvPManager = nil

    local layer = display.newColorLayer(cc.c4b(0,0,0,200))
    layer:zorder(100000)
    self:addChild(layer)

    local images = {
        normal = "ui/button.png",
        pressed = "ui/button_press.png",
        disabled = "ui/button_press.png",
        }

    local button = cc.ui.UIPushButton.new(images, {scale9 = true})
    :setButtonSize(200, 60)
    :setButtonLabel("normal", cc.ui.UILabel.new({
        text = "返回开始游戏",
        font = "font/main.ttf",
        size = 32,
        color = cc.c3b(0,200,200)
        }))
    :onButtonClicked(function(event)
        app:enterStartScene()
        end)
    :align(display.CENTER, display.cx, display.cy)
    :addTo(layer)

    -- button:opacity(0)
    -- button:fadeTo(1, 255)

    local content = "胜利"
    local content_color = cc.c4b(200,200,0,0)
    if not win then
        content = "失败"
        content_color = cc.c4b(200,200,200,0)
    end

    local label = cc.ui.UILabel.new({
        text = content,
        font = "font/main.ttf",
        size = 128,
        color = content_color
        })
    label:setAnchorPoint(cc.p(0.5, 0.5))
    label:setPosition(display.cx, display.cy+200)
    layer:addChild(label)

    label:opacity(0)
    label:fadeTo(1, 255)
end


return PvPScene