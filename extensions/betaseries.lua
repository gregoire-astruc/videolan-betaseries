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

require 'betaseries.api'
require 'betaseries.set'

local md5 = require 'betaseries.md5'
local json = require 'dkjson'

local tag = '[BetaSeries-Extension] '
local dlg = nil
local widget = {}
local user = nil
local userdata = {
  username = nil,
  password = nil
}
local markers = nil

-- ******************************
-- *                            *
-- *  VLC extension functions   *
-- *                            *
-- ******************************

-- VLC specific. Used to describe the extension
function descriptor()
  return {
    title          = 'BetaSeries';
    version        = '2017.04';
    author         = 'Gregoire Astruc';
    url            = 'http://www.betaseries.com/';
    shortdesc      = 'Betaseries - Le site de vos series.';
    description    = '<center><strong>betaseries.com</strong></center>'
              .. '<p>'
              .. 'Marque votre &eacutepisode comme <em>vu</em> lorsque celui-ci se termine.'
              .. '</p>' ;
    capabilities   = { 'menu', 'meta-listener', 'input-listener' }
  }
end

-- VLC specific. Called on extension startup
function activate()
  vlc.msg.dbg(tag .. 'Welcome')

  markers = set.new()

  local f = io.open(vlc.config.configdir() .. '/.betaseries', 'r')

  if f then
    local raw_json_text = ''
    for line in f:lines() do
      raw_json_text = raw_json_text .. line
    end
    f:close()

    obj, pos, err = json.decode(raw_json_text, 1, nil)

    if err then
      vlc.msg.warn(tag .. 'Error decoding .betaseries for reading: ' .. err)
    else
      userdata = obj
    end
  end

  if userdata.username ~= nil and userdata.password ~= nil then
    user = betaseries.members.auth(userdata.username, userdata.password)

    trigger_menu(1)

    if user ~= nil then
      if vlc.input.is_playing() then
        parse_input()
      end
    else
      update_login_dialog('Nom d\'utilisateur ou mot de passe incorrect.')
    end
  else
    trigger_menu(1)
  end
end

-- VLC specific. Called on extension deactivation
function deactivate()
  vlc.msg.dbg(tag .. 'Bye bye!')

  close_dlg()

  if user then
    user:destroy()
  end
end

-- VLC specific. Called when the extension is closed
function close()
  close_dlg()
end

-- VLC specific. TOOD add description
function menu()
  return { 'Mon Compte...' }
end

-- VLC specific. TOOD add description
function input_changed()
  parse_input()
end

-- VLC specific. TOOD add description
function meta_changed()
  parse_input()
end

function parse_input()
  if not user then
    return
  end

  if not vlc.input.is_playing() then
    return
  end

  local metas = vlc.input.item():metas()

  local showUrl = metas['betaseries/url']
  if not showUrl then
    return
  end

  local season = metas['betaseries/season']
  if not season then
    return
  end

  local episode = metas['betaseries/episode']
  if not episode then
    return
  end

  local title = metas['betaseries/title']
  if not title then
    return
  end

  if markers:contains(title) then
    return
  end

  if showUrl and season and episode then
    local url = user:watchedurl(showUrl, season, episode)
    -- Add an item playlist to mark the show as read once seen :)
    local mark = { path = url, name = '[BetaSeries] Watched - ' .. title }
    vlc.playlist.enqueue({ mark })
    markers:insert(title)
  end
end

-- ******************************
-- *                            *
-- *  UI dialog functions       *
-- *                            *
-- ******************************

function create_login_dialog()
  dlg:hide()

  widget['login_username_label'] = dlg:add_label('<strong>Pseudo : </strong>', 1, 1, 1, 1)
  widget['login_username_imput'] = dlg:add_text_input('', 2, 1, 1, 1)

  widget['login_password_label'] = dlg:add_label('<strong>Mot de passe : </strong>', 1, 2, 1, 1)
  widget['login_password_input'] = dlg:add_text_input('', 2, 2, 1, 1)

  widget['login_button'] = dlg:add_button('Se connecter', login_action, 2, 3, 1, 1)

  dlg:show()
end

function update_login_dialog(message)
  if not widget['login_error'] then
    widget['login_error'] = dlg:add_label(message, 1, 4, 2, 1)
  else
    widget['login_error']:set_text(message)
  end

  dlg:update()
end

function create_dashboard_dialog()
  dlg:hide()

  widget['logout_username_label'] = dlg:add_label('<strong>Pseudo : </strong>', 1, 1, 1, 1)
  widget['logout_username_imput'] = dlg:add_label(userdata.username, 2, 1, 1, 1)

  widget['logout_button'] = dlg:add_button('Se déconnecter', logout_action, 2, 2, 1, 1)

  dlg:show()
end

function close_dlg()
  if dlg then
    dlg:delete()
  end

  dlg = nil
  widget = nil
  widget = {}
end

-- VLC specific. Used to control which dialog is displayed
function trigger_menu(dlg_id)
  if dlg_id == 1 then
    close_dlg()
    dlg = vlc.dialog('Mon Compte BetaSeries')

    if user then
      create_dashboard_dialog()
    else
      create_login_dialog()
    end
  end
end

function login_action()
  local username = widget['login_username_imput']:get_text()
  local password = widget['login_password_input']:get_text()

  if not username or username == '' then
    return
  end

  if not password or password == '' then
    return
  end

  update_login_dialog('Connexion a Betaseries...')

  user = betaseries.members.auth(username, md5.sumhexa(password))

  if user ~= nil then
    local f, errmsg = io.open(vlc.config.configdir() .. '/.betaseries', 'w')

    if not f then
      vlc.msg.warn(tag .. 'Error opening .betaseries for writing: ' .. errmsg)
      return
    end

    userdata.username = username
    userdata.password = md5.sumhexa(password)

    f:write(json.encode(userdata, { indent = true }))
    f:close()

    update_login_dialog('Connexion reussie.')
    trigger_menu(1)

    if vlc.input.is_playing() then
      parse_input()
    end
  else
    update_login_dialog('Nom d\'utilisateur ou mot de passe incorrect.')
  end
end

function logout_action()
  if user then
    user:destroy()
    user = nil
  end

  os.remove(vlc.config.configdir() .. '/.betaseries')

  trigger_menu(1)
end
