
local NetManager = import("..datamanager.netmanager")
local MSG = import("..datamanager.MsgDefine")
local Player = import("..roles.Player")

local StartScene = class("StartScene", function()
    return display.newScene("StartScene")
end)

function StartScene:onEnter()
    audio.playMusic("music/dominis.mp3")
end

function StartScene:ctor()
    local background = display.newSprite("image/start-bg.jpg")
    background:setPosition(display.cx, display.cy)
    self:addChild(background)

    local images = {
        normal = "ui/button.png",
        pressed = "ui/button_press.png",
        disabled = "ui/button_press.png",
    }

    -- 连接服务器
    local netManager = NetManager.new()
    netManager:AddMsgListener(MSG.RESPOND_CLIENTID, function(msg)
        cclog(msg)
        end)
    netManager:Connect()

    local btn = cc.ui.UIPushButton.new(images, {scale9 = true})
    :setButtonSize(200, 60)
    :setButtonLabel("normal", cc.ui.UILabel.new({
        text = "开始游戏",
        font = "font/main.ttf",
        size = 32,
        color = cc.c3b(0,200,200)
        }))
    :onButtonClicked(function(event)
            if not self.selectedHeroID then
                print("Please select your hero")
                return
            end
            netManager:AddMsgListener(MSG.RESPOND_JOIN_MATCH, function(msg)
                cclog(msg)
            end)
            netManager:Send({MSG.REQUEST_JOIN_MATCH, self.selectedHeroID})
        end)
    :align(display.CENTER_TOP, display.left+display.width/2, display.top - 170)
    :addTo(self)

    -- 初始化英雄按钮
    self:initHeroBtns()
end

-- 初始化英雄按钮
function StartScene:initHeroBtns()
    local herolist = {"hero_CM","hero_CW","hero_JUGG","hero_lion","hero_TH"}
    for i = 1, #herolist do
        local btn = self:createHeroBtn(herolist[i])
        btn:setPosition(display.cx + (3-i)*100, display.cy - 200)
    end
end

-- 创建英雄按钮
function StartScene:createHeroBtn(heroID)
    local images = {
        normal = "icon/"..heroID..".png",
        pressed = "icon/"..heroID..".png",
        disabled = "icon/"..heroID..".png",
    }

    local btn = cc.ui.UIPushButton.new(images, {scale9 = true})
    :setButtonSize(64, 64)
    :onButtonClicked(function(event)
        self.selectedHeroID = heroID
        if self.selectedHeroImage then
            self.selectedHeroImage:setTexture("icon/"..heroID..".png")
        else
            self.selectedHeroImage = display.newSprite("icon/"..heroID..".png", display.cx, display.cy)
            self.selectedHeroImage:addTo(self)
        end
        end)
    :addTo(self)

    return btn
end

return StartScene

