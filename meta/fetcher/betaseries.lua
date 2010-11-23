--[[
 Gets serie information for tv episode using betaseries.

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
require "modules.betaseries"

local tag = "[betaseries-fetcher]: "

--[[ Fetch betaseries specific metas.
     Use the betaseries module to fetch meta tag from betaseries.com
     All tags are added under betaseries/*.
]]--
function fetch_meta()
    local metas = vlc.item:metas()
    
    local show = metas["showName"]  
    local episode = metas["episodeNumber"]
    local season = metas["seasonNumber"]
    
    if not show or not episode or not season then
        return false
    end
    
    local shows, errmsg = betaseries.shows.search(show)
    
    if not shows then
        vlc.msg.warn(tag .. errmsg)
        return false
    end
    
    if #shows > 1 then
        vlc.msg.warn(tag .. "Multiple shows.")
        return false
    end

    vlc.item:set_meta("betaseries/url", shows[1].url)
    vlc.item:set_meta("betaseries/title", shows[1].title)
    vlc.item:set_meta("betaseries/episode", episode)
    vlc.item:set_meta("betaseries/season", season)
    return true
end