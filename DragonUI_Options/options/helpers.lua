local addon = _G.DragonUI_Addon

-- Shared helpers for building options
local Helpers = {}

-- Generic setter that writes to addon.db.profile[section][key][subkey?] and calls optional refreshers
function Helpers.createSetFunction(section, key, subkey, refreshFns)
    return function(_, value)
        local db = addon.db and addon.db.profile
        if not db then return end
        if subkey then
            if type(db[section][key]) ~= 'table' then db[section][key] = {} end
            db[section][key][subkey] = value
        else
            db[section][key] = value
        end
        if refreshFns then
            if type(refreshFns) == 'string' then refreshFns = { refreshFns } end
            for _, fnName in ipairs(refreshFns) do
                local fn = addon[fnName]
                if type(fn) == 'function' then pcall(fn) end
            end
        end
    end
end

-- Expose helpers (aligns with ElvUI_Config style of making helpers globally accessible via the addon table)
addon.OptionsHelpers = Helpers

-- Setter specifically for AceGUI color pickers (r,g,b,a), writes an array {r,g,b,a}
function Helpers.createColorSetFunction(section, key, subkey, refreshFns)
    return function(_, r, g, b, a)
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
            if type(refreshFns) == 'string' then refreshFns = { refreshFns } end
            for _, fnName in ipairs(refreshFns) do
                local fn = addon[fnName]
                if type(fn) == 'function' then pcall(fn) end
            end
        end
    end
end

-- For settings that should apply immediately and aren't stored under section/key
function Helpers.createInstantSetFunction(applyFnName)
    return function(_, value)
        local fn = addon[applyFnName]
        if type(fn) == 'function' then pcall(fn, value) end
    end
end

addon.OptionsHelpers = Helpers

return Helpers

