local Progress = import("..ui.Progress")
local scheduler = require("framework.scheduler")
local Effect = import("..module.Effect")
local Buff = import("..module.Buff")
local Skill = import("..module.Skill")
local AI = import("..module.AI")

local Hero = class("Hero", function()
        return display.newNode()
    end)

function Hero:ctor(heroID, side)
    local heroConf = DataManager:getHeroConf(heroID)
    if not heroConf then
        print("hero config not exist")
        return
    end

    -- 阵营
    self.side = side

    -- 初始化属性信息
    self:initProp(heroConf)

    -- 初始化动画信息
    self:initArmature(heroConf)

    -- 初始化头顶血条
    self:initHPBar()

    -- 初始化状态机
    self:addStateMachine()

    -- 初始化技能信息
    self:initSkill(heroConf)

    -- 初始化AI
    self:initAI()
end

-- 初始化英雄属性信息
function Hero:initProp(heroConf)
    self.id = heroConf.ID
    self.u_index = DataManager:getIncIndex()
    self.IsPlayer = false
    self.name = heroConf.Name

    -- 英雄类型
    self.type = heroConf.Type

    -- 力量，敏捷，智力
    self.str = heroConf.Str
    self.agi = heroConf.Agi
    self.int = heroConf.Int

    -- 记录增加的属性
    self.addstr = 0
    self.addagi = 0
    self.addint = 0
    self.addattack = 0

    -- 基础攻击力
    self.baseatk = heroConf.Attack
    -- 攻击力 = 基础攻击力+主属性转换（每点主属性加5点攻击力）+其他加成（装备和技能）
    self.attack = self.baseatk + self[self.type]*5 + self.addattack

    self.atkType = heroConf.AtkType
    self.atkSprite = heroConf.AtkSprite

    -- 暴击率
    self.crit_rate = 0

    math.randomseed(os.time()+self.u_index*100000)
    local scale = math.random(50)/100 + 1  -- 0.8-1.2 的随机数

    self.atkRange = heroConf.AtkRange*scale
    self.atkSpeed = heroConf.AtkSpeed
    self.maxHp = heroConf.HP + self.str*50
    self.hp = self.maxHp

    -- 是否能被选中
    self.canBeSelect = true

    self.atktime = 0    -- 攻击间隔计时
    self.holdtime = 0   -- 控制时间计时
    self.IsUseAI = true -- 是否AI控制
    self.schedulers = {}-- 计时器集合
    self.buffs = {}     -- buff集合
    self.customcallbacks = {} -- 回调函数集合
end

-- 更新属性
function Hero:UpdateProp()
    -- 攻击力 = 基础攻击力+主属性转换（每点主属性加5点攻击力）+其他加成（装备和技能）
    local mainProp = self[self.type] + self["add"..self.type]
    self.attack = self.baseatk + mainProp*5 + self.addattack
end

-- 初始化技能信息
function Hero:initSkill(heroConf)
    self.skills = {heroConf.Skill_1, heroConf.Skill_2, heroConf.Skill_3, heroConf.Skill_4}
    self.powers = {0,0,0,0}
    self.maxPowers = {Skill:getNeedPower(heroConf.Skill_1),
                        Skill:getNeedPower(heroConf.Skill_2),
                        Skill:getNeedPower(heroConf.Skill_3),
                        Skill:getNeedPower(heroConf.Skill_4)}
    self.skillsReady = {false,false,false,false}

    -- 使用被动技能
    for i = 1, #self.skills do
        if Skill:getSkillType(self.skills[i]) == 0 then
            Skill:UseSkill(self, i)
        end
    end
end

-- 初始化动画信息
function Hero:initArmature(heroConf)
    local manager = ccs.ArmatureDataManager:getInstance()
    manager:addArmatureFileInfo("armature/" .. heroConf.Armature .. ".ExportJson")
    self.armature = ccs.Armature:create("Hero")

    self:addChild(self.armature)

    self.armature:setScale(0.6)

    if self.side == 1 then
        self:setPosition(cc.p(display.left-self.atkRange, display.cy+40))
    else
        self:setPosition(cc.p(display.right+self.atkRange, display.cy+40))
    end

    -- 注册帧回调
    local function onFrameEvent(bone,evt,originFrameIndex,currentFrameIndex)
        self:DoCallBack(evt)
    end
    self.armature:getAnimation():setFrameEventCallFunc(onFrameEvent)

    -- 注册动画回调
    local function animationEvent(armatureBack,movementType,movementID)
        if movementType == ccs.MovementEventType.complete and 
            (movementID == "attack" or movementID == "smitten" or movementID == "skill4") then
            self:Stop()
        end
        
        self:DoCallBack("AnimationEvent", movementID, movementType)
    end
    self.armature:getAnimation():setMovementEventCallFunc(animationEvent)

    -- 计时器
    local function Timer(dt)
        -- 攻击计时
        if self.atktime > 0 then
            self.atktime = self.atktime - 0.1
        end

        -- 眩晕计时
        if self.holdtime > 0 then
            self.holdtime = self.holdtime - 0.1
        end
    end
    self.schedulers["Timer"] = scheduler.scheduleGlobal(Timer, 0.1)
end

-- 初始化头血条信息
function Hero:initHPBar()
    local image = ""
    if self.side == 1 then
        image = "ui/hp_green_small.png"
    else
        image = "ui/hp_red_small.png"
    end

    self.progress = Progress.new("ui/hp_black_small.png", image)
    local size = self.armature:getContentSize()
    size.width = size.width * math.abs(self.armature:getScaleX())
    size.height = size.height * math.abs(self.armature:getScaleY())
    self:addChild(self.progress)

    self.progress:setPosition(0, size.height+20)
    self.progress:setScale(0.8)
    self.progress:setVisible(false)
end

-- 初始化AI
function Hero:initAI()
    self.AI = AI:new()
    self.AI:SetMaster(self)
    -- 帧事件
    local function updateAI(dt)
        self.AI:CatchEvent()
        self:setLocalZOrder(10000 - self:getPositionY())
    end
    self.schedulers["updateAI"] = scheduler.scheduleUpdateGlobal(updateAI)
end

-- 更新头顶血条显示
function Hero:updateHpBar()
    self.progress:setProgress(self.hp/self.maxHp*100)

    if self.schedulers["hideHpBar"] then
        scheduler.unscheduleGlobal(self.schedulers["hideHpBar"])
        self.schedulers["hideHpBar"] = nil
    end

    if self.hp == 0 then
        self.progress:setVisible(false)
    else
        self.progress:setVisible(true)
        
        self.schedulers["hideHpBar"] = scheduler.performWithDelayGlobal(function()
            self.progress:setVisible(false)
            self.schedulers["hideHpBar"] = nil
            end, 2)
    end

    if self.IsPlayer then
        local skillPanel = display.getRunningScene().skillPanel
        skillPanel:UpdateDisplay()
    end
end

---------------------------------------- 外部属性操作 --------------------------------------------------

function Hero:getID()
    return self.id
end

function Hero:getIndex()
    return self.u_index
end

function Hero:IsDead()
    return self:getState() == "dead"
end

function Hero:IsHold()
    return self:getState() == "hold"
end

-- 是否暴击
function Hero:IsCrit()
    math.randomseed(os.time()+self.u_index*100000)
    local num = math.random(10000)/100
    return num < self.crit_rate
end

-- 是否能被选中
function Hero:CanBeSelect()
    return self.canBeSelect
end

-- 设置能否被选中
function Hero:SetCanBeSelect(value)
    self.canBeSelect = value
end

-- 获取攻击数值
function Hero:GetAttack()
    math.randomseed(os.time()+self.u_index*100000)
    local scale = math.random(50)/100+0.7  -- 0.8-1.2 的随机数
    return math.ceil(self.attack * scale)
end

-- 重置攻击时间
function Hero:CheckAtkCD()
    return self.atktime <= 0
end

-- 重置攻击时间
function Hero:ResetAtkTime()
    self.atktime = self.atkSpeed
end

-- 增加血量
function Hero:IncHp(num)
    self.hp = self.hp + num
    if self.hp > self.maxHp then
        self.hp = self.maxHp
    end
    
    if self:CanBeSelect() then
        self:updateHpBar()
        -- 头顶飘字
        Effect:HeadFlyText(self, "+" .. num, "green_digits")
    end
end

-- 减少血量
function Hero:ReduceHp(num, attacker)
    if self:getState() == "dead" or not self:CanBeSelect() then
        return
    end
    local isCrit = false
    if attacker and attacker:IsCrit() then
        isCrit = true
        num = num*2
    end
    num = math.floor(num)
    self.hp = self.hp - num
    if self.hp <= 0 then
        self.hp = 0
        self:doEvent("beKilled")
    end
    self:updateHpBar()
    if attacker then
        self:UpdateBuffs("ReduceHp", num, attacker)
    end

    -- 头顶飘字
    Effect:HeadFlyText(self, "-" .. num, "red_digits", isCrit)
end

-- 增加属性值
function Hero:IncProp(prop, num)
    self[prop] = self[prop] + num
    self:UpdateProp()
end

-- 减少属性值
function Hero:ReduceProp(prop, num)
    self[prop] = self[prop] - num
    if self[prop] <= 0 then
        self[prop] = 0
    end
    self:UpdateProp()
end

-- 增加能量
function Hero:IncPower(num)
    for i = 1, #self.powers do
        self.powers[i] = self.powers[i] + num
        if self.maxPowers[i] > 0 and self.powers[i] >= self.maxPowers[i] then
            self.powers[i] = self.maxPowers[i]
            -- 技能准备完毕
            self.skillsReady[i] = true
        end
    end
    if self.IsPlayer then
        local skillPanel = display.getRunningScene().skillPanel
        skillPanel:UpdateDisplay()
    end
end

-- 减少能量
function Hero:ReducePower(num, index)
    if index < 0 or index > #self.powers then
        print("ReducePower index error [" .. index .. "]")
        return
    end

    self.powers[index] = self.powers[index] - num
    -- 技能重新准备
    self.skillsReady[index] = false
    if self.powers[index] < 0 then
        self.powers[index] = 0
    end
    if self.IsPlayer then
        display.getRunningScene().skillPanel:UpdateDisplay()
    end
end

-- 减少所有槽位能量
function Hero:ReducePowerAll(num)
    for i = 1, 4 do
        self:ReducePower(num, i)
    end
end

function Hero:AddCallBack(event, func)
    if not self.customcallbacks[event] then
        self.customcallbacks[event] = {}
    else
        self:DelCallBack(event, func)
    end
    self.customcallbacks[event][#self.customcallbacks[event]+1] = func
end

function Hero:DelCallBack(event, func)
    if not self.customcallbacks[event] then
        return
    end
    for key, value in pairs(self.customcallbacks[event]) do
        if value == func then
            table.remove(self.customcallbacks[event], key)
            return
        end
    end
end

-- 执行自定义回调
function Hero:DoCallBack(event, ...)
    if self.customcallbacks[event] then
        for key, value in pairs(self.customcallbacks[event]) do
            value(...)
        end
    end
end

-- 刷新buff
function Hero:UpdateBuffs(type, ...)
    for key, value in pairs(self.buffs) do
        value:UpdateBuff(type, ...)
    end
end

-- 删除英雄
function Hero:RemoveHero()
    -- 淡出场景
    local action = transition.sequence(
        {cc.FadeOut:create(2), 
        cc.CallFunc:create(function() self:removeSelf() end)})

    self.armature:runAction(action)
end

---------------------------------------------外部调用 切换状态机 ----------------------------------------

function Hero:getState()
    return self.fsm_:getState()
end

function Hero:WalkTo(pos)
    self:doEvent("doWalk", pos)
end

function Hero:DoAttack()
    if self:getState() == 'dead' then
        return
    end

    if self:getState() ~= 'idle' then
        self:doEvent("stop")
    end

    self:doEvent("doAttack")
end

function Hero:DoMagic(action)
    if self:getState() ~= 'idle' then
        self:doEvent("stop")
    end

    if not action then
        action = "attack"
    end

    self:doEvent("doMagic", action)
end

function Hero:Stop()    
    self:doEvent("stop")
end

function Hero:Hold(time)
    if self:getState() == "hold" then
        if time > self.holdtime then
            self.holdtime = time
        end
    else
        if self:getState() ~= 'idle' then
            self:doEvent("stop")
        end
        self:doEvent("beHold")
        self.holdtime = time
    end
end

function Hero:EndHold()
    if self:getState() == "hold" then
        self:doEvent("stop")
    end
end

-------------------------------------------- 内部调用 -------------------------------------------------

function Hero:idle()
    if self.moveAction then
        self:stopAction(self.moveAction)
        self.moveAction = nil
    end
    self.armature:getAnimation():playWithIndex(0)
    self.armature:getAnimation():setSpeedScale(0.8)

    -- 动作被打断后清空所有帧回调
    self.customcallbacks["onDamageEvent"] = {}
end

function Hero:walkTo(pos, callback)
    local function moveStop()
        self:doEvent("stop")
        if callback then
            callback()
        end
    end

    if self.moveAction then
        self:stopAction(self.moveAction)
        self.moveAction = nil
    end

    local currentPos = cc.p(self:getPosition())
    local destPos = cc.p(pos.x, pos.y)

    -- 调整朝向
    Skill:TurnFace(self, pos.x)

    local posDiff = cc.pGetDistance(currentPos, destPos)
    self.moveAction = transition.sequence(
        {cc.MoveTo:create(5 * posDiff / display.width, cc.p(pos.x,pos.y)), 
        cc.CallFunc:create(moveStop)})

    if self.armature:getAnimation():getCurrentMovementID() ~= "run" then
        self.armature:getAnimation():playWithIndex(1)
    end

    self:runAction(self.moveAction)
    return true
end

-- 远程攻击
function farAttack(self, target)
    local starPos = self.armature:getBone("atkpoint"):getDisplayRenderNode():convertToWorldSpace(cc.p(0,0))
    local targetPos = cc.p(target:getPositionX(), target:getPositionY()+50)
    self.atkeff = display.newSprite(self.atkSprite, starPos.x, starPos.y)
    self.atkeff:setAnchorPoint(cc.p(0.5, 0.5))
    display.getRunningScene():addChild(self.atkeff)
    self.atkeff:setLocalZOrder(self:getLocalZOrder())
    local angle = cc.pToAngleSelf(cc.pSub(targetPos, starPos))
    self.atkeff:setRotation(-math.deg(angle))
    local distance = cc.pGetDistance(starPos, targetPos)
    local action = transition.sequence(
        {cc.MoveTo:create(distance / display.width*2, targetPos), 
        cc.CallFunc:create(function()
            if target.hp > 0 then
                target:ReduceHp(self:GetAttack(), self)
                self:IncPower(40)
            end
            self.atkeff:removeSelf()
            self.atkeff=nil
            end)})
    self.atkeff:runAction(action)
end

function Hero:doAttack()
    local target = Skill:GetSufferer(nil, self, "closest")
    if not target then
        print("no target")
        return
    end

    --调整朝向
    Skill:TurnFace(self, target:getPositionX())

    self.armature:getAnimation():play("attack")

    local function normalattack()
        self:DelCallBack("onDamageEvent", normalattack)

        if target:IsDead() then
            self:Stop()
            return
        end

        -- 近战
        if self.atkType == 1 then
            if target.hp > 0 then
                target:ReduceHp(self:GetAttack(), self)
                self:IncPower(40)
            end
        else -- 远程
            farAttack(self, target)
        end

        self.atktime = self.atkSpeed
    end

    self:AddCallBack("onDamageEvent", normalattack)
end

function Hero:magic(action)
    self.armature:getAnimation():play(action)
end

function Hero:leavemagic()
    Skill:EndSkill(self)
end

function Hero:hold()
    self.armature:getAnimation():play("loading")
end

function Hero:hit()
    if self.hp == 0 then
        self:doEvent("beKilled")
        return
    end
    self.armature:getAnimation():play("smitten")
end

function Hero:dead()
    -- 停止移动
    if self.moveAction then
        self:stopAction(self.moveAction)
        self.moveAction = nil
    end

    -- 删除计时器
    for key, value in pairs(self.schedulers) do
        scheduler.unscheduleGlobal(value)
    end

    -- 删除所有buff
    Buff:ClearAllBuff(self)

    -- 删除对象
    for i = 1, #self.container do
        if self.container[i].u_index == self.u_index then
            table.remove(self.container, i)
            break
        end
    end

    scheduler.performWithDelayGlobal(function()
            self:RemoveHero()
            end, 1)

    if self.subs then
        self.armature:setVisible(true)
        self.subs:removeSelf()
        self.subs = nil
    end

    self.armature:getAnimation():play("death")
end

function Hero:doEvent(event, ...)
    if self:getState() == "deal" and event ~= "stop" then
        return
    end
    self.fsm_:doEvent(event, ...)
end

function Hero:addStateMachine()
    self.fsm_ = {}
    cc.GameObject.extend(self.fsm_)
    :addComponent("components.behavior.StateMachine")
    :exportMethods()

    self.fsm_:setupState({

        initial = "idle",

        events = {
        {name = "doWalk", from = {"idle", "attack", "magic"},   to = "walk" },
        {name = "doAttack",  from = {"idle", "walk"},  to = "attack"},
        {name = "beKilled", from = {"idle", "walk", "attack", "hit", "magic", "hold"},  to = "dead"},
        {name = "beHit", from = {"idle", "walk", "attack", "hold"}, to = "hit"},
        {name = "stop", from = {"walk", "attack", "hit", "magic", "dead", "hold"}, to = "idle"},
        {name = "doMagic", from = {"idle", "walk"}, to = "magic"},
        {name = "beHold", from = {"idle", "walk", "attack", "hit", "magic"}, to = "hold"},
        },

        callbacks = {
        onidle = function (event) self:idle() end,
        onwalk = function (event) self:walkTo(event.args[1], event.args[2]) end,
        onattack = function (event) self:doAttack() end,
        onhit = function (event) self:hit() end,
        ondead = function (event) self:dead() end,
        onmagic = function (event) self:magic(event.args[1]) end,
        onleavemagic = function (event) self:leavemagic() end,
        onhold = function (event) self:hold() end
        },
        })

end

return Hero