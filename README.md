# sub transition

This user script for [mpv](https://wiki.archlinux.org/title/Mpv)
is used to increase the density of immersion.
It speeds up the video when there's no subtitles.

For the script to work it is necessary to have an active subtitle track.
If there's no active subtitle track,
or the next subtitle line hasn't been demuxed yet,
the script does nothing.

## Installation

The installation process is no different from other mpv scripts.

Install in one line:

```
$ git clone 'https://github.com/Ajatt-Tools/sub-transition.git' ~/.config/mpv/scripts/sub_transition
```

Or manually download the folder and save it to `~/.config/mpv/scripts/`.
The location may differ depending on the operating system or if you use a custom fork of mpv.

## Menu

To open the menu, press `shift+n`.

![screenshot](https://user-images.githubusercontent.com/69171671/163695143-f5a4a5f3-98a6-4b13-8820-efb4d4f91304.png)

### Change settings

Use Vim keys to navigate the menu.

* `j` and `k` to move between entries.
* `h` and `l` to change the values by `0.1`.
* `shift+h` and `shift+l` to change the values by `0.5`.

You can also use arrow keys if your keyboard has them.

### Global key bindings

Add the following to your `input.conf` to enable or change global key bindings:

```
t script-binding sub_transition_toggle_fast_forward
r script-binding sub_transition_skip_immediately
N script-binding sub_transition_menu_open
```

* <kbd>t</kbd> toggles fast-forward transition on/off.
  If no subtitles are played,
  the player will speed up playback until the next subtitle starts.
* <kbd>r</kbd> toggles instant skip transitions.
  If no subtitles are played,
  the player will immediately skip until the beginning of the next subtitle.

Note that only one transition mode can be active at a time (either fast-forward or instant skip).

### Key bindings (with menu open)

* `Esc` or `q` closes the menu.
* `t` toggles transitions.
* `s` saves current configuration to `~/.config/mpv/script-opts/sub_transition.conf`.

### Settings

* `start enabled` - enable transitions when mpv starts
* `notifications` - notify when speed changes
* `start delay` - delay before speedup
* `reset before` - seconds to stop short of the next subtitle
* `min duration` - minimum duration of a transition
* `normal speed` - reset back to this speed when a new subtitle starts
* `inter speed`- speed during speedup
* `menu font size` - font size of the menu
* `pause on start` - pause when a subtitle starts
* `pause before end` - pause before a subtitle ends
* `hide_subs_when_playing` - hide subtitles when playback is active
