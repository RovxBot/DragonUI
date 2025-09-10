local addon = select(2,...);
local class = addon._class;
local noop = addon._noop;
local InCombatLockdown = InCombatLockdown;
local UnitAffectingCombat = UnitAffectingCombat;
local hooksecurefunc = hooksecurefunc;
local UIParent = UIParent;
local NUM_POSSESS_SLOTS = NUM_POSSESS_SLOTS or 10;

-- =============================================================================
-- OPTIMIZED TIMER HELPER (with timer pool for better memory management)
-- =============================================================================
local timerPool = {}
local function DelayedCall(delay, func)
    local timer = table.remove(timerPool) or CreateFrame("Frame")
    timer.elapsed = 0
    timer:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= delay then
            self:SetScript("OnUpdate", nil)
            table.insert(timerPool, self) -- Recycle timer for reuse
            func()
        end
    end)
end

-- =============================================================================
-- CONFIG HELPER FUNCTIONS
-- =============================================================================
local function GetTotemConfig()
    if not (addon.db and addon.db.profile and addon.db.profile.additional and addon.db.profile.additional.totem) then
        return 0, 0
    end
    local totemConfig = addon.db.profile.additional.totem
    return totemConfig.x_position or 0, totemConfig.y_offset or 0
end

local function GetAdditionalConfig()
    return addon:GetConfigValue("additional") or {}
end

-- =============================================================================
-- ANCHOR FRAME: Handles positioning for both Totem and Possess bars
-- =============================================================================
local anchor = CreateFrame('Frame', 'DragonUI_MulticastAnchor', UIParent)
anchor:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 52)
anchor:SetSize(37, 37)

-- Register mover for Totem/Possess anchor
if addon.CreateMover and not (addon.Movers and addon.Movers.registry and addon.Movers.registry.totembar) then
    addon:CreateMover(anchor, 'totembar', 'Totem Bar', {'BOTTOM', UIParent, 'BOTTOM', 0, 140})
    anchor:HookScript('OnShow', function() if addon.ApplyMover then addon:ApplyMover('totembar') end end)
end

-- =============================================================================
-- SMART POSITIONING FUNCTION
-- =============================================================================
function anchor:update_position()
    if InCombatLockdown() or UnitAffectingCombat('player') then return end

    -- If using mover, do not auto-reposition
    if addon and addon.Movers and addon.Movers.registry and addon.Movers.registry.totembar then
        return
    end

    local offsetX, offsetY = GetTotemConfig()
    self:ClearAllPoints()
    
    -- Check if pretty_actionbar addon is loaded for special positioning logic
    if IsAddOnLoaded('pretty_actionbar') and _G.pUiMainBar then
        local leftbar = MultiBarBottomLeft and MultiBarBottomLeft:IsShown()
        local rightbar = MultiBarBottomRight and MultiBarBottomRight:IsShown()
        
        -- Get additional config for pretty_actionbar compatibility
        local nobar = 52
        local leftbarOffset = 90
        local rightbarOffset = 40
        
        -- Read values from database if available
        if addon.db and addon.db.profile and addon.db.profile.additional then
            local additionalConfig = addon.db.profile.additional
            leftbarOffset = additionalConfig.leftbar_offset or 90
            rightbarOffset = additionalConfig.rightbar_offset or 40
        end
        
        local yPosition = nobar
        
        if leftbar and rightbar then
            yPosition = nobar + leftbarOffset
        elseif leftbar then
            yPosition = nobar + rightbarOffset
        elseif rightbar then
            yPosition = nobar + leftbarOffset
        end
        
        self:SetPoint('BOTTOM', UIParent, 'BOTTOM', offsetX, yPosition + offsetY)
    else
        -- Standard positioning logic
        local leftbar = MultiBarBottomLeft and MultiBarBottomLeft:IsShown()
        local rightbar = MultiBarBottomRight and MultiBarBottomRight:IsShown()
        local anchorFrame, anchorPoint, relativePoint, yOffset
        
        if leftbar or rightbar then
            if leftbar and rightbar then
                anchorFrame = MultiBarBottomRight
            elseif leftbar then
                anchorFrame = MultiBarBottomLeft
            else
                anchorFrame = MultiBarBottomRight
            end
            anchorPoint = 'TOP'
            relativePoint = 'BOTTOM'
            yOffset = 5 + offsetY
        else
            anchorFrame = addon.pUiMainBar or MainMenuBar
            anchorPoint = 'TOP'
            relativePoint = 'BOTTOM'
            yOffset = 5 + offsetY
        end
        
        self:SetPoint(relativePoint, anchorFrame, anchorPoint, offsetX, yOffset)
    end
end

-- =============================================================================
-- POSSESS BAR SETUP
-- =============================================================================
local possessbar = CreateFrame('Frame', 'DragonUI_PossessBar', UIParent, 'SecureHandlerStateTemplate')
possessbar:SetAllPoints(anchor)

-- Properly parent and position the PossessBarFrame
PossessBarFrame:SetParent(possessbar)
PossessBarFrame:ClearAllPoints()
PossessBarFrame:SetPoint('BOTTOMLEFT', possessbar, 'BOTTOMLEFT', -68, 0)

-- =============================================================================
-- POSSESS BUTTON POSITIONING FUNCTION
-- =============================================================================
local function PositionPossessButtons()
    if InCombatLockdown() then return end
    
    -- Get config values safely
    local additionalConfig = GetAdditionalConfig()
    local btnsize = additionalConfig.size or 37
    local space = additionalConfig.spacing or 4
    
    for index = 1, NUM_POSSESS_SLOTS do
        local button = _G['PossessButton'..index]
        if button then
            button:ClearAllPoints()
            button:SetParent(possessbar)
            button:SetSize(btnsize, btnsize)

            if index == 1 then
                button:SetPoint('BOTTOMLEFT', possessbar, 'BOTTOMLEFT', 0, 0)
            else
                local prevButton = _G['PossessButton'..(index-1)]
                if prevButton then
                    button:SetPoint('LEFT', prevButton, 'RIGHT', space, 0)
                end
            end

            button:Show()
            possessbar:SetAttribute('addchild', button)
        end
    end

    -- Resize anchor to match layout so mover follows the shape
    local totalWidth = (btnsize * NUM_POSSESS_SLOTS) + (space * (NUM_POSSESS_SLOTS - 1))
    anchor:SetSize(totalWidth, btnsize)

    -- Apply custom button template if available
    if addon.possessbuttons_template then
        addon.possessbuttons_template()
    end
    
    -- Set visibility driver for vehicle UI
    RegisterStateDriver(possessbar, 'visibility', '[vehicleui][@vehicle,exists] hide; show')
end

-- =============================================================================
-- SHAMAN MULTICAST (TOTEM) BAR SETUP
-- =============================================================================
if MultiCastActionBarFrame and class == 'SHAMAN' then
    -- Remove default scripts that might interfere
    MultiCastActionBarFrame:SetScript('OnUpdate', nil)
    MultiCastActionBarFrame:SetScript('OnShow', nil)
    MultiCastActionBarFrame:SetScript('OnHide', nil)
    
    -- Parent and position the MultiCastActionBarFrame
    MultiCastActionBarFrame:SetParent(possessbar)
    MultiCastActionBarFrame:ClearAllPoints()
    MultiCastActionBarFrame:SetPoint('BOTTOMLEFT', possessbar, 'BOTTOMLEFT', 0, 0)
    MultiCastActionBarFrame:Show()
    
    -- Prevent the frame from being moved by other addons
    MultiCastActionBarFrame.SetParent = noop
    MultiCastActionBarFrame.SetPoint = noop
    
    -- Also protect the recall button if it exists
    if MultiCastRecallSpellButton then
        MultiCastRecallSpellButton.SetPoint = noop
    end
end

-- =============================================================================
-- HOOK ACTION BAR VISIBILITY CHANGES
-- =============================================================================
local function HookActionBarEvents()
    local bars = {MultiBarBottomLeft, MultiBarBottomRight}
    
    for _, bar in pairs(bars) do
        if bar then
            -- Safely hook without causing self-reference errors
            if not bar.__DragonUI_Hooked then
                bar:HookScript('OnShow', function() 
                    DelayedCall(0.1, function() anchor:update_position() end)
                end)
                bar:HookScript('OnHide', function() 
                    DelayedCall(0.1, function() anchor:update_position() end)
                end)
                bar.__DragonUI_Hooked = true
            end
        end
    end
end

-- =============================================================================
-- UNIFIED REFRESH FUNCTION 
-- =============================================================================
-- Fast refresh: Only updates size and spacing WITHOUT repositioning
function addon.RefreshMulticast(fullRefresh)
    if InCombatLockdown() or UnitAffectingCombat("player") then 
        -- Schedule refresh after combat
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            addon.RefreshMulticast(fullRefresh)
        end)
        return 
    end
    
    -- Only update anchor position if NOT a full refresh (X/Y changes)
    if not fullRefresh then
        if anchor and anchor.update_position then
            anchor:update_position()
        end
        return -- Exit here for X/Y changes
    end
    
    -- Get config values once (cached for performance)
    local additionalConfig = GetAdditionalConfig()
    local btnsize = additionalConfig.size or 37
    local space = additionalConfig.spacing or 4
    
    -- ✅ UPDATE POSSESS BUTTONS - ONLY SIZE, NO REPOSITIONING
    for index = 1, NUM_POSSESS_SLOTS do
        local button = _G["PossessButton"..index]
        if button then
            button:SetSize(btnsize, btnsize)
            -- DO NOT reposition - keep existing positions
        end
    end
    
    -- ✅ UPDATE TOTEM BUTTONS - ONLY SIZE, NO REPOSITIONING  
    if MultiCastActionBarFrame and class == 'SHAMAN' then
        -- Update totem slot buttons
        for i = 1, 4 do
            local button = _G["MultiCastSlotButton"..i]
            if button then
                button:SetSize(btnsize, btnsize)
                -- DO NOT reposition - keep existing positions
            end
        end
        
        -- Update summon button if it exists
        if MultiCastSummonSpellButton then
            MultiCastSummonSpellButton:SetSize(btnsize, btnsize)
        end
        
        -- Update recall button if it exists  
        if MultiCastRecallSpellButton then
            MultiCastRecallSpellButton:SetSize(btnsize, btnsize)
        end
    end
end

-- Full rebuild: Only for major changes (profile changes, etc.)
function addon.RefreshMulticastFull()
    if InCombatLockdown() or UnitAffectingCombat("player") then return end
    
    -- Reinitialize everything from scratch
    InitializeMulticast()
end

-- =============================================================================
-- INITIALIZATION FUNCTION
-- =============================================================================
local function InitializeMulticast()
    -- Position possess buttons
    PositionPossessButtons()
    
    -- Hook action bar events
    HookActionBarEvents()
    
    -- Update anchor position
    anchor:update_position()
end

-- =============================================================================
-- PROFILE CHANGE HANDLER
-- =============================================================================
local function OnProfileChanged()
    -- Delay to ensure profile data is fully loaded
    DelayedCall(0.2, function()
        if InCombatLockdown() or UnitAffectingCombat("player") then
            -- Schedule for after combat if in combat
            local frame = CreateFrame("Frame")
            frame:RegisterEvent("PLAYER_REGEN_ENABLED")
            frame:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                OnProfileChanged()
            end)
            return
        end
        
        -- Use the same refresh that works for X/Y sliders (prevents ghost elements)
        addon.RefreshMulticast()
    end)
end

-- =============================================================================
-- CENTRALIZED EVENT HANDLER (optimized event management)
-- =============================================================================
local eventFrame = CreateFrame("Frame")
local function RegisterEvents()
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGOUT")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    eventFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "DragonUI" then
            -- Initialize multicast system
            if addon.core and addon.core.RegisterMessage then
                addon.core.RegisterMessage(addon, "DRAGONUI_READY", InitializeMulticast)
            else
                -- Fallback initialization
                DelayedCall(1, InitializeMulticast)
            end
            
            -- Register profile callbacks after a short delay
            DelayedCall(0.5, function()
                if addon.db and addon.db.RegisterCallback then
                    addon.db.RegisterCallback(addon, "OnProfileChanged", OnProfileChanged)
                    addon.db.RegisterCallback(addon, "OnProfileCopied", OnProfileChanged)
                    addon.db.RegisterCallback(addon, "OnProfileReset", OnProfileChanged)
                end
                
                -- Also register with addon core if available
                if addon.core and addon.core.RegisterMessage then
                    addon.core.RegisterMessage(addon, "DRAGONUI_PROFILE_CHANGED", OnProfileChanged)
                end
            end)
            
        elseif event == "PLAYER_LOGOUT" then
            -- Cleanup callbacks on logout
            if addon.db and addon.db.UnregisterCallback then
                addon.db.UnregisterCallback(addon, "OnProfileChanged")
                addon.db.UnregisterCallback(addon, "OnProfileCopied") 
                addon.db.UnregisterCallback(addon, "OnProfileReset")
            end
            
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Update position after combat ends (with delay for stability)
            DelayedCall(0.5, function()
                if anchor and anchor.update_position then
                    anchor:update_position()
                end
            end)
        end
    end)
end

-- Initialize event system
RegisterEvents()