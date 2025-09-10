local addon = _G.DragonUI_Addon

local function BuildGeneralOptions()
    return {
        type = 'group',
        name = "General",
        order = 0,
        args = {
            toggle_editor_mode = {
                type = 'execute',
                name = function()
                    if addon.EditorMode and addon.EditorMode:IsActive() then
                        return "|cffFF6347Editor Mode Active|r"
                    else
                        return "|cff00FF00Move UI Elements|r"
                    end
                end,
                desc = "Unlock UI elements to move them with your mouse. A button will appear to exit this mode.",
                func = function()
                    GameTooltip:Hide()
                    LibStub("AceConfigDialog-3.0"):Close("DragonUI")
                    if addon.EditorMode then addon.EditorMode:Toggle() end
                end,
                disabled = function()
                    return addon.EditorMode and addon.EditorMode:IsActive()
                end,
                order = 0
            },
            editor_separator = { type = 'header', name = ' ', order = 0.5 },
        }
    }
end

addon:RegisterOptionsSection('general', 0, BuildGeneralOptions)

