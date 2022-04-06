--[[
Copyright: Ren Tatsumoto
License: GNU GPL, version 3 or later; https://www.gnu.org/licenses/gpl-3.0.html
]]

local NAME = 'sub_transition'
local mpopt = require('mp.options')
local mp = require('mp')
local utils = require('mp.utils')
local com = require('common')
local msg = require('mp.msg')
local OSD = require('osd_styler')
local Menu = require('menu')
local default_sync_property = mp.get_property("video-sync", "audio")

local config = {
    start_enabled = false, -- enable transitions when mpv starts without having to enable them in the menu
    start_delay = 0.1, -- if the next subtitle appears after this threshold then speedup
    reset_before = 0.3, --seconds to stop short of the next subtitle
    min_duration = 0.4, -- minimum duration of a skip
    normal_speed = 1, -- reset back to this speed
    inter_speed = 2.5, -- the value that "speed" is set to during speedup
    menu_font_size = 24, -- font size
}

local function is_empty(var)
    return var == nil or var == '' or (type(var) == 'table' and next(var) == nil)
end

local function _(text)
    return text:gsub('_', ' ')
end

local function new_timer()
    local end_time_pos = -1
    local check_stop
    local on_end_fn

    local set = function(end_time, on_end)
        end_time_pos = end_time
        on_end_fn = on_end
        mp.observe_property("time-pos", "number", check_stop)
    end

    local cancel = function()
        mp.unobserve_property(check_stop)
        end_time_pos = -1
    end

    check_stop = function(_, time)
        if time >= end_time_pos then
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

local function get_delay_to_next_sub()
    local initial_sub_delay = mp.get_property_native("sub-delay") or 0
    mp.command("no-osd sub-step 1")
    local next_sub_delay = mp.get_property_native("sub-delay") or 0
    mp.set_property("sub-delay", initial_sub_delay)
    return initial_sub_delay - next_sub_delay
end

local timers = {
    start_transition = new_timer(),
    end_transition = new_timer(),
}

local function start_transition()
    mp.set_property("speed", config.inter_speed)
    if mp.get_property_native("video-sync") == default_sync_property then
        mp.set_property("video-sync", "desync")
    end
    msg['info'](string.format("Changed speed to %f", config.inter_speed))
end

local function end_transition()
    mp.set_property("speed", config.normal_speed)
    if mp.get_property_native("video-sync") == "desync" then
        mp.set_property("video-sync", default_sync_property)
    end
end

local function reset_transition()
    for _, timer in pairs(timers) do
        timer.cancel()
    end
    end_transition()
end

local function check_sub(_, sub)
    if is_empty(sub) then
        local current_pos = mp.get_property_native("time-pos")
        local delay_to_next_sub = get_delay_to_next_sub()
        if current_pos and delay_to_next_sub then
            local speedup_start = current_pos + config.start_delay
            local speedup_end = current_pos + delay_to_next_sub - config.reset_before
            if speedup_end - speedup_start >= config.min_duration then
                timers.start_transition.set(speedup_start, start_transition)
                timers.end_transition.set(speedup_end, end_transition)
            end
        end
    else
        reset_transition()
    end
end

local transitions = (function()
    local enabled = false
    local function toggle()
        if not enabled then
            mp.observe_property("sub-text", "string", check_sub)
            mp.osd_message("Transitions enabled.")
        else
            mp.unobserve_property(check_sub)
            reset_transition()
            mp.osd_message("Transitions disabled.")
        end
        enabled = not enabled
    end
    local function status()
        return enabled and 'enabed' or 'disabled'
    end
    return {
        toggle = toggle,
        status = status,
    }
end)()

local function lua_to_mpv(config_value)
    if type(config_value) == 'boolean' then
        return config_value and 'yes' or 'no'
    else
        return config_value
    end
end

local function save_config()
    local mpv_dir_path = string.gsub(mp.get_script_directory(), "scripts/[^/]+$", "")
    local config_filepath = utils.join_path(mpv_dir_path, string.format('script-opts/%s.conf', NAME))
    local handle = io.open(config_filepath, 'w')
    if handle ~= nil then
        handle:write(string.format("# Written by %s on %s.\n", NAME, os.date()))
        for key, value in pairs(config) do
            handle:write(string.format('%s=%s\n', key, lua_to_mpv(value)))
        end
        handle:close()
        com.notify("Saved.", "info", 3)
    else
        com.notify(string.format("Couldn't open %s.", config_filepath), "error", 5)
    end
end

local menu = Menu:new { selected = 1 }

menu.keybindings = {
    -- bindings
    { key = 't', fn = menu:with_update { transitions.toggle } },
    { key = 's', fn = save_config },
    { key = 'ESC', fn = function() menu:close() end },
    -- vim keys
    { key = 'k', fn = menu:with_update { function() menu:change_menu_item(-1) end } },
    { key = 'j', fn = menu:with_update { function() menu:change_menu_item(1) end } },
    { key = 'h', fn = menu:with_update { function() menu:change_selected_value(-0.1) end } },
    { key = 'l', fn = menu:with_update { function() menu:change_selected_value(0.1) end } },
    { key = 'shift+h', fn = menu:with_update { function() menu:change_selected_value(-0.5) end } },
    { key = 'shift+l', fn = menu:with_update { function() menu:change_selected_value(0.5) end } },
    -- arrows
    { key = 'up', fn = menu:with_update { function() menu:change_menu_item(-1) end } },
    { key = 'down', fn = menu:with_update { function() menu:change_menu_item(1) end } },
    { key = 'left', fn = menu:with_update { function() menu:change_selected_value(-0.1) end } },
    { key = 'right', fn = menu:with_update { function() menu:change_selected_value(0.1) end } },
    { key = 'shift+left', fn = menu:with_update { function() menu:change_selected_value(-0.5) end } },
    { key = 'shift+right', fn = menu:with_update { function() menu:change_selected_value(0.5) end } },
}

menu.keys = (function()
    local keys = {}
    for key in pairs(config) do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end)()

function menu:change_menu_item(step)
    self.selected = self.selected + step
    if self.selected < 1 then
        self.selected = #self.keys
    elseif self.selected > #self.keys then
        self.selected = 1
    end
end

function menu:change_selected_value(step)
    if type(config[self.keys[self.selected]]) == "boolean" then
        config[self.keys[self.selected]] = not config[self.keys[self.selected]]
    else
        config[self.keys[self.selected]] = config[self.keys[self.selected]] + step
        if config[self.keys[self.selected]] < 0 then
            config[self.keys[self.selected]] = 0
        end
    end
end

function menu:make_osd()
    local osd = OSD:new():size(config.menu_font_size):align(4)

    osd:submenu('Sub transition options ⇳'):newline()

    for i = 1, #self.keys do
        local key, value = self.keys[i], config[self.keys[i]]
        if self.selected == i then
            osd:tab():selected(_(key)):text('　<'):selected(value):text('>'):newline()
        else
            osd:tab():item(_(key)):text('　<'):text(value):text('>'):newline()
        end
    end

    osd:submenu('Bindings'):newline()

    osd:tab():item('t: '):text('toggle sub transition ['):blue(transitions.status()):text(']'):newline()
    osd:tab():item('s: '):text('save current options'):newline()
    osd:tab():item('ESC: '):text('close menu'):newline()

    return osd
end

local main = (function()
    local init_done = false
    local function fn()
        if not init_done then
            mpopt.read_options(config, NAME)
            mp.add_key_binding("shift+n", NAME .. '_menu_open', function() menu:open() end)
            if config.start_enabled then transitions.toggle() end
            init_done = true
        else
            reset_transition()
        end
    end
    return fn
end)()

--- Start

mp.register_event("file-loaded", main)
