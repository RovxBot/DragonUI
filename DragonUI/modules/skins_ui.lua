local addon = select(2, ...)

-- DragonUI UI Skins - Authentic Dragonflight panel styling
-- Uses the 4-corner paperdoll textures for the DF look

local texBase = "Interface\\AddOns\\DragonUI\\assets\\ui\\"

-- Texture paths
local TEX_TOP_LEFT = texBase .. "paperdoll_top_left.tga"
local TEX_TOP_RIGHT = texBase .. "paperdoll_top_right.tga"
local TEX_BOT_LEFT = texBase .. "paperdoll_bot_left.tga"
local TEX_BOT_RIGHT = texBase .. "paperdoll_bot_right.tga"
local TEX_CLOSE_NORMAL = texBase .. "close_normal.tga"
local TEX_CLOSE_PUSHED = texBase .. "close_pushed.tga"
local TEX_HEADER = texBase .. "top_ui_header.tga"
local TEX_HEADER_LEFT = texBase .. "top_ui_header_left.tga"
local TEX_HEADER_RIGHT = texBase .. "top_ui_header_right.tga"

local function safeHookScript(frame, script, func)
    if frame and frame.HookScript then
        frame:HookScript(script, func)
    end
end

-- Aggressively hide ALL textures on a frame (except portraits)
local function HideAllFrameTextures(frame)
    if not frame then return end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region:GetObjectType() == "Texture" then
            local name = region:GetName() or ""
            if not string.find(string.lower(name), "portrait") then
                region:SetTexture(nil)
                region:Hide()
                region:SetAlpha(0)
            end
        end
    end
end

-- Hide textures by global name
local function HideNamedTextures(names)
    for _, name in ipairs(names) do
        local tex = _G[name]
        if tex then 
            tex:SetTexture(nil)
            tex:Hide()
            tex:SetAlpha(0)
        end
    end
end

-- Create DF-style panel background
-- Solid dark base + 4-corner decorative textures
local function CreateDFPanelBackground(frame)
    if not frame or frame.DragonUI_DFBackground then return end
    
    local bg = CreateFrame("Frame", nil, frame)
    bg:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
    bg:SetAllPoints(frame)
    
    -- Solid dark background (covers everything)
    local solid = bg:CreateTexture(nil, "BACKGROUND", nil, -8)
    solid:SetTexture("Interface\\Buttons\\WHITE8x8")
    solid:SetVertexColor(0.06, 0.06, 0.08, 1)
    solid:SetAllPoints(bg)
    bg.solid = solid
    
    -- Top-left corner (256x256)
    local tl = bg:CreateTexture(nil, "BACKGROUND", nil, -7)
    tl:SetTexture(TEX_TOP_LEFT)
    tl:SetSize(256, 256)
    tl:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
    
    -- Top-right corner (128x256)
    local tr = bg:CreateTexture(nil, "BACKGROUND", nil, -7)
    tr:SetTexture(TEX_TOP_RIGHT)
    tr:SetSize(128, 256)
    tr:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 0, 0)
    
    -- Bottom-left corner (256x256)
    local bl = bg:CreateTexture(nil, "BACKGROUND", nil, -7)
    bl:SetTexture(TEX_BOT_LEFT)
    bl:SetSize(256, 256)
    bl:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
    
    -- Bottom-right corner (128x256)
    local br = bg:CreateTexture(nil, "BACKGROUND", nil, -7)
    br:SetTexture(TEX_BOT_RIGHT)
    br:SetSize(128, 256)
    br:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0)
    
    frame.DragonUI_DFBackground = bg
    return bg
end

-- Create DF-style header decoration
local function CreateDFHeader(frame)
    if not frame or frame.DragonUI_Header then return end
    
    local left = frame:CreateTexture(nil, "OVERLAY")
    left:SetTexture(TEX_HEADER_LEFT)
    left:SetSize(50, 50)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", -15, 22)
    
    local mid = frame:CreateTexture(nil, "ARTWORK")
    mid:SetTexture(TEX_HEADER)
    mid:SetHeight(50)
    mid:SetPoint("LEFT", left, "RIGHT", -25, 0)
    mid:SetPoint("RIGHT", frame, "TOPRIGHT", -25, 0)
    
    local right = frame:CreateTexture(nil, "OVERLAY")
    right:SetTexture(TEX_HEADER_RIGHT)
    right:SetSize(50, 50)
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 15, 22)
    
    frame.DragonUI_Header = { left = left, mid = mid, right = right }
    return frame.DragonUI_Header
end

-- Close button re-skinning
local function ReskinCloseButton(button, parent, offX, offY)
    if not button then return end
    button:SetNormalTexture(TEX_CLOSE_NORMAL)
    button:SetPushedTexture(TEX_CLOSE_PUSHED)
    button:SetHighlightTexture(TEX_CLOSE_NORMAL)
    button:SetSize(18, 18)
    if parent and offX and offY then
        button:ClearAllPoints()
        button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", offX, offY)
    end
end

-- Style tabs
local function StyleTabs(baseName, count)
    for i = 1, count do
        local tab = _G[baseName .. i]
        if tab then
            local left = _G[baseName .. i .. "Left"]
            local middle = _G[baseName .. i .. "Middle"]
            local right = _G[baseName .. i .. "Right"]
            if left then left:SetAlpha(0.6) end
            if middle then middle:SetAlpha(0.6) end
            if right then right:SetAlpha(0.6) end
        end
    end
end

-- ============================================================================
-- CHARACTER FRAME SKIN
-- ============================================================================
local function ApplyCharacterFrameSkin()
    local frame = _G.CharacterFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- Hide ALL Blizzard textures by name
    HideNamedTextures({
        "CharacterFrameTopLeft", "CharacterFrameTopRight",
        "CharacterFrameBottomLeft", "CharacterFrameBottomRight",
        "CharacterFrameTop", "CharacterFrameBottom",
        "CharacterFrameLeft", "CharacterFrameRight",
        "CharacterFrameInset", "CharacterFrameInsetRight",
        "CharacterFrameInsetRightInset",
        "CharacterFramePortraitFrame",
    })
    
    -- Hide any remaining textures on the frame
    HideAllFrameTextures(frame)
    
    -- Apply DF background
    CreateDFPanelBackground(frame)
    
    -- Add header decoration  
    CreateDFHeader(frame)
    
    -- Style tabs
    StyleTabs("CharacterFrameTab", 5)
    
    -- Hide subframe textures
    local subs = { "PaperDollFrame", "PetPaperDollFrame", "ReputationFrame", "SkillFrame", "TokenFrame", "HonorFrame" }
    for _, name in ipairs(subs) do
        local subFrame = _G[name]
        if subFrame then
            HideAllFrameTextures(subFrame)
        end
    end
end

-- ============================================================================
-- QUEST LOG SKIN
-- ============================================================================
local function ApplyQuestLogSkin()
    local frame = _G.QuestLogFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- Hide ALL textures - quest log has many
    HideAllFrameTextures(frame)
    
    -- Also hide the count frame textures
    if _G.QuestLogCount then
        HideAllFrameTextures(_G.QuestLogCount)
    end
    
    -- Hide detail frame
    if _G.QuestLogDetailFrame then
        HideAllFrameTextures(_G.QuestLogDetailFrame)
    end
    
    -- Apply DF background
    CreateDFPanelBackground(frame)
    
    -- Header
    CreateDFHeader(frame)
end

-- ============================================================================
-- SPELLBOOK SKIN
-- ============================================================================
local function ApplySpellbookSkin()
    local frame = _G.SpellBookFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- Hide textures by name
    HideNamedTextures({
        "SpellBookFrameTopLeft", "SpellBookFrameTopRight",
        "SpellBookFrameBotLeft", "SpellBookFrameBotRight",
        "SpellBookPage1", "SpellBookPage2",
    })
    
    -- Hide remaining textures
    HideAllFrameTextures(frame)
    
    -- Apply DF background
    CreateDFPanelBackground(frame)
    
    -- Header
    CreateDFHeader(frame)
end

-- ============================================================================
-- FRIENDS / WHO / GUILD SKIN
-- ============================================================================
local function ApplyFriendsSkin()
    local frame = _G.FriendsFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- Hide textures by name
    HideNamedTextures({
        "FriendsFrameTopLeft", "FriendsFrameTopRight",
        "FriendsFrameBottomLeft", "FriendsFrameBottomRight",
    })
    
    -- Hide remaining textures
    HideAllFrameTextures(frame)
    
    -- Apply DF background
    CreateDFPanelBackground(frame)
    
    -- Header
    CreateDFHeader(frame)
    
    -- Style tabs
    StyleTabs("FriendsFrameTab", 5)
end

-- ============================================================================
-- ENTRY POINT
-- ============================================================================
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    local skins = (addon.db and addon.db.profile and addon.db.profile.skins) or {}
    local function enabled(key) return skins[key] ~= false end

    -- Character Frame
    if enabled('character') and _G.CharacterFrame then
        safeHookScript(_G.CharacterFrame, "OnShow", ApplyCharacterFrameSkin)
    end

    -- Spellbook
    if enabled('spellbook') and _G.SpellBookFrame then
        safeHookScript(_G.SpellBookFrame, "OnShow", ApplySpellbookSkin)
    end

    -- QuestLog
    if enabled('questlog') and _G.QuestLogFrame then
        safeHookScript(_G.QuestLogFrame, "OnShow", ApplyQuestLogSkin)
    end

    -- Friends / Who / Guild
    if enabled('friends') and _G.FriendsFrame then
        safeHookScript(_G.FriendsFrame, "OnShow", ApplyFriendsSkin)
    end

    -- Close buttons
    if enabled('closebuttons') then
        local closeTargets = {
            { frame = _G.CharacterFrame, btn = _G.CharacterFrameCloseButton, x = -3, y = 17 },
            { frame = _G.SpellBookFrame, btn = _G.SpellBookCloseButton, x = -3, y = 17 },
            { frame = _G.QuestLogFrame, btn = _G.QuestLogFrameCloseButton, x = -3, y = 17 },
            { frame = _G.FriendsFrame, btn = _G.FriendsFrameCloseButton, x = -3, y = 17 },
            { frame = _G.TalentFrame, btn = _G.TalentFrameCloseButton, x = -3, y = 17 },
            { frame = _G.QuestFrame, btn = _G.QuestFrameCloseButton, x = -3, y = 17 },
        }
        for _, t in ipairs(closeTargets) do
            if t.btn then 
                ReskinCloseButton(t.btn, t.frame, t.x, t.y) 
            end
        end

        -- Bag close buttons
        for i = 1, NUM_CONTAINER_FRAMES or 13 do
            local bagFrame = _G["ContainerFrame" .. i]
            local btn = _G["ContainerFrame" .. i .. "CloseButton"]
            if bagFrame and btn then
                ReskinCloseButton(btn, bagFrame, -2, -2)
            end
        end
    end
end)

