
--[[
                                                  
     Lain                                         
     Layouts, widgets and utilities for Awesome WM
                                                  
     Utilities section                            
                                                  
     Licensed under GNU General Public License v2 
      * (c) 2013,      Luke Bonham                
      * (c) 2010-2012, Peter Hofmann              
                                                  
--]]

local awful        = require("awful")
local beautiful    = require("beautiful")
local math         = { sqrt = math.sqrt }
local mouse        = mouse
local pairs        = pairs
local string       = string
local client       = client
local screen       = screen
local tonumber     = tonumber

local wrequire     = require("lain.helpers").wrequire
local setmetatable = setmetatable

-- Lain utilities submodule
-- lain.util
local util = { _NAME = "lain.util" }

-- Like awful.menu.clients, but only show clients of currently selected
-- tags.
function util.menu_clients_current_tags(menu, args)
    -- List of currently selected tags.
    local cls_tags = awful.tag.selectedlist(mouse.screen)

    -- Final list of menu items.
    local cls_t = {}

    if cls_tags == nil
    then
        return nil
    end

    -- For each selected tag get all clients of that tag and add them to
    -- the menu. A click on a menu item will raise that client.
    for i = 1,#cls_tags
    do
        local t = cls_tags[i]
        local cls = t:clients()

        for k, c in pairs(cls)
        do
            cls_t[#cls_t + 1] = { awful.util.escape(c.name) or "",
                                  function ()
                                      c.minimized = false
                                      client.focus = c
                                      c:raise()
                                  end,
                                  c.icon }
        end
    end

    -- No clients? Then quit.
    if #cls_t <= 0
    then
        return nil
    end

    -- menu may contain some predefined values, otherwise start with a
    -- fresh menu.
    if not menu
    then
        menu = {}
    end

    -- Set the list of items and show the menu.
    menu.items = cls_t
    local m = awful.menu.new(menu)
    m:show(args)
    return m
end

-- Magnify a client: Set it to "float" and resize it.
function util.magnify_client(c)
    awful.client.floating.set(c, true)

    local mg = screen[mouse.screen].geometry
    local tag = awful.tag.selected(mouse.screen)
    local mwfact = awful.tag.getmwfact(tag)
    local g = {}
    g.width = math.sqrt(mwfact) * mg.width
    g.height = math.sqrt(mwfact) * mg.height
    g.x = mg.x + (mg.width - g.width) / 2
    g.y = mg.y + (mg.height - g.height) / 2
    c:geometry(g)
end

-- Read the nice value of pid from /proc.
local function get_nice_value(pid)
    local n = first_line('/proc/' .. pid .. '/stat')
    if n == nil
    then
        -- This should not happen. But I don't want to crash, either.
        return 0
    end

    -- Remove pid and tcomm. This is necessary because tcomm may contain
    -- nasty stuff such as whitespace or additional parentheses...
    n = string.gsub(n, '.*%) ', '')

    -- Field number 17 now is the nice value.
    fields = split(n, ' ')
    return tonumber(fields[17])
end

-- To be used as a signal handler for "focus"
-- This requires beautiful.border_focus{,_highprio,_lowprio}.
function util.niceborder_focus(c)
    local n = get_nice_value(c.pid)
    if n == 0
    then
        c.border_color = beautiful.border_focus
    elseif n < 0
    then
        c.border_color = beautiful.border_focus_highprio
    else
        c.border_color = beautiful.border_focus_lowprio
    end
end

-- To be used as a signal handler for "unfocus"
-- This requires beautiful.border_normal{,_highprio,_lowprio}.
function util.niceborder_unfocus(c)
    local n = get_nice_value(c.pid)
    if n == 0
    then
        c.border_color = beautiful.border_normal
    elseif n < 0
    then
        c.border_color = beautiful.border_normal_highprio
    else
        c.border_color = beautiful.border_normal_lowprio
    end
end

-- Non-empty tag browsing
-- direction in {-1, 1} <-> {previous, next} non-empty tag
function util.tag_view_nonempty(direction, sc)
   local s = sc or mouse.screen or 1
   local scr = screen[s]

   for i = 1, #tags[s] do
       awful.tag.viewidx(direction,s)
       if #awful.client.visible(s) > 0 then
           return
       end
   end
end

-- Dynamically rename the current tag you have focused.
function util.prompt_rename_tag(mypromptbox)
    local tag = awful.tag.selected(mouse.screen)
    awful.prompt.run({prompt="Rename tag: "}, mypromptbox[mouse.screen].widget,
    function(text)
        if text:len() > 0 then
            tag.name = text
            tag:emit_signal("property::name")
        end
    end)
end

return setmetatable(util, { __index = wrequire })