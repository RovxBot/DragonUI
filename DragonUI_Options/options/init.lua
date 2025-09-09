local addon = _G.DragonUI_Addon

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

-- TEMP: enable diagnostics to list registered sections in the options UI
addon.__options_debug = true

-- Registrar to (re)build and register options; safe to call multiple times
function addon.EnsureOptionsRegistered()
    -- Build root args from registered sections
    local args = {}

    -- Sort keys by order for stable layout
    local ordered = {}
    for key, entry in pairs(addon._optionsSections or {}) do
        table.insert(ordered, { key = key, order = entry.order or 100, build = entry.build })
    end

    table.sort(ordered, function(a,b)
        if a.order == b.order then return a.key < b.key end
        return a.order < b.order
    end)

    for _, entry in ipairs(ordered) do
        local ok, group = pcall(entry.build)
        if ok and type(group) == 'table' then
            group.order = entry.order
            args[entry.key] = group
        else
            -- fallback: show a tiny diagnostic group if a builder failed
            args[entry.key] = { type='group', name=entry.key, order=entry.order, args = {
                _err = { type='description', name = "Failed to build options for '"..entry.key.."'", order=0 }
            }}
        end
    end

    -- Lightweight diagnostics to help verify registration (hidden unless debug flag set)
    if addon.__options_debug then
        local keys = {}
        for _, e in ipairs(ordered) do table.insert(keys, e.key) end
        local regs = addon.__debug_regs and table.concat(addon.__debug_regs, ', ') or '(none)'
        args.__diagnostics = {
            type='group', name='Diagnostics', order=999, args = {
                info = { type='description', order=0, name = 'Registered sections (built): '..table.concat(keys, ', ') },
                info2 = { type='description', order=1, name = 'RegisterOptionsSection calls seen: '..regs },
            }
        }
    end

    -- Add Profiles pane
    if addon.db then
        local profiles = AceDBOptions:GetOptionsTable(addon.db)
        args.profiles = profiles
        args.profiles.order = 1000
    end

    local options = { name = "DragonUI", type = "group", childGroups = 'tree', args = args }

    -- Always (re)register options table so changes appear
    AceConfig:RegisterOptionsTable("DragonUI", options)

    -- Add to Blizzard options: main page once and each top-level group as subpages
    addon.__bliz_added = addon.__bliz_added or {}
    if not addon.__bliz_added.__root then
        AceConfigDialog:AddToBlizOptions("DragonUI", "DragonUI")
        addon.__bliz_added.__root = true
    end
    -- Add a page for each top-level section so they appear in Interface Options
    for _, entry in ipairs(ordered) do
        local key = entry.key
        local group = args[key]
        local displayName = (type(group.name) == 'function') and group.name() or group.name or key
        if not addon.__bliz_added[key] then
            AceConfigDialog:AddToBlizOptions("DragonUI", displayName, "DragonUI", key)
            addon.__bliz_added[key] = true
        end
    end
    -- Add Profiles as its own page too (optional, in case Ace doesn’t auto-add)
    if args.profiles and not addon.__bliz_added.profiles then
        AceConfigDialog:AddToBlizOptions("DragonUI", "Profiles", "DragonUI", "profiles")
        addon.__bliz_added.profiles = true
    end

    -- Notify UIs to refresh if open
    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if reg and reg.NotifyChange then reg:NotifyChange("DragonUI") end

    return true
end

-- Register immediately on load as well
addon.EnsureOptionsRegistered()

