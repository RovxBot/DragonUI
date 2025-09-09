local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers or {}
local set = H.createSetFunction or function() return function() end end

local function BuildAdditionalBarsOptions()
    return {
        type='group', name = "Additional Bars", desc = "Specialized bars that appear when needed (stance/pet/vehicle/totems)", order = 8,
        args = {
            info_header = { type='description', order=0, name = "|cffFFD700Additional Bars Configuration|r\n|cff00FF00Auto-show bars:|r Stance (Warriors/Druids/DKs) • Pet (Hunters/Warlocks/DKs) • Vehicle (All classes) • Totem (Shamans)" },
            common_group = { type='group', name = "Common Settings", inline=true, order=1, args = {
                size = { type='range', name="Button Size", desc="Size of buttons for all additional bars", min=15, max=50, step=1,
                    get=function() return addon.db.profile.additional.size end, set=set('additional','size',nil,'RefreshStance RefreshPetbar RefreshVehicle RefreshMulticast'), order=1, width='half' },
                spacing = { type='range', name="Button Spacing", desc="Space between buttons for all additional bars", min=0, max=20, step=1,
                    get=function() return addon.db.profile.additional.spacing end, set=set('additional','spacing',nil,'RefreshStance RefreshPetbar RefreshVehicle RefreshMulticast'), order=2, width='half' },
            }},
            individual_bars_group = { type='group', name = "Individual Bar Positions & Settings", desc = "|cffFFD700Now using Smart Anchoring:|r Bars automatically position relative to each other", inline=true, order=2, args = {
                stance_group = { type='group', name = "Stance Bar", desc = "Warriors, Druids, Death Knights", inline=true, order=1, args = {
                    override = { type='toggle', name="Independent Positioning", desc="Enable independent positioning for stance bar (not tied to other bars)",
                        get=function() return addon.db.profile.additional.stance.override end, set=set('additional','stance','override','RefreshStance'), order=0.5, width='full' },
                    x_position = { type='range', name="X Position", desc="Horizontal position of stance bar", min=-500, max=500, step=1,
                        get=function() return addon.db.profile.additional.stance.x_position end, set=set('additional','stance','x_position','RefreshStance'), order=1, width='full' },
                    y_position = { type='range', name="Y Position", desc="Vertical position of the stance bar (independent mode only)", min=0, max=1000, step=1,
                        get=function() return addon.db.profile.additional.stance.y_position end, set=set('additional','stance','y_position','RefreshStance'), order=1.5, width='full', disabled=function() return not addon.db.profile.additional.stance.override end },
                    y_offset = { type='range', name="Y Offset", desc=function()
                            if addon.db.profile.additional.stance.override then
                                return "|cffFFFF00Independent Mode:|r Additional fine-tuning offset for precise positioning."
                            else
                                return "|cff00FF00Smart Anchoring:|r The stance bar automatically positions above the main action bar using intelligent anchoring.\n|cffFFFF00Fine-Tuning:|r Use this offset to make small vertical adjustments while preserving the smart anchoring behavior.\n|cffFFD700Note:|r Positive values move the bar up, negative values move it down."
                            end
                        end, min=-50, max=50, step=1,
                        get=function() return addon.db.profile.additional.stance.y_offset end, set=set('additional','stance','y_offset','RefreshStance'), order=2, width='full' },
                    header_stance_visibility = { type='header', name = "Visibility Behavior", order=3 },
                    show_on_hover = { type='toggle', name = "Show on Hover Only", desc = "Stance bar will only be visible when you hover over it",
                        get=function() return addon.db.profile.additional.stance.show_on_hover end,
                        set=function(_,v) addon.db.profile.additional.stance.show_on_hover=v; if addon.UpdateStanceBarVisibility then addon.UpdateStanceBarVisibility() end end,
                        order=4, width='half' },
                    show_in_combat = { type='toggle', name = "Show in Combat Only", desc = "Stance bar will only be visible during combat",
                        get=function() return addon.db.profile.additional.stance.show_in_combat end,
                        set=function(_,v) addon.db.profile.additional.stance.show_in_combat=v; if addon.UpdateStanceBarVisibility then addon.UpdateStanceBarVisibility() end end,
                        order=5, width='half' },
                }},
                pet_group = { type='group', name = "Pet Bar", desc = "Hunters, Warlocks, Death Knights", inline=true, order=2, args = {
                    x_position = { type='range', name="X Position", desc="Horizontal position of pet bar", min=-500, max=500, step=1,
                        get=function() return addon.db.profile.additional.pet.x_position end, set=set('additional','pet','x_position','RefreshPetbar'), order=1, width='double' },
                    y_offset = { type='range', name="Y Offset", desc = "|cffFFD700Smart Anchored Bar:|r This bar automatically positions itself relative to other visible bars.\n\n• This Y offset adds extra spacing above/below the automatic position\n• Positive values = move UP\n• Negative values = move DOWN\n• The bar will still move automatically when you show/hide other action bars", min=-100, max=100, step=1,
                        get=function() return addon.db.profile.additional.pet.y_offset or 0 end, set=set('additional','pet','y_offset','RefreshPetbar'), order=2, width='full' },
                    grid = { type='toggle', name = "Show Empty Slots", desc = "Display empty action slots on pet bar",
                        get=function() return addon.db.profile.additional.pet.grid end, set=set('additional','pet','grid','RefreshPetbar'), order=3, width='full' },
                }},
                vehicle_group = { type='group', name = "Vehicle Bar", desc = "All classes (vehicles/special mounts)", inline=true, order=3, args = {
                    x_position = { type='range', name="X Position", desc="Horizontal position of vehicle bar", min=-500, max=500, step=1,
                        get=function() return (addon.db.profile.additional.vehicle and addon.db.profile.additional.vehicle.x_position) or 0 end, set=set('additional','vehicle','x_position','RefreshVehicle'), order=1, width='double' },
                    artstyle = { type='toggle', name = "Blizzard Art Style", desc = "Use Blizzard original bar arts style",
                        get=function() return addon.db.profile.additional.vehicle.artstyle end, set=set('additional','vehicle','artstyle','RefreshVehicle'), order=2, width='full' },
                }},
                totem_group = { type='group', name = "Totem Bar", desc = "Shamans only (multicast)", inline=true, order=4, args = {
                    x_position = { type='range', name="X Position", desc="Horizontal offset for totem bar", min=-500, max=500, step=1,
                        get=function() return (addon.db.profile.additional.totem and addon.db.profile.additional.totem.x_position) or 0 end,
                        set=function(_,v) addon.db.profile.additional.totem = addon.db.profile.additional.totem or {}; addon.db.profile.additional.totem.x_position=v; if addon.RefreshMulticast then addon.RefreshMulticast() end end, order=1 },
                    y_offset = { type='range', name="Y Offset", desc="Vertical offset for totem bar", min=-200, max=200, step=1,
                        get=function() return (addon.db.profile.additional.totem and addon.db.profile.additional.totem.y_offset) or 0 end,
                        set=function(_,v) addon.db.profile.additional.totem = addon.db.profile.additional.totem or {}; addon.db.profile.additional.totem.y_offset=v; if addon.RefreshMulticast then addon.RefreshMulticast() end end, order=2 },
                }},
            }},
        }
    }
end

addon:RegisterOptionsSection('additional', 8, BuildAdditionalBarsOptions)

