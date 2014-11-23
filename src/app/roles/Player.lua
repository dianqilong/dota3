--
-- Author: yjun
-- Date: 2014-11-23 13:35:34
--
local Player = class("Player")

function Player:ctor(heroID)
	self.heroID = heroID
end

return Player