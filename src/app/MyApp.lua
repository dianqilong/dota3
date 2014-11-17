require("config")
require("framework.init")

local dataManager = import(".datamanager.datamanager")

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
end

function MyApp:run()
    cc.FileUtils:getInstance():addSearchPath("res/")

    local args = {hero = "hero_CM", side = 1, team = {"soldier01","soldier01","soldier01","soldier02"},
					enemy = {"soldier01","soldier01","soldier01","soldier02","tower"}}

	DataManager = dataManager:new()
    self:enterStartScene()
end

function MyApp:enterFightScene(args)
    self:enterScene("FightScene", {args}, "fade", 0.6)
end

function MyApp:enterStartScene()
    self:enterScene("StartScene", nil, "fade", 0.6)
end

function MyApp:enterPvPScene(args)
    self:enterScene("PvPScene", {args}, "fade", 0.6)
end

return MyApp
