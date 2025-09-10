local addon = _G.DragonUI_Addon

local function BuildBagsOptions()
    return {
        type='group', name = "Bags", order = 3, args = {
            description = { type='description', name = "Configure the position and scale of the bag bar independently from the micro menu.", order=1 },
            scale = { type='range', name="Scale", desc="Scale for the bag bar", min=0.5, max=2.0, step=0.1,
                get=function() return addon.db.profile.bags.scale end,
                set=function(_,v) addon.db.profile.bags.scale=v; if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end end,
                order=2 },
            x_position = { type='range', name="X Position", desc="Horizontal position adjustment for the bag bar", min=-200, max=200, step=1,
                get=function() return addon.db.profile.bags.x_position end,
                set=function(_,v) addon.db.profile.bags.x_position=v; if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end end,
                order=3 },
            y_position = { type='range', name="Y Position", desc="Vertical position adjustment for the bag bar", min=-200, max=200, step=1,
                get=function() return addon.db.profile.bags.y_position end,
                set=function(_,v) addon.db.profile.bags.y_position=v; if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end end,
                order=4 },
            reset_position = { type='execute', name="Reset Position", desc="Resets the bag position and scale to default values.",
                func=function()
                    local defaults = { scale=0.9, x_position=1, y_position=41 }
                    addon.db.profile.bags.scale = defaults.scale
                    addon.db.profile.bags.x_position = defaults.x_position
                    addon.db.profile.bags.y_position = defaults.y_position
                    if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end
                end,
                order=5 },
        }
    }
end

addon:RegisterOptionsSection('bags', 3, BuildBagsOptions)

