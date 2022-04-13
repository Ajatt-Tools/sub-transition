--[[
Copyright: Ren Tatsumoto
License: GNU GPL, version 3 or later; https://www.gnu.org/licenses/gpl-3.0.html
]]

local mp = require('mp')
local msg = require('mp.msg')
local unpack = unpack and unpack or table.unpack

local function notify(params)
    local osd = params.osd or false
    local level = params.level or 'info'
    local duration = params.duration or 1
    msg[level](params.message)
    if osd then
        mp.osd_message(params.message, duration)
    end
end

return {
    unpack = unpack,
    notify = notify,
}
