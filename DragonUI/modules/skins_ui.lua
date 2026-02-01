local addon = select(2, ...)

-- DragonUI UI Skins - Clean dark theme for Blizzard frames
-- Approach: Hide original textures, add dark backdrop behind content
-- Supports: CharacterFrame, SpellBook, QuestLog, Friends/Who/Guild

local texBase = "Interface\\AddOns\\DragonUI\\assets\\ui\\"

-- Standard backdrop for skinned frames
local SKIN_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local SKIN_BACKDROP_COLOR = { 0.05, 0.05, 0.08, 0.95 }
local SKIN_BORDER_COLOR = { 0.3, 0.3, 0.35, 1 }

local function safeHookScript(frame, script, func)
    if frame and frame.HookScript then
        frame:HookScript(script, func)
    end
end

-- Hide all background textures on a frame by checking texture path
local function HideBackgroundTextures(frame)
    if not frame then return end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region:GetObjectType() == "Texture" then
            local tex = region:GetTexture()
            if tex then
                local texLower = string.lower(tex)
                -- Hide common background texture patterns
                if string.find(texLower, "ui%-character") or
                   string.find(texLower, "paperdoll") or
                   string.find(texLower, "ui%-spellbook") or
                   string.find(texLower, "ui%-questlog") or
                   string.find(texLower, "ui%-friendsframe") or
                   string.find(texLower, "dialogframe") then
                    region:Hide()
                    region:SetAlpha(0)
                end
            end
        end
    end
end

-- Create a skinned backdrop for a frame
local function CreateSkinBackdrop(frame, insetL, insetR, insetT, insetB)
    if not frame or frame.DragonUI_Backdrop then return end
    
    insetL = insetL or 8
    insetR = insetR or 8
    insetT = insetT or 8
    insetB = insetB or 8
    
    local backdrop = CreateFrame("Frame", nil, frame)
    backdrop:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
    backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", insetL, -insetT)
    backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insetR, insetB)
    backdrop:SetBackdrop(SKIN_BACKDROP)
    backdrop:SetBackdropColor(unpack(SKIN_BACKDROP_COLOR))
    backdrop:SetBackdropBorderColor(unpack(SKIN_BORDER_COLOR))
    
    frame.DragonUI_Backdrop = backdrop
    return backdrop
end

-- Close button re-skinning (smaller circular DF-style)
local function ReskinCloseButton(button, parent, offX, offY)
    if not button then return end
    button:SetNormalTexture(texBase .. "close_normal.tga")
    button:SetPushedTexture(texBase .. "close_pushed.tga")
    button:SetHighlightTexture(texBase .. "close_normal.tga")
    button:SetSize(20, 20)
    if parent and offX and offY then
        button:ClearAllPoints()
        button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", offX, offY)
    end
end

-- ============================================================================
-- CHARACTER FRAME SKIN
-- ============================================================================
local function ApplyCharacterFrameSkin()
    local frame = _G.CharacterFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- Hide the default background textures
    local bgTextures = {
        "CharacterFrameTopLeft", "CharacterFrameTopRight",
        "CharacterFrameBottomLeft", "CharacterFrameBottomRight",
        "CharacterFrameTop", "CharacterFrameBottom",
        "CharacterFrameLeft", "CharacterFrameRight",
        "CharacterFrameInset", "CharacterFrameInsetRight",
    }
    for _, name in ipairs(bgTextures) do
        local tex = _G[name]
        if tex then tex:SetAlpha(0) end
    end
    
    -- Also hide textures by pattern
    HideBackgroundTextures(frame)
    
    -- Create dark backdrop
    CreateSkinBackdrop(frame, 4, 4, 4, 4)
    
    -- Style the tabs
    for i = 1, 5 do
        local tab = _G["CharacterFrameTab" .. i]
        if tab then
            local left = _G["CharacterFrameTab" .. i .. "Left"]
            local middle = _G["CharacterFrameTab" .. i .. "Middle"]
            local right = _G["CharacterFrameTab" .. i .. "Right"]
            if left then left:SetAlpha(0.5) end
            if middle then middle:SetAlpha(0.5) end
            if right then right:SetAlpha(0.5) end
        end
    end
    
    -- Subframes
    local subs = { "PaperDollFrame", "PetPaperDollFrame", "ReputationFrame", "SkillFrame", "TokenFrame" }
    for _, name in ipairs(subs) do
        local subFrame = _G[name]
        if subFrame then
            HideBackgroundTextures(subFrame)
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
    
    -- Hide default background textures
    local bgTextures = {
        "SpellBookFrameTopLeft", "SpellBookFrameTopRight",
        "SpellBookFrameBotLeft", "SpellBookFrameBotRight",
        "SpellBookPage1", "SpellBookPage2",
    }
    for _, name in ipairs(bgTextures) do
        local tex = _G[name]
        if tex then tex:SetAlpha(0) end
    end
    
    HideBackgroundTextures(frame)
    
    -- Create dark backdrop
    CreateSkinBackdrop(frame, 8, 8, 8, 8)
    
    -- Style spell buttons
    for i = 1, 12 do
        local button = _G["SpellButton" .. i]
        if button then
            local autoCast = _G["SpellButton" .. i .. "AutoCastable"]
            if autoCast then autoCast:SetAlpha(0.7) end
        end
        
        local subText = _G["SpellButton" .. i .. "SubSpellName"]
        if subText and subText.SetTextColor then
            subText:SetTextColor(0.7, 0.7, 0.6, 1)
        end
    end
    
    -- Style tabs
    for i = 1, MAX_SKILLLINE_TABS or 8 do
        local tab = _G["SpellBookSkillLineTab" .. i]
        if tab then
            -- Slight cleanup of tab appearance
            local bg = tab:GetNormalTexture()
            if bg then bg:SetAlpha(0.8) end
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
    
    -- Hide the parchment textures
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region:GetObjectType() == "Texture" then
            local tex = region:GetTexture()
            if tex then
                local texLower = string.lower(tex)
                if string.find(texLower, "questlog") or string.find(texLower, "questframe") then
                    region:SetAlpha(0)
                end
            end
        end
    end
    
    HideBackgroundTextures(frame)
    
    -- Create dark backdrop
    CreateSkinBackdrop(frame, 6, 6, 6, 6)
    
    -- QuestLogDetailFrame background
    local detail = _G.QuestLogDetailFrame
    if detail then
        HideBackgroundTextures(detail)
    end
end

-- ============================================================================
-- FRIENDS / WHO / GUILD SKIN
-- ============================================================================
local function ApplyFriendsSkin()
    local frame = _G.FriendsFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- Hide background textures
    local bgTextures = {
        "FriendsFrameTopLeft", "FriendsFrameTopRight",
        "FriendsFrameBottomLeft", "FriendsFrameBottomRight",
    }
    for _, name in ipairs(bgTextures) do
        local tex = _G[name]
        if tex then tex:SetAlpha(0) end
    end
    
    HideBackgroundTextures(frame)
    
    -- Create dark backdrop
    CreateSkinBackdrop(frame, 4, 4, 4, 4)
    
    -- Style tabs
    for i = 1, 5 do
        local tab = _G["FriendsFrameTab" .. i]
        if tab then
            local left = _G["FriendsFrameTab" .. i .. "Left"]
            local middle = _G["FriendsFrameTab" .. i .. "Middle"]
            local right = _G["FriendsFrameTab" .. i .. "Right"]
            if left then left:SetAlpha(0.5) end
            if middle then middle:SetAlpha(0.5) end
            if right then right:SetAlpha(0.5) end
        end
    end
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
            { frame = _G.CharacterFrame, btn = _G.CharacterFrameCloseButton, x = -4, y = -4 },
            { frame = _G.SpellBookFrame, btn = _G.SpellBookCloseButton, x = -4, y = -4 },
            { frame = _G.QuestLogFrame, btn = _G.QuestLogFrameCloseButton, x = -4, y = -4 },
            { frame = _G.FriendsFrame, btn = _G.FriendsFrameCloseButton, x = -4, y = -4 },
            { frame = _G.TalentFrame, btn = _G.TalentFrameCloseButton, x = -4, y = -4 },
            { frame = _G.HelpFrame, btn = _G.HelpFrameCloseButton, x = -10, y = -10 },
            { frame = _G.QuestFrame, btn = _G.QuestFrameCloseButton, x = -4, y = -4 },
        }
        for _, t in ipairs(closeTargets) do
            if t.btn then 
                ReskinCloseButton(t.btn, t.frame, t.x, t.y) 
            end
        end

        -- Bag close buttons
        for i = 1, NUM_CONTAINER_FRAMES or 13 do
            local frame = _G["ContainerFrame" .. i]
            local btn = _G["ContainerFrame" .. i .. "CloseButton"]
            if frame and btn then
                ReskinCloseButton(btn, frame, -2, -2)
            end
        end
    end
end)

