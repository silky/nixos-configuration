local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

config.font = wezterm.font 'iMWritingMono Nerd Font'
config.font_size = 12
config.color_scheme = 'Belafonte Day'

config.mouse_bindings = {
  -- Scrolling up while holding CTRL increases the font size
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = 'CTRL',
    action = act.IncreaseFontSize,
  },

  -- Scrolling down while holding CTRL decreases the font size
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = 'CTRL',
    action = act.DecreaseFontSize,
  },
}

return config
