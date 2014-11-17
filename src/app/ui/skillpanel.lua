--
-- Author: yjun
-- Date: 2014-09-23 20:56:03
--
local Skill = import("..module.Skill")
local Progress = import("..ui.Progress")
local Effect = import("..module.Effect")

local SkillPanel = class("SkillPanel", function(scene)
        local hero = scene.hero
        local heroID = hero:getID()
        -- 获取英雄技能信息
        local subheroID = string.split(heroID, '_')[2]
        local heroInfo = DataManager:getHeroConf(heroID)

        local node = cc.uiloader:load("ui/SkillPanelUI/SkillPanelUI_1.json")
        node.hero = hero
        scene:addChild(node)
        
        node.btns = {}
        -- 初始化技能图标
        for i = 1, 4 do
            node.btns[i] = cc.uiloader:seekNodeByTag(node, i)
            node.btns[i]:setColor(cc.c3b(100, 100, 100))
            node.btns[i]:onButtonClicked(function(event)
                if Skill:CanUseSkill(hero, i) then
                    Skill:UseSkill(hero, i)
                end
                end)
            :setButtonImage("normal", "icon/skill_"..subheroID .. "_" .. i .. ".png")
            :setButtonImage("pressed", "icon/skill_"..subheroID .. "_" .. i .. ".png")
            :setButtonImage("disabled", "icon/skill_"..subheroID .. "_" .. i .. ".png")
        end

        local skillBtn = cc.uiloader:seekNodeByTag(node, 5)
        skillBtn:onButtonClicked(function(event)
        	if (display.getRunningScene().hero.armature:getAnimation():getCurrentMovementID() ~= "attack") then
                hero:doEvent("doAttack")
        	end
        	end)
        :setButtonImage("normal", "icon/"..heroID .. ".png")
        :setButtonImage("pressed", "icon/"..heroID .. ".png")
        :setButtonImage("disabled", "icon/"..heroID .. ".png")

        node.powerBars = {}
        for i = 1, 4 do
            node.powerBars[i] = cc.uiloader:seekNodeByTag(node, i+10)
            if hero.maxPowers[i] == 0 then
                node.powerBars[i]:setVisible(false)
            end
        end

        node.hpBar = cc.uiloader:seekNodeByTag(node, 6)

        return node

        end)

function SkillPanel:ctor()
    self:setLocalZOrder(10000)
end

-- 更新显示
function SkillPanel:UpdateDisplay()
    local hero = self.hero
    if not hero then
        return
    end

    -- 同步主玩家血条
    self.hpBar:setPercent(hero.progress:getProgress())

    -- 更新能量条
    for i = 1, 4 do
        if hero.maxPowers[i] > 0 then
            local value = hero.powers[i]/hero.maxPowers[i]*100
            if value == 100 then
                self.btns[i]:setColor(display.COLOR_WHITE)
                self.btns[i]:setButtonEnabled(true)
            else
                self.btns[i]:setColor(cc.c3b(100, 100, 100))
                self.btns[i]:setButtonEnabled(false)
            end
            self.powerBars[i]:setPercent(value)
        end
    end
end

return SkillPanel