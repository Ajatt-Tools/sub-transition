--[[
Copyright: Ren Tatsumoto
License: GNU GPL, version 3 or later; https://www.gnu.org/licenses/gpl-3.0.html
]]

local mp = require('mp')
local h = require('helpers')

local Menu = {
    active = false,
    keybindings = {},
    overlay = mp.create_osd_overlay and mp.create_osd_overlay('ass-events'),
}

function Menu:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Menu:with_update(params)
    return function()
        pcall(h.unpack(params))
        self:update()
    end
end

function Menu:make_osd()
    return nil
end

function Menu:update()
    if self.active == false then return end
    self.overlay.data = self:make_osd():get_text()
    self.overlay:update()
end

function Menu:open()
    if self.overlay == nil then
        h.notify("OSD overlay is not supported in " .. mp.get_property("mpv-version"), "error", 5)
        return
    end

    if self.active == true then
        self:close()
        return
    end

    for _, val in pairs(self.keybindings) do
        mp.add_forced_key_binding(val.key, val.key, val.fn)
    end

    self.active = true
    self:update()
end

function Menu:close()
    if self.active == false then
        return
    end

    for _, val in pairs(self.keybindings) do
        mp.remove_key_binding(val.key)
    end

    self.overlay:remove()
    self.active = false
end

return Menu
