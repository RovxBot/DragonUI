local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers; local set = H and H.createSetFunction or function() return function() end end

local function XpRep()
  return { type='group', name='XP & Rep Bars', order=6, args = {
    bothbar_offset = { type='range', order=1, name='Both Bars Offset', desc='Y offset when XP & reputation bar are shown', min=0,max=100,step=1, get=function() return addon.db.profile.xprepbar.bothbar_offset end, set=set('xprepbar','bothbar_offset',nil,'RefreshXpRepBarPosition') },
    singlebar_offset = { type='range', order=2, name='Single Bar Offset', desc='Y offset when XP or reputation bar is shown', min=0,max=100,step=1, get=function() return addon.db.profile.xprepbar.singlebar_offset end, set=set('xprepbar','singlebar_offset',nil,'RefreshXpRepBarPosition') },
    nobar_offset = { type='range', order=3, name='No Bar Offset', desc='Y offset when no XP or reputation bar is shown', min=0,max=100,step=1, get=function() return addon.db.profile.xprepbar.nobar_offset end, set=set('xprepbar','nobar_offset',nil,'RefreshXpRepBarPosition') },
    repbar_abovexp_offset = { type='range', order=4, name='Rep Bar Above XP Offset', desc='Y offset for reputation bar when XP bar is shown', min=0,max=50,step=1, get=function() return addon.db.profile.xprepbar.repbar_abovexp_offset end, set=set('xprepbar','repbar_abovexp_offset',nil,'RefreshRepBarPosition') },
    repbar_offset = { type='range', order=5, name='Rep Bar Offset', desc='Y offset when XP bar is not shown', min=0,max=50,step=1, get=function() return addon.db.profile.xprepbar.repbar_offset end, set=set('xprepbar','repbar_offset',nil,'RefreshRepBarPosition') },
  }}
end

local function Gryphons()
  return { type='group', name='Gryphons', order=7, args = {
    gryphons = { type='select', order=1, name='Gryphon Style', desc='Display style for the action bar end-cap gryphons.', values=function() local order={'old','new','flying','none'} local labels={ old='Old', new='New', flying='Flying', none='Hide Gryphons' } local t={} for _,k in ipairs(order) do t[k]=labels[k] end return t end,
      get=function() return addon.db.profile.style.gryphons end, set=function(_,v) addon.db.profile.style.gryphons=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
    gryphon_previews = { type='description', order=2, name = "|cffFFD700Old|r:      |TInterface\\AddOns\\DragonUI\\assets\\uiactionbar2x_:96:96:0:0:512:2048:1:357:209:543|t |TInterface\\AddOns\\DragonUI\\media\\uiactionbar2x_:96:96:0:0:512:2048:1:357:545:879|t\n" ..
      "|cffFFD700New|r:      |TInterface\\AddOns\\DragonUI\\assets\\uiactionbar2x_new:96:96:0:0:512:2048:1:357:209:543|t |TInterface\\AddOns\\DragonUI\\media\\uiactionbar2x_new:96:96:0:0:512:2048:1:357:545:879|t\n" ..
      "|cffFFD700Flying|r: |TInterface\\AddOns\\DragonUI\\assets\\uiactionbar2x_flying:105:105:0:0:256:2048:1:158:149:342|t |TInterface\\AddOns\\DragonUI\\media\\uiactionbar2x_flying:105:105:0:0:256:2048:1:157:539:732|t" },
  }}
end

local function Build()
  return { type='group', name='Bars Style', order=6, childGroups='tree', args = { xprepbar = XpRep(), gryphons = Gryphons() } }
end

addon:RegisterOptionsSection('xprepbar_gryphons', 6, Build)

