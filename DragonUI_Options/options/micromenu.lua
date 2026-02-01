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

local function BuildBagsOptions()
    return {
        type = 'group', name = "Bags", order = 3, args = {
            bags_header = { type='header', name = "Bag Frame Settings", order=1 },
            combine_bags = {
                type='toggle', 
                name = "Combine All Bags", 
                desc = "Show all bags as a single combined frame instead of individual bag windows",
                get = function() return addon.db.profile.bags.combine_bags end,
                set = function(_, v) 
                    addon.db.profile.bags.combine_bags = v
                    -- Close any open bags when toggling
                    CloseAllBags()
                end,
                order = 2
            },
            anchor_to_bagbar = {
                type='toggle', 
                name = "Anchor Bags Above Bag Bar", 
                desc = "Always position bag frames directly above the bag bar, regardless of where you move it",
                get = function() return addon.db.profile.bags.anchor_to_bagbar end,
                set = function(_, v) 
                    addon.db.profile.bags.anchor_to_bagbar = v
                    if addon.PositionContainerFrames then
                        addon.PositionContainerFrames()
                    end
                end,
                order = 3
            },
            separator1 = { type='description', name = "", order=4 },
            bagbar_header = { type='header', name = "Bag Bar Settings", order=5 },
            bags_scale = { 
                type='range', 
                name = "Bag Bar Scale", 
                desc = "Scale of the bag bar buttons",
                min = 0.5, max = 2.0, step = 0.05,
                get = function() return addon.db.profile.bags.scale end,
                set = function(_, v) 
                    addon.db.profile.bags.scale = v
                    if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end
                end,
                order = 6
            },
            separator2 = { type='description', name = "", order=7 },
            reset_bags = { 
                type='execute', 
                name = "Reset Bag Settings", 
                desc = "Reset all bag settings to defaults",
                func = function()
                    addon.db.profile.bags.scale = 0.9
                    addon.db.profile.bags.x_position = 1
                    addon.db.profile.bags.y_position = 41
                    addon.db.profile.bags.combine_bags = false
                    addon.db.profile.bags.anchor_to_bagbar = true
                    -- Clear mover position
                    if addon.db.profile.movers then
                        addon.db.profile.movers.bagsbar = nil
                    end
                    if addon.RefreshBags then addon.RefreshBags() end
                    if addon.ApplyMover then addon:ApplyMover('bagsbar') end
                end,
                order = 8
            },
        }
    }
end

addon:RegisterOptionsSection('micromenu', 2, BuildMicromenuOptions)
addon:RegisterOptionsSection('bags', 3, BuildBagsOptions)

