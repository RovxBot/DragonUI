local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers; local set = H and H.createSetFunction or function() return function() end end

local function QuestTracker()
  return { type='group', name='Quest Tracker', order=9, args = {
    info_text = { type='description', order=1, name='Quest Tracker Position:\nAdjust the position of the quest tracker window to avoid overlapping with the minimap or other UI elements.\n\nTip: Changes apply immediately - no reload required!' },
    spacer1 = { type='description', order=2, name=' ' },
    quest_tracker_x = { type='range', order=3, name='Horizontal Position (X)', desc='Horizontal position of quest tracker\n• Negative values = more to the left\n• Positive values = more to the right', min=-400,max=200,step=5, get=function() return addon.db.profile.map.quest_tracker_x end, set=function(_,v) addon.db.profile.map.quest_tracker_x=v; if addon.RefreshQuestTrackerPosition then addon.RefreshQuestTrackerPosition() end end },
    quest_tracker_y = { type='range', order=4, name='Vertical Position (Y)', desc='Vertical position of quest tracker\n• Negative values = more down\n• Positive values = more up', min=-600,max=200,step=5, get=function() return addon.db.profile.map.quest_tracker_y end, set=function(_,v) addon.db.profile.map.quest_tracker_y=v; if addon.RefreshQuestTrackerPosition then addon.RefreshQuestTrackerPosition() end end },
    spacer2 = { type='description', order=5, name=' ' },
    reset_position = { type='execute', order=6, name='Reset to Default Position', desc='Reset quest tracker to the default position (-115, -250)', func=function() addon.db.profile.map.quest_tracker_x=-115; addon.db.profile.map.quest_tracker_y=-250; if addon.RefreshQuestTrackerPosition then addon.RefreshQuestTrackerPosition() end end },
  }}
end

local function Minimap()
  return { type='group', name='Minimap', order=10, args = {
    scale = { type='range', order=1, name='Minimap Scale', desc="Minimap scale (don't increase too much)", min=0.5,max=2.0,step=0.05, get=function() return addon.db.profile.map.scale end, set=set('map','scale',nil,'RefreshMinimap') },
    border_alpha = { type='range', order=2, name='Border Alpha', desc='Top border alpha (0 to hide)', min=0,max=1,step=0.1, get=function() return addon.db.profile.map.border_alpha end, set=set('map','border_alpha',nil,'RefreshMinimap') },
    blip_skin = { type='toggle', order=3, name='New Blip Style', desc='New style for object icons', get=function() return addon.db.profile.map.blip_skin end, set=set('map','blip_skin',nil,'RefreshMinimap') },
    player_arrow_size = { type='range', order=4, name='Player Arrow Size', desc='Player arrow on minimap center', min=20,max=80,step=1, get=function() return addon.db.profile.map.player_arrow_size end, set=set('map','player_arrow_size',nil,'RefreshMinimap') },
    tracking_icons = { type='toggle', order=5, name='Tracking Icons', desc='Show current tracking icons (old style)', get=function() return addon.db.profile.map.tracking_icons end, set=set('map','tracking_icons',nil,'RefreshMinimap') },
    skin_button = { type='toggle', order=6, name='Skin Buttons', get=function() return addon.db.profile.map.skin_button end, set=set('map','skin_button',nil,'RefreshMinimap') },
    auras_x_offset = { type='range', order=10.1, name='Auras Horizontal Offset', min=-500,max=500,step=1, desc='Adjusts the horizontal position of the buffs/debuffs block next to the minimap.', get=function() local t=addon.db.profile.map; t.auras=t.auras or { x_offset=0,y_offset=0 }; return t.auras.x_offset end, set=function(_,v) local t=addon.db.profile.map; t.auras=t.auras or {}; t.auras.x_offset=v; if addon.RefreshMinimap then addon.RefreshMinimap() end end },
    auras_y_offset = { type='range', order=10.2, name='Auras Vertical Offset', min=-500,max=500,step=1, desc='Adjusts the vertical position of the buffs/debuffs block next to the minimap.', get=function() local t=addon.db.profile.map; t.auras=t.auras or { x_offset=0,y_offset=0 }; return t.auras.y_offset end, set=function(_,v) local t=addon.db.profile.map; t.auras=t.auras or {}; t.auras.y_offset=v; if addon.RefreshMinimap then addon.RefreshMinimap() end end },
  }}
end

local function Times()
  return { type='group', name='Time & Calendar', order=11, args = {
    clock = { type='toggle', order=1, name='Show Clock', get=function() return addon.db.profile.times.clock end, set=set('times','clock',nil,'RefreshMinimapTime') },
    calendar = { type='toggle', order=2, name='Show Calendar', get=function() return addon.db.profile.times.calendar end, set=set('times','calendar',nil,'RefreshMinimapTime') },
    clock_font_size = { type='range', order=3, name='Clock Font Size', desc='Clock numbers size', min=8,max=20,step=1, get=function() return addon.db.profile.times.clock_font_size end, set=set('times','clock_font_size',nil,'RefreshMinimapTime') },
  }}
end

local function Build()
  return { type='group', name='Map/Time', order=9, childGroups='tree', args = { questtracker = QuestTracker(), minimap = Minimap(), times = Times() } }
end

addon:RegisterOptionsSection('quest_minimap_times', 9, Build)

