local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers or {}
local set = H.createSetFunction or function() return function() end end

local function BuildXpRepOptions()
    return {
        type='group', name = "XP & Rep Bars", order = 6, args = {
            bothbar_offset = { type='range', name="Both Bars Offset", desc="Y offset when XP & reputation bar are shown", min=0, max=100, step=1,
                get=function() return addon.db.profile.xprepbar.bothbar_offset end, set=set('xprepbar','bothbar_offset',nil,'RefreshXpRepBarPosition'), order=1 },
            singlebar_offset = { type='range', name="Single Bar Offset", desc="Y offset when XP or reputation bar is shown", min=0, max=100, step=1,
                get=function() return addon.db.profile.xprepbar.singlebar_offset end, set=set('xprepbar','singlebar_offset',nil,'RefreshXpRepBarPosition'), order=2 },
            nobar_offset = { type='range', name="No Bar Offset", desc="Y offset when no XP or reputation bar is shown", min=0, max=100, step=1,
                get=function() return addon.db.profile.xprepbar.nobar_offset end, set=set('xprepbar','nobar_offset',nil,'RefreshXpRepBarPosition'), order=3 },
            repbar_abovexp_offset = { type='range', name="Rep Bar Above XP Offset", desc="Y offset for reputation bar when XP bar is shown", min=0, max=50, step=1,
                get=function() return addon.db.profile.xprepbar.repbar_abovexp_offset end, set=set('xprepbar','repbar_abovexp_offset',nil,'RefreshRepBarPosition'), order=4 },
            repbar_offset = { type='range', name="Rep Bar Offset", desc="Y offset when XP bar is not shown", min=0, max=50, step=1,
                get=function() return addon.db.profile.xprepbar.repbar_offset end, set=set('xprepbar','repbar_offset',nil,'RefreshRepBarPosition'), order=5 },
        }
    }
end

addon:RegisterOptionsSection('xprepbar', 6, BuildXpRepOptions)

