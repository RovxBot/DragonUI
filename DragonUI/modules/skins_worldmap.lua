local addon = select(2, ...)

-- Lightweight World Map skin + small map toggle
-- Applies a dark backdrop and styled close button; supports small/large modes.

local function EnabledSkin()  
    return addon and addon.db and addon.db.profile and addon.db.profile.skins and addon.db.profile.skins.worldmap_skin ~= false  
end

local function EnabledSmall() 
    return addon and addon.db and addon.db.profile and addon.db.profile.skins and addon.db.profile.skins.worldmap_small ~= false 
end

local texBase = "Interface\\AddOns\\DragonUI\\assets\\ui\\"

local SKIN_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local function ReskinClose(btn)
    if not btn then return end
    btn:SetNormalTexture(texBase .. 'close_normal.tga')
    btn:SetPushedTexture(texBase .. 'close_pushed.tga')
    btn:SetHighlightTexture(texBase .. 'close_normal.tga')
    btn:SetSize(20, 20)
end

local worldMapBackdrop = nil

local function ApplyWorldMapSkin()
    if not EnabledSkin() or not WorldMapFrame then return end
    
    -- Create backdrop only once
    if not worldMapBackdrop then
        worldMapBackdrop = CreateFrame('Frame', 'DragonUI_WorldMapBackdrop', WorldMapFrame)
        worldMapBackdrop:SetFrameLevel(math.max(0, WorldMapFrame:GetFrameLevel() - 1))
        worldMapBackdrop:SetBackdrop(SKIN_BACKDROP)
        worldMapBackdrop:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
        worldMapBackdrop:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    end
    
    -- Determine if we're in small mode
    local isSmall = EnabledSmall()
    
    -- Position backdrop around the map detail frame
    local anchor = WorldMapDetailFrame or WorldMapFrame
    worldMapBackdrop:ClearAllPoints()
    
    if isSmall then
        worldMapBackdrop:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -10, 30)
        worldMapBackdrop:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', 10, -10)
    else
        worldMapBackdrop:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -15, 35)
        worldMapBackdrop:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', 15, -15)
    end
    
    worldMapBackdrop:Show()

    -- Style close button
    local closeBtn = WorldMapFrameCloseButton
    if closeBtn then
        ReskinClose(closeBtn)
        closeBtn:ClearAllPoints()
        if isSmall then
            closeBtn:SetPoint('TOPRIGHT', worldMapBackdrop, 'TOPRIGHT', -5, -5)
        else
            closeBtn:SetPoint('TOPRIGHT', worldMapBackdrop, 'TOPRIGHT', -8, -8)
        end
    end
end

local function ApplyWorldMapMode()
    if not WorldMapFrame then return end
    
    if EnabledSmall() then
        -- Use windowed mode
        if SetCVar then SetCVar('miniWorldMap', '1') end
        WorldMapFrame:SetAttribute('UIPanelLayout-area', 'center')
        WorldMapFrame:SetAttribute('UIPanelLayout-allowOtherPanels', true)
    else
        if SetCVar then SetCVar('miniWorldMap', '0') end
    end
    
    ApplyWorldMapSkin()
end

function addon.RefreshWorldMapPosition()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    if not EnabledSmall() then return end
    
    if not (addon.db and addon.db.profile and addon.db.profile.worldmap) then return end
    
    local cfg = addon.db.profile.worldmap
    local x = cfg.x_position or 0
    local y = cfg.y_position or 0

    WorldMapFrame:SetClampedToScreen(true)
    WorldMapFrame:ClearAllPoints()
    WorldMapFrame:SetPoint('CENTER', UIParent, 'CENTER', x, y)
end

local function HookModeChanges()
    if not WorldMapFrame then return end
    
    -- Hook OnShow to reapply skin
    WorldMapFrame:HookScript('OnShow', function()
        ApplyWorldMapSkin()
        addon.RefreshWorldMapPosition()
    end)
end

local f = CreateFrame('Frame')
f:RegisterEvent('PLAYER_LOGIN')
f:SetScript('OnEvent', function()
    ApplyWorldMapMode()
    HookModeChanges()
end)

