
local StartScene = class("StartScene", function()
    return display.newScene("StartScene")
end)

function StartScene:ctor()

    local background = display.newSprite("image/start-bg.jpg")
    background:setPosition(display.cx, display.cy)
    self:addChild(background)

    -- local label = cc.ui.UILabel.new({
    --     text = "开始游戏",
    --     font = "font/main.ttf",
    --     size = 64,
    --     align = cc.ui.UILabel.TEXT_ALIGN_CENTER})
    -- label:setPosition(display.cx, display.cy)
    -- label:setAnchorPoint(cc.p(0.5, 0.5))
    -- self:addChild(label)

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
        display.replaceScene(require("app.scenes.MainScene").new())
        end)
    :align(display.CENTER_TOP, display.left+display.width/2, display.top - 170)
    :addTo(self)

    -- local item = ui.newImageMenuItem({image="#start1.png", imageSelected="#start2.png",
    --     listener = function()
    --         display.replaceScene(require("app.scenes.MainScene").new())
    --     end})
    -- item:setPosition(display.cx, display.cy)
    -- local menu = ui.newMenu({item})
    -- menu:setPosition(display.left, display.bottom)

    -- self:addChild(menu)
end

function StartScene:onExit()
end

return StartScene

