local addon = _G.DragonUI_Addon

local function BuildGryphonsOptions()
    return {
        type='group', name = "Gryphons", order = 7, args = {
            gryphons = { type='select', name = "Gryphon Style", desc = "Display style for the action bar end-cap gryphons.",
                values = function()
                    local order = {'old','new','flying','none'}
                    local labels = { old="Old", new="New", flying="Flying", none="Hide Gryphons" }
                    local t = {}; for _,k in ipairs(order) do t[k]=labels[k] end; return t
                end,
                get=function() return addon.db.profile.style.gryphons end,
                set=function(_,v) addon.db.profile.style.gryphons=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end,
                order=1 },
            spacer = { type='description', name = " ", order = 1.5 },
            gryphon_previews = { type='description', order=2, name = "|cffFFD700Old|r:      |TInterface\\AddOns\\DragonUI\\assets\\uiactionbar2x_:96:96:0:0:512:2048:1:357:209:543|t |TInterface\\AddOns\\DragonUI\\media\\uiactionbar2x_:96:96:0:0:512:2048:1:357:545:879|t\n" ..
                "|cffFFD700New|r:      |TInterface\\AddOns\\DragonUI\\assets\\uiactionbar2x_new:96:96:0:0:512:2048:1:357:209:543|t |TInterface\\AddOns\\DragonUI\\media\\uiactionbar2x_new:96:96:0:0:512:2048:1:357:545:879|t\n" ..
                "|cffFFD700Flying|r: |TInterface\\AddOns\\DragonUI\\assets\\uiactionbar2x_flying:105:105:0:0:256:2048:1:158:149:342|t |TInterface\\AddOns\\DragonUI\\media\\uiactionbar2x_flying:105:105:0:0:256:2048:1:157:539:732|t" },
        }
    }
end

addon:RegisterOptionsSection('gryphons', 7, BuildGryphonsOptions)

