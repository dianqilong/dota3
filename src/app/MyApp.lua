
require("config")
require("framework.init")

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
end

function MyApp:run()
    cc.FileUtils:getInstance():addSearchPath("res/")
    self:enterFightScene()
end

function MyApp:enterFightScene()
    self:enterScene("FightScene", nil, "fade", 0.6)
end

function MyApp:enterStartScene()
    self:enterScene("StartScene", nil, "fade", 0.6)
end

function MyApp:enterPvPScene()
    self:enterScene("PvPScene", nil, "fade", 0.6)
end

return MyApp
