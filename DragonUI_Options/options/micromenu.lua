local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers or {}

local function BuildMicromenuOptions()
    return {
        type = 'group', name = "Micro Menu", order = 2, args = {
            grayscale_icons = {
                type='toggle', name = "Gray Scale Icons", desc = "Use grayscale icons instead of colored icons for the micro menu",
                get=function() return addon.db.profile.micromenu.grayscale_icons end,
                set=function(_,v) addon.db.profile.micromenu.grayscale_icons=v; StaticPopup_Show("DRAGONUI_RELOAD_UI") end,
                order=1
            },
            separator1 = { type='description', name = "", order=2 },
            current_mode_header = { type='header', name = function()
                return addon.db.profile.micromenu.grayscale_icons and "Grayscale Icons Settings" or "Normal Icons Settings"
            end, order=3 },
            scale_menu = { type='range', name="Menu Scale", desc=function()
                    local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                    return "Scale for micromenu ("..mode.." icons)"
                end,
                min=0.5, max=3.0, step=0.1,
                get=function() local m=addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"; return addon.db.profile.micromenu[m].scale_menu end,
                set=function(_,v) local m=addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"; addon.db.profile.micromenu[m].scale_menu=v; if addon.RefreshMicromenu then addon.RefreshMicromenu() end end,
                order=4 },
            x_position = { type='range', name="X Position", desc=function()
                    local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                    return "X offset for "..mode.." icons (negative moves menu to left side)"
                end, min=-500, max=500, step=1,
                get=function() local m=addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"; return addon.db.profile.micromenu[m].x_position end,
                set=function(_,v) local m=addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"; addon.db.profile.micromenu[m].x_position=v; if addon.RefreshMicromenu then addon.RefreshMicromenu() end end,
                order=5 },
            y_position = { type='range', name="Y Position", desc=function()
                    local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                    return "Y offset for "..mode.." icons"
                end, min=-200, max=200, step=1,
                get=function() local m=addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"; return addon.db.profile.micromenu[m].y_position end,
                set=function(_,v) local m=addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"; addon.db.profile.micromenu[m].y_position=v; if addon.RefreshMicromenu then addon.RefreshMicromenu() end end,
                order=6 },
            icon_spacing = { type='range', name="Icon Spacing", desc=function()
                    local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                    return "Gap between "..mode.." icons (pixels)"
                end, min=5, max=40, step=1,
                get=function() local m=addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"; return addon.db.profile.micromenu[m].icon_spacing end,
                set=function(_,v) local m=addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"; addon.db.profile.micromenu[m].icon_spacing=v; if addon.RefreshMicromenu then addon.RefreshMicromenu() end end,
                order=7 },
            separator2 = { type='description', name = "", order=8 },
            hide_on_vehicle = { type='toggle', name="Hide on Vehicle", desc="Hide micromenu and bags if you sit on vehicle",
                get=function() return addon.db.profile.micromenu.hide_on_vehicle end,
                set=function(_,v) addon.db.profile.micromenu.hide_on_vehicle=v; if addon.RefreshMicromenuVehicle then addon.RefreshMicromenuVehicle() end; if addon.RefreshBagsVehicle then addon.RefreshBagsVehicle() end end,
                order=9 },
            reset_position = { type='execute', name="Reset Position", desc=function()
                    local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                    return "Resets the position and scale to default for "..mode.." icons."
                end,
                func=function()
                    local m = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                    local defaults = { grayscale = { scale_menu=1.5, x_position=5, y_position=-54, icon_spacing=15 }, normal = { scale_menu=0.9, x_position=-111, y_position=-53, icon_spacing=26 } }
                    addon.db.profile.micromenu[m].scale_menu = defaults[m].scale_menu
                    addon.db.profile.micromenu[m].x_position = defaults[m].x_position
                    addon.db.profile.micromenu[m].y_position = defaults[m].y_position
                    addon.db.profile.micromenu[m].icon_spacing = defaults[m].icon_spacing
                    if addon.RefreshMicromenu then addon.RefreshMicromenu() end
                end,
                order=10 },
        }
    }
end

addon:RegisterOptionsSection('micromenu', 2, BuildMicromenuOptions)

