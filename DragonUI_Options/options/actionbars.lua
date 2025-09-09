local addon = _G.DragonUI_Addon

-- Use helpers via main addon table (populated by DragonUI_Options/helpers.lua)
local function dynamicSet(section, key, subkey, refreshFns)
    return function(_, value)
        local H = addon and addon.OptionsHelpers
        if H and H.createSetFunction then
            return H.createSetFunction(section, key, subkey, refreshFns)(_, value)
        end
        -- Fallback minimal implementation
        local db = addon.db and addon.db.profile
        if not db then return end
        if subkey then
            if type(db[section][key]) ~= 'table' then db[section][key] = {} end
            db[section][key][subkey] = value
        else
            db[section][key] = value
        end
        if refreshFns then
            local list = type(refreshFns) == 'string' and { refreshFns } or refreshFns
            for _, fnName in ipairs(list) do
                local fn = addon[fnName]
                if type(fn) == 'function' then pcall(fn) end
            end
        end
    end
end

local function dynamicColorSet(section, key, subkey, refreshFns)
    return function(_, r, g, b, a)
        local H = addon and addon.OptionsHelpers
        if H and H.createColorSetFunction then
            return H.createColorSetFunction(section, key, subkey, refreshFns)(_, r, g, b, a)
        end
        -- Fallback minimal implementation
        local db = addon.db and addon.db.profile
        if not db then return end
        local target
        if subkey then
            if type(db[section][key]) ~= 'table' then db[section][key] = {} end
            if type(db[section][key][subkey]) ~= 'table' then db[section][key][subkey] = {} end
            target = db[section][key][subkey]
        else
            if type(db[section][key]) ~= 'table' then db[section][key] = {} end
            target = db[section][key]
        end
        target[1], target[2], target[3], target[4] = r, g, b, a
        if refreshFns then
            local list = type(refreshFns) == 'string' and { refreshFns } or refreshFns
            for _, fnName in ipairs(list) do
                local fn = addon[fnName]
                if type(fn) == 'function' then pcall(fn) end
            end
        end
    end
end

local set = dynamicSet
local colorSet = dynamicColorSet

local function generalGroup()
    return {
        type = 'group', name = "General", order = 0, args = {
            general_desc = { type='description', name = "General settings that affect all action bars.", order = 0 },
            quicksetup2 = { type='group', name = "Quick Setup", inline = true, order = 0.1, args = {
                desc_quicksetup2 = { type='description', name = "|cffFFD700Quick Actions:|r Get started with common action bar configurations.", order = 1 },
                enable_all_bars2 = { type='execute', name = "Enable All Action Bars", order = 2, func = function()
                    local db = addon.db.profile.actionbars
                    db.bottom_left_enabled, db.bottom_right_enabled = true, true
                    db.right_enabled, db.right2_enabled = true, true
                    if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end
                    print("DragonUI: All action bars enabled!")
                end },
                disable_all_bars2 = { type='execute', name = "Disable All Secondary Bars", order = 3, func = function()
                    local db = addon.db.profile.actionbars
                    db.bottom_left_enabled, db.bottom_right_enabled = false, false
                    db.right_enabled, db.right2_enabled = false, false
                    if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end
                    print("DragonUI: All secondary action bars disabled!")
                end },
            }},
            visibility_global = { type='group', name = "Enable/Disable Bars", inline = true, order=0.2, args = {
                bottom_left_enabled2 = { type='toggle', name = "Bottom Left Bar", width='half', order=2,
                    get=function() return addon.db.profile.actionbars.bottom_left_enabled end,
                    set=function(_,v) addon.db.profile.actionbars.bottom_left_enabled=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
                bottom_right_enabled2 = { type='toggle', name = "Bottom Right Bar", width='half', order=3,
                    get=function() return addon.db.profile.actionbars.bottom_right_enabled end,
                    set=function(_,v) addon.db.profile.actionbars.bottom_right_enabled=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
                right_enabled2 = { type='toggle', name = "Right Bar", width='half', order=4,
                    get=function() return addon.db.profile.actionbars.right_enabled end,
                    set=function(_,v) addon.db.profile.actionbars.right_enabled=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
                right2_enabled2 = { type='toggle', name = "Right Bar 2", width='half', order=5,
                    get=function() return addon.db.profile.actionbars.right2_enabled end,
                    set=function(_,v) addon.db.profile.actionbars.right2_enabled=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
            }},
            positions = { type='group', name = "Positions", inline = true, order=0.3, args = {
                header_position2 = { type='header', name = "Action Bar Positions", order = 0 },
                editor_mode_desc2 = { type='description', order=0.1, name = "|cffFFD700Tip:|r Use the |cff00FF00/duiedit|r command to unlock and move the bars with your mouse.",
                    hidden=function() local db=addon.db.profile.mainbars; return db.player.override or db.left.override or db.right.override end },
                reset_positions2 = { type='execute', name = "Reset All Bar Positions", order=0.2, func=function()
                    local db = addon.db.profile.mainbars
                    db.player.override, db.left.override, db.right.override = false, false, false
                    db.bottom_left.override, db.bottom_right.override = false, false
                    db.player.x, db.player.y = 0, 0; db.left.x, db.left.y = 0, 0; db.right.x, db.right.y = 0, 0
                    db.bottom_left.x, db.bottom_left.y = 0, 0; db.bottom_right.x, db.bottom_right.y = 0, 0
                    if addon.db.profile.additional and addon.db.profile.additional.stance then
                        local s = addon.db.profile.additional.stance
                        s.override=false; s.x_position=82; s.y_position=200; s.y_offset=-44
                    end
                    if addon.PositionActionBars then addon.PositionActionBars() end
                    if addon.RefreshStance then addon.RefreshStance() end
                    print("DragonUI: All action bar positions reset to defaults!")
                end },
            }},
            bottomBarsPresets = { type='group', name = "Bottom Bars Presets", inline=true, order=0.4, args = {
                preset_bottom_single2 = { type='execute', name = "Set Both to Single Row (1x12)", order=1, func=function()
                    local mb = addon.db.profile.mainbars
                    mb.bottom_left.rows, mb.bottom_left.columns, mb.bottom_left.buttons_shown = 1, 12, 12
                    mb.bottom_right.rows, mb.bottom_right.columns, mb.bottom_right.buttons_shown = 1, 12, 12
                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                end },
                preset_bottom_compact2 = { type='execute', name = "Set Both to Compact (2x6)", order=2, func=function()
                    local mb = addon.db.profile.mainbars
                    mb.bottom_left.rows, mb.bottom_left.columns, mb.bottom_left.buttons_shown = 2, 6, 12
                    mb.bottom_right.rows, mb.bottom_right.columns, mb.bottom_right.buttons_shown = 2, 6, 12
                    if addon.RefreshMainbars then addon.RefreshMainbars() end
                end },
            }},
        }
    }
end

local function mainBarGroup()
    return { type='group', name = "Main Bar", order=1, args = {
        main_show_on_hover2 = { type='toggle', name = "Show on Hover Only", width='half', order=1,
            get=function() return addon.db.profile.actionbars.main_show_on_hover end,
            set=function(_,v) addon.db.profile.actionbars.main_show_on_hover=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        main_show_in_combat2 = { type='toggle', name = "Show in Combat Only", width='half', order=2,
            get=function() return addon.db.profile.actionbars.main_show_in_combat end,
            set=function(_,v) addon.db.profile.actionbars.main_show_in_combat=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        header_main_layout2 = { type='header', name = "Layout", order=2.5 },
        main_rows = { type='range', name="Rows", min=1, max=4, step=1, order=2.6,
            get=function() return addon.db.profile.mainbars.player.rows or 1 end,
            set=function(_,v) addon.db.profile.mainbars.player.rows=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        main_columns = { type='range', name="Columns", min=1, max=12, step=1, order=2.7,
            get=function() return addon.db.profile.mainbars.player.columns or 12 end,
            set=function(_,v) addon.db.profile.mainbars.player.columns=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        main_buttons_shown = { type='range', name="Buttons Shown", min=1, max=12, step=1, order=2.8,
            get=function() return addon.db.profile.mainbars.player.buttons_shown or 12 end,
            set=function(_,v) addon.db.profile.mainbars.player.buttons_shown=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        header_presets_main2 = { type='header', name = "Layout Presets", order=2.9 },
        preset_main_single_row = { type='execute', name="Single Row (1x12)", order=3.0, func=function() local p=addon.db.profile.mainbars.player; p.rows=1; p.columns=12; p.buttons_shown=12; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        preset_main_double_row = { type='execute', name="Double Row (2x6)", order=3.1, func=function() local p=addon.db.profile.mainbars.player; p.rows=2; p.columns=6; p.buttons_shown=12; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        preset_main_triple_row = { type='execute', name="Triple Row (3x4)", order=3.2, func=function() local p=addon.db.profile.mainbars.player; p.rows=3; p.columns=4; p.buttons_shown=12; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        preset_main_quad_row = { type='execute', name="Quad Row (4x3)", order=3.3, func=function() local p=addon.db.profile.mainbars.player; p.rows=4; p.columns=3; p.buttons_shown=12; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        scale_actionbar2 = { type='range', name = "Scale", min=0.5, max=2.0, step=0.1, order=3.4,
            get=function() return addon.db.profile.mainbars.scale_actionbar end,
            set=set('mainbars','scale_actionbar', nil, 'RefreshMainbars') },
    }}
end

local function bottomLeftGroup()
    return { type='group', name = "Bottom Left", order=2, args = {
        bottom_left_enabled_tab = { type='toggle', name="Enabled", width='half', order=0,
            get=function() return addon.db.profile.actionbars.bottom_left_enabled end,
            set=function(_,v) addon.db.profile.actionbars.bottom_left_enabled=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        bottom_left_show_on_hover2 = { type='toggle', name="Show on Hover Only", width='half', order=1,
            get=function() return addon.db.profile.actionbars.bottom_left_show_on_hover end,
            set=function(_,v) addon.db.profile.actionbars.bottom_left_show_on_hover=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        bottom_left_show_in_combat2 = { type='toggle', name="Show in Combat Only", width='half', order=2,
            get=function() return addon.db.profile.actionbars.bottom_left_show_in_combat end,
            set=function(_,v) addon.db.profile.actionbars.bottom_left_show_in_combat=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        header_bottom_left_layout2 = { type='header', name = "Layout", order=2.5 },
        bottom_left_rows2 = { type='range', name="Rows", min=1, max=4, step=1, order=2.6,
            get=function() return addon.db.profile.mainbars.bottom_left.rows or 1 end,
            set=function(_,v) addon.db.profile.mainbars.bottom_left.rows=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        bottom_left_columns2 = { type='range', name="Columns", min=1, max=12, step=1, order=2.7,
            get=function() return addon.db.profile.mainbars.bottom_left.columns or 12 end,
            set=function(_,v) addon.db.profile.mainbars.bottom_left.columns=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        bottom_left_buttons_shown2 = { type='range', name="Buttons Shown", min=1, max=12, step=1, order=2.8,
            get=function() return addon.db.profile.mainbars.bottom_left.buttons_shown or 12 end,
            set=function(_,v) addon.db.profile.mainbars.bottom_left.buttons_shown=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        scale_bottom_left2 = { type='range', name = "Scale", min=0.5, max=2.0, step=0.1, order=3.4,
            get=function() return addon.db.profile.mainbars.scale_bottom_left end,
            set=set('mainbars','scale_bottom_left', nil, 'RefreshMainbars') },
    }}
end

local function bottomRightGroup()
    return { type='group', name = "Bottom Right", order=3, args = {
        bottom_right_enabled_tab = { type='toggle', name="Enabled", width='half', order=0,
            get=function() return addon.db.profile.actionbars.bottom_right_enabled end,
            set=function(_,v) addon.db.profile.actionbars.bottom_right_enabled=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        bottom_right_show_on_hover2 = { type='toggle', name="Show on Hover Only", width='half', order=1,
            get=function() return addon.db.profile.actionbars.bottom_right_show_on_hover end,
            set=function(_,v) addon.db.profile.actionbars.bottom_right_show_on_hover=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        bottom_right_show_in_combat2 = { type='toggle', name="Show in Combat Only", width='half', order=2,
            get=function() return addon.db.profile.actionbars.bottom_right_show_in_combat end,
            set=function(_,v) addon.db.profile.actionbars.bottom_right_show_in_combat=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        header_bottom_right_layout2 = { type='header', name = "Layout", order=2.5 },
        bottom_right_rows2 = { type='range', name="Rows", min=1, max=4, step=1, order=2.6,
            get=function() return addon.db.profile.mainbars.bottom_right.rows or 1 end,
            set=function(_,v) addon.db.profile.mainbars.bottom_right.rows=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        bottom_right_columns2 = { type='range', name="Columns", min=1, max=12, step=1, order=2.7,
            get=function() return addon.db.profile.mainbars.bottom_right.columns or 12 end,
            set=function(_,v) addon.db.profile.mainbars.bottom_right.columns=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        bottom_right_buttons_shown2 = { type='range', name="Buttons Shown", min=1, max=12, step=1, order=2.8,
            get=function() return addon.db.profile.mainbars.bottom_right.buttons_shown or 12 end,
            set=function(_,v) addon.db.profile.mainbars.bottom_right.buttons_shown=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        scale_bottom_right2 = { type='range', name = "Scale", min=0.5, max=2.0, step=0.1, order=3.4,
            get=function() return addon.db.profile.mainbars.scale_bottom_right end,
            set=set('mainbars','scale_bottom_right', nil, 'RefreshMainbars') },
    }}
end

local function rightGroup()
    return { type='group', name = "Right", order=4, args = {
        right_enabled_tab = { type='toggle', name="Enabled", width='half', order=0,
            get=function() return addon.db.profile.actionbars.right_enabled end,
            set=function(_,v) addon.db.profile.actionbars.right_enabled=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        right_show_on_hover2 = { type='toggle', name="Show on Hover Only", width='half', order=1,
            get=function() return addon.db.profile.actionbars.right_show_on_hover end,
            set=function(_,v) addon.db.profile.actionbars.right_show_on_hover=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        right_show_in_combat2 = { type='toggle', name="Show in Combat Only", width='half', order=2,
            get=function() return addon.db.profile.actionbars.right_show_in_combat end,
            set=function(_,v) addon.db.profile.actionbars.right_show_in_combat=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        scale_rightbar2 = { type='range', name = "Scale", min=0.5, max=2.0, step=0.1, order=3,
            get=function() return addon.db.profile.mainbars.scale_rightbar end,
            set=set('mainbars','scale_rightbar', nil, 'RefreshMainbars') },
    }}
end

local function right2Group()
    return { type='group', name = "Right 2", order=5, args = {
        right2_enabled_tab = { type='toggle', name="Enabled", width='half', order=0,
            get=function() return addon.db.profile.actionbars.right2_enabled end,
            set=function(_,v) addon.db.profile.actionbars.right2_enabled=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        right2_show_on_hover2 = { type='toggle', name="Show on Hover Only", width='half', order=1,
            get=function() return addon.db.profile.actionbars.right2_show_on_hover end,
            set=function(_,v) addon.db.profile.actionbars.right2_show_on_hover=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        right2_show_in_combat2 = { type='toggle', name="Show in Combat Only", width='half', order=2,
            get=function() return addon.db.profile.actionbars.right2_show_in_combat end,
            set=function(_,v) addon.db.profile.actionbars.right2_show_in_combat=v; if addon.RefreshActionBarVisibility then addon.RefreshActionBarVisibility() end end },
        header_right2_layout2 = { type='header', name = "Layout", order=2.5 },
        right2_rows2 = { type='range', name="Rows", min=1, max=4, step=1, order=2.6,
            get=function() return addon.db.profile.mainbars.left.rows or 1 end,
            set=function(_,v) addon.db.profile.mainbars.left.rows=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        right2_columns2 = { type='range', name="Columns", min=1, max=12, step=1, order=2.7,
            get=function() return addon.db.profile.mainbars.left.columns or 12 end,
            set=function(_,v) addon.db.profile.mainbars.left.columns=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        right2_buttons_shown2 = { type='range', name="Buttons Shown", min=1, max=12, step=1, order=2.8,
            get=function() return addon.db.profile.mainbars.left.buttons_shown or 12 end,
            set=function(_,v) addon.db.profile.mainbars.left.buttons_shown=v; if addon.RefreshMainbars then addon.RefreshMainbars() end end },
        scale_leftbar2 = { type='range', name = "Scale", min=0.5, max=2.0, step=0.1, order=3.4,
            get=function() return addon.db.profile.mainbars.scale_leftbar end,
            set=set('mainbars','scale_leftbar', nil, 'RefreshMainbars') },
    }}
end

local function buttonsAppearanceGroup()
    return { type='group', name = "Button Appearance", inline = true, order = 2, args = {
        border_color = { type='color', name = "Border Color", order=10,
            get=function() local c=addon.db.profile.buttons.border_color or {1,1,1,1}; return c[1],c[2],c[3],c[4] end,
            set=colorSet('buttons','border_color', nil, 'RefreshButtons'), hasAlpha=true },
        hotkey = { type='group', name = "Hotkey Text", inline=true, order=4, args = {
            show = { type='toggle', name="Show Hotkeys", order=1,
                get=function() return addon.db.profile.buttons.hotkey.show end,
                set=set('buttons','hotkey','show','RefreshButtons') },
            color = { type='color', name = "Text Color", order=2, hasAlpha=true,
                get=function() local c=addon.db.profile.buttons.hotkey.color or {1,1,1,1}; return c[1],c[2],c[3],c[4] end,
                set=colorSet('buttons','hotkey','color','RefreshButtons') },
        }},
        macros = { type='group', name = "Macro Text", inline=true, order=5, args = {
            show = { type='toggle', name="Show Macro Names", order=1,
                get=function() return addon.db.profile.buttons.macros.show end,
                set=set('buttons','macros','show','RefreshButtons') },
            color = { type='color', name = "Text Color", order=2, hasAlpha=true,
                get=function() local c=addon.db.profile.buttons.macros.color or {1,1,1,1}; return c[1],c[2],c[3],c[4] end,
                set=colorSet('buttons','macros','color','RefreshButtons') },
        }},
        pages = { type='group', name = "Page Numbers", inline=true, order=6, args = {
            show = { type='toggle', name="Show Page Number", order=1,
                get=function() return addon.db.profile.buttons.pages.show end,
                set=set('buttons','pages','show','RefreshButtons') },
            color = { type='color', name = "Text Color", order=2, hasAlpha=true,
                get=function() local c=addon.db.profile.buttons.pages.color or {1,1,1,1}; return c[1],c[2],c[3],c[4] end,
                set=colorSet('buttons','pages','color','RefreshButtons') },
        }},
        cooldown = { type='group', name = "Cooldown Text", inline=true, order=7, args = {
            show = { type='toggle', name="Show Cooldown", desc="Display cooldown text", order=1,
                get=function() return addon.db.profile.buttons.cooldown.show end,
                set=set('buttons','cooldown','show','RefreshCooldowns') },
            color = { type='color', name = "Text Color", desc="Cooldown text color", order=3, hasAlpha=true,
                get=function() local c=addon.db.profile.buttons.cooldown.color or {1,1,1,1}; return c[1],c[2],c[3],c[4] end,
                set=colorSet('buttons','cooldown','color','RefreshCooldowns') },
        }},
        macros_color = { type='color', name = "Macro Text Color", order=8, hasAlpha=true,
            get=function() local c=addon.db.profile.buttons.macros.color or {1,1,1,1}; return c[1],c[2],c[3],c[4] end,
            set=colorSet('buttons','macros','color','RefreshButtons') },
        hotkey_shadow = { type='color', name = "Hotkey Shadow Color", order=10, hasAlpha=true,
            get=function() local c=addon.db.profile.buttons.hotkey.shadow or {0,0,0,1}; return c[1],c[2],c[3],c[4] end,
            set=colorSet('buttons','hotkey','shadow','RefreshButtons') },
    }}
end

local function BuildActionBarsOptions()
    return {
        type = 'group', name = "Action Bars", order = 1, childGroups = 'tree',
        args = {
            general = generalGroup(),
            mainBar = mainBarGroup(),
            bottomLeftBar = bottomLeftGroup(),
            bottomRightBar = bottomRightGroup(),
            rightBar = rightGroup(),
            right2Bar = right2Group(),
            buttons = buttonsAppearanceGroup(),
        }
    }
end

-- Register this section with the core's options registry
addon:RegisterOptionsSection('actionbars', 1, BuildActionBarsOptions)

