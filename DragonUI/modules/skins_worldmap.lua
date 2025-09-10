local addon = select(2, ...)

-- Lightweight World Map skin + small map toggle (inspired by ElvUI behavior)
-- Keeps Blizzard logic but applies a minimal backdrop and proper close button; supports small/large modes.

local function EnabledSkin()  return addon and addon.db and addon.db.profile and addon.db.profile.skins and addon.db.profile.skins.worldmap_skin ~= false  end
local function EnabledSmall() return addon and addon.db and addon.db.profile and addon.db.profile.skins and addon.db.profile.skins.worldmap_small ~= false end

local texBase = "Interface\\AddOns\\DragonUI\\assets\\ui\\"

local function ReskinClose(btn)
    if not btn then return end
    btn:SetNormalTexture(texBase .. 'close_normal.tga')
    btn:SetPushedTexture(texBase .. 'close_pushed.tga')
    btn:SetHighlightTexture(texBase .. 'close_normal.tga')
    btn:SetSize(17, 17)
end

local function ApplyWorldMapSkin()
    if not EnabledSkin() or not WorldMapFrame then return end

    -- reduce clutter and backdrop the map
    WorldMapFrame:EnableMouse(true)
    if WorldMapFrame.backdrop then WorldMapFrame.backdrop:Hide(); WorldMapFrame.backdrop = nil end

    local bg = CreateFrame('Frame', nil, WorldMapFrame)
    bg:SetFrameStrata(WorldMapFrame:GetFrameStrata())
    bg:SetFrameLevel(WorldMapFrame:GetFrameLevel())

    -- Anchor differently for small vs large modes (mirrors ElvUI logic)
    local isSmall = (GetCVar and GetCVar('miniWorldMap') == '1') or (WORLDMAP_SETTINGS and WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE)
    local advanced = WORLDMAP_SETTINGS and WORLDMAP_SETTINGS.advanced

    bg:ClearAllPoints()
    if isSmall then
        -- Anchor to the visible map area instead of the close button for symmetry
        local anchor = WorldMapDetailFrame or WorldMapFrame
        bg:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -8, 8)
        bg:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', 8, -8)
    else
        local anchor = WorldMapDetailFrame or WorldMapFrame
        bg:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -12, 12)
        bg:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', 12, -12)
    end

    bg:SetBackdrop({ bgFile='Interface/Tooltips/UI-Tooltip-Background', edgeFile='Interface/Tooltips/UI-Tooltip-Border', tile=true, tileSize=16, edgeSize=16, insets={left=4,right=4,top=4,bottom=4} })
    bg:SetBackdropColor(0,0,0,0.8)
    WorldMapFrame.backdrop = bg

    local closeBtn = WorldMapCloseButton or WorldMapFrameCloseButton
    ReskinClose(closeBtn)
    -- Ensure close button sits flush in small mode
    if isSmall and closeBtn then
        closeBtn:ClearAllPoints()
        closeBtn:SetPoint('TOPRIGHT', WorldMapFrame, 'TOPRIGHT', -8, -6)
    end
end

local function ApplyWorldMapMode()
    if not WorldMapFrame then return end
    if EnabledSmall() then
        SetCVar('miniWorldMap', 1)
        WorldMapFrame:SetAttribute('UIPanelLayout-area', 'center')
        WorldMapFrame:SetAttribute('UIPanelLayout-allowOtherPanels', true)
        WorldMapFrame:SetScale(1)
    else
        SetCVar('miniWorldMap', 0)
        WorldMapFrame:SetScale(1)
    end
    ApplyWorldMapSkin()
    -- Safety: ensure WorldMapButton OnUpdate never runs with nil center
    if WorldMapButton then
        local orig = WorldMapButton:GetScript('OnUpdate')
        WorldMapButton:SetScript('OnUpdate', function(self, elapsed)
            local cx, cy = self:GetCenter()
            if not cx or not cy then return end
            if orig then orig(self, elapsed) end
        end)
    end

    if addon and addon.Movers and addon.Movers.registry and addon.Movers.registry.worldmap and addon.ApplyMover then
        addon:ApplyMover('worldmap')
    elseif addon.RefreshWorldMapPosition then
        addon.RefreshWorldMapPosition()
    end
end

function addon.RefreshWorldMapPosition()
    if not WorldMapFrame then return end
    if addon and addon.Movers and addon.Movers.registry and addon.Movers.registry.worldmap then return end -- Mover takes precedence
    if not (addon and addon.db and addon.db.profile and addon.db.profile.worldmap) then return end
    if not EnabledSmall() then return end -- Only reposition in small mode

    -- Avoid re-anchoring while hidden or during layout to prevent nil centers in FrameXML
    if not WorldMapFrame:IsShown() then return end

    local cfg = addon.db.profile.worldmap
    local x = cfg.x_position or 0
    local y = cfg.y_position or 0

    -- Make user-placed and clamped for safety
    WorldMapFrame:SetClampedToScreen(true)
    if WorldMapFrame.SetUserPlaced then WorldMapFrame:SetUserPlaced(true) end

    WorldMapFrame:ClearAllPoints()
    WorldMapFrame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', x, y)

    -- Ensure the map button has valid anchors to avoid GetCenter() returning nil
    if WorldMapButton and WorldMapButton:GetNumPoints() == 0 then
        WorldMapButton:ClearAllPoints()
        if WorldMapDetailFrame then
            WorldMapButton:SetAllPoints(WorldMapDetailFrame)
        else
            WorldMapButton:SetAllPoints(WorldMapFrame)
        end
    end
end


local function HookModeChanges()
    if not WorldMapFrame then return end
    local function reskinAndReposition()
        ApplyWorldMapSkin()
        if addon.RefreshWorldMapPosition then addon.RefreshWorldMapPosition() end
    end
    hooksecurefunc('WorldMapFrame_SetQuestMapView', reskinAndReposition)
    hooksecurefunc('WorldMapFrame_SetFullMapView', reskinAndReposition)
    hooksecurefunc('WorldMapFrame_SetMiniMode', function()
        if EnabledSmall() then reskinAndReposition() end
    end)
    hooksecurefunc('ToggleMapFramerate', reskinAndReposition)
    hooksecurefunc('WorldMapFrame_ToggleAdvanced', reskinAndReposition)
end

local f = CreateFrame('Frame')
f:RegisterEvent('PLAYER_LOGIN')
f:SetScript('OnEvent', function()
    ApplyWorldMapMode()
    HookModeChanges()
end)

