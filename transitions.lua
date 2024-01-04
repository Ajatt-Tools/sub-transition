--[[
Copyright: Ren Tatsumoto
License: GNU GPL, version 3 or later; https://www.gnu.org/licenses/gpl-3.0.html
]]

-- Imports
local mp = require('mp')
local timer = require('timer')
local h = require('helpers')

-- Consts
local default_sync_property = mp.get_property("video-sync", "audio")
local revisit_delay = 0.15
local end_ahead = 0.05

-- Transitions
local self = {
    enabled = false,
}

local timers = {
    start_transition = timer.new(),
    end_transition = timer.new(),
    pause_on_end = timer.new(),
    sub_visitor = timer.new(),
}

local function start_transition()
    mp.set_property("speed", self.config.inter_speed)
    if mp.get_property_native("video-sync") == default_sync_property then
        mp.set_property("video-sync", "desync")
    end
    h.notify { message = string.format("x%.1f", self.config.inter_speed), osd = self.config.notifications, }
end

local function end_transition()
    mp.set_property("speed", self.config.normal_speed)
    if mp.get_property_native("video-sync") == "desync" then
        mp.set_property("video-sync", default_sync_property)
    end
    h.notify { message = string.format("x%.1f", self.config.normal_speed), osd = self.config.notifications, }
end

local function reset_transition()
    for _, t in pairs(timers) do
        t.cancel()
    end
    end_transition()
end

local function should_skip_dialogue(text)
    return h.is_empty(text) or (self.config.skip_non_dialogue and h.is_non_dialogue(text))
end

local function should_fast_forward()
    return h.is_empty(mp.get_property_native("sub-end")) or should_skip_dialogue(mp.get_property("sub-text"))
end

local function get_delay_to_next_sub()
    local initial_sub_visibility = mp.get_property_bool("sub-visibility")
    local initial_sub_delay = mp.get_property_native("sub-delay") or 0
    mp.set_property_bool("sub-visibility", false)
    mp.commandv("no-osd", "sub-step", 1)
    local next_sub_delay = mp.get_property_native("sub-delay") or 0
    local next_sub_text = mp.get_property("sub-text") or ""
    mp.set_property_number("sub-delay", initial_sub_delay)
    mp.set_property_bool("sub-visibility", initial_sub_visibility)
    if initial_sub_delay > next_sub_delay then
        return (initial_sub_delay - next_sub_delay), next_sub_text
    else
        return nil
    end
end

local function get_padded_sub_end()
    return mp.get_property_number("sub-end", 0) + mp.get_property_number("sub-delay", 0) - mp.get_property_number("audio-delay", 0) - end_ahead
end

local function pause_playback()
    mp.set_property("pause", "yes")
    h.notify { message = "Paused.", osd = self.config.notifications, }
end

local function skip_immediately(to_position)
    -- don't transition, just immediately skip to the next subtitle line.
    if not mp.get_property_bool("pause") then
        mp.commandv("seek", to_position, "absolute+exact")
    end
end

local function check_sub()
    if should_fast_forward() then
        local current_pos = mp.get_property_number("time-pos", 0)
        local delay_to_next_sub, next_sub_text = get_delay_to_next_sub()
        if delay_to_next_sub then
            local speedup_start = current_pos + self.config.start_delay
            local speedup_end = current_pos + delay_to_next_sub - self.config.reset_before
            if speedup_end - speedup_start >= self.config.min_duration then
                if self.config.skip_immediately then
                    timers.start_transition.set(speedup_start, function() skip_immediately(speedup_end) end)
                else
                    timers.start_transition.set(speedup_start, start_transition)
                    if not should_skip_dialogue(next_sub_text) then
                        timers.end_transition.set(speedup_end, end_transition)
                    end
                end
            end
        elseif mp.get_property("sid") ~= "no" then
            timers.sub_visitor.set(current_pos + revisit_delay, check_sub)
        end
    else
        reset_transition()
        local sub_end = get_padded_sub_end()
        if self.config.pause_before_end and sub_end > 0 then
            timers.pause_on_end.set(sub_end, pause_playback)
        end
        if self.config.pause_on_start and mp.get_property("pause") ~= "yes" then
            pause_playback()
            mp.commandv("frame-step")
        end
    end
end

local function toggle_enabled(val)
    self.enabled = val or not self.enabled
    if self.enabled then
        mp.observe_property("sub-end", "number", check_sub)
        mp.observe_property("sub-text", "string", check_sub)
        h.notify { message = "Transitions enabled.", osd = self.config.notifications, }
    else
        mp.unobserve_property(check_sub)
        reset_transition()
        h.notify { message = "Transitions disabled.", osd = self.config.notifications, }
    end
end

local function toggle_fast_forward()
    if not (self.enabled and self.config.skip_immediately) then
        toggle_enabled()
    end
    self.config.skip_immediately = false
end

local function status()
    return self.enabled and 'enabled' or 'disabled'
end

local function toggle_skip_immediately()
    self.config.skip_immediately = not self.config.skip_immediately
    toggle_enabled(self.config.skip_immediately)
    h.notify {
        message = string.format("Transition skip %s.", (self.config.skip_immediately and "enabled" or "disabled")),
        osd = self.config.skip_immediately,
    }
end

local function init(config)
    self.config = config
end

return {
    init = init,
    toggle_enabled = toggle_enabled,
    toggle_fast_forward = toggle_fast_forward,
    toggle_skip_immediately = toggle_skip_immediately,
    status = status,
    reset = reset_transition,
    check_sub = check_sub,
}
