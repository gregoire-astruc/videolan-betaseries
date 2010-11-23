--[[
 betaseries API.

 $Id$
 Copyright © 2010 Gregoire Astruc <gregoire.astruc@anelis.isima.fr>

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
module("betaseries",package.seeall)

-- Interface
shows = {}
members = {}

local key = "81452e2dc55d" -- Please don't steal ;-)
local api_key = ".xml?key="..key.."&"

local tag = "[betaseries-module]: "

-- API URLs.
local api = {
            base    = "http://api.betaseries.com/",
            -- Sections
            shows = {
                search = "shows/search"..api_key
            },
            members = {
                auth = "members/auth"..api_key,
                destroy = "members/destroy"..api_key,
                watched = "members/watched/"
            }
        }           

-- Helper function: loads and fetch the given url.
local function load(url)
    local fd, errmsg = vlc.stream(api.base .. url)
    if not fd then return nil, errmsg end
    local page = fd:read(65653)
    fd = nil

    return page
end

-- Shows section.
-- Search a show.
local function sortby_title(showa, showb)
    return showa.title < showb.title
end

function shows.search(title)
    local page, errmsg = load(api.shows.search .."title="..title)
    if not page then return nil, errmsg end
    
    local showsTable = {}
    
    for showUrl, showTitle  in page:gmatch("<url>(.-)</url>.*<title>(.-)</title>") do
        -- shows[showUrl] = showTitle
        table.insert(showsTable, {url = showUrl, title = showTitle})
    end

    if #showsTable == 0 then
        vlc.msg.warn(page)
        return nil, "Unable to find poper <url> tag."
    end
    
    table.sort(showsTable, sortby_title)

    return showsTable
end


-- Show information.
function shows.display(url)
    return nil
end

-- Members section.
-- Authentification.
-- Given a username and password (must be md5), attempts to login
-- returns:
-- - token                          - on success
-- - nil, error message, error code - on failure.
function members.auth(username, password)
    -- Build URL
    -- local url = base .. "members/auth.xml?key=" .. key .. "&login=" .. username .. "&password=" .. password
    local url = api.members.auth .. "login=" .. username .. "&password=" .. password

    -- Open/Fetch URL.
    local data, msg = load(url)
    if not data then
        vlc.msg.warn(tag .. "" .. msg)
        return nil, msg, -1
    end
    
    -- Find user token.
    _, _, token = data:find("<token>(.-)</token>")
    if not token then
        _, _, errorcode, errormsg = data:find("<error code=\"(%d-)\">(.+)</error>")
        if not errormsg then
            vlc.msg.warn(tag .. "Unexpected error at logging.")
            return nil, "Unexpected error", -2
        end
        
        vlc.msg.warn(tag .. "error: " .. errormsg .. "(" .. errorcode .. ")")
        return nil, errormsg, errorcode
    end
    
    -- Token generated: username/password combo is correct.
    
    local self = members
    self.token = token
    return self
end

-- Destroy member token.
function members:destroyurl()
    return api.members.destroy .. "token=" .. self.token
end

function members:destroy()
    local page, errmsg = load(self:destroyurl())
    if not page then
        return false, errmsg
    else
        vlc.msg.dbg(tag .. "members.destroy: " .. page)
        return true
    end
end

-- Mark an episode as watched.
function members:watchedurl(showUrl, season, episode, note)
    local url = api.base .. api.members.watched ..showUrl..api_key.."token="..self.token
            url = url.."&season="..season.."&episode="..episode
    if note ~= nil then
        url = url.."&e="..note
    end
    return url
end

function members:watched(showUrl, season, episode, note)
    local url = api.members.watched ..showUrl..api_key.."token="..self.token.."&season="..season.."&episode="..episode
    local page, errmsg = load(url)
    if not page then
        return false, errmsg
    else
        vlc.msg.dbg(tag .. "members.watched: " .. page)
        return true
    end 
end
