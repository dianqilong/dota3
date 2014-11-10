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

    self.hero.powers[4] = 1000

    -- 友军AI
    self:addTeam()

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

-- 战斗结束画面
function FightScene:ShowEndLayer()
	local layer = display.newLayer()
	
end

return FightScene