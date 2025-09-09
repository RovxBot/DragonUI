local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers or {}
local set = H.createSetFunction or function() return function() end end

local function BuildChatOptions()
    return {
        type='group', name = "Chat", order = 12, args = {
            enabled = { type='toggle', name = "Enable Custom Chat", desc = "Enable/disable custom chat positioning and sizing. When disabled, restores original WoW chat.",
                get=function() return addon.db.profile.chat.enabled end, set=set('chat','enabled',nil,'RefreshChat'), order=1 },
            header1 = { type='header', name = "Position Settings", order=10 },
            x_position = { type='range', name = "X Position", desc = "X position relative to bottom left corner", min=0, max=1000, step=1,
                get=function() return addon.db.profile.chat.x_position end, set=set('chat','x_position',nil,'RefreshChat'), order=11, disabled=function() return not addon.db.profile.chat.enabled end },
            y_position = { type='range', name = "Y Position", desc = "Y position relative to bottom left corner", min=0, max=1000, step=1,
                get=function() return addon.db.profile.chat.y_position end, set=set('chat','y_position',nil,'RefreshChat'), order=12, disabled=function() return not addon.db.profile.chat.enabled end },
            header2 = { type='header', name = "Size Settings", order=20 },
            size_x = { type='range', name = "Width", desc = "Chat frame width", min=200, max=800, step=1,
                get=function() return addon.db.profile.chat.size_x end, set=set('chat','size_x',nil,'RefreshChat'), order=21, disabled=function() return not addon.db.profile.chat.enabled end },
            size_y = { type='range', name = "Height", desc = "Chat frame height", min=100, max=500, step=1,
                get=function() return addon.db.profile.chat.size_y end, set=set('chat','size_y',nil,'RefreshChat'), order=22, disabled=function() return not addon.db.profile.chat.enabled end },
            scale = { type='range', name = "Scale", desc = "Chat frame scale", min=0.5, max=2.0, step=0.1,
                get=function() return addon.db.profile.chat.scale end, set=set('chat','scale',nil,'RefreshChat'), order=23, disabled=function() return not addon.db.profile.chat.enabled end },
        }
    }
end

addon:RegisterOptionsSection('chat', 12, BuildChatOptions)

