local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers; local set = H and H.createSetFunction or function() return function() end end

local function Additional()
  return { type='group', name='Additional Bars', order=8, args = {
    info_header = { type='description', order=0, name='|cffFFD700Additional Bars Configuration|r\n|cff00FF00Auto-show bars:|r Stance (Warriors/Druids/DKs) • Pet (Hunters/Warlocks/DKs) • Vehicle (All classes) • Totem (Shamans)' },
    common_group = { type='group', name='Common Settings', inline=true, order=1, args={
      size = { type='range', order=1, name='Button Size', min=15,max=50,step=1, get=function() return addon.db.profile.additional.size end, set=set('additional','size',nil,{'RefreshStance','RefreshPetbar','RefreshVehicle','RefreshMulticast'}), width='half' },
      spacing = { type='range', order=2, name='Button Spacing', min=0,max=20,step=1, get=function() return addon.db.profile.additional.spacing end, set=set('additional','spacing',nil,{'RefreshStance','RefreshPetbar','RefreshVehicle','RefreshMulticast'}), width='half' },
    }},
    individual_bars_group = { type='group', name='Individual Bar Positions & Settings', inline=true, order=2, args={
      stance_group = { type='group', name='Stance Bar', inline=true, order=1, args={
        override = { type='toggle', order=0.5, width='full', name='Independent Positioning', desc='Enable independent positioning for stance bar (not tied to other bars)', get=function() return addon.db.profile.additional.stance.override end, set=set('additional','stance','override','RefreshStance') },
        x_position = { type='range', order=1, width='full', name='X Position', min=-500,max=500,step=1, get=function() return addon.db.profile.additional.stance.x_position end, set=set('additional','stance','x_position','RefreshStance') },
        y_position = { type='range', order=1.5, width='full', name='Y Position', min=0,max=1000,step=1, get=function() return addon.db.profile.additional.stance.y_position end, set=set('additional','stance','y_position','RefreshStance'), disabled=function() return not addon.db.profile.additional.stance.override end },
        y_offset = { type='range', order=2, width='full', name='Y Offset', min=-50,max=50,step=1, get=function() return addon.db.profile.additional.stance.y_offset end, set=set('additional','stance','y_offset','RefreshStance') },
        header_stance_visibility = { type='header', order=3, name='Visibility Behavior' },
        show_on_hover = { type='toggle', order=4, width='half', name='Show on Hover Only', get=function() return addon.db.profile.additional.stance.show_on_hover end, set=function(_,v) addon.db.profile.additional.stance.show_on_hover=v; if addon.UpdateStanceBarVisibility then addon.UpdateStanceBarVisibility() end end },
        show_in_combat = { type='toggle', order=5, width='half', name='Show in Combat Only', get=function() return addon.db.profile.additional.stance.show_in_combat end, set=function(_,v) addon.db.profile.additional.stance.show_in_combat=v; if addon.UpdateStanceBarVisibility then addon.UpdateStanceBarVisibility() end end },
      }},
      pet_group = { type='group', name='Pet Bar', inline=true, order=2, args={
        x_position = { type='range', order=1, width='double', name='X Position', min=-500,max=500,step=1, get=function() return addon.db.profile.additional.pet.x_position end, set=set('additional','pet','x_position','RefreshPetbar') },
        y_offset = { type='range', order=2, width='full', name='Y Offset', min=-100,max=100,step=1, get=function() return addon.db.profile.additional.pet.y_offset or 0 end, set=set('additional','pet','y_offset','RefreshPetbar') },
        grid = { type='toggle', order=3, width='full', name='Show Empty Slots', desc='Display empty action slots on pet bar', get=function() return addon.db.profile.additional.pet.grid end, set=set('additional','pet','grid','RefreshPetbar') },
      }},
      vehicle_group = { type='group', name='Vehicle Bar', inline=true, order=3, args={
        x_position = { type='range', order=1, width='double', name='X Position', min=-500,max=500,step=1, get=function() return (addon.db.profile.additional.vehicle and addon.db.profile.additional.vehicle.x_position) or 0 end, set=set('additional','vehicle','x_position','RefreshVehicle') },
        artstyle = { type='toggle', order=2, width='full', name='Blizzard Art Style', desc='Use Blizzard original bar arts style', get=function() return addon.db.profile.additional.vehicle.artstyle end, set=set('additional','vehicle','artstyle','RefreshVehicle') },
      }},
      totem_group = { type='group', name='Totem Bar', inline=true, order=4, args={
        x_position = { type='range', order=1, name='X Position', min=-500,max=500,step=1, get=function() return (addon.db.profile.additional.totem and addon.db.profile.additional.totem.x_position) or 0 end, set=set('additional','totem','x_position','RefreshMulticast') },
        y_offset = { type='range', order=2, name='Y Offset', min=-200,max=200,step=1, get=function() return (addon.db.profile.additional.totem and addon.db.profile.additional.totem.y_offset) or 0 end, set=set('additional','totem','y_offset','RefreshMulticast') },
      }},
    }},
  }}
end

addon:RegisterOptionsSection('additional', 8, Additional)

