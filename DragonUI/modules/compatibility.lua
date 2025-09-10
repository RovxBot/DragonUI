local addon = select(2, ...)
local compatibility = {}
addon.compatibility = compatibility

--[[
* DragonUI Compatibility Manager
* 
* Modular system to detect specific addons and apply custom behaviors.
* Each addon can have its own detection and behavior logic.
]]

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
    warningDelay = 0.5,
    scanDelay = 0.1
}

-- ============================================================================
-- OPTIMIZED SYSTEMS
-- ============================================================================

-- Shared timer system for memory efficiency
local delayedActions = {}
local sharedTimer = CreateFrame("Frame")
sharedTimer:SetScript("OnUpdate", function(self, elapsed)
    for i = #delayedActions, 1, -1 do
        local action = delayedActions[i]
        action.elapsed = action.elapsed + elapsed
        if action.elapsed >= action.delay then
            action.func()
            table.remove(delayedActions, i)
        end
    end
    if #delayedActions == 0 then
        self:SetScript("OnUpdate", nil)
    end
end)

local function DelayedCall(func, delay)
    table.insert(delayedActions, { func = func, delay = delay, elapsed = 0 })
    sharedTimer:SetScript("OnUpdate", sharedTimer:GetScript("OnUpdate"))
end

-- Cache system for addon loading checks
local addonLoadCache = {}
local function IsAddonLoadedCached(addonName)
    if addonLoadCache[addonName] == nil then
        addonLoadCache[addonName] = IsAddOnLoaded(addonName)
    end
    return addonLoadCache[addonName]
end

-- ============================================================================
-- BEHAVIOR SYSTEM
-- ============================================================================

local behaviors = {}

-- Behavior: Show conflict warning with disable option
behaviors.ConflictWarning = function(addonName, addonInfo)
    local popupName = "DRAGONUI_CONFLICT_" .. string.upper(addonName)
    
    StaticPopupDialogs[popupName] = {
        text = string.format(
            "|cFFFF0000DragonUI Conflict Warning|r\n\n" ..
            "The addon |cFFFFFF00%s|r conflicts with DragonUI.\n\n" ..
            "|cFFFF9999Reason:|r %s\n\n" ..
            "Disable the conflicting addon now?",
            addonInfo.name, addonInfo.reason
        ),
        button1 = "Disable ",
        button2 = "Keep Both",
        OnAccept = function()
            DisableAddOn(addonName)
            ReloadUI()
        end,
        OnCancel = function() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,
        preferredIndex = 3
    }
    
    StaticPopup_Show(popupName)
end

-- Behavior: Coordinate party frames in raids
behaviors.CoordinatePartyFrames = function(addonName, addonInfo)
    local function UpdateFrameVisibility()
        if not addon.unitframe or not addon.unitframe.PartyMoveFrame then
            return
        end

        local isInRaid = GetNumRaidMembers() > 0
        
        -- Hide party frames when in raid, show when in party only
        if isInRaid then
            addon.unitframe.PartyMoveFrame:Hide()
        else
            -- In party or solo, let DragonUI handle normal logic
            -- Only force Show if we are in party (not solo)
            local isInParty = GetNumPartyMembers() > 0
            if isInParty then
                addon.unitframe.PartyMoveFrame:Show()
            end
            -- If solo, don't interfere - DragonUI decides
        end
    end

    -- Initial check with small delay
    DelayedCall(UpdateFrameVisibility, 0.2)

    -- Register for future events
    if not compatibility.raidUpdateHandlers then
        compatibility.raidUpdateHandlers = {}
    end
    compatibility.raidUpdateHandlers[addonName] = UpdateFrameVisibility
end

-- ============================================================================
-- ADDON REGISTRY
-- ============================================================================

local ADDON_REGISTRY = {
    ["unitframelayers"] = {
        name = "UnitFrameLayers",
        reason = "Conflicts with DragonUI's custom unit frame textures and power bar system.",
        behavior = behaviors.ConflictWarning,
        checkOnce = true
    },
    
    ["CompactRaidFrame"] = {
        name = "Compact Raid Frames",
        reason = "Coordinate party frame visibility in raids.",
        behavior = behaviors.CoordinatePartyFrames,
        checkOnce = false,
        listenToRaidEvents = true
    }
}

-- ============================================================================
-- STATE TRACKING
-- ============================================================================

local state = {
    processedAddons = {},
    activeAddons = {},
    initialized = false
}

-- ============================================================================
-- EVENT SYSTEM (ADDON SPECIFIC)
-- ============================================================================

local activeEventFrames = {}

local function RegisterEventsForAddon(addonName, addonInfo)
    if not addonInfo.listenToRaidEvents then
        return
    end
    
    local eventFrame = CreateFrame("Frame", "DragonUI_Events_" .. addonName)
    eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PARTY_CONVERTED_TO_RAID")
    eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")
    eventFrame:RegisterEvent("GROUP_FORMED")
    eventFrame:RegisterEvent("GROUP_JOINED")
    eventFrame:RegisterEvent("GROUP_LEFT")
    
    eventFrame:SetScript("OnEvent", function(self, event)
        if compatibility.raidUpdateHandlers and compatibility.raidUpdateHandlers[addonName] then
            compatibility.raidUpdateHandlers[addonName]()
        end
    end)
    
    activeEventFrames[addonName] = eventFrame
end

local function UnregisterEventsForAddon(addonName)
    if activeEventFrames[addonName] then
        activeEventFrames[addonName]:UnregisterAllEvents()
        activeEventFrames[addonName] = nil
    end
end

-- ============================================================================
-- CORE DETECTION & EXECUTION
-- ============================================================================

local function ValidateRegistryEntry(addonName, addonInfo)
    if not addonInfo.name or not addonInfo.reason or not addonInfo.behavior then
        return false
    end
    return true
end

local function ProcessAddon(addonName, addonInfo)
    if not ValidateRegistryEntry(addonName, addonInfo) then
        return
    end

    if addonInfo.checkOnce and state.processedAddons[addonName] then
        return
    end

    if addonInfo.checkOnce then
        state.processedAddons[addonName] = true
    end

    state.activeAddons[addonName] = addonInfo

    if addonInfo.behavior then
        addonInfo.behavior(addonName, addonInfo)
    end
    
    if addonInfo.listenToRaidEvents then
        RegisterEventsForAddon(addonName, addonInfo)
    end
end

local function ScanForRegisteredAddons()
    local foundAddons = {}
    
    for addonName, addonInfo in pairs(ADDON_REGISTRY) do
        if IsAddonLoadedCached(addonName) then
            foundAddons[addonName] = addonInfo
        end
    end
    
    return foundAddons
end

-- ============================================================================
-- MAIN EVENT SYSTEM
-- ============================================================================

local function InitializeEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")

    eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
        if event == "ADDON_LOADED" then
            if loadedAddonName then
                addonLoadCache[loadedAddonName] = true
            end

            if loadedAddonName == "DragonUI" then
                DelayedCall(function()
                    local foundAddons = ScanForRegisteredAddons()
                    for addonName, addonInfo in pairs(foundAddons) do
                        ProcessAddon(addonName, addonInfo)
                    end
                end, CONFIG.scanDelay)

            elseif ADDON_REGISTRY[loadedAddonName] then
                DelayedCall(function()
                    ProcessAddon(loadedAddonName, ADDON_REGISTRY[loadedAddonName])
                end, CONFIG.warningDelay)
            end

        elseif event == "PLAYER_LOGIN" then
            state.initialized = true
        end
    end)
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

local function InitializeCommands()
    SLASH_DRAGONUI_COMPAT1 = "/duicomp"
    
    SlashCmdList["DRAGONUI_COMPAT"] = function(msg)
        print("|cFF00FF00Active Addons:|r")
        for i = 1, GetNumAddOns() do
            local name = select(1, GetAddOnInfo(i))
            local title = GetAddOnMetadata(i, "Title") or "Unknown"
            local loaded = IsAddOnLoaded(i)
            if loaded then
                print("  - " .. title .. " |cFFFFFF00(" .. name .. ")|r")
            end
        end
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function compatibility:RegisterAddon(addonName, addonInfo)
    if not ValidateRegistryEntry(addonName, addonInfo) then
        return false
    end
    
    ADDON_REGISTRY[addonName] = addonInfo
    
    if IsAddonLoadedCached(addonName) then
        ProcessAddon(addonName, addonInfo)
    end
    
    return true
end

function compatibility:UnregisterAddon(addonName)
    if ADDON_REGISTRY[addonName] then
        UnregisterEventsForAddon(addonName)
        state.activeAddons[addonName] = nil
        if compatibility.raidUpdateHandlers then
            compatibility.raidUpdateHandlers[addonName] = nil
        end
        
        ADDON_REGISTRY[addonName] = nil
        
        return true
    end
    return false
end

function compatibility:IsRegistered(addonName)
    return ADDON_REGISTRY[addonName] ~= nil
end

function compatibility:GetActiveAddons()
    return state.activeAddons
end

-- ============================================================================
-- CLEANUP FUNCTIONS
-- ============================================================================

local function Cleanup()
    for addonName, _ in pairs(activeEventFrames) do
        UnregisterEventsForAddon(addonName)
    end
    activeEventFrames = {}
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

InitializeEvents()
InitializeCommands()