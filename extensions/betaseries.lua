--[[
 Betaseries Extension for VLC media player 1.1
 French website only

 Copyright © 2010 AUTHORS

 Authors:  Gregoire Astruc <gregoire.astruc@anelis.isima.fr>

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
--]]

-- Lua modules
require "betaseries"
require "set"

local dlg       = nil   -- Account Dialog
local user      = nil   -- Text input widget
local pass      = nil   -- Password input widget
local message   = nil   -- Label
local configfilename = nil
local token     = nil   -- BetaSeries token.
local markers   = nil   -- Playlist item names to mark 'show' as watched.

local menus = { "Mon Compte..." }
local tag   = "[betaseries-extension]: " 

-- Extension description
function descriptor()
    return { title          = "Betaseries" ;
             version        = "2014.01" ;
             author         = "Gregoire Astruc" ;
             url            = 'http://www.betaseries.com/';
             shortdesc      = "Betaseries - Le site de vos series.";
             description    = "<center><strong>betaseries.com</strong></center>"
                        .. "<p>"
                        .. "Marque votre &eacutepisode comme <em>vu</em> lorsque celui-ci se termine."
                        .. "</p>" ;
             capabilities   = { "menu", "meta-listener", "input-listener" } }
end

--
-- VLC Interface at the end.
--


---------------------
-- Local functions --
---------------------

-- Parse the input, see if we can add the 'hook' on the playlist.
local function parse_input()
    vlc.msg.warn(tag .. "Parsing input.")
    if not token then
        vlc.msg.warn(tag .. "No Token set.")
        return
    end
    
    if not vlc.input.is_playing() then
        return
    end

    -- Little coffee break.
    vlc.misc.mwait(500 * 1000)
    local metas = vlc.input.item():metas()
    local showUrl = metas["betaseries/url"]
    if not showUrl then
        vlc.msg.warn(tag .. "No betaseries/url.")
        return
    end
    
    local season = metas["betaseries/season"]
    if not season then
        vlc.msg.warn(tag .. "No betaseries/season.")
        return
    end
    
    local episode = metas["betaseries/episode"]
    if not episode then
        vlc.msg.warn(tag .. "No betaseries/episode.")
        return
    end
    
    local title = metas["betaseries/title"]
    if not title then
        vlc.msg.warn(tag .. "No betaseries/title.")
        return
    end

    if markers:contains(title) then
        vlc.msg.warn(tag .. "Already in the playlist!")
        return
    end
    
    if showUrl and season and episode and title then
        vlc.msg.warn(tag .. "showUrl, season and episode found :)")
        local url = token:watchedurl(showUrl, season, episode)
        -- Add an item playlist to mark the show as read once seen :)
        local mark = {
                    path = url,
                    name = "[BetaSeries] " .. "- Watched " .. title
                }
        vlc.msg.dbg(tag .. mark.path)
        vlc.msg.warn(tag .. "search name: " .. table.concat(vlc.playlist.search(mark.name)))
        vlc.msg.warn(tag .. "search path: " .. table.concat(vlc.playlist.search(mark.path)))
        vlc.playlist.enqueue({mark})
        markers:insert(title)
    end
end
-- Display a message.
local function show_message(message_text)
    if not message then
        message = dlg:add_label(message_text, 2, 3, 1, 1)
    else
        message:set_text(message_text)
    end
    dlg:update()
end

local function save_config(username, password)
    -- Save login/password to VLC's user config directory.
    vlc.msg.dbg(tag .. "Config dir: " .. vlc.misc.configdir())
    
    configfile, errmsg = io.open(vlc.misc.configdir() .. "/.betaseries", "w")
    
    if not configfile then
        vlc.msg.warn(tag .. "Error opening .betaseries for writing: " .. errmsg)
        return
    end

    -- Password is saved in its md5 form, but it's not any safer :) 
    configfile:write(username .. "\n" .. password)
    configfile:close()
end

local function check_user(username, password)
    -- Destroy previous token (if any)
    if token then
        token:destroy()
        token = nil
    end

    token = betaseries.members.auth(username, password)

    return token ~= nil
end

-- Login the user.
local function click_login()
    -- Get username
    local username = user:get_text()
    local password = pass:get_text()
    if not username or username == "" then
        vlc.msg.dbg(tag .. "Missing username.")
        return
    end
    
    if not password or password == "" then
        vlc.msg.dbg(tag .. "Missing password.")
        return
    end

    -- Please wait...
    show_message("Identification sur Betaseries...")
    
    if check_user(username, vlc.md5(password)) then
        -- Username/password combination is correct: save them to a file.
        save_config(username, vlc.md5(password))
        show_message("Identification reussie.")
        dlg:hide()
        -- See if something is playing and parse it if we can.
        if vlc.input.is_playing() then
            parse_input()
        end
    else
        show_message("L'identification a echoue : mot de passe ou nom d'utilisateur incorrect.")
    end
end

-- Create the dialog
local function create_dialog()
    dlg = vlc.dialog("Mon Compte BetaSeries.com")
    dlg:add_label("<strong>Pseudo : </strong>", 1, 1, 1, 1)
    user = dlg:add_text_input("", 2, 1, 1, 1)
    dlg:add_label("<strong>Mot de passe : </strong>", 1, 2, 1, 1)
    pass = dlg:add_password("", 2, 2, 1, 1)
    dlg:add_button("Login", click_login, 1, 3, 1, 1)
end

local function show_settings(message_text)
    if not dlg then
        create_dialog()
    else
        dlg:show()
    end
    
    if message_text then
        show_message(message_text)
    end
end

-------------------------
-- _! VLC Interface !_ --
-------------------------

-- Activation hook
function activate()
    markers = set.new()
    vlc.msg.dbg(tag .. "starting up.")
    configfilename = vlc.misc.configdir() .. "/.betaseries"
    
    --[[ First, we look for an existing configfile.
            If it exists, we attempt to load it.
            Otherwise we immediately prompt the account dialog.
    --]]
    configfile = io.open(configfilename)
    if configfile then
        for line in configfile:lines() do
            -- Could probably do nicer, but I don't know lua :(
            if not user then
                user = line
            else
                pass = line
            end
        end
        
        configfile:close()
    end
    
    local msg = nil
    if user ~= nil and pass ~= nil then
        -- Config ok: Try to get a token.
        if check_user(user, pass) then
            -- Token OK ! Let's see is something is playing and we can get its info.
            if vlc.input.is_playing() then
                parse_input()
            end
            return
        else
            msg = 'Username and password mismatch.'
        end
    end
    -- No user or pass set, or token was nil: show the settings dialog.
    show_settings(msg)
end

function menu()
    return menus
end

function trigger_menu(id)
    if id == 1 then
        show_settings()
    end
end

-- Deactivation hook
function deactivate()
    vlc.msg.warn(tag .. "shutting down.")
    if dlg then
        dlg:delete()
    end
    
    if token then
        token:destroy()
    end
end

-- Input change hook
function input_changed()
    vlc.msg.dbg(tag .. "Input Changed !")
    parse_input()
end

-- Meta change hook
function meta_changed()
    vlc.msg.warn(tag .. "Meta Changed !")
    parse_input()
end
