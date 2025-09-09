local addon = select(2, ...);

-- Define the reload dialog
StaticPopupDialogs["DRAGONUI_RELOAD_UI"] = {
    text = "Changing this setting requires a UI reload to apply correctly.",
    button1 = "Reload UI",
    button2 = "Not Now",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3
};


-- Helper function to create set functions with automatic refresh
-- Uses throttling to reduce scroll reset issues
local refreshThrottle = {}
local function createSetFunction(section, key, subkey, refreshFunctions)
    return function(info, val)
        if subkey then
            -- Ensure the parent table exists and is actually a table
            if not addon.db.profile[section][key] or type(addon.db.profile[section][key]) ~= "table" then
                addon.db.profile[section][key] = {}
            end
            addon.db.profile[section][key][subkey] = val;
        else
            addon.db.profile[section][key] = val;
        end
        if refreshFunctions then
            -- Throttle refresh calls to reduce UI resets
            local throttleKey = refreshFunctions
            if refreshThrottle[throttleKey] then
                return -- Skip if already scheduled
            end
            refreshThrottle[throttleKey] = true

            -- Use a simple frame-based delay
            local frame = CreateFrame("Frame")
            local elapsed = 0
            frame:SetScript("OnUpdate", function(self, dt)
                elapsed = elapsed + dt
                if elapsed >= 0.1 then -- 100ms delay
                    frame:SetScript("OnUpdate", nil)
                    refreshThrottle[throttleKey] = nil

                    -- Handle multiple refresh functions separated by spaces
                    for refreshFunc in refreshFunctions:gmatch("%S+") do
                        if addon[refreshFunc] then
                            addon[refreshFunc]();
                        end
                    end
                end
            end)
        end
    end
end

-- Helper function for instant refresh (no throttling) for real-time feedback
local function createInstantSetFunction(section, key, subkey, refreshFunction)
    return function(info, val)
        if subkey then
            -- Ensure the parent table exists and is actually a table
            if not addon.db.profile[section][key] or type(addon.db.profile[section][key]) ~= "table" then
                addon.db.profile[section][key] = {}
            end
            addon.db.profile[section][key][subkey] = val;
        else
            addon.db.profile[section][key] = val;
        end
        if refreshFunction and addon[refreshFunction] then
            addon[refreshFunction]();
        end
    end
end

-- Helper for color set functions
local function createColorSetFunction(section, key, subkey, refreshFunctions)
    return function(info, r, g, b, a)
        if subkey then
            addon.db.profile[section][key][subkey] = {r, g, b, a or 1};
        else
            addon.db.profile[section][key] = {r, g, b, a or 1};
        end
        if refreshFunctions then
            -- Use the same throttled refresh as createSetFunction
            local throttleKey = refreshFunctions
            if refreshThrottle[throttleKey] then
                return
            end
            refreshThrottle[throttleKey] = true

            local frame = CreateFrame("Frame")
            local elapsed = 0
            frame:SetScript("OnUpdate", function(self, dt)
                elapsed = elapsed + dt
                if elapsed >= 0.1 then
                    frame:SetScript("OnUpdate", nil)
                    refreshThrottle[throttleKey] = nil

                    for refreshFunc in refreshFunctions:gmatch("%S+") do
                        if addon[refreshFunc] then
                            addon[refreshFunc]();
                        end
                    end
                end
            end)
        end
    end
end

-- Function to create configuration options (called after DB is ready)
function addon:CreateOptionsTable()
    return {
        name = "DragonUI",
        type = 'group',
        args = {
            -- ✅ BOTÓN PARA ACTIVAR EL MODO DE EDICIÓN
            toggle_editor_mode = {
                type = 'execute',
                name = function()
                    -- El nombre del botón cambia dinámicamente
                    if addon.EditorMode and addon.EditorMode:IsActive() then
                        return "|cffFF6347Editor Mode Active|r"
                    else
                        return "|cff00FF00Move UI Elements|r"
                    end
                end,
                desc = "Unlock UI elements to move them with your mouse. A button will appear to exit this mode.",
                func = function()
                   -- ✅ CORRECCIÓN 3: Ocultar el tooltip para que no se quede pegado.
                    GameTooltip:Hide()
                    
                    -- Usar la función de la librería para cerrar su propia ventana.
                    LibStub("AceConfigDialog-3.0"):Close("DragonUI")
                    
                    -- Llama a la función Toggle del editor_mode.lua
                    if addon.EditorMode then
                        addon.EditorMode:Toggle()
                    end
                end,
                -- Se deshabilita mientras el modo editor está activo para evitar conflictos
                disabled = function()
                    return addon.EditorMode and addon.EditorMode:IsActive()
                end,
                order = 0 -- El orden más bajo para que aparezca primero
            },
            -- ✅ SEPARADOR VISUAL
            editor_separator = {
                type = 'header',
                name = ' ', -- Un espacio en blanco actúa como separador
                order = 0.5
            },
            actionbars = {
                type = 'group',
                name = "Action Bars",
                order = 1,
                args = {
                    -- ========================================
                    -- ✅ QUICK SETUP SECTION
                    -- ========================================
                    quicksetup = {
                        type = 'group',
                        name = "Quick Setup",
                        inline = true,
                        order = 0.1,
                        args = {
                            desc_quicksetup = {
                                type = 'description',
                                name = "|cffFFD700Quick Actions:|r Get started with common action bar configurations.",
                                order = 1
                            },
                            enable_all_bars = {
                                type = 'execute',
                                name = "Enable All Action Bars",
                                desc = "Enable all action bars at once for maximum hotkey availability",
                                func = function()
                                    addon.db.profile.actionbars.bottom_left_enabled = true
                                    addon.db.profile.actionbars.bottom_right_enabled = true
                                    addon.db.profile.actionbars.right_enabled = true
                                    addon.db.profile.actionbars.right2_enabled = true
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                    print("DragonUI: All action bars enabled!")
                                end,
                                order = 2
                            },
                            disable_all_bars = {
                                type = 'execute',
                                name = "Disable All Secondary Bars",
                                desc = "Disable all secondary action bars (keeps only main bar visible)",
                                func = function()
                                    addon.db.profile.actionbars.bottom_left_enabled = false
                                    addon.db.profile.actionbars.bottom_right_enabled = false
                                    addon.db.profile.actionbars.right_enabled = false
                                    addon.db.profile.actionbars.right2_enabled = false
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                    print("DragonUI: All secondary action bars disabled!")
                                end,
                                order = 3
                            }
                        }
                    },

                    -- ========================================
                    -- ✅ ACTION BAR VISIBILITY TOGGLES
                    -- ========================================
                    visibility = {
                        type = 'group',
                        name = "Individual Bar Visibility",
                        inline = true,
                        order = 0.5,
                        args = {
                            header_visibility = {
                                type = 'header',
                                name = "Enable/Disable Action Bars",
                                order = 1
                            },
                            desc_visibility = {
                                type = 'description',
                                name = "Control which action bars are shown. These work alongside Blizzard's built-in action bar toggles.",
                                order = 1.1
                            },
                            bottom_left_enabled = {
                                type = 'toggle',
                                name = "Bottom Left Bar",
                                desc = "Show/hide the bottom left action bar (MultiBarBottomLeft)",
                                get = function()
                                    return addon.db.profile.actionbars.bottom_left_enabled
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.bottom_left_enabled = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 2,
                                width = "half"
                            },
                            bottom_right_enabled = {
                                type = 'toggle',
                                name = "Bottom Right Bar",
                                desc = "Show/hide the bottom right action bar (MultiBarBottomRight)",
                                get = function()
                                    return addon.db.profile.actionbars.bottom_right_enabled
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.bottom_right_enabled = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 3,
                                width = "half"
                            },
                            right_enabled = {
                                type = 'toggle',
                                name = "Right Bar",
                                desc = "Show/hide the right action bar (MultiBarRight)",
                                get = function()
                                    return addon.db.profile.actionbars.right_enabled
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.right_enabled = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 4,
                                width = "half"
                            },
                            right2_enabled = {
                                type = 'toggle',
                                name = "Right Bar 2",
                                desc = "Show/hide the second right action bar (MultiBarLeft)",
                                get = function()
                                    return addon.db.profile.actionbars.right2_enabled
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.right2_enabled = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 5,
                                width = "half"
                            }
                        }
                    },

                    -- ========================================
                    -- ✅ VISIBILITY BEHAVIOR OPTIONS
                    -- ========================================
                    visibility_behavior = {
                        type = 'group',
                        name = "Visibility Behavior",
                        inline = true,
                        order = 0.7,
                        args = {
                            desc_visibility_behavior = {
                                type = 'description',
                                name = "|cffFFD700Advanced Visibility Options:|r Control when action bars are shown based on mouse hover and combat state.",
                                order = 1
                            },

                            -- Main Action Bar
                            header_main_visibility = {
                                type = 'header',
                                name = "Main Action Bar",
                                order = 2
                            },
                            main_show_on_hover = {
                                type = 'toggle',
                                name = "Show on Hover Only",
                                desc = "Main action bar will only be visible when you hover over it",
                                get = function()
                                    return addon.db.profile.actionbars.main_show_on_hover
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.main_show_on_hover = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 3,
                                width = "half"
                            },
                            main_show_in_combat = {
                                type = 'toggle',
                                name = "Show in Combat Only",
                                desc = "Main action bar will only be visible during combat",
                                get = function()
                                    return addon.db.profile.actionbars.main_show_in_combat
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.main_show_in_combat = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 4,
                                width = "half"
                            },

                            -- Bottom Left Bar
                            header_bottom_left_visibility = {
                                type = 'header',
                                name = "Bottom Left Bar",
                                order = 5
                            },
                            bottom_left_show_on_hover = {
                                type = 'toggle',
                                name = "Show on Hover Only",
                                desc = "Bottom left bar will only be visible when you hover over it",
                                get = function()
                                    return addon.db.profile.actionbars.bottom_left_show_on_hover
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.bottom_left_show_on_hover = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 6,
                                width = "half"
                            },
                            bottom_left_show_in_combat = {
                                type = 'toggle',
                                name = "Show in Combat Only",
                                desc = "Bottom left bar will only be visible during combat",
                                get = function()
                                    return addon.db.profile.actionbars.bottom_left_show_in_combat
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.bottom_left_show_in_combat = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 7,
                                width = "half"
                            },

                            -- Bottom Right Bar
                            header_bottom_right_visibility = {
                                type = 'header',
                                name = "Bottom Right Bar",
                                order = 8
                            },
                            bottom_right_show_on_hover = {
                                type = 'toggle',
                                name = "Show on Hover Only",
                                desc = "Bottom right bar will only be visible when you hover over it",
                                get = function()
                                    return addon.db.profile.actionbars.bottom_right_show_on_hover
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.bottom_right_show_on_hover = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 9,
                                width = "half"
                            },
                            bottom_right_show_in_combat = {
                                type = 'toggle',
                                name = "Show in Combat Only",
                                desc = "Bottom right bar will only be visible during combat",
                                get = function()
                                    return addon.db.profile.actionbars.bottom_right_show_in_combat
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.bottom_right_show_in_combat = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 10,
                                width = "half"
                            },

                            -- Right Bar
                            header_right_visibility = {
                                type = 'header',
                                name = "Right Bar",
                                order = 11
                            },
                            right_show_on_hover = {
                                type = 'toggle',
                                name = "Show on Hover Only",
                                desc = "Right bar will only be visible when you hover over it",
                                get = function()
                                    return addon.db.profile.actionbars.right_show_on_hover
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.right_show_on_hover = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 12,
                                width = "half"
                            },
                            right_show_in_combat = {
                                type = 'toggle',
                                name = "Show in Combat Only",
                                desc = "Right bar will only be visible during combat",
                                get = function()
                                    return addon.db.profile.actionbars.right_show_in_combat
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.right_show_in_combat = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 13,
                                width = "half"
                            },

                            -- Right Bar 2
                            header_right2_visibility = {
                                type = 'header',
                                name = "Right Bar 2",
                                order = 14
                            },
                            right2_show_on_hover = {
                                type = 'toggle',
                                name = "Show on Hover Only",
                                desc = "Right bar 2 will only be visible when you hover over it",
                                get = function()
                                    return addon.db.profile.actionbars.right2_show_on_hover
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.right2_show_on_hover = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 15,
                                width = "half"
                            },
                            right2_show_in_combat = {
                                type = 'toggle',
                                name = "Show in Combat Only",
                                desc = "Right bar 2 will only be visible during combat",
                                get = function()
                                    return addon.db.profile.actionbars.right2_show_in_combat
                                end,
                                set = function(_, value)
                                    addon.db.profile.actionbars.right2_show_in_combat = value
                                    if addon.RefreshActionBarVisibility then
                                        addon.RefreshActionBarVisibility()
                                    end
                                end,
                                order = 16,
                                width = "half"
                            }
                        }
                    },

                    mainbars = {
                        type = 'group',
                        name = "Action Bar Configuration",
                        inline = true,
                        order = 1,
                        args = {
                            -- ========================================
                            -- ✅ ACTION BAR SCALING OPTIONS
                            -- ========================================
                            header_scaling = {
                                type = 'header',
                                name = "Action Bar Scaling",
                                order = 0.5
                            },
                            scale_actionbar = {
                                type = 'range',
                                name = "Main Bar Scale",
                                desc = "Scale for main action bar",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.mainbars.scale_actionbar
                                end,
                                set = createSetFunction("mainbars", "scale_actionbar", nil, "RefreshMainbars"),
                                order = 1
                            },
                            scale_bottom_left = {
                                type = 'range',
                                name = "Bottom Left Bar Scale",
                                desc = "Scale for bottom left action bar",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.mainbars.scale_bottom_left
                                end,
                                set = createSetFunction("mainbars", "scale_bottom_left", nil, "RefreshMainbars"),
                                order = 1.1
                            },
                            scale_bottom_right = {
                                type = 'range',
                                name = "Bottom Right Bar Scale",
                                desc = "Scale for bottom right action bar",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.mainbars.scale_bottom_right
                                end,
                                set = createSetFunction("mainbars", "scale_bottom_right", nil, "RefreshMainbars"),
                                order = 1.2
                            },
                            scale_rightbar = {
                                type = 'range',
                                name = "Right Bar Scale",
                                desc = "Scale for right action bar",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.mainbars.scale_rightbar
                                end,
                                set = createSetFunction("mainbars", "scale_rightbar", nil, "RefreshMainbars"),
                                order = 1.3
                            },
                            scale_leftbar = {
                                type = 'range',
                                name = "Right Bar 2 Scale",
                                desc = "Scale for second right action bar (MultiBarLeft)",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.mainbars.scale_leftbar
                                end,
                                set = createSetFunction("mainbars", "scale_leftbar", nil, "RefreshMainbars"),
                                order = 1.4
                            },
                            scale_stance = {
                                type = 'range',
                                name = "Stance Bar Scale",
                                desc = "Scale for stance/shapeshift bar",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.mainbars.scale_stance
                                end,
                                set = createSetFunction("mainbars", "scale_stance", nil, "RefreshStance"),
                                order = 1.5
                            },

                            -- ========================================
                            -- ✅ MAIN BAR LAYOUT CONFIGURATION
                            -- ========================================
                            header_layout = {
                                type = 'header',
                                name = "Main Action Bar Layout",
                                order = 1.5
                            },
                            player_rows = {
                                type = 'range',
                                name = "Rows",
                                desc = "Number of rows for the main action bar (1-4)",
                                min = 1,
                                max = 4,
                                step = 1,
                                get = function()
                                    return addon.db.profile.mainbars.player.rows or 1
                                end,
                                set = function(info, value)
                                    addon.db.profile.mainbars.player.rows = value
                                    -- Ensure we have enough slots for visible buttons
                                    local columns = addon.db.profile.mainbars.player.columns or 12
                                    local buttonsShown = addon.db.profile.mainbars.player.buttons_shown or 12
                                    if value * columns < buttonsShown then
                                        addon.db.profile.mainbars.player.buttons_shown = value * columns
                                    end
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 2
                            },
                            player_columns = {
                                type = 'range',
                                name = "Columns",
                                desc = "Number of columns for the main action bar (1-12)",
                                min = 1,
                                max = 12,
                                step = 1,
                                get = function()
                                    return addon.db.profile.mainbars.player.columns or 12
                                end,
                                set = function(info, value)
                                    addon.db.profile.mainbars.player.columns = value
                                    -- Ensure we have enough slots for visible buttons
                                    local rows = addon.db.profile.mainbars.player.rows or 1
                                    local buttonsShown = addon.db.profile.mainbars.player.buttons_shown or 12
                                    if rows * value < buttonsShown then
                                        addon.db.profile.mainbars.player.buttons_shown = rows * value
                                    end
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 3
                            },
                            player_buttons_shown = {
                                type = 'range',
                                name = "Buttons Shown",
                                desc = "Number of buttons to display (1-12)",
                                min = 1,
                                max = 12,
                                step = 1,
                                get = function()
                                    return addon.db.profile.mainbars.player.buttons_shown or 12
                                end,
                                set = function(info, value)
                                    local rows = addon.db.profile.mainbars.player.rows or 1
                                    local columns = addon.db.profile.mainbars.player.columns or 12
                                    -- Ensure we don't exceed available slots
                                    if value > rows * columns then
                                        value = rows * columns
                                    end
                                    addon.db.profile.mainbars.player.buttons_shown = value
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 4
                            },

                            -- Layout presets
                            header_presets = {
                                type = 'header',
                                name = "Layout Presets",
                                order = 4.5
                            },
                            preset_reset = {
                                type = 'execute',
                                name = "Reset to Default (1x12)",
                                desc = "Reset main bar to default single row layout",
                                func = function()
                                    addon.db.profile.mainbars.player.rows = 1
                                    addon.db.profile.mainbars.player.columns = 12
                                    addon.db.profile.mainbars.player.buttons_shown = 12
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 4.8
                            },
                            preset_single_row = {
                                type = 'execute',
                                name = "Single Row (1x12)",
                                desc = "Set main bar to single row layout",
                                func = function()
                                    addon.db.profile.mainbars.player.rows = 1
                                    addon.db.profile.mainbars.player.columns = 12
                                    addon.db.profile.mainbars.player.buttons_shown = 12
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 5
                            },
                            preset_double_row = {
                                type = 'execute',
                                name = "Double Row (2x6)",
                                desc = "Set main bar to double row layout",
                                func = function()
                                    addon.db.profile.mainbars.player.rows = 2
                                    addon.db.profile.mainbars.player.columns = 6
                                    addon.db.profile.mainbars.player.buttons_shown = 12
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 6
                            },
                            preset_triple_row = {
                                type = 'execute',
                                name = "Triple Row (3x4)",
                                desc = "Set main bar to triple row layout",
                                func = function()
                                    addon.db.profile.mainbars.player.rows = 3
                                    addon.db.profile.mainbars.player.columns = 4
                                    addon.db.profile.mainbars.player.buttons_shown = 12
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 7
                            },
                            preset_quad_row = {
                                type = 'execute',
                                name = "Quad Row (4x3)",
                                desc = "Set main bar to quad row layout (your preference!)",
                                func = function()
                                    addon.db.profile.mainbars.player.rows = 4
                                    addon.db.profile.mainbars.player.columns = 3
                                    addon.db.profile.mainbars.player.buttons_shown = 12
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 8
                            },

                            -- ========================================
                            -- ✅ LEFT BAR LAYOUT CONFIGURATION
                            -- ========================================
                            header_left_layout = {
                                type = 'header',
                                name = "Left Action Bar Layout",
                                order = 8.5
                            },
                            left_rows = {
                                type = 'range',
                                name = "Left Bar Rows",
                                desc = "Number of rows for the left action bar (1-4)",
                                min = 1,
                                max = 4,
                                step = 1,
                                get = function()
                                    return addon.db.profile.mainbars.left.rows or 1
                                end,
                                set = function(info, value)
                                    addon.db.profile.mainbars.left.rows = value
                                    local columns = addon.db.profile.mainbars.left.columns or 12
                                    local buttonsShown = addon.db.profile.mainbars.left.buttons_shown or 12
                                    if value * columns < buttonsShown then
                                        addon.db.profile.mainbars.left.buttons_shown = value * columns
                                    end
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 9
                            },
                            left_columns = {
                                type = 'range',
                                name = "Left Bar Columns",
                                desc = "Number of columns for the left action bar (1-12)",
                                min = 1,
                                max = 12,
                                step = 1,
                                get = function()
                                    return addon.db.profile.mainbars.left.columns or 12
                                end,
                                set = function(info, value)
                                    addon.db.profile.mainbars.left.columns = value
                                    local rows = addon.db.profile.mainbars.left.rows or 1
                                    local buttonsShown = addon.db.profile.mainbars.left.buttons_shown or 12
                                    if rows * value < buttonsShown then
                                        addon.db.profile.mainbars.left.buttons_shown = rows * value
                                    end
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 10
                            },
                            left_buttons_shown = {
                                type = 'range',
                                name = "Left Bar Buttons Shown",
                                desc = "Number of buttons to display on left bar (1-12)",
                                min = 1,
                                max = 12,
                                step = 1,
                                get = function()
                                    return addon.db.profile.mainbars.left.buttons_shown or 12
                                end,
                                set = function(info, value)
                                    local rows = addon.db.profile.mainbars.left.rows or 1
                                    local columns = addon.db.profile.mainbars.left.columns or 12
                                    if value > rows * columns then
                                        value = rows * columns
                                    end
                                    addon.db.profile.mainbars.left.buttons_shown = value
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 11
                            },
                            -- AÑADIR CONFIGURACIONES DE POSICIÓN
                           header_position = {
                                type = 'header',
                                name = "Action Bar Positions",
                                order = 4.5
                            },
                            -- ✅ AÑADIMOS UNA DESCRIPCIÓN INTELIGENTE
                            editor_mode_desc = {
                                type = 'description',
                                name = "|cffFFD700Tip:|r Use the |cff00FF00/duiedit|r command to unlock and move the bars with your mouse.",
                                order = 4.51,
                                -- Solo se muestra si NINGUNA barra ha sido movida manualmente.
                                hidden = function()
                                    local db = addon.db.profile.mainbars
                                    return db.player.override or db.left.override or db.right.override
                                end,
                            },
                            reset_positions = {
                                type = 'execute',
                                name = "Reset All Bar Positions",
                                desc = "Resets all action bars to their default positions and disables manual positioning.",
                                func = function()
                                    local db = addon.db.profile.mainbars
                                    -- Reset all action bar overrides
                                    db.player.override = false
                                    db.left.override = false
                                    db.right.override = false
                                    db.bottom_left.override = false
                                    db.bottom_right.override = false

                                    -- Reset coordinates
                                    db.player.x, db.player.y = 0, 0
                                    db.left.x, db.left.y = 0, 0
                                    db.right.x, db.right.y = 0, 0
                                    db.bottom_left.x, db.bottom_left.y = 0, 0
                                    db.bottom_right.x, db.bottom_right.y = 0, 0

                                    -- Reset stance bar if it exists
                                    if addon.db.profile.additional and addon.db.profile.additional.stance then
                                        addon.db.profile.additional.stance.override = false
                                        addon.db.profile.additional.stance.x_position = 82
                                        addon.db.profile.additional.stance.y_position = 200
                                        addon.db.profile.additional.stance.y_offset = -44
                                    end

                                    -- Apply changes
                                    if addon.PositionActionBars then addon.PositionActionBars() end
                                    if addon.RefreshStance then addon.RefreshStance() end

                                    print("DragonUI: All action bar positions reset to defaults!")
                                end,
                                order = 4.6
                             },
                            -- ========================================
                            -- ✅ EDITOR MODE POSITIONING
                            -- ========================================
                            header_editor_positioning = {
                                type = 'header',
                                name = "Action Bar Positioning",
                                order = 5
                            },
                            desc_editor_positioning = {
                                type = 'description',
                                name = "|cff00FF00Use Editor Mode to position action bars:|r Click 'Move UI Elements' at the top of the options menu to drag and drop action bars to your desired positions.\n\n" ..
                                      "|cffFFD700Tip:|r All action bars can be moved independently and will remember their positions.",
                                order = 5.1
                            }
                        }
                    },

                    -- ========================================
                    -- ✅ BOTTOM BARS LAYOUT CONFIGURATION
                    -- ========================================
                    bottombars = {
                        type = 'group',
                        name = "Bottom Bars Layout",
                        inline = true,
                        order = 1.5,
                        args = {
                            header_bottom_layout = {
                                type = 'header',
                                name = "Bottom Action Bars Layout",
                                order = 1
                            },
                            desc_bottom_layout = {
                                type = 'description',
                                name = "Configure the layout (rows/columns) for bottom action bars. These bars stack above the main action bar.",
                                order = 1.1
                            },

                            -- Quick preset buttons for bottom bars
                            preset_bottom_single = {
                                type = 'execute',
                                name = "Set Both to Single Row (1x12)",
                                desc = "Set both bottom bars to traditional single row layout",
                                func = function()
                                    addon.db.profile.mainbars.bottom_left.rows = 1
                                    addon.db.profile.mainbars.bottom_left.columns = 12
                                    addon.db.profile.mainbars.bottom_left.buttons_shown = 12
                                    addon.db.profile.mainbars.bottom_right.rows = 1
                                    addon.db.profile.mainbars.bottom_right.columns = 12
                                    addon.db.profile.mainbars.bottom_right.buttons_shown = 12
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 1.5
                            },
                            preset_bottom_compact = {
                                type = 'execute',
                                name = "Set Both to Compact (2x6)",
                                desc = "Set both bottom bars to compact 2 row layout",
                                func = function()
                                    addon.db.profile.mainbars.bottom_left.rows = 2
                                    addon.db.profile.mainbars.bottom_left.columns = 6
                                    addon.db.profile.mainbars.bottom_left.buttons_shown = 12
                                    addon.db.profile.mainbars.bottom_right.rows = 2
                                    addon.db.profile.mainbars.bottom_right.columns = 6
                                    addon.db.profile.mainbars.bottom_right.buttons_shown = 12
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 1.6
                            },

                            -- Bottom Left Bar Layout
                            header_bottom_left = {
                                type = 'header',
                                name = "Bottom Left Bar Layout",
                                order = 2
                            },
                            bottom_left_rows = {
                                type = 'range',
                                name = "Bottom Left Rows",
                                desc = "Number of rows for bottom left bar",
                                min = 1, max = 4, step = 1,
                                get = function() return addon.db.profile.mainbars.bottom_left.rows or 1 end,
                                set = function(_, value)
                                    addon.db.profile.mainbars.bottom_left.rows = value
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 2.1
                            },
                            bottom_left_columns = {
                                type = 'range',
                                name = "Bottom Left Columns",
                                desc = "Number of columns for bottom left bar",
                                min = 1, max = 12, step = 1,
                                get = function() return addon.db.profile.mainbars.bottom_left.columns or 12 end,
                                set = function(_, value)
                                    addon.db.profile.mainbars.bottom_left.columns = value
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 2.2
                            },
                            bottom_left_buttons_shown = {
                                type = 'range',
                                name = "Bottom Left Buttons Shown",
                                desc = "Number of buttons to display for bottom left bar",
                                min = 1, max = 12, step = 1,
                                get = function() return addon.db.profile.mainbars.bottom_left.buttons_shown or 12 end,
                                set = function(_, value)
                                    addon.db.profile.mainbars.bottom_left.buttons_shown = value
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 2.3
                            },

                            -- Bottom Right Bar Layout
                            header_bottom_right = {
                                type = 'header',
                                name = "Bottom Right Bar Layout",
                                order = 3
                            },
                            bottom_right_rows = {
                                type = 'range',
                                name = "Bottom Right Rows",
                                desc = "Number of rows for bottom right bar",
                                min = 1, max = 4, step = 1,
                                get = function() return addon.db.profile.mainbars.bottom_right.rows or 1 end,
                                set = function(_, value)
                                    addon.db.profile.mainbars.bottom_right.rows = value
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 3.1
                            },
                            bottom_right_columns = {
                                type = 'range',
                                name = "Bottom Right Columns",
                                desc = "Number of columns for bottom right bar",
                                min = 1, max = 12, step = 1,
                                get = function() return addon.db.profile.mainbars.bottom_right.columns or 12 end,
                                set = function(_, value)
                                    addon.db.profile.mainbars.bottom_right.columns = value
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 3.2
                            },
                            bottom_right_buttons_shown = {
                                type = 'range',
                                name = "Bottom Right Buttons Shown",
                                desc = "Number of buttons to display for bottom right bar",
                                min = 1, max = 12, step = 1,
                                get = function() return addon.db.profile.mainbars.bottom_right.buttons_shown or 12 end,
                                set = function(_, value)
                                    addon.db.profile.mainbars.bottom_right.buttons_shown = value
                                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                                end,
                                order = 3.3
                            }
                        }
                    },

                    buttons = {
                        type = 'group',
                        name = "Button Appearance",
                        inline = true,
                        order = 2,
                        args = {
                            only_actionbackground = {
                                type = 'toggle',
                                name = "Main Bar Only Background",
                                desc = "If checked, only the main action bar buttons will have a background. If unchecked, all action bar buttons will have a background.",
                                get = function()
                                    return addon.db.profile.buttons.only_actionbackground
                                end,
                                set = createSetFunction("buttons", "only_actionbackground", nil, "RefreshButtons"),
                                order = 1
                            },
                            hide_main_bar_background = {
                                type = 'toggle',
                                name = "Hide Main Bar Background",
                                desc = "Hide the background texture of the main action bar (makes it completely transparent)",
                                get = function()
                                    return addon.db.profile.buttons.hide_main_bar_background
                                end,
                                set = createSetFunction("buttons", "hide_main_bar_background", nil, "RefreshMainbars"),
                                order = 1.5
                            },
                            count = {
                                type = 'group',
                                name = "Count Text",
                                inline = true,
                                order = 2,
                                args = {
                                    show = {
                                        type = 'toggle',
                                        name = "Show Count",
                                        get = function()
                                            return addon.db.profile.buttons.count.show
                                        end,
                                        set = createSetFunction("buttons", "count", "show", "RefreshButtons"),
                                        order = 1
                                    }
                                }
                            },
                            hotkey = {
                                type = 'group',
                                name = "Hotkey Text",
                                inline = true,
                                order = 4,
                                args = {
                                    show = {
                                        type = 'toggle',
                                        name = "Show Hotkey",
                                        get = function()
                                            return addon.db.profile.buttons.hotkey.show
                                        end,
                                        set = createSetFunction("buttons", "hotkey", "show", "RefreshButtons"),
                                        order = 1
                                    },
                                    range = {
                                        type = 'toggle',
                                        name = "Range Indicator",
                                        desc = "Show small range indicator point on buttons",
                                        get = function()
                                            return addon.db.profile.buttons.hotkey.range
                                        end,
                                        set = createSetFunction("buttons", "hotkey", "range", "RefreshButtons"),
                                        order = 2
                                    }
                                }
                            },
                            macros = {
                                type = 'group',
                                name = "Macro Text",
                                inline = true,
                                order = 5,
                                args = {
                                    show = {
                                        type = 'toggle',
                                        name = "Show Macro Names",
                                        get = function()
                                            return addon.db.profile.buttons.macros.show
                                        end,
                                        set = createSetFunction("buttons", "macros", "show", "RefreshButtons"),
                                        order = 1
                                    }
                                }
                            },
                            pages = {
                                type = 'group',
                                name = "Page Numbers",
                                inline = true,
                                order = 6,
                                args = {
                                    show = {
                                        type = 'toggle',
                                        name = "Show Pages",
                                        get = function()
                                            return addon.db.profile.buttons.pages.show
                                        end,
                                        set = createSetFunction("buttons", "pages", "show", "RefreshMainbars"),
                                        order = 1
                                    }
                                }
                            },
                            cooldown = {
                                type = 'group',
                                name = "Cooldown Text",
                                inline = true,
                                order = 7,
                                args = {
                                    show = {
                                        type = 'toggle',
                                        name = "Show Cooldown",
                                        desc = "Display cooldown text",
                                        get = function()
                                            return addon.db.profile.buttons.cooldown.show
                                        end,
                                        set = createSetFunction("buttons", "cooldown", "show", "RefreshCooldowns"),
                                        order = 1
                                    },
                                    min_duration = {
                                        type = 'range',
                                        name = "Min Duration",
                                        desc = "Minimum duration for text triggering",
                                        min = 1,
                                        max = 10,
                                        step = 1,
                                        get = function()
                                            return addon.db.profile.buttons.cooldown.min_duration
                                        end,
                                        set = createSetFunction("buttons", "cooldown", "min_duration",
                                            "RefreshCooldowns"),
                                        order = 2
                                    },
                                    color = {
                                        type = 'color',
                                        name = "Text Color",
                                        desc = "Cooldown text color",
                                        get = function()
                                            local c = addon.db.profile.buttons.cooldown.color;
                                            return c[1], c[2], c[3], c[4];
                                        end,
                                        set = createColorSetFunction("buttons", "cooldown", "color", "RefreshCooldowns"),
                                        hasAlpha = true,
                                        order = 3
                                    }
                                }
                            },
                            macros_color = {
                                type = 'color',
                                name = "Macro Text Color",
                                desc = "Color for macro text",
                                get = function()
                                    local c = addon.db.profile.buttons.macros.color;
                                    return c[1], c[2], c[3], c[4];
                                end,
                                set = createColorSetFunction("buttons", "macros", "color", "RefreshButtons"),
                                hasAlpha = true,
                                order = 8
                            },
                            hotkey_shadow = {
                                type = 'color',
                                name = "Hotkey Shadow Color",
                                desc = "Shadow color for hotkey text",
                                get = function()
                                    local c = addon.db.profile.buttons.hotkey.shadow;
                                    return c[1], c[2], c[3], c[4];
                                end,
                                set = createColorSetFunction("buttons", "hotkey", "shadow", "RefreshButtons"),
                                hasAlpha = true,
                                order = 10
                            },
                            border_color = {
                                type = 'color',
                                name = "Border Color",
                                desc = "Border color for buttons",
                                get = function()
                                    local c = addon.db.profile.buttons.border_color;
                                    return c[1], c[2], c[3], c[4];
                                end,
                                set = createColorSetFunction("buttons", "border_color", "RefreshButtons"),
                                hasAlpha = true,
                                order = 10
                            }
                        }
                    }
                }
            },

            micromenu = {
                type = 'group',
                name = "Micro Menu",
                order = 2,
                args = {
                    grayscale_icons = {
                        type = 'toggle',
                        name = "Gray Scale Icons",
                        desc = "Use grayscale icons instead of colored icons for the micro menu",
                        get = function()
                            return addon.db.profile.micromenu.grayscale_icons
                        end,
                        set = function(info, value)
                            addon.db.profile.micromenu.grayscale_icons = value
                            -- Show reload dialog
                            StaticPopup_Show("DRAGONUI_RELOAD_UI")
                        end,
                        order = 1
                    },
                    separator1 = {
                        type = 'description',
                        name = "",
                        order = 2
                    },
                    current_mode_header = {
                        type = 'header',
                        name = function()
                            return addon.db.profile.micromenu.grayscale_icons and "Grayscale Icons Settings" or
                                       "Normal Icons Settings"
                        end,
                        order = 3
                    },
                    scale_menu = {
                        type = 'range',
                        name = "Menu Scale",
                        desc = function()
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            return "Scale for micromenu (" .. mode .. " icons)"
                        end,
                        min = 0.5,
                        max = 3.0,
                        step = 0.1,
                        get = function()
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            return addon.db.profile.micromenu[mode].scale_menu
                        end,
                        set = function(info, value)
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            addon.db.profile.micromenu[mode].scale_menu = value
                            if addon.RefreshMicromenu then
                                addon.RefreshMicromenu()
                            end
                        end,
                        order = 4
                    },
                    x_position = {
                        type = 'range',
                        name = "X Position",
                        desc = function()
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            return "X offset for " .. mode .. " icons (negative moves menu to left side)"
                        end,
                        min = -500,
                        max = 500,
                        step = 1,
                        get = function()
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            return addon.db.profile.micromenu[mode].x_position
                        end,
                        set = function(info, value)
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            addon.db.profile.micromenu[mode].x_position = value
                            if addon.RefreshMicromenu then
                                addon.RefreshMicromenu()
                            end
                        end,
                        order = 5
                    },
                    y_position = {
                        type = 'range',
                        name = "Y Position",
                        desc = function()
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            return "Y offset for " .. mode .. " icons"
                        end,
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            return addon.db.profile.micromenu[mode].y_position
                        end,
                        set = function(info, value)
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            addon.db.profile.micromenu[mode].y_position = value
                            if addon.RefreshMicromenu then
                                addon.RefreshMicromenu()
                            end
                        end,
                        order = 6
                    },
                    icon_spacing = {
                        type = 'range',
                        name = "Icon Spacing",
                        desc = function()
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            return "Gap between " .. mode .. " icons (pixels)"
                        end,
                        min = 5,
                        max = 40,
                        step = 1,
                        get = function()
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            return addon.db.profile.micromenu[mode].icon_spacing
                        end,
                        set = function(info, value)
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            addon.db.profile.micromenu[mode].icon_spacing = value
                            if addon.RefreshMicromenu then
                                addon.RefreshMicromenu()
                            end
                        end,
                        order = 7
                    },
                    separator2 = {
                        type = 'description',
                        name = "",
                        order = 8
                    },
                    hide_on_vehicle = {
                        type = 'toggle',
                        name = "Hide on Vehicle",
                        desc = "Hide micromenu and bags if you sit on vehicle",
                        get = function()
                            return addon.db.profile.micromenu.hide_on_vehicle
                        end,
                        set = function(info, value)
                            addon.db.profile.micromenu.hide_on_vehicle = value
                            -- Apply vehicle visibility immediately to both micromenu and bags
                            if addon.RefreshMicromenuVehicle then
                                addon.RefreshMicromenuVehicle()
                            end
                            if addon.RefreshBagsVehicle then
                                addon.RefreshBagsVehicle()
                            end
                        end,
                        order = 9
                    },
                    reset_position = {
                        type = 'execute',
                        name = "Reset Position",
                        desc = function()
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            return "Resets the position and scale to default for " .. mode .. " icons."
                        end,
                        func = function()
                            local mode = addon.db.profile.micromenu.grayscale_icons and "grayscale" or "normal"
                            -- Set defaults based on mode
                            local defaults = {
                                grayscale = {
                                    scale_menu = 1.5,
                                    x_position = 5,
                                    y_position = -54,
                                    icon_spacing = 15
                                },
                                normal = {
                                    scale_menu = 0.9,
                                    x_position = -111,
                                    y_position = -53,
                                    icon_spacing = 26
                                }
                            }
                            addon.db.profile.micromenu[mode].scale_menu = defaults[mode].scale_menu
                            addon.db.profile.micromenu[mode].x_position = defaults[mode].x_position
                            addon.db.profile.micromenu[mode].y_position = defaults[mode].y_position
                            addon.db.profile.micromenu[mode].icon_spacing = defaults[mode].icon_spacing
                            -- Use complete refresh for reset
                            if addon.RefreshMicromenu then
                                addon.RefreshMicromenu()
                            end
                        end,
                        order = 10
                    }
                }
            },

            bags = {
                type = 'group',
                name = "Bags",
                order = 3,
                args = {
                    description = {
                        type = 'description',
                        name = "Configure the position and scale of the bag bar independently from the micro menu.",
                        order = 1
                    },
                    scale = {
                        type = 'range',
                        name = "Scale",
                        desc = "Scale for the bag bar",
                        min = 0.5,
                        max = 2.0,
                        step = 0.1,
                        get = function()
                            return addon.db.profile.bags.scale
                        end,
                        set = function(info, value)
                            addon.db.profile.bags.scale = value
                            if addon.RefreshBagsPosition then
                                addon.RefreshBagsPosition()
                            end
                        end,
                        order = 2
                    },
                    x_position = {
                        type = 'range',
                        name = "X Position",
                        desc = "Horizontal position adjustment for the bag bar",
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            return addon.db.profile.bags.x_position
                        end,
                        set = function(info, value)
                            addon.db.profile.bags.x_position = value
                            if addon.RefreshBagsPosition then
                                addon.RefreshBagsPosition()
                            end
                        end,
                        order = 3
                    },
                    y_position = {
                        type = 'range',
                        name = "Y Position",
                        desc = "Vertical position adjustment for the bag bar",
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            return addon.db.profile.bags.y_position
                        end,
                        set = function(info, value)
                            addon.db.profile.bags.y_position = value
                            if addon.RefreshBagsPosition then
                                addon.RefreshBagsPosition()
                            end
                        end,
                        order = 4
                    },
                    reset_position = {
                        type = 'execute',
                        name = "Reset Position",
                        desc = "Resets the bag position and scale to default values.",
                        func = function()
                            -- Get defaults from database.lua
                            local defaults = {
                                scale = 0.9,
                                x_position = 1,
                                y_position = 41
                            }
                            addon.db.profile.bags.scale = defaults.scale
                            addon.db.profile.bags.x_position = defaults.x_position
                            addon.db.profile.bags.y_position = defaults.y_position
                            -- Use specific bags refresh function
                            if addon.RefreshBagsPosition then
                                addon.RefreshBagsPosition()
                            end
                        end,
                        order = 5
                    }
                }
            },

            xprepbar = {
                type = 'group',
                name = "XP & Rep Bars",
                order = 6,
                args = {
                    bothbar_offset = {
                        type = 'range',
                        name = "Both Bars Offset",
                        desc = "Y offset when XP & reputation bar are shown",
                        min = 0,
                        max = 100,
                        step = 1,
                        get = function()
                            return addon.db.profile.xprepbar.bothbar_offset
                        end,
                        set = createSetFunction("xprepbar", "bothbar_offset", nil, "RefreshXpRepBarPosition"),
                        order = 1
                    },
                    singlebar_offset = {
                        type = 'range',
                        name = "Single Bar Offset",
                        desc = "Y offset when XP or reputation bar is shown",
                        min = 0,
                        max = 100,
                        step = 1,
                        get = function()
                            return addon.db.profile.xprepbar.singlebar_offset
                        end,
                        set = createSetFunction("xprepbar", "singlebar_offset", nil, "RefreshXpRepBarPosition"),
                        order = 2
                    },
                    nobar_offset = {
                        type = 'range',
                        name = "No Bar Offset",
                        desc = "Y offset when no XP or reputation bar is shown",
                        min = 0,
                        max = 100,
                        step = 1,
                        get = function()
                            return addon.db.profile.xprepbar.nobar_offset
                        end,
                        set = createSetFunction("xprepbar", "nobar_offset", nil, "RefreshXpRepBarPosition"),
                        order = 3
                    },
                    repbar_abovexp_offset = {
                        type = 'range',
                        name = "Rep Bar Above XP Offset",
                        desc = "Y offset for reputation bar when XP bar is shown",
                        min = 0,
                        max = 50,
                        step = 1,
                        get = function()
                            return addon.db.profile.xprepbar.repbar_abovexp_offset
                        end,
                        set = createSetFunction("xprepbar", "repbar_abovexp_offset", nil, "RefreshRepBarPosition"),
                        order = 4
                    },
                    repbar_offset = {
                        type = 'range',
                        name = "Rep Bar Offset",
                        desc = "Y offset when XP bar is not shown",
                        min = 0,
                        max = 50,
                        step = 1,
                        get = function()
                            return addon.db.profile.xprepbar.repbar_offset
                        end,
                        set = createSetFunction("xprepbar", "repbar_offset", nil, "RefreshRepBarPosition"),
                        order = 5
                    }
                }
            },

            style = {
                type = 'group',
                name = "Gryphons",
                order = 7,
                args = {
                    gryphons = {
                        type = 'select',
                        name = "Gryphon Style",
                        desc = "Display style for the action bar end-cap gryphons.",
                        values = function()
                            local order = {'old', 'new', 'flying', 'none'}
                            local labels = {
                                old = "Old",
                                new = "New",
                                flying = "Flying",
                                none = "Hide Gryphons"
                            }
                            local t = {}
                            for _, k in ipairs(order) do
                                t[k] = labels[k]
                            end
                            return t
                        end,
                        get = function()
                            return addon.db.profile.style.gryphons
                        end,
                        set = function(info, val)
                            addon.db.profile.style.gryphons = val
                            if addon.RefreshMainbars then
                                addon.RefreshMainbars()
                            end
                        end,
                        order = 1
                    },
                    spacer = {
                        type = 'description',
                        name = " ", -- Espacio visual extra
                        order = 1.5
                    },
                    gryphon_previews = {
                        type = 'description',
                        name = "|cffFFD700Old|r:      |TInterface\\AddOns\\DragonUI\\assets\\uiactionbar2x_:96:96:0:0:512:2048:1:357:209:543|t |TInterface\\AddOns\\DragonUI\\media\\uiactionbar2x_:96:96:0:0:512:2048:1:357:545:879|t\n" ..
                            "|cffFFD700New|r:      |TInterface\\AddOns\\DragonUI\\assets\\uiactionbar2x_new:96:96:0:0:512:2048:1:357:209:543|t |TInterface\\AddOns\\DragonUI\\media\\uiactionbar2x_new:96:96:0:0:512:2048:1:357:545:879|t\n" ..
                            "|cffFFD700Flying|r: |TInterface\\AddOns\\DragonUI\\assets\\uiactionbar2x_flying:105:105:0:0:256:2048:1:158:149:342|t |TInterface\\AddOns\\DragonUI\\media\\uiactionbar2x_flying:105:105:0:0:256:2048:1:157:539:732|t",
                        order = 2
                    }
                }
            },

            additional = {
                type = 'group',
                name = "Additional Bars",
                desc = "Specialized bars that appear when needed (stance/pet/vehicle/totems)",
                order = 8,
                args = {
                    info_header = {
                        type = 'description',
                        name = "|cffFFD700Additional Bars Configuration|r\n" ..
                            "|cff00FF00Auto-show bars:|r Stance (Warriors/Druids/DKs) • Pet (Hunters/Warlocks/DKs) • Vehicle (All classes) • Totem (Shamans)",
                        order = 0
                    },

                    -- COMPACT COMMON SETTINGS
                    common_group = {
                        type = 'group',
                        name = "Common Settings",
                        inline = true,
                        order = 1,
                        args = {
                            size = {
                                type = 'range',
                                name = "Button Size",
                                desc = "Size of buttons for all additional bars",
                                min = 15,
                                max = 50,
                                step = 1,
                                get = function()
                                    return addon.db.profile.additional.size
                                end,
                                set = createSetFunction("additional", "size", nil,
                                    "RefreshStance RefreshPetbar RefreshVehicle RefreshMulticast"),
                                order = 1,
                                width = "half"
                            },
                            spacing = {
                                type = 'range',
                                name = "Button Spacing",
                                desc = "Space between buttons for all additional bars",
                                min = 0,
                                max = 20,
                                step = 1,
                                get = function()
                                    return addon.db.profile.additional.spacing
                                end,
                                set = createSetFunction("additional", "spacing", nil,
                                    "RefreshStance RefreshPetbar RefreshVehicle RefreshMulticast"),
                                order = 2,
                                width = "half"
                            }
                        }
                    },

                    -- INDIVIDUAL BARS - ORGANIZED IN 2x2 GRID
                    individual_bars_group = {
                        type = 'group',
                        name = "Individual Bar Positions & Settings",
                        desc = "|cffFFD700Now using Smart Anchoring:|r Bars automatically position relative to each other",
                        inline = true,
                        order = 2,
                        args = {
                            -- TOP ROW: STANCE AND PET
                            stance_group = {
                                type = 'group',
                                name = "Stance Bar",
                                desc = "Warriors, Druids, Death Knights",
                                inline = true,
                                order = 1,
                                args = {
                                    override = {
                                        type = 'toggle',
                                        name = "Independent Positioning",
                                        desc = "Enable independent positioning for stance bar (not tied to other bars)",
                                        get = function()
                                            return addon.db.profile.additional.stance.override
                                        end,
                                        set = createSetFunction("additional", "stance", "override", "RefreshStance"),
                                        order = 0.5,
                                        width = "full"
                                    },
                                    x_position = {
                                        type = 'range',
                                        name = "X Position",
                                        desc = "Horizontal position of stance bar",
                                        min = -500,
                                        max = 500,
                                        step = 1,
                                        get = function()
                                            return addon.db.profile.additional.stance.x_position
                                        end,
                                        set = createSetFunction("additional", "stance", "x_position", "RefreshStance"),
                                        order = 1,
                                        width = "full"
                                    },
                                    y_position = {
                                        type = 'range',
                                        name = "Y Position",
                                        desc = "Vertical position of the stance bar (independent mode only)",
                                        min = 0,
                                        max = 1000,
                                        step = 1,
                                        get = function()
                                            return addon.db.profile.additional.stance.y_position
                                        end,
                                        set = createSetFunction("additional", "stance", "y_position", "RefreshStance"),
                                        order = 1.5,
                                        width = "full",
                                        disabled = function() return not addon.db.profile.additional.stance.override end
                                    },
                                    y_offset = {
                                        type = 'range',
                                        name = "Y Offset",
                                        desc = function()
                                            if addon.db.profile.additional.stance.override then
                                                return "|cffFFFF00Independent Mode:|r Additional fine-tuning offset for precise positioning."
                                            else
                                                return "|cff00FF00Smart Anchoring:|r The stance bar automatically positions above the main action bar using intelligent anchoring.\n" ..
                                                    "|cffFFFF00Fine-Tuning:|r Use this offset to make small vertical adjustments while preserving the smart anchoring behavior.\n" ..
                                                    "|cffFFD700Note:|r Positive values move the bar up, negative values move it down."
                                            end
                                        end,
                                        min = -50,
                                        max = 50,
                                        step = 1,
                                        get = function()
                                            return addon.db.profile.additional.stance.y_offset
                                        end,
                                        set = createSetFunction("additional", "stance", "y_offset", "RefreshStance"),
                                        order = 2,
                                        width = "full"
                                    },

                                    -- Visibility behavior options
                                    header_stance_visibility = {
                                        type = 'header',
                                        name = "Visibility Behavior",
                                        order = 3
                                    },
                                    show_on_hover = {
                                        type = 'toggle',
                                        name = "Show on Hover Only",
                                        desc = "Stance bar will only be visible when you hover over it",
                                        get = function()
                                            return addon.db.profile.additional.stance.show_on_hover
                                        end,
                                        set = function(_, value)
                                            addon.db.profile.additional.stance.show_on_hover = value
                                            if addon.UpdateStanceBarVisibility then
                                                addon.UpdateStanceBarVisibility()
                                            end
                                        end,
                                        order = 4,
                                        width = "half"
                                    },
                                    show_in_combat = {
                                        type = 'toggle',
                                        name = "Show in Combat Only",
                                        desc = "Stance bar will only be visible during combat",
                                        get = function()
                                            return addon.db.profile.additional.stance.show_in_combat
                                        end,
                                        set = function(_, value)
                                            addon.db.profile.additional.stance.show_in_combat = value
                                            if addon.UpdateStanceBarVisibility then
                                                addon.UpdateStanceBarVisibility()
                                            end
                                        end,
                                        order = 5,
                                        width = "half"
                                    }
                                }
                            },
                            pet_group = {
                                type = 'group',
                                name = "Pet Bar",
                                desc = "Hunters, Warlocks, Death Knights",
                                inline = true,
                                order = 2,
                                args = {
                                    x_position = {
                                        type = 'range',
                                        name = "X Position",
                                        desc = "Horizontal position of pet bar",
                                        min = -500,
                                        max = 500,
                                        step = 1,
                                        get = function()
                                            return addon.db.profile.additional.pet.x_position
                                        end,
                                        set = createSetFunction("additional", "pet", "x_position", "RefreshPetbar"),
                                        order = 1,
                                        width = "double"
                                    },
                                    y_offset = {
                                        type = 'range',
                                        name = "Y Offset",
                                        desc = "|cffFFD700Smart Anchored Bar:|r This bar automatically positions itself relative to other visible bars.\n\n• This Y offset adds extra spacing above/below the automatic position\n• Positive values = move UP\n• Negative values = move DOWN\n• The bar will still move automatically when you show/hide other action bars",
                                        min = -100,
                                        max = 100,
                                        step = 1,
                                        get = function()
                                            return addon.db.profile.additional.pet.y_offset or 0
                                        end,
                                        set = createSetFunction("additional", "pet", "y_offset", "RefreshPetbar"),
                                        order = 2,
                                        width = "full"
                                    },
                                    grid = {
                                        type = 'toggle',
                                        name = "Show Empty Slots",
                                        desc = "Display empty action slots on pet bar",
                                        get = function()
                                            return addon.db.profile.additional.pet.grid
                                        end,
                                        set = createSetFunction("additional", "pet", "grid", "RefreshPetbar"),
                                        order = 3,
                                        width = "full"
                                    }
                                }
                            },

                            -- BOTTOM ROW: VEHICLE AND TOTEM
                            vehicle_group = {
                                type = 'group',
                                name = "Vehicle Bar",
                                desc = "All classes (vehicles/special mounts)",
                                inline = true,
                                order = 3,
                                args = {
                                    x_position = {
                                        type = 'range',
                                        name = "X Position",
                                        desc = "Horizontal position of vehicle bar",
                                        min = -500,
                                        max = 500,
                                        step = 1,
                                        get = function()
                                            return (addon.db.profile.additional.vehicle and
                                                       addon.db.profile.additional.vehicle.x_position) or 0
                                        end,
                                        set = createSetFunction("additional", "vehicle", "x_position", "RefreshVehicle"),
                                        order = 1,
                                        width = "double"
                                    },
                                    artstyle = {
                                        type = 'toggle',
                                        name = "Blizzard Art Style",
                                        desc = "Use Blizzard original bar arts style",
                                        get = function()
                                            return addon.db.profile.additional.vehicle.artstyle
                                        end,
                                        set = createSetFunction("additional", "vehicle", "artstyle", "RefreshVehicle"),
                                        order = 2,
                                        width = "full"
                                    }
                                }
                            },
                            totem_group = {
                                type = 'group',
                                name = "Totem Bar",
                                desc = "Shamans only (multicast)",
                                inline = true,
                                order = 4,
                                args = {
                                    x_position = {
                                        type = 'range',
                                        name = "X Position",
                                        desc = "Horizontal offset for totem bar",
                                        min = -500,
                                        max = 500,
                                        step = 1,
                                        order = 1,
                                        get = function()
                                            return (addon.db.profile.additional.totem and
                                                       addon.db.profile.additional.totem.x_position) or 0
                                        end,
                                        set = createInstantSetFunction("additional", "totem", "x_position",
                                            "RefreshMulticast")
                                    },
                                    y_offset = {
                                        type = 'range',
                                        name = "Y Offset",
                                        desc = "Vertical offset for totem bar",
                                        min = -200,
                                        max = 200,
                                        step = 1,
                                        order = 2,
                                        get = function()
                                            return (addon.db.profile.additional.totem and
                                                       addon.db.profile.additional.totem.y_offset) or 0
                                        end,
                                        set = createInstantSetFunction("additional", "totem", "y_offset",
                                            "RefreshMulticast")
                                    }
                                }
                            }
                        }
                    }
                }
            },

            questtracker = {
                type = 'group',
                name = "Quest Tracker",
                desc = "Configure the position and behavior of the quest tracker",
                order = 9,
                args = {
                    info_text = {
                        type = 'description',
                        name = "Quest Tracker Position:\nAdjust the position of the quest tracker window to avoid overlapping with the minimap or other UI elements.\n\nTip: Changes apply immediately - no reload required!",
                        order = 1
                    },
                    spacer1 = {
                        type = 'description',
                        name = " ",
                        order = 2
                    },
                    quest_tracker_x = {
                        type = 'range',
                        name = "Horizontal Position (X)",
                        desc = "Horizontal position of quest tracker\n• Negative values = more to the left\n• Positive values = more to the right",
                        min = -400,
                        max = 200,
                        step = 5,
                        get = function()
                            return addon.db.profile.map.quest_tracker_x
                        end,
                        set = function(info, val)
                            -- Get current value to avoid abrupt jumps
                            local currentVal = addon.db.profile.map.quest_tracker_x
                            if not currentVal then
                                currentVal = -100 -- Use fallback default
                            end

                            addon.db.profile.map.quest_tracker_x = val
                            if addon.RefreshQuestTrackerPosition then
                                addon.RefreshQuestTrackerPosition()
                            end
                        end,
                        order = 3
                    },
                    quest_tracker_y = {
                        type = 'range',
                        name = "Vertical Position (Y)",
                        desc = "Vertical position of quest tracker\n• Negative values = more down\n• Positive values = more up",
                        min = -600,
                        max = 200,
                        step = 5,
                        get = function()
                            return addon.db.profile.map.quest_tracker_y
                        end,
                        set = function(info, val)
                            -- Get current value to avoid abrupt jumps
                            local currentVal = addon.db.profile.map.quest_tracker_y
                            if not currentVal then
                                currentVal = -290 -- Use fallback default
                            end

                            addon.db.profile.map.quest_tracker_y = val
                            if addon.RefreshQuestTrackerPosition then
                                addon.RefreshQuestTrackerPosition()
                            end
                        end,
                        order = 4
                    },
                    spacer2 = {
                        type = 'description',
                        name = " ",
                        order = 5
                    },
                    reset_position = {
                        type = 'execute',
                        name = "Reset to Default Position",
                        desc = "Reset quest tracker to the default position (-115, -250)",
                        func = function()
                            addon.db.profile.map.quest_tracker_x = -115
                            addon.db.profile.map.quest_tracker_y = -250
                            if addon.RefreshQuestTrackerPosition then
                                addon.RefreshQuestTrackerPosition()
                            end
                        end,
                        order = 6
                    }
                }
            },

            minimap = {
                type = 'group',
                name = "Minimap",
                order = 10,
                args = {
                    scale = {
                        type = 'range',
                        name = "Minimap Scale",
                        desc = "Minimap scale (don't increase too much)",
                        min = 0.5,
                        max = 2.0,
                        step = 0.05,
                        get = function()
                            return addon.db.profile.map.scale
                        end,
                        set = createSetFunction("map", "scale", nil, "RefreshMinimap"),
                        order = 1
                    },
                    border_alpha = {
                        type = 'range',
                        name = "Border Alpha",
                        desc = "Top border alpha (0 to hide)",
                        min = 0,
                        max = 1,
                        step = 0.1,
                        get = function()
                            return addon.db.profile.map.border_alpha
                        end,
                        set = createSetFunction("map", "border_alpha", nil, "RefreshMinimap"),
                        order = 2
                    },
                    blip_skin = {
                        type = 'toggle',
                        name = "New Blip Style",
                        desc = "New style for object icons",
                        get = function()
                            return addon.db.profile.map.blip_skin
                        end,
                        set = createSetFunction("map", "blip_skin", nil, "RefreshMinimap"),
                        order = 3
                    },
                    player_arrow_size = {
                        type = 'range',
                        name = "Player Arrow Size",
                        desc = "Player arrow on minimap center",
                        min = 20,
                        max = 80,
                        step = 1,
                        get = function()
                            return addon.db.profile.map.player_arrow_size
                        end,
                        set = createSetFunction("map", "player_arrow_size", nil, "RefreshMinimap"),
                        order = 4
                    },
                    tracking_icons = {
                        type = 'toggle',
                        name = "Tracking Icons",
                        desc = "Show current tracking icons (old style)",
                        get = function()
                            return addon.db.profile.map.tracking_icons
                        end,
                        set = createSetFunction("map", "tracking_icons", nil, "RefreshMinimap"),
                        order = 5
                    },
                    skin_button = {
                        type = 'toggle',
                        name = "Skin Buttons",
                        desc = "Circle skin for addon buttons (requires /reload)",
                        get = function()
                            return addon.db.profile.map.skin_button
                        end,
                        set = function(info, val)
                            addon.db.profile.map.skin_button = val
                        end,
                        order = 7
                    },
                    fade_button = {
                        type = 'toggle',
                        name = "Fade Buttons",
                        desc = "Fading for addon buttons",
                        get = function()
                            return addon.db.profile.map.fade_button
                        end,
                        set = function(info, val)
                            addon.db.profile.map.fade_button = val
                            -- Apply fade changes immediately
                            if addon.RefreshMinimapButtonFade then
                                addon.RefreshMinimapButtonFade()
                            end
                        end,
                        order = 8
                    },
                    zonetext_font_size = {
                        type = 'range',
                        name = "Zone Text Size",
                        desc = "Zone text font size on top border",
                        min = 8,
                        max = 20,
                        step = 1,
                        get = function()
                            return addon.db.profile.map.zonetext_font_size
                        end,
                        set = createSetFunction("map", "zonetext_font_size", nil, "RefreshMinimap"),
                        order = 10
                    },
                    zoom_in_out = {
                        type = 'toggle',
                        name = "Zoom Buttons",
                        desc = "Show zoom buttons (+/-)",
                        get = function()
                            return addon.db.profile.map.zoom_in_out
                        end,
                        set = createSetFunction("map", "zoom_in_out", nil, "RefreshMinimap"),
                        order = 10
                    },

                    -- AURAS POSITION
                    auras_header = {
                        type = 'header',
                        name = "Minimap Auras Position",
                        order = 10.1
                    },
                    auras_x_offset = {
                        type = 'range',
                        name = "Auras Horizontal Offset",
                        desc = "Adjusts the horizontal position of the buffs/debuffs block next to the minimap.",
                        min = -500, -- More space to the left
                        max = 500, -- ✅ Aumentado para más flexibilidad
                        step = 1,
                        get = function()
                            -- ✅ CORRECCIÓN: Inicializar la tabla completa si no existe
                            if not addon.db.profile.map.auras then
                                addon.db.profile.map.auras = { x_offset = -70, y_offset = 23 }
                            end
                            return addon.db.profile.map.auras.x_offset or -70
                        end,
                        set = createInstantSetFunction("map", "auras", "x_offset", "RefreshAuraPosition"),
                        order = 10.2
                    },
                    auras_y_offset = {
                        type = 'range',
                        name = "Auras Vertical Offset",
                        desc = "Adjusts the vertical position of the buffs/debuffs block next to the minimap.",
                        min = -500, -- ✅ Aumentado para más flexibilidad
                        max = 500, -- ✅ Aumentado para más flexibilidad
                        step = 1,
                        get = function()
                            -- ✅ CORRECCIÓN: Inicializar la tabla completa si no existe
                            if not addon.db.profile.map.auras then
                                addon.db.profile.map.auras = { x_offset = -70, y_offset = 23 }
                            end
                            return addon.db.profile.map.auras.y_offset or 23
                        end,
                        set = createInstantSetFunction("map", "auras", "y_offset", "RefreshAuraPosition"),
                        order = 10.3
                    },

                    auras_reset = {
                        type = 'execute',
                        name = "Reset Auras Position",
                        desc = "Reset auras position to default values (-80, 0)",
                        func = function()
                            -- Ensure the 'auras' table exists
                            if not addon.db.profile.map.auras then
                                addon.db.profile.map.auras = {}
                            end
                            -- Reset to defaults
                            addon.db.profile.map.auras.x_offset = -70
                            addon.db.profile.map.auras.y_offset = 23
                            -- Refresh the position
                            if addon.RefreshAuraPosition then
                                addon.RefreshAuraPosition()
                            end
                        end,
                        order = 10.4
                    },

                    -- MAIL ICON POSITION
                    mail_header = {
                        type = 'header',
                        name = "Mail Icon Position",
                        order = 11
                    },
                    mail_icon_x = {
                        type = 'range',
                        name = "Mail Icon X Position",
                        desc = "Horizontal position of the mail notification icon relative to minimap\n• Negative values = more to the left\n• Positive values = more to the right",
                        min = -100,
                        max = 100,
                        step = 1,
                        get = function()
                            return addon.db.profile.map.mail_icon_x
                        end,
                        set = createSetFunction("map", "mail_icon_x", nil, "RefreshMinimap"),
                        order = 12
                    },
                    mail_icon_y = {
                        type = 'range',
                        name = "Mail Icon Y Position",
                        desc = "Vertical position of the mail notification icon relative to minimap\n• Negative values = more down\n• Positive values = more up",
                        min = -100,
                        max = 100,
                        step = 1,
                        get = function()
                            return addon.db.profile.map.mail_icon_y
                        end,
                        set = createSetFunction("map", "mail_icon_y", nil, "RefreshMinimap"),
                        order = 13
                    },
                    mail_reset = {
                        type = 'execute',
                        name = "Reset Mail Icon Position",
                        desc = "Reset mail icon to default position (-4, -5)",
                        func = function()
                            addon.db.profile.map.mail_icon_x = -4
                            addon.db.profile.map.mail_icon_y = -5
                            if addon.RefreshMinimap then
                                addon.RefreshMinimap()
                            end
                        end,
                        order = 14
                    }
                }
            },

            times = {
                type = 'group',
                name = "Time & Calendar",
                order = 11,
                args = {
                    clock = {
                        type = 'toggle',
                        name = "Show Clock",
                        get = function()
                            return addon.db.profile.times.clock
                        end,
                        set = createSetFunction("times", "clock", nil, "RefreshMinimapTime"),
                        order = 1
                    },
                    calendar = {
                        type = 'toggle',
                        name = "Show Calendar",
                        get = function()
                            return addon.db.profile.times.calendar
                        end,
                        set = createSetFunction("times", "calendar", nil, "RefreshMinimapTime"),
                        order = 2
                    },
                    clock_font_size = {
                        type = 'range',
                        name = "Clock Font Size",
                        desc = "Clock numbers size",
                        min = 8,
                        max = 20,
                        step = 1,
                        get = function()
                            return addon.db.profile.times.clock_font_size
                        end,
                        set = createSetFunction("times", "clock_font_size", nil, "RefreshMinimapTime"),
                        order = 3
                    }
                }
            },

            castbars = {
                type = 'group',
                name = "Cast Bars",
                order = 4,
                args = {
                    player_castbar = {
                        type = 'group',
                        name = "Player Castbar",
                        order = 1,
                        args = {
                            enabled = {
                                type = 'toggle',
                                name = "Enable Cast Bar",
                                desc = "Enable the improved cast bar",
                                get = function()
                                    return addon.db.profile.castbar.enabled
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.enabled = val
                                    addon.RefreshCastbar()
                                end,
                                order = 1
                            },
                            x_position = {
                                type = 'range',
                                name = "X Position",
                                desc = "Horizontal position",
                                min = -500,
                                max = 500,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.x_position
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.x_position = val
                                    addon.RefreshCastbar()
                                end,
                                order = 2
                            },
                            y_position = {
                                type = 'range',
                                name = "Y Position",
                                desc = "Vertical position",
                                min = 0,
                                max = 600,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.y_position
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.y_position = val
                                    addon.RefreshCastbar()
                                end,
                                order = 3
                            },
                            sizeX = {
                                type = 'range',
                                name = "Width",
                                desc = "Width of the cast bar",
                                min = 80,
                                max = 512,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.sizeX
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.sizeX = val
                                    addon.RefreshCastbar()
                                end,
                                order = 4
                            },
                            sizeY = {
                                type = 'range',
                                name = "Height",
                                desc = "Height of the cast bar",
                                min = 10,
                                max = 64,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.sizeY
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.sizeY = val
                                    addon.RefreshCastbar()
                                end,
                                order = 5
                            },
                            scale = {
                                type = 'range',
                                name = "Scale",
                                desc = "Size scale of the cast bar",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.castbar.scale
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.scale = val
                                    addon.RefreshCastbar()
                                end,
                                order = 6
                            },
                            showIcon = {
                                type = 'toggle',
                                name = "Show Icon",
                                desc = "Show the spell icon next to the cast bar",
                                get = function()
                                    return addon.db.profile.castbar.showIcon
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.showIcon = val
                                    addon.RefreshCastbar()
                                end,
                                order = 7
                            },
                            sizeIcon = {
                                type = 'range',
                                name = "Icon Size",
                                desc = "Size of the spell icon",
                                min = 1,
                                max = 64,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.sizeIcon
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.sizeIcon = val
                                    addon.RefreshCastbar()
                                end,
                                order = 8,
                                disabled = function()
                                    return not addon.db.profile.castbar.showIcon
                                end
                            },
                            text_mode = {
                                type = 'select',
                                name = "Text Mode",
                                desc = "Choose how to display spell text: Simple (centered spell name only) or Detailed (spell name + time)",
                                values = {
                                    simple = "Simple (Centered Name Only)",
                                    detailed = "Detailed (Name + Time)"
                                },
                                get = function()
                                    return addon.db.profile.castbar.text_mode or "simple"
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.text_mode = val
                                    addon.RefreshCastbar()
                                end,
                                order = 9
                            },
                            precision_time = {
                                type = 'range',
                                name = "Time Precision",
                                desc = "Decimal places for remaining time",
                                min = 0,
                                max = 3,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.precision_time
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.precision_time = val
                                end,
                                order = 10,
                                disabled = function()
                                    return addon.db.profile.castbar.text_mode == "simple"
                                end
                            },
                            precision_max = {
                                type = 'range',
                                name = "Max Time Precision",
                                desc = "Decimal places for total time",
                                min = 0,
                                max = 3,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.precision_max
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.precision_max = val
                                end,
                                order = 11,
                                disabled = function()
                                    return addon.db.profile.castbar.text_mode == "simple"
                                end
                            },
                            holdTime = {
                                type = 'range',
                                name = "Hold Time (Success)",
                                desc = "How long the bar stays visible after a successful cast.",
                                min = 0,
                                max = 2,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.castbar.holdTime
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.holdTime = val
                                    addon.RefreshCastbar()
                                end,
                                order = 12
                            },
                            holdTimeInterrupt = {
                                type = 'range',
                                name = "Hold Time (Interrupt)",
                                desc = "How long the bar stays visible after being interrupted.",
                                min = 0,
                                max = 2,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.castbar.holdTimeInterrupt
                                end,
                                set = function(info, val)
                                    addon.db.profile.castbar.holdTimeInterrupt = val
                                    addon.RefreshCastbar()
                                end,
                                order = 13
                            },
                            reset_position = {
                                type = 'execute',
                                name = "Reset Position",
                                desc = "Resets the X and Y position to default.",
                                func = function()
                                    addon.db.profile.castbar.x_position = addon.defaults.profile.castbar.x_position
                                    addon.db.profile.castbar.y_position = addon.defaults.profile.castbar.y_position
                                    addon.RefreshCastbar()
                                end,
                                order = 14
                            }
                        }
                    },

                    target_castbar = {
                        type = 'group',
                        name = "Target Castbar",
                        order = 2,
                        args = {
                            enabled = {
                                type = 'toggle',
                                name = "Enable Target Castbar",
                                desc = "Enable or disable the target castbar",
                                get = function()
                                    if not addon.db.profile.castbar.target then
                                        return true
                                    end
                                    local value = addon.db.profile.castbar.target.enabled
                                    if value == nil then
                                        return true
                                    end
                                    return value == true
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.enabled = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 1
                            },
                            x_position = {
                                type = 'range',
                                name = "X Position",
                                desc = "Horizontal position relative to anchor point",
                                min = -500,
                                max = 500,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.target and
                                               addon.db.profile.castbar.target.x_position or -20
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.x_position = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 2
                            },
                            y_position = {
                                type = 'range',
                                name = "Y Position",
                                desc = "Vertical position relative to anchor point",
                                min = -500,
                                max = 500,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.target and
                                               addon.db.profile.castbar.target.y_position or -20
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.y_position = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 3
                            },
                            sizeX = {
                                type = 'range',
                                name = "Width",
                                desc = "Width of the target castbar",
                                min = 50,
                                max = 400,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.target and addon.db.profile.castbar.target.sizeX or
                                               150
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.sizeX = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 4
                            },
                            sizeY = {
                                type = 'range',
                                name = "Height",
                                desc = "Height of the target castbar",
                                min = 5,
                                max = 50,
                                step = 1,
                                get = function()
                                    return addon.db.profile.castbar.target and addon.db.profile.castbar.target.sizeY or
                                               10
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.sizeY = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 5
                            },
                            scale = {
                                type = 'range',
                                name = "Scale",
                                desc = "Scale of the target castbar",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.castbar.target and addon.db.profile.castbar.target.scale or
                                               1
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.scale = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 6
                            },
                            showIcon = {
                                type = 'toggle',
                                name = "Show Spell Icon",
                                desc = "Show the spell icon next to the target castbar",
                                get = function()
                                    if not addon.db.profile.castbar.target then
                                        return true
                                    end
                                    local value = addon.db.profile.castbar.target.showIcon
                                    if value == nil then
                                        return true
                                    end
                                    return value == true
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.showIcon = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 7
                            },
                            sizeIcon = {
                                type = 'range',
                                name = "Icon Size",
                                desc = "Size of the spell icon",
                                min = 10,
                                max = 50,
                                step = 1,
                                get = function()
                                    return
                                        addon.db.profile.castbar.target and addon.db.profile.castbar.target.sizeIcon or
                                            20
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.sizeIcon = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 8,
                                disabled = function()
                                    return not (addon.db.profile.castbar.target and
                                               addon.db.profile.castbar.target.showIcon)
                                end
                            },
                            text_mode = {
                                type = 'select',
                                name = "Text Mode",
                                desc = "Choose how to display spell text: Simple (centered spell name only) or Detailed (spell name + time)",
                                values = {
                                    simple = "Simple (Centered Name Only)",
                                    detailed = "Detailed (Name + Time)"
                                },
                                get = function()
                                    return (addon.db.profile.castbar.target and
                                               addon.db.profile.castbar.target.text_mode) or "simple"
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.text_mode = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 9
                            },
                            precision_time = {
                                type = 'range',
                                name = "Time Precision",
                                desc = "Decimal places for remaining time",
                                min = 0,
                                max = 3,
                                step = 1,
                                get = function()
                                    return (addon.db.profile.castbar.target and
                                               addon.db.profile.castbar.target.precision_time) or 1
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.precision_time = val
                                end,
                                order = 10,
                                disabled = function()
                                    -- ✅ CORRECCIÓN LÓGICA: Deshabilitar si el modo es "simple"
                                    return (addon.db.profile.castbar.target and
                                               addon.db.profile.castbar.target.text_mode) == "simple"
                                end
                            },
                            precision_max = {
                                type = 'range',
                                name = "Max Time Precision",
                                desc = "Decimal places for total time",
                                min = 0,
                                max = 3,
                                step = 1,
                                get = function()
                                    return (addon.db.profile.castbar.target and
                                               addon.db.profile.castbar.target.precision_max) or 1
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.precision_max = val
                                end,
                                order = 11,
                                disabled = function()
                                    -- ✅ CORRECCIÓN LÓGICA: Deshabilitar si el modo es "simple"
                                    return (addon.db.profile.castbar.target and
                                               addon.db.profile.castbar.target.text_mode) == "simple"
                                end
                            },
                            autoAdjust = {
                                type = 'toggle',
                                name = "Auto Adjust for Auras",
                                desc = "Automatically adjust position based on target auras (CRITICAL FEATURE)",
                                get = function()
                                    if not addon.db.profile.castbar.target then
                                        return true
                                    end
                                    local value = addon.db.profile.castbar.target.autoAdjust
                                    if value == nil then
                                        return true
                                    end
                                    return value == true
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.autoAdjust = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 12
                            },
                            holdTime = {
                                type = 'range',
                                name = "Hold Time (Success)",
                                desc = "How long to show the castbar after successful completion",
                                min = 0,
                                max = 3,
                                step = 0.1,
                                get = function()
                                    return
                                        addon.db.profile.castbar.target and addon.db.profile.castbar.target.holdTime or
                                            0.3
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.holdTime = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 13
                            },
                            holdTimeInterrupt = {
                                type = 'range',
                                name = "Hold Time (Interrupt)",
                                desc = "How long to show the castbar after interruption/failure",
                                min = 0,
                                max = 3,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.castbar.target and
                                               addon.db.profile.castbar.target.holdTimeInterrupt or 0.8
                                end,
                                set = function(info, val)
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.holdTimeInterrupt = val
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 14
                            },
                            reset_position = {
                                type = 'execute',
                                name = "Reset Position",
                                desc = "Reset target castbar position to default",
                                func = function()
                                    if not addon.db.profile.castbar.target then
                                        addon.db.profile.castbar.target = {}
                                    end
                                    addon.db.profile.castbar.target.x_position = -20
                                    addon.db.profile.castbar.target.y_position = -20
                                    addon.RefreshTargetCastbar()
                                end,
                                order = 15
                            }
                        }
                    },



                    focus_castbar = {
                        type = 'group',
                        name = "Focus Castbar",
                        order = 3,
                        args = {
                            enabled = {
                                type = 'toggle',
                                name = "Enable Focus Castbar",
                                desc = "Enable or disable the focus castbar",
                                get = function() return addon.db.profile.castbar.focus.enabled end,
                                set = createInstantSetFunction("castbar", "focus", "enabled", "RefreshFocusCastbar"),
                                order = 1
                            },
                            x_position = {
                                type = 'range',
                                name = "X Position",
                                desc = "Horizontal position relative to anchor point",
                                min = -1500, max = 1500, step = 1,
                                get = function() return addon.db.profile.castbar.focus.x_position or 0 end,
                                set = createInstantSetFunction("castbar", "focus", "x_position", "RefreshFocusCastbar"),
                                order = 2
                            },
                            y_position = {
                                type = 'range',
                                name = "Y Position",
                                desc = "Vertical position relative to anchor point",
                                min = -1500, max = 1500, step = 1,
                                get = function() return addon.db.profile.castbar.focus.y_position or 0 end,
                                set = createInstantSetFunction("castbar", "focus", "y_position", "RefreshFocusCastbar"),
                                order = 3
                            },
                            sizeX = {
                                type = 'range',
                                name = "Width",
                                desc = "Width of the focus castbar",
                                min = 50, max = 400, step = 1,
                                get = function() return addon.db.profile.castbar.focus.sizeX or 200 end,
                                set = createInstantSetFunction("castbar", "focus", "sizeX", "RefreshFocusCastbar"),
                                order = 4
                            },
                            sizeY = {
                                type = 'range',
                                name = "Height",
                                desc = "Height of the focus castbar",
                                min = 5, max = 50, step = 1,
                                get = function() return addon.db.profile.castbar.focus.sizeY or 16 end,
                                set = createInstantSetFunction("castbar", "focus", "sizeY", "RefreshFocusCastbar"),
                                order = 5
                            },
                            scale = {
                                type = 'range',
                                name = "Scale",
                                desc = "Scale of the focus castbar",
                                min = 0.5, max = 2.0, step = 0.1,
                                get = function() return addon.db.profile.castbar.focus.scale or 1 end,
                                set = createInstantSetFunction("castbar", "focus", "scale", "RefreshFocusCastbar"),
                                order = 6
                            },
                            showIcon = {
                                type = 'toggle',
                                name = "Show Icon",
                                desc = "Show the spell icon next to the focus castbar",
                                get = function() return addon.db.profile.castbar.focus.showIcon end,
                                set = createInstantSetFunction("castbar", "focus", "showIcon", "RefreshFocusCastbar"),
                                order = 7
                            },
                            sizeIcon = {
                                type = 'range',
                                name = "Icon Size",
                                desc = "Size of the spell icon",
                                min = 10, max = 50, step = 1,
                                get = function() return addon.db.profile.castbar.focus.sizeIcon or 20 end,
                                set = createInstantSetFunction("castbar", "focus", "sizeIcon", "RefreshFocusCastbar"),
                                order = 8,
                                disabled = function() return not addon.db.profile.castbar.focus.showIcon end
                            },
                            text_mode = {
                                type = 'select',
                                name = "Text Mode",
                                desc = "Choose how to display spell text: Simple (centered spell name only) or Detailed (spell name + time)",
                                values = { simple = "Simple", detailed = "Detailed" },
                                get = function() return addon.db.profile.castbar.focus.text_mode or "detailed" end,
                                set = createInstantSetFunction("castbar", "focus", "text_mode", "RefreshFocusCastbar"),
                                order = 9
                            },
                            precision_time = {
                                type = 'range',
                                name = "Time Precision",
                                desc = "Decimal places for remaining time",
                                min = 0, max = 3, step = 1,
                                get = function() return addon.db.profile.castbar.focus.precision_time or 1 end,
                                set = function(info, val) addon.db.profile.castbar.focus.precision_time = val end,
                                order = 10,
                                disabled = function() return addon.db.profile.castbar.focus.text_mode == "simple" end
                            },
                            precision_max = {
                                type = 'range',
                                name = "Max Time Precision",
                                desc = "Decimal places for total time",
                                min = 0, max = 3, step = 1,
                                get = function() return addon.db.profile.castbar.focus.precision_max or 1 end,
                                set = function(info, val) addon.db.profile.castbar.focus.precision_max = val end,
                                order = 11,
                                disabled = function() return addon.db.profile.castbar.focus.text_mode == "simple" end
                            },
                            autoAdjust = {
                                type = 'toggle',
                                name = "Auto Adjust for Auras",
                                desc = "Automatically adjust position based on focus auras",
                                get = function() return addon.db.profile.castbar.focus.autoAdjust end,
                                set = createInstantSetFunction("castbar", "focus", "autoAdjust", "RefreshFocusCastbar"),
                                order = 12
                            },
                            holdTime = {
                                type = 'range',
                                name = "Hold Time (Success)",
                                desc = "Time to show the castbar after successful cast completion",
                                min = 0, max = 3.0, step = 0.1,
                                get = function() return addon.db.profile.castbar.focus.holdTime or 0.3 end,
                                set = createInstantSetFunction("castbar", "focus", "holdTime", "RefreshFocusCastbar"),
                                order = 13
                            },
                            holdTimeInterrupt = {
                                type = 'range',
                                name = "Hold Time (Interrupt)",
                                desc = "Time to show the castbar after cast interruption",
                                min = 0, max = 3.0, step = 0.1,
                                get = function() return addon.db.profile.castbar.focus.holdTimeInterrupt or 0.8 end,
                                set = createInstantSetFunction("castbar", "focus", "holdTimeInterrupt", "RefreshFocusCastbar"),
                                order = 14
                            },
                            reset_position = {
                                type = 'execute',
                                name = "Reset Position",
                                desc = "Reset focus castbar position to default",
                                func = function()
                                    local defaults = addon.defaults.profile.castbar.focus
                                    addon.db.profile.castbar.focus.x_position = defaults.x_position
                                    addon.db.profile.castbar.focus.y_position = defaults.y_position
                                    addon.RefreshFocusCastbar()
                                end,
                                order = 15
                            }
                        }
                    }
                }
            },

            chat = {
                type = 'group',
                name = "Chat",
                order = 12,
                args = {
                    enabled = {
                        type = 'toggle',
                        name = "Enable Custom Chat",
                        desc = "Enable/disable custom chat positioning and sizing. When disabled, restores original WoW chat.",
                        get = function()
                            return addon.db.profile.chat.enabled
                        end,
                        set = createSetFunction("chat", "enabled", nil, "RefreshChat"),
                        order = 1
                    },
                    header1 = {
                        type = 'header',
                        name = "Position Settings",
                        order = 10
                    },
                    x_position = {
                        type = 'range',
                        name = "X Position",
                        desc = "X position relative to bottom left corner",
                        min = 0,
                        max = 1000,
                        step = 1,
                        get = function()
                            return addon.db.profile.chat.x_position
                        end,
                        set = createSetFunction("chat", "x_position", nil, "RefreshChat"),
                        order = 11,
                        disabled = function()
                            return not addon.db.profile.chat.enabled
                        end
                    },
                    y_position = {
                        type = 'range',
                        name = "Y Position",
                        desc = "Y position relative to bottom left corner",
                        min = 0,
                        max = 1000,
                        step = 1,
                        get = function()
                            return addon.db.profile.chat.y_position
                        end,
                        set = createSetFunction("chat", "y_position", nil, "RefreshChat"),
                        order = 12,
                        disabled = function()
                            return not addon.db.profile.chat.enabled
                        end
                    },
                    header2 = {
                        type = 'header',
                        name = "Size Settings",
                        order = 20
                    },
                    size_x = {
                        type = 'range',
                        name = "Width",
                        desc = "Chat frame width",
                        min = 200,
                        max = 800,
                        step = 1,
                        get = function()
                            return addon.db.profile.chat.size_x
                        end,
                        set = createSetFunction("chat", "size_x", nil, "RefreshChat"),
                        order = 21,
                        disabled = function()
                            return not addon.db.profile.chat.enabled
                        end
                    },
                    size_y = {
                        type = 'range',
                        name = "Height",
                        desc = "Chat frame height",
                        min = 100,
                        max = 500,
                        step = 1,
                        get = function()
                            return addon.db.profile.chat.size_y
                        end,
                        set = createSetFunction("chat", "size_y", nil, "RefreshChat"),
                        order = 22,
                        disabled = function()
                            return not addon.db.profile.chat.enabled
                        end
                    },
                    scale = {
                        type = 'range',
                        name = "Scale",
                        desc = "Chat frame scale",
                        min = 0.5,
                        max = 2.0,
                        step = 0.1,
                        get = function()
                            return addon.db.profile.chat.scale
                        end,
                        set = createSetFunction("chat", "scale", nil, "RefreshChat"),
                        order = 23,
                        disabled = function()
                            return not addon.db.profile.chat.enabled
                        end
                    }
                }
            },

            unitframe = {
                type = 'group',
                name = "Unit Frames",
                order = 5,
                args = {
                    general = {
                        type = 'group',
                        name = "General",
                        inline = true,
                        order = 1,
                        args = {
                            scale = {
                                type = 'range',
                                name = "Global Scale",
                                desc = "Global scale for all unit frames",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.unitframe.scale
                                end,
                                set = createSetFunction("unitframe", "scale", nil, "RefreshUnitFrames"),
                                order = 1
                            }
                        }
                    },

                    player = {
                        type = 'group',
                        name = "Player Frame",
                        order = 2,
                        args = {
                            scale = {
                                type = 'range',
                                name = "Scale",
                                desc = "Scale of the player frame",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.unitframe.player.scale
                                end,
                                set = createSetFunction("unitframe", "player", "scale", "RefreshUnitFrames"),
                                order = 1
                            },
                            classcolor = {
                                type = 'toggle',
                                name = "Class Color",
                                desc = "Use class color for health bar",
                                get = function()
                                    return addon.db.profile.unitframe.player.classcolor
                                end,
                                set = createSetFunction("unitframe", "player", "classcolor", "RefreshUnitFrames"),
                                order = 2
                            },
                            breakUpLargeNumbers = {
                                type = 'toggle',
                                name = "Large Numbers",
                                desc = "Format large numbers (1k, 1m)",
                                get = function()
                                    return addon.db.profile.unitframe.player.breakUpLargeNumbers
                                end,
                                set = createSetFunction("unitframe", "player", "breakUpLargeNumbers",
                                    "RefreshUnitFrames"),
                                order = 3
                            },
                            textFormat = {
                                type = 'select',
                                name = "Text Format",
                                desc = "How to display health and mana values",
                                values = {
                                    numeric = "Current Value Only",
                                    percentage = "Percentage Only",
                                    both = "Both (Numbers + Percentage)",
                                    formatted = "Current/Max Values"
                                },
                                get = function()
                                    return addon.db.profile.unitframe.player.textFormat
                                end,
                                set = createSetFunction("unitframe", "player", "textFormat", "RefreshUnitFrames"),
                                order = 4
                            },
                            showHealthTextAlways = {
                                type = 'toggle',
                                name = "Always Show Health Text",
                                desc = "Show health text always (true) or only on hover (false)",
                                get = function()
                                    return addon.db.profile.unitframe.player.showHealthTextAlways
                                end,
                                set = createSetFunction("unitframe", "player", "showHealthTextAlways",
                                    "RefreshUnitFrames"),
                                order = 5
                            },
                            showManaTextAlways = {
                                type = 'toggle',
                                name = "Always Show Mana Text",
                                desc = "Show mana/power text always (true) or only on hover (false)",
                                get = function()
                                    return addon.db.profile.unitframe.player.showManaTextAlways
                                end,
                                set = createSetFunction("unitframe", "player", "showManaTextAlways", "RefreshUnitFrames"),
                                order = 6
                            },
                            override = {
                                type = 'toggle',
                                name = "Override Position",
                                desc = "Override default positioning",
                                get = function()
                                    return addon.db.profile.unitframe.player.override
                                end,
                                set = createSetFunction("unitframe", "player", "override", "RefreshUnitFrames"),
                                order = 6
                            },
                            x = {
                                type = 'range',
                                name = "X Position",
                                desc = "Horizontal position",
                                min = -1000,
                                max = 1000,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.player.x
                                end,
                                set = createSetFunction("unitframe", "player", "x", "RefreshUnitFrames"),
                                order = 7,
                                disabled = function()
                                    return not addon.db.profile.unitframe.player.override
                                end
                            },
                            y = {
                                type = 'range',
                                name = "Y Position",
                                desc = "Vertical position",
                                min = -1000,
                                max = 1000,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.player.y
                                end,
                                set = createSetFunction("unitframe", "player", "y", "RefreshUnitFrames"),
                                order = 8,
                                disabled = function()
                                    return not addon.db.profile.unitframe.player.override
                                end
                            }
                        }
                    },

                    target = {
                        type = 'group',
                        name = "Target Frame",
                        order = 3,
                        args = {
                            scale = {
                                type = 'range',
                                name = "Scale",
                                desc = "Scale of the target frame",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.unitframe.target.scale
                                end,
                                set = createSetFunction("unitframe", "target", "scale", "RefreshUnitFrames"),
                                order = 1
                            },
                            classcolor = {
                                type = 'toggle',
                                name = "Class Color",
                                desc = "Use class color for health bar",
                                get = function()
                                    return addon.db.profile.unitframe.target.classcolor
                                end,
                                set = createSetFunction("unitframe", "target", "classcolor", "RefreshUnitFrames"),
                                order = 2
                            },
                            breakUpLargeNumbers = {
                                type = 'toggle',
                                name = "Large Numbers",
                                desc = "Format large numbers (1k, 1m)",
                                get = function()
                                    return addon.db.profile.unitframe.target.breakUpLargeNumbers
                                end,
                                set = createSetFunction("unitframe", "target", "breakUpLargeNumbers",
                                    "RefreshUnitFrames"),
                                order = 3
                            },
                            textFormat = {
                                type = 'select',
                                name = "Text Format",
                                desc = "How to display health and mana values",
                                values = {
                                    numeric = "Current Value Only",
                                    percentage = "Percentage Only",
                                    both = "Both (Numbers + Percentage)",
                                    formatted = "Current/Max Values"
                                },
                                get = function()
                                    return addon.db.profile.unitframe.target.textFormat
                                end,
                                set = createSetFunction("unitframe", "target", "textFormat", "RefreshUnitFrames"),
                                order = 4
                            },
                            showHealthTextAlways = {
                                type = 'toggle',
                                name = "Always Show Health Text",
                                desc = "Show health text always (true) or only on hover (false)",
                                get = function()
                                    return addon.db.profile.unitframe.target.showHealthTextAlways
                                end,
                                set = createSetFunction("unitframe", "target", "showHealthTextAlways",
                                    "RefreshUnitFrames"),
                                order = 5
                            },
                            showManaTextAlways = {
                                type = 'toggle',
                                name = "Always Show Mana Text",
                                desc = "Show mana/power text always (true) or only on hover (false)",
                                get = function()
                                    return addon.db.profile.unitframe.target.showManaTextAlways
                                end,
                                set = createSetFunction("unitframe", "target", "showManaTextAlways", "RefreshUnitFrames"),
                                order = 6
                            },
                            enableThreatGlow = {
                                type = 'toggle',
                                name = "Threat Glow",
                                desc = "Show threat glow effect",
                                get = function()
                                    return addon.db.profile.unitframe.target.enableThreatGlow
                                end,
                                set = createSetFunction("unitframe", "target", "enableThreatGlow", "RefreshUnitFrames"),
                                order = 6
                            },
                            override = {
                                type = 'toggle',
                                name = "Override Position",
                                desc = "Override default positioning",
                                get = function()
                                    return addon.db.profile.unitframe.target.override
                                end,
                                set = createSetFunction("unitframe", "target", "override", "RefreshUnitFrames"),
                                order = 7
                            },
                            x = {
                                type = 'range',
                                name = "X Position",
                                desc = "Horizontal position",
                                min = -1000,
                                max = 1000,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.target.x
                                end,
                                set = createSetFunction("unitframe", "target", "x", "RefreshUnitFrames"),
                                order = 8,
                                disabled = function()
                                    return not addon.db.profile.unitframe.target.override
                                end
                            },
                            y = {
                                type = 'range',
                                name = "Y Position",
                                desc = "Vertical position",
                                min = -1000,
                                max = 1000,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.target.y
                                end,
                                set = createSetFunction("unitframe", "target", "y", "RefreshUnitFrames"),
                                order = 10,
                                disabled = function()
                                    return not addon.db.profile.unitframe.target.override
                                end
                            }
                        }
                    },

                    tot = {
                        type = 'group',
                        name = "Target of Target",
                        order = 4,
                        args = {
                            scale = {
                                type = 'range',
                                name = "Scale",
                                desc = "Scale of the target of target frame",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.unitframe.tot.scale
                                end,
                                set = createSetFunction("unitframe", "tot", "scale", "RefreshUnitFrames"),
                                order = 1
                            },
                            classcolor = {
                                type = 'toggle',
                                name = "Class Color",
                                desc = "Use class color for health bar",
                                get = function()
                                    return addon.db.profile.unitframe.tot.classcolor
                                end,
                                set = createSetFunction("unitframe", "tot", "classcolor", "RefreshUnitFrames"),
                                order = 2
                            },
                            x = {
                                type = 'range',
                                name = "X Position",
                                desc = "Horizontal position offset",
                                min = -200,
                                max = 200,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.tot.x
                                end,
                                set = createSetFunction("unitframe", "tot", "x", "RefreshUnitFrames"),
                                order = 3
                            },
                            y = {
                                type = 'range',
                                name = "Y Position",
                                desc = "Vertical position offset",
                                min = -200,
                                max = 200,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.tot.y
                                end,
                                set = createSetFunction("unitframe", "tot", "y", "RefreshUnitFrames"),
                                order = 4
                            }
                        }
                    },

                    fot = {
                        type = 'group',
                        name = "Target of Focus",
                        order = 4.5,
                        args = {
                            scale = {
                                type = 'range',
                                name = "Scale",
                                desc = "Scale of the focus of target frame",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.unitframe.fot.scale
                                end,
                                set = createSetFunction("unitframe", "fot", "scale", "RefreshUnitFrames"),
                                order = 1
                            },
                            classcolor = {
                                type = 'toggle',
                                name = "Class Color",
                                desc = "Use class color for health bar",
                                get = function()
                                    return addon.db.profile.unitframe.fot.classcolor
                                end,
                                set = createSetFunction("unitframe", "fot", "classcolor", "RefreshUnitFrames"),
                                order = 2
                            },
                            x = {
                                type = 'range',
                                name = "X Position",
                                desc = "Horizontal position offset",
                                min = -200,
                                max = 200,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.fot.x
                                end,
                                set = createSetFunction("unitframe", "fot", "x", "RefreshUnitFrames"),
                                order = 3
                            },
                            y = {
                                type = 'range',
                                name = "Y Position",
                                desc = "Vertical position offset",
                                min = -200,
                                max = 200,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.fot.y
                                end,
                                set = createSetFunction("unitframe", "fot", "y", "RefreshUnitFrames"),
                                order = 4
                            }
                        }
                    },

                    focus = {
                        type = 'group',
                        name = "Focus Frame",
                        order = 5,
                        args = {
                            scale = {
                                type = 'range',
                                name = "Scale",
                                desc = "Scale of the focus frame",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.unitframe.focus.scale
                                end,
                                set = createSetFunction("unitframe", "focus", "scale", "RefreshUnitFrames"),
                                order = 1
                            },
                            classcolor = {
                                type = 'toggle',
                                name = "Class Color",
                                desc = "Use class color for health bar",
                                get = function()
                                    return addon.db.profile.unitframe.focus.classcolor
                                end,
                                set = createSetFunction("unitframe", "focus", "classcolor", "RefreshUnitFrames"),
                                order = 2
                            },
                            breakUpLargeNumbers = {
                                type = 'toggle',
                                name = "Large Numbers",
                                desc = "Format large numbers (1k, 1m)",
                                get = function()
                                    return addon.db.profile.unitframe.focus.breakUpLargeNumbers
                                end,
                                set = createSetFunction("unitframe", "focus", "breakUpLargeNumbers", "RefreshUnitFrames"),
                                order = 3
                            },
                            textFormat = {
                                type = 'select',
                                name = "Text Format",
                                desc = "How to display health and mana values",
                                values = {
                                    numeric = "Current Value Only",
                                    percentage = "Percentage Only",
                                    both = "Both (Numbers + Percentage)",
                                    formatted = "Current/Max Values"
                                },
                                get = function()
                                    return addon.db.profile.unitframe.focus.textFormat
                                end,
                                set = createSetFunction("unitframe", "focus", "textFormat", "RefreshUnitFrames"),
                                order = 4
                            },
                            showHealthTextAlways = {
                                type = 'toggle',
                                name = "Always Show Health Text",
                                desc = "Show health text always (true) or only on hover (false)",
                                get = function()
                                    return addon.db.profile.unitframe.focus.showHealthTextAlways
                                end,
                                set = createSetFunction("unitframe", "focus", "showHealthTextAlways",
                                    "RefreshUnitFrames"),
                                order = 5
                            },
                            showManaTextAlways = {
                                type = 'toggle',
                                name = "Always Show Mana Text",
                                desc = "Show mana/power text always (true) or only on hover (false)",
                                get = function()
                                    return addon.db.profile.unitframe.focus.showManaTextAlways
                                end,
                                set = createSetFunction("unitframe", "focus", "showManaTextAlways", "RefreshUnitFrames"),
                                order = 6
                            },
                            override = {
                                type = 'toggle',
                                name = "Override Position",
                                desc = "Override default positioning",
                                get = function()
                                    return addon.db.profile.unitframe.focus.override
                                end,
                                set = createSetFunction("unitframe", "focus", "override", "RefreshUnitFrames"),
                                order = 6
                            },
                            x = {
                                type = 'range',
                                name = "X Position",
                                desc = "Horizontal position",
                                min = -1000,
                                max = 1000,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.focus.x
                                end,
                                set = createSetFunction("unitframe", "focus", "x", "RefreshUnitFrames"),
                                order = 7,
                                disabled = function()
                                    return not addon.db.profile.unitframe.focus.override
                                end
                            },
                            y = {
                                type = 'range',
                                name = "Y Position",
                                desc = "Vertical position",
                                min = -1000,
                                max = 1000,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.focus.y
                                end,
                                set = createSetFunction("unitframe", "focus", "y", "RefreshUnitFrames"),
                                order = 8,
                                disabled = function()
                                    return not addon.db.profile.unitframe.focus.override
                                end
                            }
                        }
                    },

                    pet = {
                        type = 'group',
                        name = "Pet Frame",
                        order = 6,
                        args = {
                            scale = {
                                type = 'range',
                                name = "Scale",
                                desc = "Scale of the pet frame",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.unitframe.pet.scale
                                end,
                                set = createSetFunction("unitframe", "pet", "scale", "RefreshPetFrame"),
                                order = 1
                            },
                            textFormat = {
                                type = 'select',
                                name = "Text Format",
                                desc = "How to display health and mana values",
                                values = {
                                    numeric = "Current Value Only",
                                    percentage = "Percentage Only",
                                    both = "Both (Numbers + Percentage)",
                                    formatted = "Current/Max Values"
                                },
                                get = function()
                                    return addon.db.profile.unitframe.pet.textFormat
                                end,
                                set = createSetFunction("unitframe", "pet", "textFormat", "RefreshPetFrame"),
                                order = 2
                            },
                            breakUpLargeNumbers = {
                                type = 'toggle',
                                name = "Large Numbers",
                                desc = "Format large numbers (1k, 1m)",
                                get = function()
                                    return addon.db.profile.unitframe.pet.breakUpLargeNumbers
                                end,
                                set = createSetFunction("unitframe", "pet", "breakUpLargeNumbers", "RefreshPetFrame"),
                                order = 3
                            },
                            showHealthTextAlways = {
                                type = 'toggle',
                                name = "Always Show Health Text",
                                desc = "Always display health text (otherwise only on mouseover)",
                                get = function()
                                    return addon.db.profile.unitframe.pet.showHealthTextAlways
                                end,
                                set = createSetFunction("unitframe", "pet", "showHealthTextAlways", "RefreshPetFrame"),
                                order = 4
                            },
                            showManaTextAlways = {
                                type = 'toggle',
                                name = "Always Show Mana Text",
                                desc = "Always display mana/energy/rage text (otherwise only on mouseover)",
                                get = function()
                                    return addon.db.profile.unitframe.pet.showManaTextAlways
                                end,
                                set = createSetFunction("unitframe", "pet", "showManaTextAlways", "RefreshPetFrame"),
                                order = 5
                            },
                            enableThreatGlow = {
                                type = 'toggle',
                                name = "Threat Glow",
                                desc = "Show threat glow effect",
                                get = function()
                                    return addon.db.profile.unitframe.pet.enableThreatGlow
                                end,
                                set = createSetFunction("unitframe", "pet", "enableThreatGlow", "RefreshPetFrame"),
                                order = 6
                            },
                            override = {
                                type = 'toggle',
                                name = "Override Position",
                                desc = "Allows the pet frame to be moved freely. When unchecked, it will be positioned relative to the player frame.",
                                get = function()
                                    return addon.db.profile.unitframe.pet.override
                                end,
                                set = createSetFunction("unitframe", "pet", "override", "RefreshPetFrame"),
                                order = 7
                            },
                            -- REMOVED: Anchor options are not needed for a simple movable frame.
                            -- The X and Y coordinates will be relative to the center of the screen when override is active.
                            x = {
                                type = 'range',
                                name = "X Position",
                                desc = "Horizontal position (only active if Override is checked)",
                                min = -2500,
                                max = 2500,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.pet.x
                                end,
                                set = createSetFunction("unitframe", "pet", "x", "RefreshPetFrame"),
                                order = 10,
                                disabled = function()
                                    return not addon.db.profile.unitframe.pet.override
                                end
                            },
                            y = {
                                type = 'range',
                                name = "Y Position",
                                desc = "Vertical position (only active if Override is checked)",
                                min = -2500,
                                max = 2500,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.pet.y
                                end,
                                set = createSetFunction("unitframe", "pet", "y", "RefreshPetFrame"),
                                order = 11,
                                disabled = function()
                                    return not addon.db.profile.unitframe.pet.override
                                end
                            }
                        }
                    },

                    party = {
                        type = 'group',
                        name = "Party Frames",
                        order = 6,
                        args = {
                            scale = {
                                type = 'range',
                                name = "Scale",
                                desc = "Scale of party frames",
                                min = 0.5,
                                max = 2.0,
                                step = 0.1,
                                get = function()
                                    return addon.db.profile.unitframe.party.scale
                                end,
                                set = createSetFunction("unitframe", "party", "scale", "RefreshUnitFrames"),
                                order = 1
                            },
                            classcolor = {
                                type = 'toggle',
                                name = "Class Color",
                                desc = "Use class color for health bars",
                                get = function()
                                    return addon.db.profile.unitframe.party.classcolor
                                end,
                                set = createSetFunction("unitframe", "party", "classcolor", "RefreshUnitFrames"),
                                order = 2
                            },
                            textFormat = {
                                type = 'select',
                                name = "Text Format",
                                desc = "How to display health and mana values",
                                values = {
                                    numeric = "Current Value Only",
                                    percentage = "Percentage Only",
                                    both = "Both (Numbers + Percentage)",
                                    formatted = "Current/Max Values"
                                },
                                get = function()
                                    return addon.db.profile.unitframe.party.textFormat
                                end,
                                set = createSetFunction("unitframe", "party", "textFormat", "RefreshUnitFrames"),
                                order = 3
                            },
                            breakUpLargeNumbers = {
                                type = 'toggle',
                                name = "Large Numbers",
                                desc = "Format large numbers (1k, 1m)",
                                get = function()
                                    return addon.db.profile.unitframe.party.breakUpLargeNumbers
                                end,
                                set = createSetFunction("unitframe", "party", "breakUpLargeNumbers", "RefreshUnitFrames"),
                                order = 4
                            },
                            showHealthTextAlways = {
                                type = 'toggle',
                                name = "Always Show Health Text",
                                desc = "Always display health text (otherwise only on mouseover)",
                                get = function()
                                    return addon.db.profile.unitframe.party.showHealthTextAlways
                                end,
                                set = createSetFunction("unitframe", "party", "showHealthTextAlways",
                                    "RefreshUnitFrames"),
                                order = 5
                            },
                            showManaTextAlways = {
                                type = 'toggle',
                                name = "Always Show Mana Text",
                                desc = "Always display mana/energy/rage text (otherwise only on mouseover)",
                                get = function()
                                    return addon.db.profile.unitframe.party.showManaTextAlways
                                end,
                                set = createSetFunction("unitframe", "party", "showManaTextAlways", "RefreshUnitFrames"),
                                order = 6
                            },
                            orientation = {
                                type = 'select',
                                name = "Orientation",
                                desc = "Party frame orientation",
                                values = {
                                    ['vertical'] = 'Vertical',
                                    ['horizontal'] = 'Horizontal'
                                },
                                get = function()
                                    return addon.db.profile.unitframe.party.orientation
                                end,
                                set = createSetFunction("unitframe", "party", "orientation", "RefreshUnitFrames"),
                                order = 7
                            },
                            padding = {
                                type = 'range',
                                name = "Padding",
                                desc = "Space between party frames",
                                min = 0,
                                max = 50,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.party.padding
                                end,
                                set = createSetFunction("unitframe", "party", "padding", "RefreshUnitFrames"),
                                order = 8
                            },
                            override = {
                                type = 'toggle',
                                name = "Override Position",
                                desc = "Override default party frame position",
                                get = function()
                                    return addon.db.profile.unitframe.party.override
                                end,
                                set = createSetFunction("unitframe", "party", "override", "RefreshUnitFrames"),
                                order = 10
                            },
                            x = {
                                type = 'range',
                                name = "X Position",
                                desc = "Horizontal position",
                                min = -1000,
                                max = 1000,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.party.x
                                end,
                                set = createSetFunction("unitframe", "party", "x", "RefreshUnitFrames"),
                                order = 10,
                                disabled = function()
                                    return not addon.db.profile.unitframe.party.override
                                end
                            },
                            y = {
                                type = 'range',
                                name = "Y Position",
                                desc = "Vertical position",
                                min = -1000,
                                max = 1000,
                                step = 1,
                                get = function()
                                    return addon.db.profile.unitframe.party.y
                                end,
                                set = createSetFunction("unitframe", "party", "y", "RefreshUnitFrames"),
                                order = 11,
                                disabled = function()
                                    return not addon.db.profile.unitframe.party.override
                                end
                            }
                        }
                    }
                }
            },

             profiles = (function()
                -- Obtenemos la tabla de opciones de perfiles estándar
                local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db)

                -- Modificamos los textos para que sean más concisos
                profileOptions.name = "Profiles"
                profileOptions.desc = "Manage UI settings profiles."
                profileOptions.order = 99
                
                --  COMPROBAMOS QUE LA TABLA DE PERFIL EXISTE ANTES DE MODIFICARLA
                if profileOptions.args and profileOptions.args.profile then
                    profileOptions.args.profile.name = "Active Profile"
                    profileOptions.args.profile.desc = "Choose the profile to use for your settings."
                end
                
                -- AÑADIMOS LA DESCRIPCIÓN Y EL BOTÓN DE RECARGA
                profileOptions.args.reload_warning = {
                    type = 'description',
                    name = "\n|cffFFD700It's recommended to reload the UI after switching profiles.|r",
                    order = 15 -- Justo después del selector de perfiles
                }
                
                profileOptions.args.reload_execute = {
                    type = 'execute',
                    name = "Reload UI",
                    func = function() ReloadUI() end,
                    order = 16 -- Justo después del texto de advertencia
                }

                return profileOptions
            end)(),
        }
    }
end