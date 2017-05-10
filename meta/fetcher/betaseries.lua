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

 Inspired from https://github.com/videolan/vlc/blob/5f24d114aa3a7d491536bc58cb064cd4e2d875d3/share/lua/meta/fetcher/tvrage.lua
--]]

local tag = '[BetaSeries-Fetcher] '

--[[ Fetch betaseries specific metas.
     Use the betaseries module to fetch meta tag from betaseries.com
     All tags are added under betaseries/*.
]]--

function descriptor()
  return { scope='network' }
end

-- Replace non alphanumeric char by +
function get_query(title)
  -- If we have a .EXT remove the extension.
  str = string.gsub(title, '(.*)%....$', '%1')
  return string.gsub(str, '([^%w ])', function (c) return string.format('%%%02X', string.byte(c)) end)
end

function fetch_meta()
  local metas = vlc.item:metas()

  local showName = metas['showName']
  if not showName then
    return false
  end

  -- Find "[Source tag] Show Name"
  _, _, showName = string.find(showName, '^%[[^%]]-%]%s(.*)')
  showName = showName or metas['showName']

  local episodeNumber = metas['episodeNumber']
  if not episodeNumber then
    return false
  end

  local seasonNumber = metas['seasonNumber']
  if not seasonNumber then
    return false
  end

  local fd = vlc.stream('http://api.betaseries.com/shows/search?key=5b8a94c91877&title=' .. get_query(showName))
  if not fd then return nil end
  local page = fd:read(65653)
  fd = nil

  if not page then
    return false
  end

  local shows = {}

  -- for showTitle, showArtwork, showUrl in page:gmatch('"title":"(.-)".-"poster":"(.-)".-"resource_url":"(.-)"') do
  --   table.insert(shows, { url = showUrl, title = showTitle, artwork = string.gsub(showArtwork, '\\', '') })
  -- end

  for showTitle, showUrl in page:gmatch('"title":"(.-)".-"resource_url":"(.-)"') do
    table.insert(shows, { url = showUrl, title = showTitle })
  end

  -- Look for an exact title match.
  -- If none, we acknownledge we failed.
  local showUrl
  local showTitle
  -- local showArtwork

  if #shows == 1 then
    -- Only one show returned : assume it's the correct one.
    showUrl = shows[1].url
    showTitle = shows[1].title
    -- showArtwork = shows[1].artwork
  else
    -- Multiple show : we look for an exact match.
    for _, showInfo in ipairs(shows) do
      if string.lower(showName) == string.lower(showInfo.title) then
        showUrl = showInfo.url
        showTitle = showInfo.title
        -- showArtwork = showInfo.artwork
        break
      end
    end
  end

  if not showUrl then
    return false
  end

  -- vlc.item:set_meta('artwork_url', showArtwork)
  vlc.item:set_meta('betaseries/url', showUrl)
  vlc.item:set_meta('betaseries/title', showTitle)
  vlc.item:set_meta('betaseries/episode', episodeNumber)
  vlc.item:set_meta('betaseries/season', seasonNumber)

  return true
end
