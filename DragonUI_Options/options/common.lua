local addon = _G.DragonUI_Addon

-- Shared UI bits used across option panes
-- Define the reload dialog used by various settings
StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["DRAGONUI_RELOAD_UI"] = {
    text = "Changing this setting requires a UI reload to apply correctly.",
    button1 = "Reload UI",
    button2 = "Not Now",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

