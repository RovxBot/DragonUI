local addon = select(2, ...);

-- Default values for new profiles (only used when creating new profiles)
local defaults = {
    profile = {
        -- ACTIONBAR SETTINGS
        actionbars = {
            -- Enable/disable states for all action bars
            bottom_left_enabled = true,     -- MultiBarBottomLeft (Bottom Left Bar)
            bottom_right_enabled = true,    -- MultiBarBottomRight (Bottom Right Bar)
            right_enabled = true,           -- MultiBarRight (Right Bar)
            right2_enabled = true,          -- MultiBarLeft (Right Bar 2)

            -- Visibility behavior options for all action bars
            main_show_on_hover = false,         -- Main action bar shows only on mouse hover
            main_show_in_combat = false,        -- Main action bar shows only in combat
            bottom_left_show_on_hover = false,  -- Bottom left bar shows only on mouse hover
            bottom_left_show_in_combat = false, -- Bottom left bar shows only in combat
            bottom_right_show_on_hover = false, -- Bottom right bar shows only on mouse hover
            bottom_right_show_in_combat = false,-- Bottom right bar shows only in combat
            right_show_on_hover = false,        -- Right bar shows only on mouse hover
            right_show_in_combat = false,       -- Right bar shows only in combat
            right2_show_on_hover = false,       -- Right bar 2 shows only on mouse hover
            right2_show_in_combat = false,      -- Right bar 2 shows only in combat
        },

       mainbars = {
            -- ✅ Cada barra ahora tiene su propia configuración de posición y override.
            player = {
                override = false,
                y_position_offset = 25, -- Offset vertical para el modo automático.
                x = 0,
                y = 0,
                -- Layout configuration - Default to traditional single row
                rows = 1,           -- Number of rows (1-4)
                columns = 12,       -- Number of columns (1-12)
                buttons_shown = 12, -- Number of buttons to display (1-12)
            },
            left = {
                override = false,
                x = 0,
                y = 0,
                -- Layout configuration
                rows = 1,           -- Number of rows (1-4)
                columns = 12,       -- Number of columns (1-12)
                buttons_shown = 12, -- Number of buttons to display (1-12)
            },
            right = {
                override = false,
                x = 0,
                y = 0,
                -- Layout configuration
                rows = 1,           -- Number of rows (1-4)
                columns = 12,       -- Number of columns (1-12)
                buttons_shown = 12, -- Number of buttons to display (1-12)
            },
            bottom_left = {
                override = false,
                x = 0,
                y = 0,
                -- Layout configuration
                rows = 1,           -- Number of rows (1-4)
                columns = 12,       -- Number of columns (1-12)
                buttons_shown = 12, -- Number of buttons to display (1-12)
            },
            bottom_right = {
                override = false,
                x = 0,
                y = 0,
                -- Layout configuration
                rows = 1,           -- Number of rows (1-4)
                columns = 12,       -- Number of columns (1-12)
                buttons_shown = 12, -- Number of buttons to display (1-12)
            },

            -- Individual scaling for each action bar
            scale_actionbar = 0.9,      -- Main action bar
            scale_rightbar = 0.9,       -- Right bar (MultiBarRight)
            scale_leftbar = 0.9,        -- Left bar (MultiBarLeft)
            scale_bottom_left = 0.9,    -- Bottom left bar (MultiBarBottomLeft)
            scale_bottom_right = 0.9,   -- Bottom right bar (MultiBarBottomRight)
            scale_stance = 0.9,         -- Stance bar
            scale_vehicle = 1,
        },

        micromenu = {
            -- Legacy/shared settings
            hide_on_vehicle = false,
            bags_collapsed = false,
            grayscale_icons = false,

            -- Grayscale icons configuration
            grayscale = {
                scale_menu = 1.5,
                x_position = 5,
                y_position = -54,
                icon_spacing = 15 -- Gap between icons
            },

            -- Normal colored icons configuration  
            normal = {
                scale_menu = 0.9,
                x_position = -113,
                y_position = -53,
                icon_spacing = 26
            }
        },

        bags = {
            scale = 0.9,
            x_position = 1,
            y_position = 41
        },

        xprepbar = {
            bothbar_offset = 39,
            singlebar_offset = 24,
            nobar_offset = 18,
            repbar_abovexp_offset = 16,
            repbar_offset = 2
        },

        style = {
            gryphons = 'new',
            xpbar = 'new'
        },

        buttons = {
            only_actionbackground = true,
            hide_main_bar_background = false,
            count = {
                show = true
            },
            hotkey = {
                show = true,
                range = true,
                shadow = {0, 0, 0, 1},
                font = {"Fonts\\ARIALN.TTF", 12, "OUTLINE"}
            },
            macros = {
                show = true,
                color = {.67, .80, .93, 1},
                font = {"Fonts\\ARIALN.TTF", 10, "OUTLINE"}
            },
            pages = {
                show = true,
                font = {"Fonts\\ARIALN.TTF", 12, "OUTLINE"}
            },
            cooldown = {
                show = false,
                color = {.67, .80, .93, 1},
                min_duration = 3,
                font = {"Fonts\\ARIALN.TTF", 14, "OUTLINE"},
                position = {'CENTER', 0, 1}
            },
            border_color = {1, 1, 1, 1}
        },

        additional = {
            size = 27,
            spacing = 6,
            -- Pretty actionbar compatibility values (hardcoded for optimal positioning)
            leftbar_offset = 90, -- Offset when bottom left is shown (for pretty_actionbar)
            rightbar_offset = 40, -- Offset when bottom right is shown (for pretty_actionbar)
            stance = {
                x_position = 82,
                y_position = 200,  -- Independent Y position
                y_offset = -44,    -- Additional Y offset for fine-tuning position
                override = false,  -- Enable independent positioning
                anchor = "BOTTOM", -- Anchor point
                anchorParent = "BOTTOM", -- Parent anchor point
                anchorFrame = "UIParent",  -- Frame to anchor to
                show_on_hover = false,     -- Show stance bar only on mouse hover
                show_in_combat = false     -- Show stance bar only in combat
            },
            pet = {
                x_position = -134,
                y_offset = 0, -- Additional Y offset for fine-tuning position
                grid = false -- Disable grid by default (matches original Dragonflight port)
            },
            vehicle = {
                x_position = 0,
                artstyle = true
            },
            totem = {
                x_position = -210,
                y_offset = 0 -- Additional Y offset for fine-tuning position
            }
        },

        -- MINIMAP SETTINGS
        map = {
            scale = 1,
            border_alpha = 1,
            blip_skin = true,
            player_arrow_size = 40,
            tracking_icons = false,
            skin_button = true,
            fade_button = false,
            zonetext_font_size = 12,
            zoom_in_out = false,
            quest_tracker_x = -115,
            quest_tracker_y = -250,
            auras = {
                x_offset = -70, -- Default horizontal position for minimap auras
                y_offset = 23 -- Default vertical position for minimap auras
            },
            -- MAIL ICON SETTINGS
            mail_icon_x = -4,
            mail_icon_y = -5
        },

        times = {
            clock = true,
            calendar = true,
            clock_font_size = 11
        },

        -- CASTBAR SETTINGS
        castbar = {
            enabled = true,
            scale = 1,
            anchorFrame = "UIParent",      -- Anclar al frame principal de la UI
            anchor = "BOTTOM",             -- Usar el punto de anclaje inferior central de la barra
            anchorParent = "BOTTOM",       -- Anclarlo al punto inferior central de la pantalla
            x_position = 0,                -- Desplazamiento horizontal (0 para centrado)
            y_position = 230,              -- Desplazamiento vertical hacia arriba
            text_mode = "simple", -- "simple" (centered spell name only) or "detailed" (name + time)
            precision_time = 1,
            precision_max = 1,
            sizeX = 256,
            sizeY = 16,
            showIcon = false,
            sizeIcon = 27,
            holdTime = 0.3,
            holdTimeInterrupt = 0.8,

            -- TARGET CASTBAR SETTINGS
            target = {
                enabled = true,
                scale = 1,
                x_position = -20,
                y_position = -20,
                text_mode = "simple", -- "simple" (centered spell name only) or "detailed" (name + time)
                precision_time = 1,
                precision_max = 1,
                sizeX = 150,
                sizeY = 10,
                showIcon = true,
                sizeIcon = 20,
                holdTime = 0.3,
                holdTimeInterrupt = 0.8,
                -- AUTO-ADJUST BY AURAS SETTINGS
                autoAdjust = true, -- Enable automatic positioning based on target auras
                anchorFrame = 'TargetFrame',
                anchor = 'TOP',
                anchorParent = 'BOTTOM',
                showTicks = false
            },

            -- FOCUS CASTBAR SETTINGS
            focus = {
                enabled = true,
                scale = 1,
                x_position = -20,
                y_position = -20,
                text_mode = "simple", -- "simple" (centered spell name only) or "detailed" (name + time)
                precision_time = 1,
                precision_max = 1,
                sizeX = 150,
                sizeY = 10,
                showIcon = true,
                sizeIcon = 20,
                holdTime = 0.3,
                holdTimeInterrupt = 0.8,
                -- AUTO-ADJUST BY AURAS SETTINGS
                autoAdjust = true, -- Enable automatic positioning based on focus auras
                anchorFrame = 'FocusFrame',
                anchor = 'TOP',
                anchorParent = 'BOTTOM',
                showTicks = false
            }
        },

        -- CHAT SETTINGS
        chat = {
            enabled = true, -- Por defecto deshabilitado para no interferir con el chat original
            scale = 1.0,
            x_position = 42, -- X relativo a BOTTOM LEFT
            y_position = 35, -- Y relativo a BOTTOM LEFT
            size_x = 295, -- Ancho del chat
            size_y = 120 -- Alto del chat
        },

        -- UNIT FRAMES SETTINGS
        unitframe = {
            scale = 1,
            player = {
                classcolor = false,
                breakUpLargeNumbers = true, -- Changed to false - no commas by default
                textFormat = 'both', -- Changed to 'both' - Current Value + Percentage
                showHealthTextAlways = false, -- true = always visible, false = only on hover
                showManaTextAlways = false, -- true = always visible, false = only on hover
                scale = 1.0,
                override = false,
                anchor = 'TOPLEFT',
                anchorParent = 'TOPLEFT',
                x = -19,
                y = -4
            },
            target = {
                classcolor = false,
                breakUpLargeNumbers = true, -- Changed to false - no commas by default
                textFormat = 'both', -- Changed to 'both' - Current Value + Percentage
                showHealthTextAlways = false, -- true = always visible, false = only on hover
                showManaTextAlways = false, -- true = always visible, false = only on hover
                enableNumericThreat = true,
                enableThreatGlow = true,
                scale = 1.0,
                override = false,
                anchor = 'TOPLEFT',
                anchorParent = 'TOPLEFT',
                x = 250,
                y = -4
            },
            focus = {
                classcolor = false,
                breakUpLargeNumbers = false, -- Changed to false - no commas by default
                textFormat = 'both', -- Changed to 'numeric' - Current Value Only by default
                showHealthTextAlways = false, -- true = always visible, false = only on hover
                showManaTextAlways = false, -- true = always visible, false = only on hover
                scale = 0.9,
                override = false,
                anchor = 'TOPLEFT',
                anchorParent = 'TOPLEFT',
                x = 250,
                y = -170
            },
            pet = {
                breakUpLargeNumbers = true,
                textFormat = 'numeric',
                showHealthTextAlways = false,
                showManaTextAlways = false,
                enableThreatGlow = false,
                scale = 1.0,
                override = false,
                anchor = 'TOPRIGHT',
                anchorParent = 'BOTTOMRIGHT',
                x = -1259,
                y = 752
            },
            party = {
                classcolor = false,
                textFormat = 'both',
                breakUpLargeNumbers = true,
                showHealthTextAlways = false,
                showManaTextAlways = false,
                orientation = 'vertical',
                padding = 10,
                scale = 1.0,
                override = false,
                anchor = 'TOPLEFT',
                anchorParent = 'TOPLEFT',
                x = 10,
                y = 720
            },
            tot = {
                classcolor = false,
                scale = 1.0,
                x = -8,
                y = -15,
                textFormat = 'numeric',
                breakUpLargeNumbers = false,
                showHealthTextAlways = false,
                showManaTextAlways = false,
                override = false,
                anchor = 'BOTTOMRIGHT',
                anchorParent = 'BOTTOMRIGHT',
                anchorFrame = 'TargetFrame'
            },
            fot = {
                classcolor = false,
                scale = 1.0,
                x = -8,
                y = -15,
                textFormat = 'numeric',
                breakUpLargeNumbers = false,
                showHealthTextAlways = false,
                showManaTextAlways = false,
                override = false,
                anchor = 'BOTTOMRIGHT',
                anchorParent = 'BOTTOMRIGHT',
                anchorFrame = 'FocusFrame'
            }
        }
    }
};

-- Initialize AceDB immediately to ensure it's available for modules
-- This is a temporary placeholder that will be replaced in OnInitialize
addon.db = {
    profile = addon.defaults and addon.defaults.profile or {}
};

-- Function to recursively copy tables  
local function deepCopy(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if not target[key] then
                target[key] = {};
            end
            deepCopy(value, target[key]);
        else
            if target[key] == nil then
                target[key] = value;
            end
        end
    end
end

-- Copy defaults to the temporary profile immediately
if defaults and defaults.profile then
    deepCopy(defaults.profile, addon.db.profile);
end

-- Export defaults for use in core.lua
addon.defaults = defaults;

-- Function to get database values
function addon:GetConfigValue(section, key, subkey)
    if subkey then
        return self.db.profile[section][key][subkey];
    elseif key then
        return self.db.profile[section][key];
    else
        return self.db.profile[section];
    end
end

-- Function to set database values
function addon:SetConfigValue(section, key, subkey, value)
    if subkey then
        self.db.profile[section][key][subkey] = value;
    elseif key then
        self.db.profile[section][key] = value;
    else
        self.db.profile[section] = value;
    end
end
