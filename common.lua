--[[
Copyright: Ren Tatsumoto
License: GNU GPL, version 3 or later; http://www.gnu.org/licenses/agpl.html
]]

local mp = require('mp')
local msg = require('mp.msg')
local unpack = unpack and unpack or table.unpack

local function notify(message, level, duration)
    level = level or 'info'
    duration = duration or 1
    msg[level](message)
    mp.osd_message(message, duration)
end

return {
    unpack = unpack,
    notify = notify,
}
