--[[
Copyright: Ren Tatsumoto
License: GNU GPL, version 3 or later; https://www.gnu.org/licenses/gpl-3.0.html
]]

-- Includes
local NAME = 'sub_transition'
local mpopt = require('mp.options')
local mp = require('mp')
local utils = require('mp.utils')
local com = require('helpers')
local OSD = require('osd_styler')
local Menu = require('menu')
local transitions = require('transitions')
local hide_subs = require('hide_subs')

-- Consts
local default_readahead_secs = mp.get_property_number("demuxer-readahead-secs", 0)
local recommended_readahead_secs = 120

local config = {
    start_enabled = false, -- enable transitions when mpv starts without having to enable them in the menu
    notifications = true, -- enable notifications when speed changes
    pause_on_start = false, -- pause when a subtitle starts
    pause_before_end = false, -- pause before a subtitle ends
    hide_subs_when_playing = false, -- hide subtitles when playback is active
    start_delay = 0.1, -- if the next subtitle appears after this threshold then speedup
    reset_before = 0.6, --seconds to stop short of the next subtitle
    min_duration = 0.4, -- minimum duration of a skip
    normal_speed = 1, -- reset back to this speed
    inter_speed = 2.5, -- the value that "speed" is set to during speedup
    menu_font_size = 24, -- font size
    skip_non_dialogue = true, -- skip lines that are enclosed in parentheses
    skip_immediately = false, -- skip non-dialogue lines without transitioning
}

local function _(text)
    return text:gsub('_', ' ')
end

local function lua_to_mpv(config_value)
    if type(config_value) == 'boolean' then
        return config_value and 'yes' or 'no'
    else
        return config_value
    end
end

local function save_config()
    local mpv_dir_path = string.gsub(mp.get_script_directory(), [[scripts[\/][^\/]+$]], "")
    local config_filepath = utils.join_path(mpv_dir_path, string.format('script-opts/%s.conf', NAME))
    local handle = io.open(config_filepath, 'w')
    if handle ~= nil then
        handle:write(string.format("# Written by %s on %s.\n", NAME, os.date()))
        for key, value in pairs(config) do
            handle:write(string.format('%s=%s\n', key, lua_to_mpv(value)))
        end
        handle:close()
        com.notify { message = "Saved.", duration = 3, osd = true, }
    else
        com.notify { message = string.format("Couldn't open %s.", config_filepath), level = "error", duration = 5, osd = true, }
    end
end

local menu = Menu:new { selected = 1 }

menu.keybindings = {
    -- bindings
    { key = 't', fn = menu:with_update { transitions.toggle_enabled } },
    { key = 's', fn = save_config },
    { key = 'ESC', fn = function() menu:close() end },
    { key = 'q', fn = function() menu:close() end },
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

            -- Global key bindings
            mp.add_key_binding(nil, string.format("%s_toggle_fast_forward", NAME), function() transitions:toggle_fast_forward() end)
            mp.add_key_binding(nil, string.format("%s_skip_immediately", NAME), function() transitions:toggle_skip_immediately() end)
            mp.add_key_binding("shift+n", string.format("%s_menu_open", NAME), function() menu:open() end)

            transitions.init(config)
            hide_subs.init(config)
            if config.start_enabled then
                transitions.toggle_enabled()
            end
            if default_readahead_secs < recommended_readahead_secs then
                mp.set_property("demuxer-readahead-secs", recommended_readahead_secs)
            end
            init_done = true
        else
            transitions.reset()
            transitions.check_sub()
        end
    end
    return fn
end)()

--- Start

mp.register_event("file-loaded", main)
