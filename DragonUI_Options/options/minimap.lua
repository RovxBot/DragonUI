local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers or {}
local set = H.createSetFunction or function() return function() end end

local function BuildMinimapOptions()
    return {
        type='group', name = "Minimap", order = 10, args = {
            scale = { type='range', name = "Minimap Scale", desc = "Minimap scale (don't increase too much)", min=0.5, max=2.0, step=0.05,
                get=function() return addon.db.profile.map.scale end, set=set('map','scale',nil,'RefreshMinimap'), order=1 },
            border_alpha = { type='range', name = "Border Alpha", desc = "Top border alpha (0 to hide)", min=0, max=1, step=0.1,
                get=function() return addon.db.profile.map.border_alpha end, set=set('map','border_alpha',nil,'RefreshMinimap'), order=2 },
            blip_skin = { type='toggle', name = "New Blip Style", desc = "New style for object icons",
                get=function() return addon.db.profile.map.blip_skin end, set=set('map','blip_skin',nil,'RefreshMinimap'), order=3 },
            player_arrow_size = { type='range', name = "Player Arrow Size", desc = "Player arrow on minimap center", min=20, max=80, step=1,
                get=function() return addon.db.profile.map.player_arrow_size end, set=set('map','player_arrow_size',nil,'RefreshMinimap'), order=4 },
            tracking_icons = { type='toggle', name = "Tracking Icons", desc = "Show current tracking icons (old style)",
                get=function() return addon.db.profile.map.tracking_icons end, set=set('map','tracking_icons',nil,'RefreshMinimap'), order=5 },
            skin_button = { type='toggle', name = "Skin Buttons",
                get=function() return addon.db.profile.map.skin_button end, set=set('map','skin_button',nil,'RefreshMinimap'), order=6 },
            auras_x_offset = { type='range', name = "Auras Horizontal Offset", desc = "Adjusts the horizontal position of the buffs/debuffs block next to the minimap.", min=-500, max=500, step=1,
                get=function() local t=addon.db.profile.map.auras or {x=0,y=0}; addon.db.profile.map.auras=t; return t.x or 0 end,
                set=function(_,v) addon.db.profile.map.auras=addon.db.profile.map.auras or {}; addon.db.profile.map.auras.x=v; if addon.RefreshMinimapAuras then addon.RefreshMinimapAuras() end end,
                order=10.1 },
            auras_y_offset = { type='range', name = "Auras Vertical Offset", desc = "Adjusts the vertical position of the buffs/debuffs block next to the minimap.", min=-500, max=500, step=1,
                get=function() local t=addon.db.profile.map.auras or {x=0,y=0}; addon.db.profile.map.auras=t; return t.y or 0 end,
                set=function(_,v) addon.db.profile.map.auras=addon.db.profile.map.auras or {}; addon.db.profile.map.auras.y=v; if addon.RefreshMinimapAuras then addon.RefreshMinimapAuras() end end,
                order=10.2 },
        }
    }
end

addon:RegisterOptionsSection('minimap', 10, BuildMinimapOptions)

