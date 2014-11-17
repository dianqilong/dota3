
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

    cc.ui.UIPushButton.new(images, {scale9 = true})
    :setButtonSize(200, 60)
    :setButtonLabel("normal", cc.ui.UILabel.new({
        text = "开始游戏",
        font = "font/main.ttf",
        size = 32,
        color = cc.c3b(0,200,200)
        }))
    :onButtonClicked(function(event)
        app:enterPvPScene()
        end)
    :align(display.CENTER_TOP, display.left+display.width/2, display.top - 170)
    :addTo(self)
end

return StartScene

