local addon = _G.DragonUI_Addon

local function BuildCastbarsOptions()
    local player = type(addon._buildCastbarsPlayer) == 'function' and addon._buildCastbarsPlayer() or { type='group', name='Player Castbar', order=1, args={ _warn = { type='description', order=1, name = "Player castbar builder missing. Please /reload." } } }
    local target = type(addon._buildCastbarsTarget) == 'function' and addon._buildCastbarsTarget() or { type='group', name='Target Castbar', order=2, args={ _warn = { type='description', order=1, name = "Target castbar builder missing. Please /reload." } } }
    local focus  = type(addon._buildCastbarsFocus)  == 'function' and addon._buildCastbarsFocus()  or { type='group', name='Focus Castbar',  order=3, args={ _warn = { type='description', order=1, name = "Focus castbar builder missing. Please /reload." } } }

    return {
        type = 'group', name = "Cast Bars", order = 4, childGroups = 'tree',
        args = {
            player_castbar = player,
            target_castbar = target,
            focus_castbar  = focus,
        }
    }
end

addon:RegisterOptionsSection('castbars', 4, BuildCastbarsOptions)

