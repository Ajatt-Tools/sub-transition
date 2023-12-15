--[[
Copyright: Ren Tatsumoto
License: GNU GPL, version 3 or later; https://www.gnu.org/licenses/gpl-3.0.html
]]

local mp = require('mp')
local msg = require('mp.msg')

local self = {
    unpack = unpack and unpack or table.unpack,
}

self.notify = function(params)
    local osd = params.osd or false
    local level = params.level or 'info'
    local duration = params.duration or 1
    msg[level](params.message)
    if osd then
        mp.osd_message(params.message, duration)
    end
end

self.is_empty = function(var)
    return var == nil or var == '' or (type(var) == 'table' and next(var) == nil)
end

local non_dialogue = {
    '^%b()$',
    '^（.-）$',
    '^-?%[.-%]$',
    '^[♪♬～〜]+$',
}

self.is_non_dialogue = function(sub_line_text)
    if self.is_empty(sub_line_text) then
        return true
    end
    for _, test_str in pairs(non_dialogue) do
        if sub_line_text:match(test_str) then
            return true
        end
    end
    return false
end

return self
