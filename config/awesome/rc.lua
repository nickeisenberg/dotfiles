-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- there is an issue with the version on lua being used
-- local awesome = require("awesome")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")

-- Widget and layout library
local wibox = require("wibox")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
  naughty.notify({
    preset = naughty.config.presets.critical,
    title = "Oops, there were errors during startup!",
    text = awesome.startup_errors,
  })
end

-- Handle runtime errors after startup
do
  local in_error = false
  awesome.connect_signal("debug::error", function(err)
    -- Make sure we don't go into an endless error loop
    if in_error then
      return
    end
    in_error = true

    naughty.notify({
      preset = naughty.config.presets.critical,
      title = "Oops, an error happened!",
      text = tostring(err),
    })
    in_error = false
  end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

--------------------------------------------------
-- work in progress
-- beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/rosepine/theme.lua")
--------------------------------------------------

-- This is used later as the default terminal and editor to run.
terminal = "alacritty"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
  awful.layout.suit.tile,
  awful.layout.suit.fair,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
  {
    "hotkeys",
    function()
      hotkeys_popup.show_help(nil, awful.screen.focused())
    end,
  },
  { "manual", terminal .. " -e man awesome" },
  { "edit config", editor_cmd .. " " .. awesome.conffile },
  { "restart", awesome.restart },
  {
    "quit",
    function()
      awesome.quit()
    end,
  },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

if has_fdo then
  mymainmenu = freedesktop.menu.build({
    before = { menu_awesome },
    after = { menu_terminal },
  })
else
  mymainmenu = awful.menu({
    items = {
      menu_awesome,
      { "Debian", debian.menu.Debian_menu.Debian },
      menu_terminal,
    },
  })
end

mylauncher = awful.widget.launcher(
  { image = beautiful.awesome_icon, menu = mymainmenu }
)

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
  awful.button({}, 1, function(t) t:view_only() end),

  awful.button(
    { modkey }, 1,
    function(t)
      if client.focus then
        client.focus:move_to_tag(t)
      end
    end
  ),

  awful.button({}, 3, awful.tag.viewtoggle),

  awful.button(
    { modkey }, 3,
    function(t)
      if client.focus then
        client.focus:toggle_tag(t)
      end
    end
  ),

  awful.button(
    {}, 4, function(t) awful.tag.viewnext(t.screen) end
  ),

  awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
  awful.button(
    {}, 1,
    function(c)
      if c == client.focus then
        c.minimized = true
      else
        c:emit_signal("request::activate", "tasklist", { raise = true })
      end
    end
  ),

  awful.button(
    {}, 3,
    function()
    awful.menu.client_list({ theme = { width = 250 } })
    end
  ),

  awful.button(
    {}, 4,
    function()
      awful.client.focus.byidx(1)
    end
  ),

  awful.button(
    {}, 5,
    function()
      awful.client.focus.byidx(-1)
    end
  )
)

local function set_wallpaper(s)
  -- Wallpaper
  if beautiful.wallpaper then
    local wallpaper = beautiful.wallpaper
    -- If wallpaper is a function, call it with the screen
    if type(wallpaper) == "function" then
      wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)
  end
end

--------------------------------------------------
-- My custom battery widget
local battery_widget = wibox.widget.textbox()
battery_widget:set_align("right")


--------------------------------------------------
-- Battery widget
awful.widget.watch("acpi -b", 30,
  function(widget, stdout)

    local battery_status, battery_percent = stdout:match(
      "Battery %d+: ([%a%s]+), (%d+)%%"
    )
    local status_char = "?" -- Default to unknown

    -- Determine the status character based on the battery_status
    if battery_status then
      if battery_status:find("Charging") then
        status_char = "C"
      elseif battery_status:find("Discharging") then
        status_char = "DC"
      elseif battery_status:find("Not charging") then
        status_char = "NC"
      elseif battery_status:find("Full") then
        status_char = "F"
      end
    end

    -- Set the widget text with the formatted string
    widget:set_text(
      string.format("Bat: %s %%%s", status_char, battery_percent)
    )
  end,
  battery_widget
)
--------------------------------------------------

--------------------------------------------------
-- Create the VRAM usage widget
local vram_usage_widget = wibox.widget {
    widget = wibox.widget.textbox,
    align  = "center"
}

-- Function to update the VRAM usage widget
local function update_vram_usage()
    awful.spawn.easy_async_with_shell("nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits", function(stdout)
        local vram_used = stdout:gsub("\n", "") -- Remove newline character
        vram_usage_widget:set_text("vRAM: " .. vram_used .. " MiB")
    end)
end

-- Set up a timer to periodically update the widget
local vram_usage_timer = gears.timer({
    timeout   = 10, -- Update interval in seconds
    autostart = true,
    call_now  = true, -- Update the widget as soon as the timer starts
    callback  = update_vram_usage
})
--------------------------------------------------

--------------------------------------------------
-- Create the RAM usage widget
local ram_usage_widget = wibox.widget {
    widget = wibox.widget.textbox,
    align  = "center"
}

local function update_ram_usage()
    awful.spawn.easy_async_with_shell(
    "free | awk '/^Mem:/ {print int($3 / 1024) \" MiB\"}'",
    function(stdout)
        local ram_used = stdout:gsub("\n", "")
        ram_usage_widget:set_text("RAM: " .. ram_used)
    end)
end

-- Set up a timer to periodically update the widget
local ram_usage_timer = gears.timer({
    timeout   = 10, -- Update interval in seconds
    autostart = true,
    call_now  = true, -- Update the widget as soon as the timer starts
    callback  = update_ram_usage
})
--------------------------------------------------

--------------------------------------------------
-- Volume Widget
--------------------------------------------------
local volume_widget = wibox.widget {
    widget = wibox.widget.textbox,
    align  = 'center',
    valign = 'center',
    text   = 'Vol: --%'
}

local function update_volume(widget)
  -- Using pactl to get volume level and mute status
  local cmd = "pactl list sinks | awk '/Mute:/{m = $2} /Volume: "
  cmd = cmd .. "front-left:/{v = $5} END{print m \" \" v}'"
  awful.spawn.easy_async_with_shell(
    cmd,
    function(stdout)
      local mute, volume = stdout:match("(%S+)%s(%d?%d?%d)%%") -- Matches the mute status and volume level
      if mute == "yes" then
        widget.text = "Vol: Muted"
      else
        widget.text = "Vol: " .. volume .. "%"
      end
    end
  )
end

-- Update volume on AwesomeWM startup
update_volume(volume_widget)
--------------------------------------------------

local sep = wibox.widget.textbox()
sep:set_markup('<span font="12"> - </span>')

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(
  function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag(
      { "1", "2", "3", "4", "5", "6", "7", "8", "9" },
      s,
      awful.layout.layouts[1]
    )
  
    -- adds padding to the windows
    local tags = s.tags
    for i, tag in pairs(tags) do
        tag.gap = 2
    end

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(
      gears.table.join(
        awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)
      )
    )

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist({
      screen = s,
      filter = awful.widget.taglist.filter.all,
      buttons = taglist_buttons,
    })

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist({
      screen = s,
      filter = awful.widget.tasklist.filter.currenttags,
      buttons = tasklist_buttons,
    })

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup({
      layout = wibox.layout.stack,
      expand = "none",
      {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
          layout = wibox.layout.fixed.horizontal,
          mylauncher,
          wibox.widget.textbox(" "),
          mytextclock,
          --s.mytaglist,
          --s.mylayoutbox,
          s.mypromptbox,
        },
        nil,
        { -- Right widgets
          layout = wibox.layout.fixed.horizontal,
          ram_usage_widget, sep,
          vram_usage_widget, sep,
          volume_widget, sep,
          battery_widget,
          wibox.widget.textbox(" "),
        },
      },
      {
        {
          layout = wibox.layout.fixed.horizontal,
          s.mytaglist,
          s.mylayoutbox,
        },
        layout = wibox.container.place,
        valign = "center",
        halign = "center",
      },
    })
  end
)
-- }}}

-- {{{ Mouse bindings
root.buttons(
  gears.table.join(
    awful.button({}, 3, function() mymainmenu:toggle() end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
  )
)
-- }}}


local function toggle_floating_terminal(title)
  -- Find the terminal by title
  local terminal = nil
  for _, c in ipairs(client.get()) do
    if c.name == title then
      terminal = c
      break
    end
  end

  -- Toggle or spawn the terminal
  if terminal then
    terminal.hidden = not terminal.hidden
    if not terminal.hidden then
      client.focus = terminal
      terminal:raise()
      awful.placement.centered(terminal)
    end
  else
    awful.spawn(
      "alacritty --title '" .. title .. "'",
      {}  -- see the "floating_terminal" rules above
    )
  end
end


-- {{{ Key bindings
globalkeys = gears.table.join(
  awful.key(
    { modkey }, "s", hotkeys_popup.show_help,
    { description = "show help", group = "awesome" }
  ),

  awful.key(
    { }, "F10",
    function () toggle_floating_terminal("floating_terminal_f10") end,
    {description = "Toggle floating term 1", group = "fnKeys"}
  ),

  awful.key(
    { }, "F11",
    function () toggle_floating_terminal("floating_terminal_f11") end,
    {description = "Toggle floating term 2", group = "fnKeys"}
  ),

  awful.key(
    { }, "F12",
    function () toggle_floating_terminal("floating_terminal_f12") end,
    {description = "Toggle floating term 3", group = "fnKeys"}
  ),

  awful.key(
    { modkey }, "b", function () awful.spawn("google-chrome") end,
    {description = "open Google Chrome", group = "launcher"}
  ),

  awful.key(
    { modkey }, "h",
    function ()
      awful.spawn("google-chrome --new-window https://chat.openai.com")
    end,
    { description = "open ChatGPT on Google Chrome", group = "launcher" }
  ),

  -- Increase brightness
  awful.key(
    {}, "XF86MonBrightnessUp",
    function ()
      awful.spawn("light -A 10", false)
    end, 
    {description = "+10% brightness", group = "fnKeys"}
  ),
  
  -- Decrease brightness
  awful.key(
    {}, "XF86MonBrightnessDown",
    function ()
      awful.spawn("light -U 10", false)
    end,
    {description = "-10% brightness", group = "fnKeys"}
  ),

  awful.key(
    { }, "XF86AudioMute",
    function ()
      awful.spawn(
        "pactl set-sink-mute @DEFAULT_SINK@ toggle",
        false
      )
      gears.timer.start_new(
        0.05,
        function()
          update_volume(volume_widget)
          return false -- Return false so the timer does not restart
        end
      )
    end,
    { description = "Toggle Mute", group = "fnKeys" }
  ),

  awful.key(
  { }, "XF86AudioRaiseVolume",
  function ()
    awful.spawn.easy_async_with_shell(
      "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+%' | " ..
      "tr -d '%' | head -n 1",
      function(stdout)
        local current_volume = tonumber(stdout)
        if current_volume < 100 then -- Check if current volume is less than the cap
          awful.spawn.with_shell("pactl set-sink-volume @DEFAULT_SINK@ +2%")
          awful.spawn.easy_async_with_shell(
            "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+%' | " ..
            "tr -d '%' | head -n 1",
            function(stdout)
              local new_volume = tonumber(stdout)
              if new_volume > 100 then
                awful.spawn.with_shell("pactl set-sink-volume @DEFAULT_SINK@ 100%")
              end
            end
          )
        end
        gears.timer.start_new(
          0.05,
          function()
            update_volume(volume_widget)
            return false -- Return false so the timer does not restart
          end
        )
      end
    )
  end,
  {description = "Raise Volume 2%", group = "fnKeys"}
  ),
  awful.key(
    { }, "XF86AudioLowerVolume",
    function ()
      awful.spawn.with_shell(
        -- "amixer -D pulse sset Master 5%-"
        "pactl set-sink-volume @DEFAULT_SINK@ -2%"

      )
      gears.timer.start_new(
        0.05,
        function()
          update_volume(volume_widget)
          return false -- Return false so the timer does not restart
        end
      )
    end,
    { description = "Lower Volume 2%", group = "fnKeys" }
  ),

  awful.key(
    { modkey }, "Right", awful.tag.viewnext, 
    { description = "view next", group = "tag" }
  ),

  awful.key(
    { modkey }, "Escape", awful.tag.history.restore, 
    { description = "go back", group = "tag" }
  ),

  awful.key(
    { "Control" }, "h",
    function ()
      awful.client.focus.bydirection("left")
      if client.focus then client.focus:raise() end
    end, 
    {description = "focus left", group = "client"}
  ),
  
  awful.key(
    { "Control" }, "l",
    function ()
      awful.client.focus.bydirection("right")
      if client.focus then client.focus:raise() end
    end, 
    {description = "focus right", group = "client"}
  ),
  
  awful.key(
    { "Control" }, "j",
    function ()
      awful.client.focus.bydirection("down")
    if client.focus then client.focus:raise() end
    end, 
    {description = "focus down", group = "client"}
  ),
  
  awful.key(
    { "Control" }, "k",
    function ()
      awful.client.focus.bydirection("up")
      if client.focus then client.focus:raise() end
    end, 
  {description = "focus up", group = "client"}
  ),

  awful.key(
    { modkey, "Control" }, "h",
    function () awful.client.swap.bydirection("left") end,
    {description = "swap with left client", group = "client"}
  ),

  awful.key(
    { modkey, "Control" }, "j",
    function () awful.client.swap.bydirection("down") end,
    {description = "swap with down client", group = "client"}
  ),

  awful.key(
    { modkey, "Control" }, "k",
    function () awful.client.swap.bydirection("up") end,
    {description = "swap with up client", group = "client"}
  ),

  awful.key(
    { modkey, "Control" }, "l",
    function () awful.client.swap.bydirection("right") end,
    {description = "swap with right client", group = "client"}
  ),

  awful.key(
    { modkey }, "Return", 
    function() awful.spawn(terminal) end,
    { description = "open a terminal", group = "launcher" }
  ),

  awful.key(
    { modkey, "Control" }, "r",
    awesome.restart,
    { description = "reload awesome", group = "awesome" }
  ),

  awful.key(
    { modkey, "Shift" }, "q", 
    awesome.quit,
    { description = "quit awesome", group = "awesome" }
  ),

  awful.key(
    { modkey }, 
    "Tab", 
    function() awful.layout.inc(1) end,
    { description = "select next", group = "layout" }
  ),

  -- Prompt
  awful.key(
    { modkey }, "r",
    function() awful.screen.focused().mypromptbox:run() end,
    { description = "run prompt", group = "launcher" }
  ),

  awful.key(
    { modkey }, "x", 
    function()
      awful.prompt.run({
        prompt = "Run Lua code: ",
        textbox = awful.screen.focused().mypromptbox.widget,
        exe_callback = awful.util.eval,
        history_path = awful.util.get_cache_dir() .. "/history_eval",
      })
    end,
    { description = "lua execute prompt", group = "awesome" })
)

clientkeys = gears.table.join(
  awful.key(
    { modkey }, "f",
    function(c)
      c.fullscreen = not c.fullscreen
      c:raise()
    end,
    { description = "toggle fullscreen", group = "client" }
  ),

  awful.key({modkey, "Shift"}, "h",
  	function(c)
  		if c.floating then
  			c:relative_move(0, 0, -20, 0)
  		else
  			awful.tag.incmwfact(-0.025)
  		end
  	end, {description = "Floating Resize Horizontal -", group = "client"}),

  awful.key({modkey, "Shift"}, "j",
  	function(c)
  		if c.floating then
  			c:relative_move(0, 0, 0, -20)
  		else
  			awful.client.incwfact(0.025)
  		end
  	end, {description = "Floating Resize Vertical -", group = "client"}),
  
  awful.key({modkey, "Shift"}, "k",
  	function(c)
  		if c.floating then
  			c:relative_move(0, 0, 0, 20)
  		else
  			awful.client.incwfact(-0.025)
  		end
  	end, {description = "Floating Resize Vertical +", group = "client"}),

  awful.key({modkey, "Shift"}, "l",
  	function(c)
  		if c.floating then
  			c:relative_move(0, 0, 20, 0)
  		else
  			awful.tag.incmwfact(0.025)
  		end
  	end, {description = "Floating Resize Horizontal +", group = "client"}),

  awful.key(
    { modkey}, "q",
    function(c) c:kill() end,
    { description = "close", group = "client" }
  ),

  awful.key(
    { modkey, "Control" },
    "space",
    awful.client.floating.toggle,
    { description = "toggle floating", group = "client" }
  ),

  awful.key(
    { modkey, "Control" }, "Return",
    function(c) c:swap(awful.client.getmaster()) end,
    { description = "move to master", group = "client" }
  ),

  awful.key(
    { modkey }, "o", function(c) c:move_to_screen() end, 
    { description = "move to screen", group = "client" }
  ),

  awful.key(
    { modkey }, "n",
    function(c)
    -- The client currently has the input focus, so it cannot be
    -- minimized, since minimized clients can't have the focus.
    c.minimized = true
    end,
    { description = "minimize", group = "client" }
  ),

  awful.key(
    { modkey }, "m",
    function(c)
      c.maximized = not c.maximized
      c:raise()
    end,
    { description = "(un)maximize", group = "client" }
  ),

  awful.key(
    { modkey, "Control" }, "m", 
    function(c)
      c.maximized_vertical = not c.maximized_vertical
      c:raise()
    end, 
    { description = "(un)maximize vertically", group = "client" }
  ),
  
  awful.key(
    { modkey, "Shift" }, "m",
    function(c)
      c.maximized_horizontal = not c.maximized_horizontal
      c:raise()
    end, 
    { description = "(un)maximize horizontally", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
  globalkeys = gears.table.join(
    globalkeys,

    -- View tag only.
    awful.key(
      { modkey }, "#" .. i + 9,
      function()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
          tag:view_only()
        end
      end, 
      { description = "view tag #" .. i, group = "tag" }
    ),

    -- Toggle tag display.
    awful.key(
      { modkey, "Shift" }, "#" .. i + 9,
      function()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
          awful.tag.viewtoggle(tag)
        end
      end,
      { description = "toggle tag #" .. i, group = "tag" }
    ),

    -- Move client to tag.
    awful.key(
      { modkey, "Control" }, "#" .. i + 9,
      function()
        if client.focus then
          local tag = client.focus.screen.tags[i]
          if tag then
            client.focus:move_to_tag(tag)
            tag:view_only()
          end
        end
      end,
      {
        description = "move focused client to tag #" .. i,
        group = "tag"
      }
    ),

    -- Toggle tag on focused client.
    awful.key(
      { modkey, "Control", "Shift" }, "#" .. i + 9,
      function()
        if client.focus then
          local tag = client.focus.screen.tags[i]
          if tag then
            client.focus:toggle_tag(tag)
          end
        end
      end,
      {
        description = "toggle focused client on tag #" .. i,
        group = "tag"
      }
    ),

    awful.key(
      { modkey, "Control" }, "b",
      function()
        awful.spawn.with_shell(
          "~/.config/rofi/scripts/launcher_t2"
        )
      end,
      { description = " Rofi " }
    ),

    awful.key(
      { modkey, "Control" }, "q",
      function()
        awful.spawn.with_shell(
          "~/.config/rofi/scripts/powermenu_t1"
        )
      end,
      { description = " Rofi Powermenu" }
    )
  )
end

clientbuttons = gears.table.join(
  awful.button(
    {}, 1, 
    function(c)
      c:emit_signal(
        "request::activate", "mouse_click", { raise = true }
      )
    end
  ),

  awful.button(
    { modkey }, 3,
    function(c)
      c:emit_signal(
        "request::activate", "mouse_click", { raise = true }
      )
      awful.mouse.client.move(c)
    end
  ),

  awful.button(
    { modkey }, 1,
    function(c)
      c:emit_signal(
        "request::activate", "mouse_click", { raise = true }
      )
      awful.mouse.client.resize(c)
    end
  )
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
  -- All clients will match this rule.
  {
    rule = {},
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = clientkeys,
      buttons = clientbuttons,
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap + awful.placement.no_offscreen,
    },
  },

  -- Add this inside your awful.rules.rules table
  {
    rule = { name = "floating_terminal" },
    properties = {
      floating = true,
      placement = awful.placement.centered,
      width=1100,
      height=800
    },
  },

  -- Floating clients.
  {
    rule_any = {
      instance = {
        "DTA", -- Firefox addon DownThemAll.
        "copyq", -- Includes session name in class.
        "pinentry",
      },
      class = {
        "Arandr",
        "Blueman-manager",
        "Gpick",
        "Kruler",
        "MessageWin", -- kalarm.
        "Sxiv",
        "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
        "Wpa_gui",
        "veromix",
        "xtightvncviewer",
      },

      -- Note that the name property shown in xprop might be set slightly after creation of the client
      -- and the name shown there might not match defined rules here.
      name = {
        "Event Tester", -- xev.
      },
      role = {
        "AlarmWindow", -- Thunderbird's calendar.
        "ConfigManager", -- Thunderbird's about:config.
        "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
      },
    },
    properties = { floating = true },
  },

  -- Add titlebars to normal clients and dialogs
  {
    rule_any =
      {
        type = { "normal", "dialog" }
      },
    properties = { titlebars_enabled = true }
  },

  -- Set Firefox to always map on the tag named "2" on screen 1.
  -- { rule = { class = "Firefox" },
  --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal(
  "manage", 
  function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
      -- Prevent clients from being unreachable after screen count changes.
      awful.placement.no_offscreen(c)
    end
  end
)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
  -- buttons for the titlebar
  local buttons = gears.table.join(
    awful.button(
      {}, 1,
      function()
        c:emit_signal(
          "request::activate", "titlebar", { raise = true }
        )
        awful.mouse.client.move(c)
      end
    ),

    awful.button(
      {}, 3, 
      function()
        c:emit_signal(
          "request::activate", "titlebar", { raise = true }
        )
        awful.mouse.client.resize(c)
      end
    )
  )

  awful.titlebar(c):setup({
    { -- Left
      awful.titlebar.widget.iconwidget(c),
      buttons = buttons,
      layout = wibox.layout.fixed.horizontal,
    },
    { -- Middle
      { -- Title
        align = "center",
        widget = awful.titlebar.widget.titlewidget(c),
      },
      buttons = buttons,
      layout = wibox.layout.flex.horizontal,
    },
    { -- Right
      awful.titlebar.widget.floatingbutton(c),
      awful.titlebar.widget.maximizedbutton(c),
      awful.titlebar.widget.stickybutton(c),
      awful.titlebar.widget.ontopbutton(c),
      awful.titlebar.widget.closebutton(c),
      layout = wibox.layout.fixed.horizontal(),
    },
    layout = wibox.layout.align.horizontal,
  })
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal(
  "mouse::enter",
  function(c)
    c:emit_signal(
      "request::activate", "mouse_enter", { raise = false }
    )
  end
)

client.connect_signal(
  "focus",
  function(c)
    c.border_color = beautiful.border_focus
  end
)

client.connect_signal(
  "unfocus",
  function(c)
    c.border_color = beautiful.border_normal
  end
)
-- }}}

-- wallpaper
awful.spawn.with_shell(
  "feh --bg-scale ~/dots_ubuntu/config/awesome/wallpaper/rosepine.png"
)

-- caps to ctrl
awful.spawn.with_shell("setxkbmap -option caps:ctrl_modifier")
