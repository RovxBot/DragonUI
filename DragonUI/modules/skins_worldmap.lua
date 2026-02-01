local addon = select(2, ...)

-- Dragonflight-style World Map skin + small map toggle
-- Uses the DF panel textures for authentic look

local function EnabledSkin()  
    return addon and addon.db and addon.db.profile and addon.db.profile.skins and addon.db.profile.skins.worldmap_skin ~= false  
end

local function EnabledSmall() 
    return addon and addon.db and addon.db.profile and addon.db.profile.skins and addon.db.profile.skins.worldmap_small ~= false 
end

local texBase = "Interface\\AddOns\\DragonUI\\assets\\ui\\"

local TEX_TOP_LEFT = texBase .. "paperdoll_top_left.tga"
local TEX_TOP_RIGHT = texBase .. "paperdoll_top_right.tga"
local TEX_BOT_LEFT = texBase .. "paperdoll_bot_left.tga"
local TEX_BOT_RIGHT = texBase .. "paperdoll_bot_right.tga"
local TEX_CLOSE_NORMAL = texBase .. "close_normal.tga"
local TEX_CLOSE_PUSHED = texBase .. "close_pushed.tga"
local TEX_HEADER = texBase .. "top_ui_header.tga"
local TEX_HEADER_LEFT = texBase .. "top_ui_header_left.tga"
local TEX_HEADER_RIGHT = texBase .. "top_ui_header_right.tga"

local function ReskinClose(btn)
    if not btn then return end
    btn:SetNormalTexture(TEX_CLOSE_NORMAL)
    btn:SetPushedTexture(TEX_CLOSE_PUSHED)
    btn:SetHighlightTexture(TEX_CLOSE_NORMAL)
    btn:SetSize(18, 18)
end

local worldMapSkinned = false

local function ApplyWorldMapSkin()
    if not EnabledSkin() or not WorldMapFrame then return end
    if worldMapSkinned then return end
    worldMapSkinned = true
    
    -- Create DF-style background container
    local bg = CreateFrame('Frame', 'DragonUI_WorldMapBackground', WorldMapFrame)
    bg:SetFrameLevel(math.max(0, WorldMapFrame:GetFrameLevel() - 1))
    
    -- Determine anchor based on mode
    local anchor = WorldMapDetailFrame or WorldMapFrame
    
    -- Position background around the map
    bg:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -20, 40)
    bg:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', 20, -20)
    
    -- Create DF textures (4 corners)
    local tl = bg:CreateTexture(nil, "BACKGROUND")
    tl:SetTexture(TEX_TOP_LEFT)
    tl:SetSize(256, 256)
    tl:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
    
    local tr = bg:CreateTexture(nil, "BACKGROUND")
    tr:SetTexture(TEX_TOP_RIGHT)
    tr:SetSize(128, 256)
    tr:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 0, 0)
    
    local bl = bg:CreateTexture(nil, "BACKGROUND")
    bl:SetTexture(TEX_BOT_LEFT)
    bl:SetSize(256, 256)
    bl:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
    
    local br = bg:CreateTexture(nil, "BACKGROUND")
    br:SetTexture(TEX_BOT_RIGHT)
    br:SetSize(128, 256)
    br:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0)
    
    -- Header decoration
    local headerLeft = bg:CreateTexture(nil, "OVERLAY")
    headerLeft:SetTexture(TEX_HEADER_LEFT)
    headerLeft:SetSize(50, 50)
    headerLeft:SetPoint("TOPLEFT", bg, "TOPLEFT", -10, 20)
    
    local headerMid = bg:CreateTexture(nil, "ARTWORK")
    headerMid:SetTexture(TEX_HEADER)
    headerMid:SetHeight(50)
    headerMid:SetPoint("LEFT", headerLeft, "RIGHT", -25, 0)
    headerMid:SetPoint("RIGHT", bg, "RIGHT", -30, 0)
    
    local headerRight = bg:CreateTexture(nil, "OVERLAY")
    headerRight:SetTexture(TEX_HEADER_RIGHT)
    headerRight:SetSize(50, 50)
    headerRight:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 10, 20)

    -- Style close button
    local closeBtn = WorldMapFrameCloseButton
    if closeBtn then
        ReskinClose(closeBtn)
        closeBtn:ClearAllPoints()
        closeBtn:SetPoint('TOPRIGHT', bg, 'TOPRIGHT', -5, 15)
    end
    
    WorldMapFrame.DragonUI_Background = bg
end

local function ApplyWorldMapMode()
    if not WorldMapFrame then return end
    
    if EnabledSmall() then
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

local f = CreateFrame('Frame')
f:RegisterEvent('PLAYER_LOGIN')
f:SetScript('OnEvent', function()
    ApplyWorldMapMode()
    
    -- Hook OnShow to ensure skin is applied
    if WorldMapFrame then
        WorldMapFrame:HookScript('OnShow', function()
            ApplyWorldMapSkin()
            addon.RefreshWorldMapPosition()
        end)
    end
end)

