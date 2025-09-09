local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers; local set = H and H.createSetFunction or function() return function() end end

local function MicroMenu()
  return { type='group', name='Micro Menu', order=2, args = {
    grayscale_icons = { type='toggle', order=1, name='Gray Scale Icons', desc='Use grayscale icons instead of colored icons for the micro menu',
      get=function() return addon.db.profile.micromenu.grayscale_icons end,
      set=function(_,v) addon.db.profile.micromenu.grayscale_icons=v; StaticPopup_Show("DRAGONUI_RELOAD_UI") end },
    sep1 = { type='description', name='', order=2 },
    current_mode_header = { type='header', order=3, name=function()
      return addon.db.profile.micromenu.grayscale_icons and 'Grayscale Icons Settings' or 'Normal Icons Settings'
    end },
    scale_menu = { type='range', order=4, name='Menu Scale', min=0.5, max=3.0, step=0.1,
      desc=function() local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; return 'Scale for micromenu ('..m..' icons)' end,
      get=function() local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; return addon.db.profile.micromenu[m].scale_menu end,
      set=function(_,v) local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; addon.db.profile.micromenu[m].scale_menu=v; if addon.RefreshMicromenu then addon.RefreshMicromenu() end end },
    x_position = { type='range', order=5, name='X Position', min=-500,max=500,step=1,
      desc=function() local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; return 'X offset for '..m..' icons (negative moves menu to left side)' end,
      get=function() local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; return addon.db.profile.micromenu[m].x_position end,
      set=function(_,v) local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; addon.db.profile.micromenu[m].x_position=v; if addon.RefreshMicromenu then addon.RefreshMicromenu() end end },
    y_position = { type='range', order=6, name='Y Position', min=-200,max=200,step=1,
      desc=function() local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; return 'Y offset for '..m..' icons' end,
      get=function() local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; return addon.db.profile.micromenu[m].y_position end,
      set=function(_,v) local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; addon.db.profile.micromenu[m].y_position=v; if addon.RefreshMicromenu then addon.RefreshMicromenu() end end },
    icon_spacing = { type='range', order=7, name='Icon Spacing', min=5,max=40,step=1,
      desc=function() local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; return 'Gap between '..m..' icons (pixels)' end,
      get=function() local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; return addon.db.profile.micromenu[m].icon_spacing end,
      set=function(_,v) local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'; addon.db.profile.micromenu[m].icon_spacing=v; if addon.RefreshMicromenu then addon.RefreshMicromenu() end end },
    hide_on_vehicle = { type='toggle', order=9, name='Hide on Vehicle', desc='Hide micromenu and bags if you sit on vehicle',
      get=function() return addon.db.profile.micromenu.hide_on_vehicle end,
      set=function(_,v) addon.db.profile.micromenu.hide_on_vehicle=v; if addon.RefreshMicromenuVehicle then addon.RefreshMicromenuVehicle() end; if addon.RefreshBagsVehicle then addon.RefreshBagsVehicle() end end },
    reset_position = { type='execute', order=10, name='Reset Position', func=function()
      local m=addon.db.profile.micromenu.grayscale_icons and 'grayscale' or 'normal'
      local d={ grayscale={scale_menu=1.5,x_position=5,y_position=-54,icon_spacing=15}, normal={scale_menu=0.9,x_position=-111,y_position=-53,icon_spacing=26} }
      for k,v in pairs(d[m]) do addon.db.profile.micromenu[m][k]=v end
      if addon.RefreshMicromenu then addon.RefreshMicromenu() end
    end },
  }}
end

local function Bags()
  return { type='group', name='Bags', order=3, args = {
    description = { type='description', name='Configure the position and scale of the bag bar independently from the micro menu.', order=1 },
    scale = { type='range', order=2, name='Scale', min=0.5, max=2.0, step=0.1, get=function() return addon.db.profile.bags.scale end, set=function(_,v) addon.db.profile.bags.scale=v; if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end end },
    x_position = { type='range', order=3, name='X Position', min=-200,max=200,step=1, get=function() return addon.db.profile.bags.x_position end, set=function(_,v) addon.db.profile.bags.x_position=v; if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end end },
    y_position = { type='range', order=4, name='Y Position', min=-200,max=200,step=1, get=function() return addon.db.profile.bags.y_position end, set=function(_,v) addon.db.profile.bags.y_position=v; if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end end },
    reset_position = { type='execute', order=5, name='Reset Position', func=function()
      local d={ scale=0.9, x_position=1, y_position=41 }
      for k,v in pairs(d) do addon.db.profile.bags[k]=v end
      if addon.RefreshBagsPosition then addon.RefreshBagsPosition() end
    end },
  }}
end

local function Build()
  return { type='group', name='Micro/Bags', order=2, childGroups='tree', args = { micromenu = MicroMenu(), bags = Bags() } }
end

addon:RegisterOptionsSection('micromenu_bags', 2, Build)

