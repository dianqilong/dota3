local scheduler = require("framework.scheduler")
local Hero = import("..roles.Hero")
local SkillPanel = import("..ui.skillpanel")
local dataManager = import("..datamanager.datamanager")
local Skill = import("..module.Skill")

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
    end)

function MainScene:ctor()
    self:initData()
    self:initScene()
end

-- 初始化数据
function MainScene:initData()
    -- 加载数据
    DataManager = dataManager:new()
end

-- 初始化场景
function MainScene:initScene()
    -- if true then
    --     local a = nil or {}
    --     print(a)
    --     return
    -- end
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

    -- self:addTouchLayer()
end

function MainScene:addTeam()
    local list = {"hero_CW","hero_JUGG","hero_TH","hero_lion"}
    for i = 1, #list do
        local team = Hero.new(list[i], 1)
        team:setPositionY(self.map_top-self.map_space*i)
        self.lefts[#self.lefts+1] = team
        team.container = self.lefts
        self:addChild(team)
    end
end

function MainScene:addEnemy()
    local list = {"hero_CM","hero_JUGG","hero_TH","hero_lion","hero_CW"}
    for i = 1, #list do
        local enemy = Hero.new(list[i], 2)
        enemy:setPositionY(self.map_top-self.map_space*(i-1))
        self.rights[#self.rights+1] = enemy
        enemy.container = self.rights
        self:addChild(enemy)
    end
end

function MainScene:addTouchLayer()
    local function onTouch(eventName, x, y)
        if eventName == "began" then
            self.hero:walkTo({x=x, y=y})
            if self.hero:getState() ~= 'walk' and self.hero:getState() ~= 'hit' then
                self.hero:doEvent("doWalk", cc.p(x, y))
            end
        end
    end

    self.layerTouch = display.newLayer()
    self.layerTouch:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return onTouch(event.name, event.x, event.y)
        end)
    self.layerTouch:setTouchEnabled(true)
    self.layerTouch:setContentSize(cc.size(display.width, display.height - 250))
    self.layerTouch:setPosition(cc.p(0,100))
    self:addChild(self.layerTouch, -5)
end

function MainScene:pause()
    display.pause()
    local layer = PauseLayer.new()
    self:addChild(layer)
end

function MainScene:showNextLevelItem()
    local goItem = self.menu:getChildByTag(2)
    goItem:setVisible(true)
    goItem:runAction(CCRepeatForever:create(CCBlink:create(1, 1)))
end

function MainScene:gotoNextLevel()
    local goItem = self.menu:getChildByTag(2)
    transition.stopTarget(goItem)
    goItem:setVisible(false)

    self.background:move("left", self.player)
end

function MainScene:enterLevel(level)
    self.level = level
    self:addUI()
    self:addRoles()
end

function MainScene:enemyDead(enemy)
    print("EnemyDead")
    self:removeEnemy(enemy)

    if #self.enemys == 0 then
        self:showNextLevelItem()
    end
end

function MainScene:backgroundMoveEnd()
end

function MainScene:onEnter()

end

function MainScene:onExit()
end

return MainScene
