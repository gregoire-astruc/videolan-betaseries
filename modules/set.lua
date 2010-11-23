--[[
 Simple set.
 Heavily inspired from:
    http://stackoverflow.com/questions/2282444/how-to-check-if-a-table-contains-an-element-in-lua

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
module("set",package.seeall)

-- Create a set.
function new()
    return set
end

-- Add a key in the set
function set:insert(key)
    self[key] = true
end

-- Remove a key.
function set:remove(key)
    self[key] = nil
end

function set:contains(key)
    return self[key] == true
end