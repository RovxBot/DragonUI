local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers or {}
local set = H.createSetFunction or function() return function() end end

local function BuildTimeOptions()
    return {
        type='group', name = "Time & Calendar", order = 11, args = {
            clock = { type='toggle', name = "Show Clock", get=function() return addon.db.profile.times.clock end, set=set('times','clock',nil,'RefreshMinimapTime'), order=1 },
            calendar = { type='toggle', name = "Show Calendar", get=function() return addon.db.profile.times.calendar end, set=set('times','calendar',nil,'RefreshMinimapTime'), order=2 },
            clock_font_size = { type='range', name = "Clock Font Size", desc = "Clock numbers size", min=8, max=20, step=1,
                get=function() return addon.db.profile.times.clock_font_size end, set=set('times','clock_font_size',nil,'RefreshMinimapTime'), order=3 },
        }
    }
end

addon:RegisterOptionsSection('times', 11, BuildTimeOptions)

