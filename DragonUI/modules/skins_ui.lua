local addon = select(2, ...)

-- DragonUI UI Skins - Authentic Dragonflight panel styling
-- Uses the 4-corner paperdoll textures for the DF look
-- Supports: CharacterFrame, SpellBook, QuestLog, Friends/Who/Guild

local texBase = "Interface\\AddOns\\DragonUI\\assets\\ui\\"

-- Texture paths for DF panel backgrounds
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

-- Hide all background textures on a frame
local function HideFrameTextures(frame, patterns)
    if not frame then return end
    
    -- Hide by global name
    if patterns then
        for _, name in ipairs(patterns) do
            local tex = _G[name]
            if tex then 
                tex:Hide()
                tex:SetAlpha(0)
            end
        end
    end
    
    -- Hide by iterating regions
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region:GetObjectType() == "Texture" then
            local tex = region:GetTexture()
            if tex then
                local texLower = string.lower(tex)
                if string.find(texLower, "ui%-character") or
                   string.find(texLower, "paperdoll") or
                   string.find(texLower, "ui%-spellbook") or
                   string.find(texLower, "ui%-questlog") or
                   string.find(texLower, "ui%-friendsframe") or
                   string.find(texLower, "dialogframe") or
                   string.find(texLower, "parchment") then
                    region:Hide()
                    region:SetAlpha(0)
                end
            end
        end
    end
end

-- Create DF-style 4-corner panel background
-- This creates the authentic Dragonflight look using the paperdoll textures
local function CreateDFPanelBackground(frame, offsetL, offsetR, offsetT, offsetB)
    if not frame or frame.DragonUI_DFBackground then return end
    
    offsetL = offsetL or 0
    offsetR = offsetR or 0
    offsetT = offsetT or 0
    offsetB = offsetB or 0
    
    -- Create container frame for our textures
    local bg = CreateFrame("Frame", nil, frame)
    bg:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
    bg:SetAllPoints(frame)
    
    -- Top-left corner (256x256)
    local tl = bg:CreateTexture(nil, "BACKGROUND")
    tl:SetTexture(TEX_TOP_LEFT)
    tl:SetSize(256, 256)
    tl:SetPoint("TOPLEFT", frame, "TOPLEFT", offsetL, offsetT)
    
    -- Top-right corner (128x256)
    local tr = bg:CreateTexture(nil, "BACKGROUND")
    tr:SetTexture(TEX_TOP_RIGHT)
    tr:SetSize(128, 256)
    tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", offsetR, offsetT)
    
    -- Bottom-left corner (256x256)
    local bl = bg:CreateTexture(nil, "BACKGROUND")
    bl:SetTexture(TEX_BOT_LEFT)
    bl:SetSize(256, 256)
    bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", offsetL, offsetB)
    
    -- Bottom-right corner (128x256)
    local br = bg:CreateTexture(nil, "BACKGROUND")
    br:SetTexture(TEX_BOT_RIGHT)
    br:SetSize(128, 256)
    br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offsetR, offsetB)
    
    frame.DragonUI_DFBackground = bg
    frame.DragonUI_DFBackground.tl = tl
    frame.DragonUI_DFBackground.tr = tr
    frame.DragonUI_DFBackground.bl = bl
    frame.DragonUI_DFBackground.br = br
    
    return bg
end

-- Create DF-style header decoration
local function CreateDFHeader(frame, yOffset)
    if not frame or frame.DragonUI_Header then return end
    
    yOffset = yOffset or 0
    
    -- Left cap
    local left = frame:CreateTexture(nil, "OVERLAY")
    left:SetTexture(TEX_HEADER_LEFT)
    left:SetSize(50, 50)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", -10, yOffset + 20)
    
    -- Middle sections (stretch across)
    local mid = frame:CreateTexture(nil, "ARTWORK")
    mid:SetTexture(TEX_HEADER)
    mid:SetSize(frame:GetWidth() - 60, 50)
    mid:SetPoint("TOP", frame, "TOP", 0, yOffset + 20)
    
    -- Right cap
    local right = frame:CreateTexture(nil, "OVERLAY")
    right:SetTexture(TEX_HEADER_RIGHT)
    right:SetSize(50, 50)
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 10, yOffset + 20)
    
    frame.DragonUI_Header = { left = left, mid = mid, right = right }
    return frame.DragonUI_Header
end

-- Close button re-skinning (DF-style)
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

-- Style tabs with semi-transparent look
local function StyleTabs(baseName, count)
    for i = 1, count do
        local tab = _G[baseName .. i]
        if tab then
            local left = _G[baseName .. i .. "Left"]
            local middle = _G[baseName .. i .. "Middle"]
            local right = _G[baseName .. i .. "Right"]
            local leftDisabled = _G[baseName .. i .. "LeftDisabled"]
            local middleDisabled = _G[baseName .. i .. "MiddleDisabled"]
            local rightDisabled = _G[baseName .. i .. "RightDisabled"]
            
            -- Fade the tab textures for a cleaner look
            if left then left:SetAlpha(0.6) end
            if middle then middle:SetAlpha(0.6) end
            if right then right:SetAlpha(0.6) end
            if leftDisabled then leftDisabled:SetAlpha(0.4) end
            if middleDisabled then middleDisabled:SetAlpha(0.4) end
            if rightDisabled then rightDisabled:SetAlpha(0.4) end
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
    
    -- Hide Blizzard's default textures
    local bgTextures = {
        "CharacterFrameTopLeft", "CharacterFrameTopRight",
        "CharacterFrameBottomLeft", "CharacterFrameBottomRight",
        "CharacterFrameTop", "CharacterFrameBottom",
        "CharacterFrameLeft", "CharacterFrameRight",
        "CharacterFrameInset", "CharacterFrameInsetRight",
        "CharacterFrameInsetRightInset",
    }
    HideFrameTextures(frame, bgTextures)
    
    -- Apply DF background
    CreateDFPanelBackground(frame, -5, 5, 10, -5)
    
    -- Add header decoration
    CreateDFHeader(frame, 0)
    
    -- Style tabs
    StyleTabs("CharacterFrameTab", 5)
    
    -- Hide subframe textures
    local subs = { "PaperDollFrame", "PetPaperDollFrame", "ReputationFrame", "SkillFrame", "TokenFrame", "HonorFrame" }
    for _, name in ipairs(subs) do
        local subFrame = _G[name]
        if subFrame then
            HideFrameTextures(subFrame)
        end
    end
end

-- ============================================================================
-- SPELLBOOK SKIN
-- ============================================================================
local function ApplySpellbookSkin()
    local frame = _G.SpellBookFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- Hide Blizzard textures
    local bgTextures = {
        "SpellBookFrameTopLeft", "SpellBookFrameTopRight",
        "SpellBookFrameBotLeft", "SpellBookFrameBotRight",
        "SpellBookPage1", "SpellBookPage2",
        "SpellBookFrameLeft", "SpellBookFrameRight",
        "SpellBookFrameTop", "SpellBookFrameBottom",
    }
    HideFrameTextures(frame, bgTextures)
    
    -- Apply DF background
    CreateDFPanelBackground(frame, -5, 5, 10, -5)
    
    -- Add header
    CreateDFHeader(frame, 0)
    
    -- Style spell buttons - subtle improvements
    for i = 1, 12 do
        local subText = _G["SpellButton" .. i .. "SubSpellName"]
        if subText and subText.SetTextColor then
            subText:SetTextColor(0.8, 0.8, 0.7, 1)
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
    
    -- Hide all textures - quest log uses unique parchment textures
    HideFrameTextures(frame)
    
    -- Also hide specific quest log textures
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region:GetObjectType() == "Texture" then
            region:Hide()
            region:SetAlpha(0)
        end
    end
    
    -- Apply DF background (quest log is wider)
    CreateDFPanelBackground(frame, -5, 5, 10, -5)
    
    -- Header
    CreateDFHeader(frame, 0)
    
    -- Hide detail frame textures too
    if _G.QuestLogDetailFrame then
        HideFrameTextures(_G.QuestLogDetailFrame)
    end
end

-- ============================================================================
-- FRIENDS / WHO / GUILD SKIN
-- ============================================================================
local function ApplyFriendsSkin()
    local frame = _G.FriendsFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- Hide Blizzard textures
    local bgTextures = {
        "FriendsFrameTopLeft", "FriendsFrameTopRight",
        "FriendsFrameBottomLeft", "FriendsFrameBottomRight",
        "FriendsFrameTop", "FriendsFrameBottom",
        "FriendsFrameLeft", "FriendsFrameRight",
    }
    HideFrameTextures(frame, bgTextures)
    
    -- Apply DF background
    CreateDFPanelBackground(frame, -5, 5, 10, -5)
    
    -- Header
    CreateDFHeader(frame, 0)
    
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
    if enabled('character') then
        if _G.CharacterFrame then
            safeHookScript(_G.CharacterFrame, "OnShow", ApplyCharacterFrameSkin)
            if _G.CharacterFrame:IsShown() then
                ApplyCharacterFrameSkin()
            end
        end
    end

    -- Spellbook
    if enabled('spellbook') then
        if _G.SpellBookFrame then
            safeHookScript(_G.SpellBookFrame, "OnShow", ApplySpellbookSkin)
            if _G.SpellBookFrame:IsShown() then
                ApplySpellbookSkin()
            end
        end
    end

    -- QuestLog
    if enabled('questlog') then
        if _G.QuestLogFrame then
            safeHookScript(_G.QuestLogFrame, "OnShow", ApplyQuestLogSkin)
            if _G.QuestLogFrame:IsShown() then
                ApplyQuestLogSkin()
            end
        end
    end

    -- Friends / Who / Guild
    if enabled('friends') then
        if _G.FriendsFrame then
            safeHookScript(_G.FriendsFrame, "OnShow", ApplyFriendsSkin)
            if _G.FriendsFrame:IsShown() then
                ApplyFriendsSkin()
            end
        end
    end

    -- Close buttons
    if enabled('closebuttons') then
        local closeTargets = {
            { frame = _G.CharacterFrame, btn = _G.CharacterFrameCloseButton, x = -8, y = 15 },
            { frame = _G.SpellBookFrame, btn = _G.SpellBookCloseButton, x = -8, y = 15 },
            { frame = _G.QuestLogFrame, btn = _G.QuestLogFrameCloseButton, x = -8, y = 15 },
            { frame = _G.FriendsFrame, btn = _G.FriendsFrameCloseButton, x = -8, y = 15 },
            { frame = _G.TalentFrame, btn = _G.TalentFrameCloseButton, x = -8, y = 15 },
            { frame = _G.HelpFrame, btn = _G.HelpFrameCloseButton, x = -10, y = -10 },
            { frame = _G.QuestFrame, btn = _G.QuestFrameCloseButton, x = -8, y = 15 },
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

