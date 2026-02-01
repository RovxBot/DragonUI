local addon = _G.DragonUI_Addon

local function BuildBagsOptions()
    return {
        type='group', name = "Bags", order = 3, args = {
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
            scale = { type='range', name="Bag Bar Scale", desc="Scale for the bag bar buttons", min=0.5, max=2.0, step=0.05,
                get=function() return addon.db.profile.bags.scale end,
                set=function(_,v) addon.db.profile.bags.scale=v; if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end end,
                order=6 },
            x_position = { type='range', name="X Position", desc="Horizontal position adjustment for the bag bar", min=-200, max=200, step=1,
                get=function() return addon.db.profile.bags.x_position end,
                set=function(_,v) addon.db.profile.bags.x_position=v; if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end end,
                order=7 },
            y_position = { type='range', name="Y Position", desc="Vertical position adjustment for the bag bar", min=-200, max=200, step=1,
                get=function() return addon.db.profile.bags.y_position end,
                set=function(_,v) addon.db.profile.bags.y_position=v; if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end end,
                order=8 },
            separator2 = { type='description', name = "", order=9 },
            reset_position = { type='execute', name="Reset Bag Settings", desc="Resets all bag settings to default values.",
                func=function()
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
                order=10 },
        }
    }
end

addon:RegisterOptionsSection('bags', 3, BuildBagsOptions)

