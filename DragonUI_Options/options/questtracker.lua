local addon = _G.DragonUI_Addon

local function BuildQuestTrackerOptions()
    return {
        type='group', name = "Quest Tracker", desc = "Configure the position and behavior of the quest tracker", order = 9,
        args = {
            info_text = { type='description', order=1, name = "Quest Tracker Position:\nAdjust the position of the quest tracker window to avoid overlapping with the minimap or other UI elements.\n\nTip: Changes apply immediately - no reload required!" },
            spacer1 = { type='description', name = " ", order=2 },
            quest_tracker_x = { type='range', name = "Horizontal Position (X)", desc = "Horizontal position of quest tracker\n• Negative values = more to the left\n• Positive values = more to the right", min=-400, max=200, step=5,
                get=function() return addon.db.profile.map.quest_tracker_x end,
                set=function(_,v) addon.db.profile.map.quest_tracker_x=v; if addon.RefreshQuestTrackerPosition then addon.RefreshQuestTrackerPosition() end end,
                order=3 },
            quest_tracker_y = { type='range', name = "Vertical Position (Y)", desc = "Vertical position of quest tracker\n• Negative values = more down\n• Positive values = more up", min=-600, max=200, step=5,
                get=function() return addon.db.profile.map.quest_tracker_y end,
                set=function(_,v) addon.db.profile.map.quest_tracker_y=v; if addon.RefreshQuestTrackerPosition then addon.RefreshQuestTrackerPosition() end end,
                order=4 },
            spacer2 = { type='description', name = " ", order=5 },
            reset_position = { type='execute', name = "Reset to Default Position", desc = "Reset quest tracker to the default position (-115, -250)",
                func=function() addon.db.profile.map.quest_tracker_x=-115; addon.db.profile.map.quest_tracker_y=-250; if addon.RefreshQuestTrackerPosition then addon.RefreshQuestTrackerPosition() end end,
                order=6 },
        }
    }
end

addon:RegisterOptionsSection('questtracker', 9, BuildQuestTrackerOptions)

