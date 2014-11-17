--
-- Author: yjun
-- Date: 2014-11-07 10:34:07
--
local scheduler = require("framework.scheduler")
local Hero = import("..roles.Hero")
local SkillPanel = import("..ui.skillpanel")
local Skill = import("..module.Skill")
local Effect = import("..module.Effect")

local FightScene = class("FightScene", function(...)
    return display.newScene("FightScene")
    end)

function FightScene:ctor(args)
    self:initScene(args)
end

function FightScene:onEnter()
    audio.playMusic("music/tactics.mp3")
end

function FightScene:onExit()
end

-- 初始化场景
function FightScene:initScene(args)
    -- local args = ...
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
    self.hero = Hero.new(args.hero, args.side)
    self.hero.IsUseAI = false
    self.lefts[#self.lefts+1] = self.hero
    self.hero.IsPlayer = true
    self.hero.container = self.lefts
    self.hero:setPositionY(self.map_top)
    Effect:AddBossEff(self.hero)
    self:addChild(self.hero)

    -- self.hero.powers[4] = 1000

    -- 友军AI
    self:addSoldiers(args.team, args.side)

    -- 敌军AI
    self:addSoldiers(args.enemy, 3-args.side)

    -- 塔
    if args.tower then
        self:addTower(args.tower)
    end

    self.skillPanel = SkillPanel.new(self)
    self.skillPanel:UpdateDisplay()
end

function FightScene:addTeam(list)
    for i = 1, #list do
        local team = Hero.new(list[i], 1)
        team:setPositionY(self.map_top-self.map_space*i)
        self.lefts[#self.lefts+1] = team
        team.container = self.lefts
        self:addChild(team)
    end
end

function FightScene:addEnemy(list)
    for i = 1, #list do
        local enemy = Hero.new(list[i], 2)
        enemy:setPositionY(self.map_top-self.map_space*(i-1))
        self.rights[#self.rights+1] = enemy
        enemy.container = self.rights
        self:addChild(enemy)
    end
end

function FightScene:addSoldiers(list, side)
    local container = nil
    if side == 1 then
        container = self.lefts 
    else
        container = self.rights 
    end

    for i = 1, #list do
        local soldier = Hero.new(list[i], side)
        soldier:setPositionY(self.map_top-self.map_space*i)
        container[#container+1] = soldier
        soldier.container = container
        self:addChild(soldier)
    end
end

function FightScene:addTower(tower)
    if not tower then
        return
    end

    local container = nil
    local towerX = 0
    local barracksX = 0

    local side = tower.side
    local index = tower.index
    if side == 1 then
        towerX = display.left+200
        barracksX = towerX - 150
        container = self.lefts
    else
        towerX = display.right-200
        barracksX = towerX + 150
        container = self.rights
    end

    if index == 1 or index == 4 or index == 7 then
        -- 兵营
        local barracks = Hero.new("barracks", side)
        if tower.BuildingHP["barracks"] and tower.BuildingHP["barracks"] > 0 then
            barracks.hp = tower.BuildingHP["barracks"]
        end
        barracks.tower = tower
        barracks.BuildingHP = {["barracks"]=0}
        container[#container+1] = barracks
        barracks.container = container
        self:addChild(barracks)
        barracks:setPosition(barracksX, self.map_top-self.map_space*3)

        -- 高地塔已破
        if tower.BuildingHP["tower_1"] or tower.BuildingHP["tower_1"] == 0 then
            return
        end

        local new_tower = Hero.new("tower", side)
        if tower.BuildingHP["tower_1"] then
            new_tower.hp = tower.BuildingHP["tower_1"]              
        end
        new_tower.tower = tower
        new_tower.BuildingHP = {["tower_1"]=0}
        container[#container+1] = new_tower
        new_tower.container = container
        self:addChild(new_tower)
        new_tower:setPosition(towerX, self.map_top-self.map_space*3)

        return
    end

    -- 基地
    if index == 0 then
        local office = Hero.new("office", side)
        if tower.BuildingHP["office"] and tower.BuildingHP["office"] > 0 then
            office.hp = tower.BuildingHP["office"]
        end
        office.tower = tower
        office.BuildingHP = {["office"]=0}
        container[#container+1] = office
        office.container = container
        self:addChild(office)
        office:setPosition(barracksX, self.map_top-self.map_space*3)

        -- 基地1塔
        if not tower.BuildingHP["tower_1"] or tower.BuildingHP["tower_1"] > 0 then
            local tower_1 = Hero.new("tower", side)
            if tower.BuildingHP["tower_1"] then
                tower_1.hp = tower.BuildingHP["tower_1"]              
            end
            tower_1.tower = tower
            tower_1.BuildingHP = {["tower_1"]=0}
            container[#container+1] = tower_1
            tower_1.container = container
            self:addChild(tower_1)
            tower_1:setPosition(towerX, self.map_top-self.map_space)
        end

        -- 基地2塔
        if not tower.BuildingHP["tower_2"] or tower.BuildingHP["tower_2"] > 0 then
            local tower_2 = Hero.new("tower", side)
            if tower.BuildingHP["tower_2"] then
                tower_2.hp = tower.BuildingHP["tower_2"]              
            end
            tower_2.tower = tower
            tower_2.BuildingHP = {["tower_2"]=0}
            container[#container+1] = tower_2
            tower_2.container = container
            self:addChild(tower_2)
            tower_2:setPosition(towerX, self.map_top-self.map_space*5)
        end

        return
    end

    local new_tower = Hero.new("tower", side)
    if tower.BuildingHP["tower"] then
        new_tower.hp = tower.BuildingHP["tower"]              
    end
    new_tower.tower = tower
    new_tower.BuildingHP = {["tower"]=0}
    container[#container+1] = new_tower
    new_tower.container = container
    self:addChild(new_tower)
    new_tower:setPosition(towerX, self.map_top-self.map_space*3)
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
        app:enterPvPScene()
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