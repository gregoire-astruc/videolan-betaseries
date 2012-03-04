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

require "modules.simplexml"

-- Interface
shows = {}
members = {}

local key = "5b8a94c91877" -- Please don't steal ;-)
local api_key = ".xml?key="..key.."&"

local tag = "[betaseries-module]: "

-- API URLs.
local api = {
            base    = "http://api.betaseries.com/",
            -- Sections
            shows = {
                search      = "shows/search"..api_key,
                display     = "shows/display/",
                episodes    = "shows/episodes/"
            },
            members = {
                auth    = "members/auth"..api_key,
                destroy = "members/destroy"..api_key,
                watched = "members/watched/",
                signup  = "members/signup"..api_key
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

local function trim(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function shows.search(title)
    vlc.msg.warn(tag.."Searching '"..title.."'")
    local page, errmsg = load(api.shows.search .."title="..title)
    if not page then return nil, errmsg end
    
    local showsTable = {}
    
    for showUrl, showTitle in page:gmatch("<url>(.-)</url>.-<title>(.-)</title>") do
        table.insert(showsTable, {shows, url = showUrl, title = trim(showTitle)})
    end
    
    vlc.msg.warn(tag..#showsTable.." results for '"..title.."'")

    if  #showsTable == 0 then
        vlc.msg.warn(page)
        return nil, "No results for '" .. title .. "'."
    end

    return showsTable
end



local function get_tag_value(page, tagname)
    return page:find('<' .. tagname .. '>(.-)</' .. tagname .. '>')
end

-- Show information.
function shows:display()
    local page, errmsg = load(api.shows.display .. self.url .. api_key)
    if not page then return nil, errmsg end
    
    showInfo = simplexml.parse_string(page)
    
    for _, node in ipairs(showInfo.children) do
        if node.name == "title" then
            self.title = trim(node.children[1])
            
        elseif node.name == "id_thetvdb" then
            self.tvdb = trim(node.children[1])
            
        elseif node.name == "url" then
            self.url = trim(node.children[1])
            
        elseif node.name == "description" then
            self.description = trim(node.children[1])
            
        elseif node.name == "status" then
            self.status = trim(node.children[1])
            
        elseif node.name == "banner" then
            self.banner = trim(node.children[1])
            
        elseif node.name == "genres" then
            self.genres = {}
            for _, genre in ipairs(node.children) do
                table.insert(self.genres, genre.children[1])
            end
        end
    end
    
    if not self.title then
        return false, "Can't display" .. url
    end
    
    return true
end

function shows:episodes(season)
    local url = api.shows.episodes .. self.url .. api_key
    if tonumber(season) ~= nil then
        url = url .. "&season=" .. season
    end
    
    local page, errmsg = load(url)
    if not page then return nil, errmsg end
    
    local xml = simplexml.parse_string(page)
    
    for _, node in ipairs(xml.children) do
        if node.name == "season" then
            local season = {}
            
            for _, subnode in ipairs(node.children) do
                if subnode.name == "number" then
                    season.number = subnode.children[1]
                
                elseif subnode.name == "episodes" then
                    season.episodes = {}
                    for _, episodes in ipairs(subnode.children) do
                        local episode = {}
                        for _, episodeInfo in ipairs(episodes.children) do
                            if episodeInfo == "episode" then
                                episode.episode = episodeInfo.children[1]
                                
                            elseif episodeInfo == "number" then
                                episode.number = episodeInfo.children[1]
                                
                            elseif episodeInfo == "date" then
                                episode.date = episodeInfo.children[1]
                            
                            elseif episodeInfo == "title" then
                                episode.title = episodeInfo.children[1]
                            
                            elseif episodeInfo == "description" then
                                episode.description = episodeInfo.children[1]
                                
                            elseif episodeInfo == "screen" then
                                episode.screen = episodeInfo.children[1]
                            end
                        end
                        
                        season.episodes[tonumber(episode.episode)] = episode
                    end
                end
            end
        end
    end
end

-- Members section.

function members.signup(login, password, mail)
    page, errmsg = load(api.members.signup.."login="..login.."&password="..password.."&mail="..mail)
    if not page then return false, errmsg end
end
-- Authentification.
-- Given a username and password (must be md5), attempts to login
-- returns:
-- - token                          - on success
-- - nil, error message, error code - on failure.
function members.auth(username, password)
    -- Build URL
    local url = api.members.auth .. "login=" .. username .. "&password=" .. password

    -- Open/Fetch URL.
    local data, msg = load(url)
    if not data then
        vlc.msg.warn(tag..msg)
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
