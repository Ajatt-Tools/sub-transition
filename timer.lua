--[[
Copyright: Ren Tatsumoto
License: GNU GPL, version 3 or later; https://www.gnu.org/licenses/gpl-3.0.html
]]

local mp = require('mp')
local small_duration = 0.015

local function new_timer()
    local end_time_pos = -1
    local check_stop
    local on_end_fn

    local set = function(end_time, on_end)
        if end_time - mp.get_property_number("time-pos", 0) < small_duration then
            on_end()
            end_time_pos = -1
        else
            end_time_pos = end_time
            on_end_fn = on_end
            mp.observe_property("time-pos", "number", check_stop)
        end

    end

    local cancel = function()
        mp.unobserve_property(check_stop)
        end_time_pos = -1
    end

    check_stop = function(_, time)
        if time ~= nil and time >= end_time_pos then
            cancel()
            on_end_fn()
        end
    end

    return {
        set = set,
        pos = function() return end_time_pos end,
        cancel = cancel,
    }
end

return {
    new = new_timer,
}
