--
-- Author: yjun
-- Date: 2014-11-07 10:34:07
--
local scheduler = require("framework.scheduler")
local Hero = import("..roles.Hero")
local SkillPanel = import("..ui.skillpanel")
local dataManager = import("..datamanager.datamanager")
local Skill = import("..module.Skill")

local FightScene = class("FightScene", function()
    return display.newScene("FightScene")
    end)

function FightScene:ctor()
    self:initData()
    self:initScene()
end

function FightScene:onEnter()
    audio.playMusic("music/tactics.mp3")
end

function FightScene:onExit()
end


-- 初始化数据
function FightScene:initData()
    -- 加载数据
    DataManager = dataManager:new()
end

-- 初始化场景
function FightScene:initScene()
	-- 背景
    local background = display.newSprite("image/background.png", display.cx, display.cy)
    self:addChild(background)

    -- 地图可行走范围
    self.map_top = 310 --360
    self.map_bottom = 210 --160
    self.map_space = (self.map_top - self.map_bottom)/5

    self.lefts = {}
    self.rights = {}

    -- 主玩家
    self.hero = Hero.new("hero_CM", 1)
    self.hero.IsUseAI = false
    self.lefts[#self.lefts+1] = self.hero
    self.hero.IsPlayer = true
    self.hero.container = self.lefts
    self.hero:setPositionY(self.map_top)
    self:addChild(self.hero)

    -- self.hero.powers[4] = 1000

    -- 友军AI
    self:addTeam()
    local tower = Hero.new("tower", 1)
    tower.container = self.lefts
    tower:setPosition(display.left+200, self.map_top-self.map_space*3)
    self.lefts[#self.lefts+1] = tower
    self:addChild(tower)

    -- 敌军AI
    self:addEnemy()

    self.skillPanel = SkillPanel.new(self)
    self.skillPanel:UpdateDisplay()
end

function FightScene:addTeam()
    local list = {"hero_CW","hero_JUGG","hero_TH","hero_lion"}
    for i = 1, #list do
        local team = Hero.new(list[i], 1)
        team:setPositionY(self.map_top-self.map_space*i)
        self.lefts[#self.lefts+1] = team
        team.container = self.lefts
        self:addChild(team)
    end
end

function FightScene:addEnemy()
    local list = {"hero_CM","hero_JUGG","hero_TH","hero_lion","hero_CW"}
    for i = 1, #list do
        local enemy = Hero.new(list[i], 2)
        enemy:setPositionY(self.map_top-self.map_space*(i-1))
        self.rights[#self.rights+1] = enemy
        enemy.container = self.rights
        self:addChild(enemy)
    end
end

-- 检查战斗是否结束
function FightScene:CheckFightOver()
    local side = self.hero.side
    if #self.lefts == 0 then
        if side == 1 then
            self:ShowEndLayer("lose")
        else
            self:ShowEndLayer("win")
        end
    elseif #self.rights == 0 then
        if side == 1 then
            self:ShowEndLayer("win")
        else
            self:ShowEndLayer("lose")
        end
    end
end

-- 战斗结束画面
function FightScene:ShowEndLayer(result)
    self:ClearAllDate()

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
    if result == "lose" then
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

-- 清理对象数据
function FightScene:ClearAllDate()
    for i = 1, #self.lefts do
        self.lefts[i]:ClearData()
    end

    for i = 1, #self.rights do
        self.rights[i]:ClearData()
    end
end

return FightScene