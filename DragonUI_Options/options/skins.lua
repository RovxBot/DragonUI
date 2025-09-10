local addon = _G.DragonUI_Addon

local function reloadSet(section, key)
    return function(_, value)
        addon.db = addon.db or { profile = {} }
        addon.db.profile[section] = addon.db.profile[section] or {}
        addon.db.profile[section][key] = value
        if StaticPopup_Show then StaticPopup_Show("DRAGONUI_RELOAD_UI") end
    end
end

local function BuildSkinsOptions()
    return {
        type = 'group',
        name = "UI Skins",
        order = 12,
        args = {
            info = { type='description', order=0, name = "Toggle Dragonflight-style skins for select Blizzard frames. Changes require a reload to fully apply/remove." },

            character = { type='toggle', order=1, name = "Character & Paperdoll",
                get=function() return (addon.db.profile.skins and addon.db.profile.skins.character) ~= false end,
                set=reloadSet('skins','character') },

            friends = { type='toggle', order=2, name = "Friends / Who / Guild",
                get=function() return (addon.db.profile.skins and addon.db.profile.skins.friends) ~= false end,
                set=reloadSet('skins','friends') },

            spellbook = { type='toggle', order=3, name = "Spellbook",
                get=function() return (addon.db.profile.skins and addon.db.profile.skins.spellbook) ~= false end,
                set=reloadSet('skins','spellbook') },

            questlog = { type='toggle', order=4, name = "Quest Log",
                get=function() return (addon.db.profile.skins and addon.db.profile.skins.questlog) ~= false end,
                set=reloadSet('skins','questlog') },

            closebuttons = { type='toggle', order=5, name = "Close Buttons",
                get=function() return (addon.db.profile.skins and addon.db.profile.skins.closebuttons) ~= false end,
                set=reloadSet('skins','closebuttons') },

            talents = { type='toggle', order=6, name = "Talents Overhaul (Large Window)",
                desc = "Replaces Blizzard Talents with an overhauled large 3-column window.",
                get=function() return (addon.db.profile.skins and addon.db.profile.skins.talents) ~= false end,
                set=reloadSet('skins','talents') },

            worldmap_header = { type='header', order=9, name = 'World Map' },
            worldmap_small = { type='toggle', order=10, name = "Smaller World Map",
                desc = "Use Blizzard's compact windowed map instead of fullscreen.",
                get=function() return (addon.db.profile.skins and addon.db.profile.skins.worldmap_small) ~= false end,
                set=reloadSet('skins','worldmap_small') },
            worldmap_skin = { type='toggle', order=11, name = "Skin World Map",
                desc = "Add a subtle backdrop and styled close button to the world map.",
                get=function() return (addon.db.profile.skins and addon.db.profile.skins.worldmap_skin) ~= false end,
                set=reloadSet('skins','worldmap_skin') },
        }
    }
end

addon:RegisterOptionsSection('skins', 12, BuildSkinsOptions)

