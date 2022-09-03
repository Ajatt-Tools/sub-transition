--[[
Copyright: Ren Tatsumoto
License: GNU GPL, version 3 or later; https://www.gnu.org/licenses/gpl-3.0.html
]]

local mp = require('mp')

local self = {}

self.on_pause_change = function(_, is_paused)
    if self.config.hide_subs_when_playing then
        mp.set_property_bool("sub-visibility", is_paused)
    end
end

self.init = function(config)
    self.config = config
    mp.observe_property("pause", "bool", self.on_pause_change)
end

return self
