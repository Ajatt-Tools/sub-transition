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
$ git clone 'https://github.com/Ajatt-Tools/sub_transition.git' ~/.config/mpv/scripts/sub_transition
```

## Menu

To open the menu, press `shift+n`.

![screenshot](https://user-images.githubusercontent.com/69171671/163695143-f5a4a5f3-98a6-4b13-8820-efb4d4f91304.png)

### Change settings

Use Vim keys to navigate the menu.

* `j` and `k` to move between entries.
* `h` and `l` to change the values by `0.1`.
* `shift+h` and `shift+l` to change the values by `0.5`.

You can also use arrow keys if your keyboard has them.

### Key bindings

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
