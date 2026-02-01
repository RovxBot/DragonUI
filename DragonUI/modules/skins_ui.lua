local addon = select(2, ...)

-- DragonUI UI Skins - Dark modern panel styling
-- Uses native WoW 3.3.5a textures for guaranteed compatibility

local dfBase = "Interface\\AddOns\\DragonUI\\Textures\\UI\\"

local DF_TEX_FRAME = dfBase .. "uiframemetal2x.blp"
local DF_TEX_EDGE_H = dfBase .. "uiframemetalhorizontal2x.blp"
local DF_TEX_EDGE_V = dfBase .. "uiframemetalvertical2x.blp"
local DF_TEX_BG = dfBase .. "ui-background-rock.blp"
local DF_TEX_STREAK = dfBase .. "uiframehorizontal.blp"
local DF_TEX_CLOSE = dfBase .. "redbutton2x.blp"
local DF_TEX_TABS = dfBase .. "uiframetabs.blp"

local function safeHookScript(frame, script, func)
    if frame and frame.HookScript then
        frame:HookScript(script, func)
    end
end

-- NUCLEAR OPTION: Hide absolutely everything on a frame (and optionally children)
local function NukeAllTextures(frame, keepPortrait, recursive)
    if not frame then return end
    
    -- Get all regions
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region:GetObjectType() == "Texture" then
            local name = region:GetName() or ""
            local nameLower = string.lower(name)
            
            -- Preserve resistance icons/labels
            if string.find(nameLower, "resist") then
                -- keep
            -- Only keep portrait if requested
            elseif keepPortrait and string.find(nameLower, "portrait") and not string.find(nameLower, "frame") then
                -- Keep the actual portrait texture (not PortraitFrame)
            else
                region:Hide()
                region:SetTexture(nil)
                region:SetAlpha(0)
            end
        end
    end
    
    -- Recursively handle children if requested
    if recursive then
        local children = { frame:GetChildren() }
        for _, child in ipairs(children) do
            local ctype = child and child.GetObjectType and child:GetObjectType() or nil
            local cname = child and child.GetName and child:GetName() or ""
            local cnameLower = string.lower(cname or "")
            -- Preserve button/slider/editbox textures (keeps scrollbars and buttons visible)
            if ctype ~= "Button" and ctype ~= "Slider" and ctype ~= "EditBox" and not string.find(cnameLower, "resist") then
                NukeAllTextures(child, false, true)
            end
        end
    end
end

-- Hide specific named global textures
local function HideNamedTextures(names)
    for _, name in ipairs(names) do
        local tex = _G[name]
        if tex then
            tex:Hide()
            if tex.SetTexture then tex:SetTexture(nil) end
            if tex.SetAlpha then tex:SetAlpha(0) end
        end
    end
end

-- Forcefully cover a frame area with solid color (for model backgrounds)
local function CoverWithSolid(frame, r, g, b)
    if not frame or frame.DFSolidCover then return end
    
    -- Create cover at ARTWORK level to be above old background textures
    local cover = frame:CreateTexture(nil, "ARTWORK", nil, 7)
    cover:SetTexture("Interface\\Buttons\\WHITE8x8")
    cover:SetVertexColor(r or 0.05, g or 0.05, b or 0.07)
    cover:SetAllPoints(frame)
    cover:Show()
    frame.DFSolidCover = cover
end

-- Create the NineSlice frame structure
local function EnsureNineSlice(frame)
    if frame.DFNineSlice then return frame.DFNineSlice end

    local slice = {}
    slice.TopLeftCorner = frame:CreateTexture(nil, "BORDER")
    slice.TopRightCorner = frame:CreateTexture(nil, "BORDER")
    slice.BottomLeftCorner = frame:CreateTexture(nil, "BORDER")
    slice.BottomRightCorner = frame:CreateTexture(nil, "BORDER")
    slice.TopEdge = frame:CreateTexture(nil, "BORDER")
    slice.BottomEdge = frame:CreateTexture(nil, "BORDER")
    slice.LeftEdge = frame:CreateTexture(nil, "BORDER")
    slice.RightEdge = frame:CreateTexture(nil, "BORDER")

    frame.DFNineSlice = slice
    return slice
end

local function ApplyDFFrameTemplateNoPortrait(frame)
    local slice = EnsureNineSlice(frame)

    -- corners
    slice.TopLeftCorner:ClearAllPoints()
    slice.TopLeftCorner:SetTexture(DF_TEX_FRAME)
    slice.TopLeftCorner:SetTexCoord(0.00195312, 0.294922, 0.00195312, 0.294922)
    slice.TopLeftCorner:SetSize(75, 74)
    slice.TopLeftCorner:SetPoint("TOPLEFT", -12, 16)

    slice.TopRightCorner:ClearAllPoints()
    slice.TopRightCorner:SetTexture(DF_TEX_FRAME)
    slice.TopRightCorner:SetTexCoord(0.298828, 0.591797, 0.00195312, 0.294922)
    slice.TopRightCorner:SetSize(75, 74)
    slice.TopRightCorner:SetPoint("TOPRIGHT", 4, 16)

    slice.BottomLeftCorner:ClearAllPoints()
    slice.BottomLeftCorner:SetTexture(DF_TEX_FRAME)
    slice.BottomLeftCorner:SetTexCoord(0.298828, 0.423828, 0.298828, 0.423828)
    slice.BottomLeftCorner:SetSize(32, 32)
    slice.BottomLeftCorner:SetPoint("BOTTOMLEFT", -12, -3)

    slice.BottomRightCorner:ClearAllPoints()
    slice.BottomRightCorner:SetTexture(DF_TEX_FRAME)
    slice.BottomRightCorner:SetTexCoord(0.427734, 0.552734, 0.298828, 0.423828)
    slice.BottomRightCorner:SetSize(32, 32)
    slice.BottomRightCorner:SetPoint("BOTTOMRIGHT", 4, -3)

    -- edges
    slice.TopEdge:ClearAllPoints()
    slice.TopEdge:SetTexture(DF_TEX_EDGE_H)
    slice.TopEdge:SetTexCoord(0, 1, 0.00390625, 0.589844)
    slice.TopEdge:SetSize(32, 74)
    slice.TopEdge:SetPoint("TOPLEFT", slice.TopLeftCorner, "TOPRIGHT", 0, 0)
    slice.TopEdge:SetPoint("TOPRIGHT", slice.TopRightCorner, "TOPLEFT", 0, 0)

    slice.BottomEdge:ClearAllPoints()
    slice.BottomEdge:SetTexture(DF_TEX_EDGE_H)
    slice.BottomEdge:SetTexCoord(0, 0.5, 0.597656, 0.847656)
    slice.BottomEdge:SetSize(16, 32)
    slice.BottomEdge:SetPoint("TOPLEFT", slice.BottomLeftCorner, "TOPRIGHT", 0, 0)
    slice.BottomEdge:SetPoint("TOPRIGHT", slice.BottomRightCorner, "TOPLEFT", 0, 0)

    slice.LeftEdge:ClearAllPoints()
    slice.LeftEdge:SetTexture(DF_TEX_EDGE_V)
    slice.LeftEdge:SetTexCoord(0.00195312, 0.294922, 0, 1)
    slice.LeftEdge:SetSize(75, 16)
    slice.LeftEdge:SetPoint("TOPLEFT", slice.TopLeftCorner, "BOTTOMLEFT", 0, 0)
    slice.LeftEdge:SetPoint("BOTTOMLEFT", slice.BottomLeftCorner, "TOPLEFT", 0, 0)

    slice.RightEdge:ClearAllPoints()
    slice.RightEdge:SetTexture(DF_TEX_EDGE_V)
    slice.RightEdge:SetTexCoord(0.298828, 0.591797, 0, 1)
    slice.RightEdge:SetSize(75, 16)
    slice.RightEdge:SetPoint("TOPRIGHT", slice.TopRightCorner, "BOTTOMRIGHT", 0, 0)
    slice.RightEdge:SetPoint("BOTTOMRIGHT", slice.BottomRightCorner, "TOPRIGHT", 0, 0)
end

-- Create solid background that COVERS everything
local function CreateSolidBackground(frame, insetTop, insetBottom, insetLeft, insetRight, texturePath)
    if frame.DFBackground then return frame.DFBackground end
    
    insetTop = insetTop or 18
    insetBottom = insetBottom or 3
    insetLeft = insetLeft or 3
    insetRight = insetRight or 3
    
    -- Create a background frame at the LOWEST possible level
    local bgFrame = CreateFrame("Frame", nil, frame)
    bgFrame:SetFrameStrata("BACKGROUND")
    bgFrame:SetFrameLevel(0)
    bgFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", insetLeft, -insetTop)
    bgFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insetRight, insetBottom)
    
    -- First layer: solid black to block EVERYTHING
    local solid = bgFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    solid:SetTexture("Interface\\Buttons\\WHITE8x8")
    solid:SetVertexColor(0.05, 0.05, 0.07, 1)
    solid:SetAllPoints(bgFrame)
    bgFrame.solid = solid
    
    -- Second layer: rock texture on top
    local rock = bgFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
    rock:SetTexture(texturePath or DF_TEX_BG)
    rock:SetAllPoints(bgFrame)
    bgFrame.rock = rock
    
    frame.DFBackground = bgFrame
    return bgFrame
end

-- Add decorative streak at top (using gradient instead of custom texture)
local function AddStreak(frame)
    if frame.DFStreak then return end
    
    local streak = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    streak:SetTexture(DF_TEX_STREAK)
    streak:SetTexCoord(0, 1, 0.0078125, 0.34375)
    streak:SetSize(256, 43)
    streak:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -21)
    streak:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -21)
    
    frame.DFStreak = streak
end

-- Style close button (use default WoW style)
local function StyleCloseButton(button)
    if not button then return end
    local skins = addon.db and addon.db.profile and addon.db.profile.skins
    if skins and skins.closebuttons == false then return end
    button:SetSize(24, 24)
    local normal = button:GetNormalTexture()
    if normal then
        normal:SetTexture(DF_TEX_CLOSE)
        normal:SetTexCoord(0.152344, 0.292969, 0.0078125, 0.304688)
    end
    local disabled = button:GetDisabledTexture()
    if disabled then
        disabled:SetTexture(DF_TEX_CLOSE)
        disabled:SetTexCoord(0.152344, 0.292969, 0.320312, 0.617188)
    end
    local pushed = button:GetPushedTexture()
    if pushed then
        pushed:SetTexture(DF_TEX_CLOSE)
        pushed:SetTexCoord(0.152344, 0.292969, 0.632812, 0.929688)
    end
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetTexture(DF_TEX_CLOSE)
        highlight:SetTexCoord(0.449219, 0.589844, 0.0078125, 0.304688)
    end
end

-- Add portrait frame decoration
local function AddPortraitFrame(frame, portrait)
    if not portrait or frame.DFPortraitFrame then return end
    
    portrait:SetSize(62, 62)
    portrait:ClearAllPoints()
    portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 7)
    portrait:SetDrawLayer("OVERLAY", 6)
    portrait:Show()
    
    local pp = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    pp:SetTexture(DF_TEX_FRAME)
    pp:SetTexCoord(0.00195312, 0.294922, 0.298828, 0.591797)
    pp:SetSize(84, 84)
    pp:SetPoint("CENTER", portrait, "CENTER", 0, 0)
    
    frame.DFPortraitFrame = pp
end

local function EnsurePortraitTexture(portrait, unit)
    if not portrait then return end
    portrait:SetAlpha(1)
    portrait:Show()
    if SetPortraitTexture and unit then
        SetPortraitTexture(portrait, unit)
    end
end

local function ReskinCharacterTab(tab)
    if not tab then return end
    local name = tab:GetName()
    if not name then return end

    tab:SetHeight(32)

    local left = _G[name .. "Left"]
    local right = _G[name .. "Right"]
    local middle = _G[name .. "Middle"]
    if left then
        left:ClearAllPoints()
        left:SetTexture(DF_TEX_TABS)
        left:SetTexCoord(0.015625, 0.5625, 0.816406, 0.957031)
        left:SetSize(35, 36)
        left:SetPoint("TOPLEFT", -3, 0)
    end
    if right then
        right:ClearAllPoints()
        right:SetTexture(DF_TEX_TABS)
        right:SetTexCoord(0.015625, 0.59375, 0.667969, 0.808594)
        right:SetSize(37, 36)
        right:SetPoint("TOPRIGHT", 7, 0)
    end
    if middle then
        middle:ClearAllPoints()
        middle:SetTexture(DF_TEX_TABS)
        middle:SetTexCoord(0, 0.015625, 0.175781, 0.316406)
        middle:SetSize(1, 36)
        middle:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
        middle:SetPoint("TOPRIGHT", right, "TOPLEFT", 0, 0)
    end

    local leftD = _G[name .. "LeftDisabled"]
    local rightD = _G[name .. "RightDisabled"]
    local middleD = _G[name .. "MiddleDisabled"]
    if leftD then
        leftD:ClearAllPoints()
        leftD:SetTexture(DF_TEX_TABS)
        leftD:SetTexCoord(0.015625, 0.5625, 0.496094, 0.660156)
        leftD:SetSize(35, 42)
        leftD:SetPoint("TOPLEFT", -1, 0)
    end
    if rightD then
        rightD:ClearAllPoints()
        rightD:SetTexture(DF_TEX_TABS)
        rightD:SetTexCoord(0.015625, 0.59375, 0.324219, 0.488281)
        rightD:SetSize(37, 42)
        rightD:SetPoint("TOPRIGHT", 8, 0)
    end
    if middleD then
        middleD:ClearAllPoints()
        middleD:SetTexture(DF_TEX_TABS)
        middleD:SetTexCoord(0, 0.015625, 0.00390625, 0.167969)
        middleD:SetSize(1, 42)
        middleD:SetPoint("TOPLEFT", leftD, "TOPRIGHT", 0, 0)
        middleD:SetPoint("TOPRIGHT", rightD, "TOPLEFT", 0, 0)
    end
end

local function ReskinCharacterTabs()
    for i = 1, 5 do
        ReskinCharacterTab(_G["CharacterFrameTab" .. i])
    end
end

local function PositionCharacterTabs(frame)
    if not frame then return end
    local first = _G["CharacterFrameTab1"]
    if first then
        first:ClearAllPoints()
        first:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, -28)
    end
    for i = 2, 5 do
        local tab = _G["CharacterFrameTab" .. i]
        if tab then
            tab:ClearAllPoints()
            tab:SetPoint("LEFT", _G["CharacterFrameTab" .. (i - 1)], "RIGHT", 4, 0)
        end
    end
end

local function SetFontStringColorRecursive(frame, r, g, b)
    if not frame or not frame.GetRegions then return end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region:GetObjectType() == "FontString" then
            region:SetTextColor(r, g, b)
            region:SetShadowColor(0, 0, 0, 0.8)
            region:SetShadowOffset(1, -1)
        end
    end
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        SetFontStringColorRecursive(child, r, g, b)
    end
end

local function StyleEditBox(box)
    if not box or box.DFSkinned then return end
    box.DFSkinned = true
    local name = box:GetName()
    if name then
        local left = _G[name .. "Left"]
        local right = _G[name .. "Right"]
        local middle = _G[name .. "Middle"]
        if left then left:Hide() end
        if right then right:Hide() end
        if middle then middle:Hide() end
    end
    box:SetAutoFocus(false)
    box:SetHeight(20)
    if box.SetBackdrop then
        box:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        box:SetBackdropColor(0.08, 0.08, 0.1, 0.9)
        box:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end
end

local function StyleHeaderButton(btn)
    if not btn or btn.DFSkinned then return end
    btn.DFSkinned = true
    local name = btn:GetName()
    if name then
        local left = _G[name .. "Left"]
        local right = _G[name .. "Right"]
        local middle = _G[name .. "Middle"]
        if left then left:Hide() end
        if right then right:Hide() end
        if middle then middle:Hide() end
    end
    if btn.SetBackdrop then
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        btn:SetBackdropColor(0.08, 0.08, 0.1, 0.85)
        btn:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    end
    if btn.SetNormalFontObject then
        btn:SetNormalFontObject("GameFontNormal")
    end
end

local function EnsureInsetBackground(frame)
    if not frame or frame.DFInsetBG then return end
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.06, 0.06, 0.08, 0.7)
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    frame.DFInsetBG = bg
end

local function ReskinGenericTab(tab)
    if not tab then return end
    ReskinCharacterTab(tab)
    local text = tab.GetFontString and tab:GetFontString() or nil
    if text then text:SetTextColor(1, 0.82, 0) end
end

local function PositionFriendsTabs(frame)
    if not frame then return end
    local first = _G["FriendsFrameTab1"]
    if first then
        first:ClearAllPoints()
        first:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, -30)
        first:SetWidth(62)
    end
    for i = 2, 5 do
        local tab = _G["FriendsFrameTab" .. i]
        local prev = _G["FriendsFrameTab" .. (i - 1)]
        if tab and prev then
            tab:ClearAllPoints()
            tab:SetPoint("LEFT", prev, "RIGHT", 2, 0)
            tab:SetWidth(62)
        end
    end
end

local function ApplyFriendsTabs(frame)
    for i = 1, 5 do
        ReskinGenericTab(_G["FriendsFrameTab" .. i])
    end
    ReskinGenericTab(_G["FriendsFrameFriendButton"])
    ReskinGenericTab(_G["FriendsFrameIgnoreButton"])

    local fbtn = _G["FriendsFrameFriendButton"]
    local ibtn = _G["FriendsFrameIgnoreButton"]
    if fbtn then
        fbtn:ClearAllPoints()
        fbtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -30)
    end
    if ibtn and fbtn then
        ibtn:ClearAllPoints()
        ibtn:SetPoint("LEFT", fbtn, "RIGHT", 4, 0)
    end
end

local function ApplyQuestTextColors()
    local title = {
        "QuestLogQuestTitle",
        "QuestLogDescriptionTitle",
        "QuestLogObjectivesText",
        "QuestLogRewardTitleText",
        "QuestLogItemChooseText",
        "QuestLogItemReceiveText",
        "QuestLogSpellLearnText",
        "QuestLogRequirements",
        "QuestLogRewardText",
        "QuestLogRewardsText",
    }
    local body = {
        "QuestLogQuestDescription",
        "QuestLogQuestInfoObjectivesText",
        "QuestLogQuestInfoDescriptionText",
        "QuestLogObjectiveText",
        "QuestLogObjectivesText",
        "QuestLogSpecialObjectivesText",
        "QuestLogLeaderNameText",
        "QuestLogZoneDescriptionText",
        "QuestLogGroupDescriptionText",
    }

    for _, name in ipairs(title) do
        local fs = _G[name]
        if fs and fs.SetTextColor then
            fs:SetTextColor(1, 0.82, 0)
        end
    end
    for _, name in ipairs(body) do
        local fs = _G[name]
        if fs and fs.SetTextColor then
            fs:SetTextColor(0.85, 0.85, 0.85)
        end
    end

    local detail = _G["QuestLogDetailScrollChildFrame"] or _G["QuestLogDetailScrollFrame"]
    if detail then
        SetFontStringColorRecursive(detail, 0.9, 0.9, 0.9)
    end
end

local function StyleReputationCheckBox(cb)
    if not cb then return end
    cb:Show()
    cb:SetSize(18, 18)
    if cb.SetNormalTexture then
        cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    end
    if cb.SetPushedTexture then
        cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    end
    if cb.SetHighlightTexture then
        cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    end
    if cb.SetCheckedTexture then
        cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    end
    local checked = cb:GetCheckedTexture()
    if checked then
        checked:SetVertexColor(1, 0.82, 0)
        checked:SetAlpha(1)
    end
    local normal = cb:GetNormalTexture()
    if normal then
        normal:SetAlpha(1)
    end
    local pushed = cb:GetPushedTexture()
    if pushed then
        pushed:SetAlpha(1)
    end
    local bg = cb.DFBackdrop
    if not bg then
        bg = cb:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        bg:SetVertexColor(0.12, 0.12, 0.14, 0.9)
        bg:SetPoint("TOPLEFT", cb, "TOPLEFT", 2, -2)
        bg:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", -2, 2)
        cb.DFBackdrop = bg
    end
end

local function ApplyReputationSkin()
    local frame = ReputationFrame
    if not frame or frame.DFSkinned then return end
    frame.DFSkinned = true

    -- Style reputation bars
    local maxBars = NUM_FACTIONS_DISPLAYED or 20
    for i = 1, maxBars do
        local bar = _G["ReputationBar" .. i]
        if bar then
            if bar.SetStatusBarTexture then
                bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            end
            local bg = _G[bar:GetName() .. "Background"]
            if bg then
                bg:SetTexture("Interface\\Buttons\\WHITE8x8")
                bg:SetVertexColor(0.12, 0.12, 0.14, 0.9)
            end
            local left = _G[bar:GetName() .. "Left"]
            local right = _G[bar:GetName() .. "Right"]
            local middle = _G[bar:GetName() .. "Middle"]
            if left then left:Hide() end
            if right then right:Hide() end
            if middle then middle:Hide() end
            local highlight = _G[bar:GetName() .. "Highlight1"] or _G[bar:GetName() .. "Highlight"]
            if highlight then
                highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
                highlight:SetVertexColor(1, 0.82, 0, 0.2)
            end
        end
    end

    -- Detail pane background to avoid text on world
    local detail = _G["ReputationDetailFrame"]
    if detail and not detail.DFDetailBG then
        local bg = detail:CreateTexture(nil, "BACKGROUND", nil, -1)
        bg:SetTexture(DF_TEX_BG)
        bg:SetAllPoints(detail)
        detail.DFDetailBG = bg
    end

    -- Ensure detail text is readable
    if detail then
        SetFontStringColorRecursive(detail, 0.9, 0.9, 0.9)
    end

    -- Ensure checkboxes are visible
    StyleReputationCheckBox(_G["ReputationDetailAtWarCheckBox"])
    StyleReputationCheckBox(_G["ReputationDetailMainScreenCheckBox"])
    StyleReputationCheckBox(_G["ReputationDetailInactiveCheckBox"])

    -- Style detail pane like DF side card
    if detail then
        detail:SetFrameStrata("DIALOG")
        detail:SetFrameLevel((CharacterFrame and CharacterFrame:GetFrameLevel() or 1) + 10)
        detail:ClearAllPoints()
        detail:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 18, -36)
        detail:SetSize(240, 180)

        CreateSolidBackground(detail, 18, 3, 3, 3, DF_TEX_BG)
        ApplyDFFrameTemplateNoPortrait(detail)
        AddStreak(detail)

        local close = _G["ReputationDetailCloseButton"]
        if close then
            StyleCloseButton(close)
            close:ClearAllPoints()
            close:SetPoint("TOPRIGHT", detail, "TOPRIGHT", 1, 0)
        end
    end
end

-- ============================================================================
-- CHARACTER FRAME SKIN
-- ============================================================================
local function ApplyCharacterFrameSkin()
    local frame = CharacterFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true

    local function ForceCharacterFrameLayout()
        if not CharacterFrame then return end
        CharacterFrame:SetSize(338, 424)
        PositionCharacterTabs(CharacterFrame)
    end
    
    -- NUKE all textures on main frame AND children (keep portrait)
    NukeAllTextures(frame, true, true)
    
    -- Hide ALL named frame textures
    HideNamedTextures({
        "CharacterFrameTopLeft", "CharacterFrameTopRight",
        "CharacterFrameBottomLeft", "CharacterFrameBottomRight",
        "CharacterFrameTop", "CharacterFrameBottom",
        "CharacterFrameLeft", "CharacterFrameRight",
        "CharacterFramePortraitFrame", "CharacterFrameInset",
        "CharacterFrameInsetRight", "CharacterFrameInsetRightInset",
    })
    
    -- NUKE all subframe textures recursively
    local subs = { "PaperDollFrame", "PetPaperDollFrame", "ReputationFrame", "SkillFrame", "TokenFrame", "HonorFrame", "CharacterModelFrame" }
    for _, name in ipairs(subs) do
        local subFrame = _G[name]
        if subFrame then
            NukeAllTextures(subFrame, false, true)
        end
    end
    
    -- Hide the model frame background textures specifically
    HideNamedTextures({
        "CharacterModelFrameBackgroundTopLeft", "CharacterModelFrameBackgroundTopRight",
        "CharacterModelFrameBackgroundBotLeft", "CharacterModelFrameBackgroundBotRight",
        "CharacterModelFrameBackgroundOverlay", "CharacterModelFrame",
    })
    
    -- Cover the model frame area with solid color
    if CharacterModelFrame then
        CoverWithSolid(CharacterModelFrame, 0.05, 0.05, 0.07)
    end
    
    -- Hook OnShow to re-hide textures that Blizzard may reset
    safeHookScript(frame, "OnShow", function()
        local subs = { "PaperDollFrame", "CharacterModelFrame" }
        for _, name in ipairs(subs) do
            local subFrame = _G[name]
            if subFrame then
                NukeAllTextures(subFrame, false, true)
            end
        end
        HideNamedTextures({
            "CharacterModelFrameBackgroundTopLeft", "CharacterModelFrameBackgroundTopRight",
            "CharacterModelFrameBackgroundBotLeft", "CharacterModelFrameBackgroundBotRight",
            "CharacterModelFrameBackgroundOverlay",
        })
        ReskinCharacterTabs()
        PositionCharacterTabs(frame)
        ForceCharacterFrameLayout()
        local portrait = _G["CharacterFramePortrait"]
        if portrait then
            AddPortraitFrame(frame, portrait)
            EnsurePortraitTexture(portrait, "player")
        end
        ApplyReputationSkin()
    end)
    
    -- Set frame size
    frame:SetSize(338, 424)
    
    -- Create solid background FIRST (blocks everything)
    CreateSolidBackground(frame, 18, 3, 3, 3, DF_TEX_BG)
    
    -- Create Dragonflight-style border
    ApplyDFFrameTemplateNoPortrait(frame)
    
    -- Add streak
    AddStreak(frame)
    
    -- Portrait frame decoration
    local portrait = _G["CharacterFramePortrait"]
    if portrait then
        AddPortraitFrame(frame, portrait)
        EnsurePortraitTexture(portrait, "player")
    end

    ReskinCharacterTabs()
    PositionCharacterTabs(frame)
    ApplyReputationSkin()

    -- Force size when switching tabs/subframes (prevents shrinking)
    local tabFrames = {
        "PaperDollFrame",
        "PetPaperDollFrame",
        "ReputationFrame",
        "SkillFrame",
        "TokenFrame",
        "HonorFrame",
        "CharacterModelFrame",
    }
    for _, name in ipairs(tabFrames) do
        local f = _G[name]
        if f then
            safeHookScript(f, "OnShow", ForceCharacterFrameLayout)
        end
    end
    
    -- Style close button
    local closeBtn = CharacterFrameCloseButton
    if closeBtn then
        StyleCloseButton(closeBtn)
        closeBtn:ClearAllPoints()
        closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 0)
    end
    
    -- Reposition title
    local title = _G["CharacterNameText"]
    if title then
        title:ClearAllPoints()
        title:SetPoint("TOP", frame, "TOP", 0, -5)
    end
end

-- ============================================================================
-- QUEST LOG SKIN  
-- ============================================================================
local function ApplyQuestLogSkin()
    local frame = QuestLogFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- NUKE all textures recursively (keep portrait)
    NukeAllTextures(frame, true, true)
    
    -- Hide named textures
    HideNamedTextures({
        "QuestLogFrameTopLeft", "QuestLogFrameTopRight",
        "QuestLogFrameBottomLeft", "QuestLogFrameBottomRight",
        "QuestLogFrameTop", "QuestLogFrameBottom",
        "QuestLogFrameLeft", "QuestLogFrameRight",
        "EmptyQuestLogFrame",
        "QuestLogDetailScrollFrameTop", "QuestLogDetailScrollFrameBottom",
        "QuestLogDetailScrollFrameMiddle",
    })
    
    -- Nuke detail frames and scroll frames recursively
    local detailFrames = { "QuestLogDetailFrame", "QuestLogDetailScrollFrame", "QuestLogDetailScrollChildFrame", "QuestLogCount" }
    for _, name in ipairs(detailFrames) do
        local f = _G[name]
        if f then
            NukeAllTextures(f, false, true)
        end
    end

    -- Soft background for quest detail pane (avoid covering text)
    local detail = _G["QuestLogDetailScrollFrame"]
    if detail and not detail.DFDetailBG then
        local bg = detail:CreateTexture(nil, "BACKGROUND", nil, 0)
        bg:SetTexture(DF_TEX_BG)
        bg:SetVertexColor(0.1, 0.1, 0.12, 0.85)
        bg:SetPoint("TOPLEFT", detail, "TOPLEFT", 4, -4)
        bg:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", -4, 4)
        detail.DFDetailBG = bg
    end
    
    -- Also hide any parchment/material textures
    HideNamedTextures({
        "QuestLogQuestDetailMaterial",
        "QuestLogQuestRewardMaterial",
    })
    
    -- Hook OnShow to re-hide textures that Blizzard may reset
    safeHookScript(frame, "OnShow", function()
        local details = { "QuestLogDetailScrollFrame", "QuestLogDetailScrollChildFrame" }
        for _, name in ipairs(details) do
            local f = _G[name]
            if f then
                NukeAllTextures(f, false, true)
            end
        end
        HideNamedTextures({
            "QuestLogDetailScrollFrameTop", "QuestLogDetailScrollFrameBottom",
            "QuestLogDetailScrollFrameMiddle", "QuestLogQuestDetailMaterial",
            "QuestLogQuestRewardMaterial",
        })
        local detail = _G["QuestLogDetailScrollFrame"]
        if detail and detail.DFDetailBG then
            detail.DFDetailBG:Show()
        end
        ApplyQuestTextColors()
        local portrait = _G["QuestLogFramePortrait"]
        if portrait then
            AddPortraitFrame(frame, portrait)
            EnsurePortraitTexture(portrait, nil)
        end
    end)
    
    -- Quest log is wider (dual pane style)
    frame:SetSize(682, 447)
    
    -- Create solid background
    CreateSolidBackground(frame, 18, 3, 3, 3, DF_TEX_BG)
    
    -- Create Dragonflight-style border
    ApplyDFFrameTemplateNoPortrait(frame)
    
    -- Add streak
    AddStreak(frame)
    
    -- Portrait frame
    local portrait = _G["QuestLogFramePortrait"]
    if portrait then
        AddPortraitFrame(frame, portrait)
        EnsurePortraitTexture(portrait, nil)
    end

    ApplyQuestTextColors()
    if QuestLog_UpdateQuestDetails then
        hooksecurefunc("QuestLog_UpdateQuestDetails", ApplyQuestTextColors)
    end
    
    -- Style close button
    local closeBtn = QuestLogFrameCloseButton
    if closeBtn then
        StyleCloseButton(closeBtn)
        closeBtn:ClearAllPoints()
        closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 0)
    end
    
    -- Reposition title
    local title = _G["QuestLogTitleText"]
    if title then
        title:ClearAllPoints()
        title:SetPoint("TOP", frame, "TOP", 0, -5)
    end
end

-- ============================================================================
-- SPELLBOOK SKIN
-- ============================================================================
local function ApplySpellbookSkin()
    local frame = SpellBookFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- NUKE all textures recursively
    NukeAllTextures(frame, true, true)
    
    -- Hide named textures
    HideNamedTextures({
        "SpellBookFrameTopLeft", "SpellBookFrameTopRight",
        "SpellBookFrameBotLeft", "SpellBookFrameBotRight",
        "SpellBookPage1", "SpellBookPage2",
        "SpellBookPageText",
    })
    
    -- Set size
    frame:SetSize(550, 525)
    
    -- Create solid background
    CreateSolidBackground(frame, 18, 3, 3, 3, DF_TEX_BG)
    
    -- Create Dragonflight-style border
    ApplyDFFrameTemplateNoPortrait(frame)
    
    -- Add streak
    AddStreak(frame)
    
    -- Portrait
    local portrait = _G["SpellBookFramePortrait"]
    if portrait then
        AddPortraitFrame(frame, portrait)
        EnsurePortraitTexture(portrait, "player")
    end
    
    -- Style close button
    local closeBtn = SpellBookCloseButton
    if closeBtn then
        StyleCloseButton(closeBtn)
        closeBtn:ClearAllPoints()
        closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 0)
    end
    
    -- Title
    local title = _G["SpellBookTitleText"]
    if title then
        title:ClearAllPoints()
        title:SetPoint("TOP", frame, "TOP", 0, -5)
    end
end

-- ============================================================================
-- FRIENDS FRAME SKIN
-- ============================================================================
local function ApplyFriendsSkin()
    local frame = FriendsFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- NUKE all textures recursively
    NukeAllTextures(frame, true, true)
    
    -- Hide named textures
    HideNamedTextures({
        "FriendsFrameTopLeft", "FriendsFrameTopRight",
        "FriendsFrameBottomLeft", "FriendsFrameBottomRight",
        "FriendsFrameInset", "FriendsFrameInsetRight",
        "FriendsFrameLeft", "FriendsFrameRight",
        "FriendsFrameTop", "FriendsFrameBottom",
    })
    
    -- Set size
    frame:SetSize(338, 424)
    
    -- Create solid background
    CreateSolidBackground(frame, 18, 3, 3, 3, DF_TEX_BG)
    
    -- Create Dragonflight-style border
    ApplyDFFrameTemplateNoPortrait(frame)
    
    -- Add streak
    AddStreak(frame)
    
    -- Portrait
    local portrait = _G["FriendsFramePortrait"]
    if portrait then
        AddPortraitFrame(frame, portrait)
        EnsurePortraitTexture(portrait, "player")
    end
    
    -- Style close button
    local closeBtn = FriendsFrameCloseButton
    if closeBtn then
        StyleCloseButton(closeBtn)
        closeBtn:ClearAllPoints()
        closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 0)
    end

    -- Title
    local title = _G["FriendsFrameTitleText"]
    if title then
        title:ClearAllPoints()
        title:SetPoint("TOP", frame, "TOP", 0, -5)
    end

    -- Subframes: remove parchment, add subtle insets, and fix text color
    local subframes = {
        "FriendsListFrame",
        "IgnoreListFrame",
        "WhoFrame",
        "GuildFrame",
        "RaidFrame",
        "RaidInfoFrame",
        "ChannelFrame",
    }
    for _, name in ipairs(subframes) do
        local f = _G[name]
        if f then
            NukeAllTextures(f, false, true)
            SetFontStringColorRecursive(f, 0.9, 0.9, 0.9)
        end
    end

    -- Scroll frame insets
    local insets = {
        "FriendsFrameFriendsScrollFrame",
        "FriendsFrameIgnoreScrollFrame",
        "WhoListScrollFrame",
        "GuildFrameGuildListScrollFrame",
        "GuildListScrollFrame",
        "RaidInfoFrameScrollFrame",
        "RaidFrameScrollFrame",
        "ChannelListScrollFrame",
    }
    for _, name in ipairs(insets) do
        local sf = _G[name]
        if sf then EnsureInsetBackground(sf) end
    end

    -- Nudge friends list scrollbar buttons inside the inset
    local function NudgeFriendsScrollButtons()
        local sb = _G["FriendsFrameFriendsScrollFrameScrollBar"]
        if sb then
            local up = _G["FriendsFrameFriendsScrollFrameScrollBarScrollUpButton"]
            local down = _G["FriendsFrameFriendsScrollFrameScrollBarScrollDownButton"]
            if up then
                up:ClearAllPoints()
                up:SetPoint("TOP", sb, "TOP", 0, -2)
            end
            if down then
                down:ClearAllPoints()
                down:SetPoint("BOTTOM", sb, "BOTTOM", 0, 6)
            end
        end
    end
    NudgeFriendsScrollButtons()
    hooksecurefunc("FriendsFrame_Update", NudgeFriendsScrollButtons)

    -- Edit boxes
    StyleEditBox(_G["WhoFrameEditBox"])
    StyleEditBox(_G["GuildFrameEditBox"])
    StyleEditBox(_G["FriendsFrameBroadcastInput"])

    -- Who headers + dropdown polish
    for i = 1, 4 do
        StyleHeaderButton(_G["WhoFrameColumnHeader" .. i])
    end
    local whoDrop = _G["WhoFrameDropDown"]
    if whoDrop then
        whoDrop:ClearAllPoints()
        whoDrop:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -28)
    end
    local whoEdit = _G["WhoFrameEditBox"]
    if whoEdit then
        whoEdit:ClearAllPoints()
        whoEdit:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 40)
        whoEdit:SetWidth(260)
    end

    local function PositionWhoLayout()
        local list = _G["WhoListScrollFrame"]
        if list then
            list:ClearAllPoints()
            list:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -78)
            list:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 72)
        end

        for i = 1, 4 do
            local header = _G["WhoFrameColumnHeader" .. i]
            if header and list then
                header:ClearAllPoints()
                if i == 1 then
                    header:SetPoint("TOPLEFT", list, "TOPLEFT", 2, 18)
                    header:SetWidth(100)
                elseif i == 2 then
                    header:SetPoint("LEFT", _G["WhoFrameColumnHeader1"], "RIGHT", 2, 0)
                    header:SetWidth(120)
                elseif i == 3 then
                    header:SetPoint("LEFT", _G["WhoFrameColumnHeader2"], "RIGHT", 2, 0)
                    header:SetWidth(34)
                elseif i == 4 then
                    header:SetPoint("LEFT", _G["WhoFrameColumnHeader3"], "RIGHT", 2, 0)
                    header:SetWidth(60)
                end
            end
        end

        local dropdown = _G["WhoFrameDropDown"]
        if dropdown then
            dropdown:ClearAllPoints()
            dropdown:SetPoint("LEFT", _G["WhoFrameColumnHeader2"], "LEFT", -6, -2)
            dropdown:SetWidth(120)
        end

        local edit = _G["WhoFrameEditBox"]
        if edit then
            edit:ClearAllPoints()
            edit:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 40)
            edit:SetWidth(240)
        end
    end

    PositionWhoLayout()
    if WhoList_Update then
        hooksecurefunc("WhoList_Update", PositionWhoLayout)
    end

    -- Friends status controls
    local statusDD = _G["FriendsFrameStatusDropDown"]
    if statusDD then
        statusDD:ClearAllPoints()
        statusDD:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -18)
        statusDD:SetWidth(130)
        statusDD:Show()
        statusDD:SetAlpha(1)
    end
    local statusText = _G["FriendsFrameStatusText"] or _G["FriendsFrameStatusDropDownText"]
    if statusText then
        statusText:Show()
        statusText:SetTextColor(1, 0.82, 0)
    end

    -- Tabs
    ApplyFriendsTabs(frame)
    PositionFriendsTabs(frame)

    safeHookScript(frame, "OnShow", function()
        ApplyFriendsTabs(frame)
        PositionFriendsTabs(frame)
    end)

    -- Friends list buttons
    local addFriend = _G["AddFriendEntryButton"] or _G["AddFriendButton"] or _G["FriendsFrameAddFriendButton"]
    if addFriend then
        addFriend:ClearAllPoints()
        addFriend:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 10)
        addFriend:SetWidth(120)
    end
    local sendMsg = _G["FriendsFrameSendMessageButton"]
    if sendMsg then
        sendMsg:ClearAllPoints()
        sendMsg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 10)
        sendMsg:SetWidth(120)
    end
    if addFriend and sendMsg then
        addFriend:ClearAllPoints()
        addFriend:SetPoint("BOTTOMRIGHT", sendMsg, "BOTTOMLEFT", -6, 0)
    end

    local function PositionFriendsButtons()
        local addFriendBtn = _G["AddFriendEntryButton"] or _G["AddFriendButton"] or _G["FriendsFrameAddFriendButton"]
        local sendMsgBtn = _G["FriendsFrameSendMessageButton"]
        if sendMsgBtn then
            sendMsgBtn:ClearAllPoints()
            sendMsgBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 10)
            sendMsgBtn:SetWidth(120)
        end
        if addFriendBtn and sendMsgBtn then
            addFriendBtn:ClearAllPoints()
            addFriendBtn:SetPoint("BOTTOMRIGHT", sendMsgBtn, "BOTTOMLEFT", -6, 0)
            addFriendBtn:SetWidth(120)
        end
    end
    PositionFriendsButtons()
    if FriendsFrame_Update then
        hooksecurefunc("FriendsFrame_Update", PositionFriendsButtons)
    end
    safeHookScript(frame, "OnShow", function()
        PositionFriendsButtons()
        frame.DFPositionButtonsElapsed = 0
    end)
    if not frame.DFPositionButtonsHooked then
        frame.DFPositionButtonsHooked = true
        frame:HookScript("OnUpdate", function(self, elapsed)
            if not self.DFPositionButtonsElapsed then return end
            self.DFPositionButtonsElapsed = self.DFPositionButtonsElapsed + elapsed
            if self.DFPositionButtonsElapsed < 0.5 then
                PositionFriendsButtons()
            else
                self.DFPositionButtonsElapsed = nil
            end
        end)
    end

    -- Lift list panel so it doesn't overlap bottom buttons
    local friendsScroll = _G["FriendsFrameFriendsScrollFrame"]
    if friendsScroll and friendsScroll.DFInsetBG then
        friendsScroll.DFInsetBG:ClearAllPoints()
        friendsScroll.DFInsetBG:SetPoint("TOPLEFT", friendsScroll, "TOPLEFT", 2, -2)
        friendsScroll.DFInsetBG:SetPoint("BOTTOMRIGHT", friendsScroll, "BOTTOMRIGHT", -2, 36)
    end
    local ignoreScroll = _G["FriendsFrameIgnoreScrollFrame"]
    if ignoreScroll and ignoreScroll.DFInsetBG then
        ignoreScroll.DFInsetBG:ClearAllPoints()
        ignoreScroll.DFInsetBG:SetPoint("TOPLEFT", ignoreScroll, "TOPLEFT", 2, -2)
        ignoreScroll.DFInsetBG:SetPoint("BOTTOMRIGHT", ignoreScroll, "BOTTOMRIGHT", -2, 36)
    end

    -- Who buttons layout
    local whoBtn = _G["WhoFrameWhoButton"]
    if whoBtn then
        whoBtn:ClearAllPoints()
        whoBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 8)
        whoBtn:SetWidth(90)
    end
    local whoInvite = _G["WhoFrameGroupInviteButton"]
    if whoInvite and whoBtn then
        whoInvite:ClearAllPoints()
        whoInvite:SetPoint("LEFT", whoBtn, "RIGHT", 4, 0)
        whoInvite:SetWidth(90)
    end
    local whoAdd = _G["WhoFrameAddFriendButton"]
    if whoAdd and whoInvite then
        whoAdd:ClearAllPoints()
        whoAdd:SetPoint("LEFT", whoInvite, "RIGHT", 4, 0)
        whoAdd:SetWidth(90)
    end

    -- Chat (Channel) buttons and list
    local channelAdd = _G["ChannelFrameAddChannelButton"]
    if channelAdd then
        channelAdd:ClearAllPoints()
        channelAdd:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 10)
    end
    local channelRemove = _G["ChannelFrameRemoveChannelButton"]
    if channelRemove and channelAdd then
        channelRemove:ClearAllPoints()
        channelRemove:SetPoint("LEFT", channelAdd, "RIGHT", 6, 0)
    end

    -- Raid buttons layout
    local raidInfoButton = _G["RaidInfoFrameButton1"] or _G["RaidFrameButton1"]
    if raidInfoButton then
        raidInfoButton:ClearAllPoints()
        raidInfoButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 10)
    end
    local raidInfoButton2 = _G["RaidInfoFrameButton2"] or _G["RaidFrameButton2"]
    if raidInfoButton2 and raidInfoButton then
        raidInfoButton2:ClearAllPoints()
        raidInfoButton2:SetPoint("LEFT", raidInfoButton, "RIGHT", 6, 0)
    end
end

-- ============================================================================
-- TALENTS FRAME SKIN
-- ============================================================================
local function ApplyTalentsSkin()
    local frame = TalentFrame
    if not frame or frame.DragonUI_Skinned then return end
    frame.DragonUI_Skinned = true
    
    -- NUKE all textures recursively
    NukeAllTextures(frame, true, true)
    
    -- Set size
    frame:SetSize(338, 424)
    
    -- Create solid background
    CreateSolidBackground(frame, 18, 3, 3, 3, DF_TEX_BG)
    
    -- Create Dragonflight-style border
    ApplyDFFrameTemplateNoPortrait(frame)
    
    -- Add streak
    AddStreak(frame)
    
    -- Portrait
    local portrait = _G["TalentFramePortrait"]
    if portrait then
        AddPortraitFrame(frame, portrait)
        EnsurePortraitTexture(portrait, "player")
    end
    
    -- Style close button
    local closeBtn = TalentFrameCloseButton
    if closeBtn then
        StyleCloseButton(closeBtn)
        closeBtn:ClearAllPoints()
        closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 0)
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
    if enabled('character') and CharacterFrame then
        safeHookScript(CharacterFrame, "OnShow", ApplyCharacterFrameSkin)
    end

    -- Spellbook
    if enabled('spellbook') and SpellBookFrame then
        safeHookScript(SpellBookFrame, "OnShow", ApplySpellbookSkin)
    end

    -- QuestLog
    if enabled('questlog') and QuestLogFrame then
        safeHookScript(QuestLogFrame, "OnShow", ApplyQuestLogSkin)
    end

    -- Friends / Who / Guild
    if enabled('friends') and FriendsFrame then
        safeHookScript(FriendsFrame, "OnShow", ApplyFriendsSkin)
    end

    -- Talents (loaded on demand)
    if enabled('talents') then
        local function hookTalents()
            if TalentFrame then
                safeHookScript(TalentFrame, "OnShow", ApplyTalentsSkin)
            end
        end
        
        if TalentFrame then
            hookTalents()
        else
            local loader = CreateFrame("Frame")
            loader:RegisterEvent("ADDON_LOADED")
            loader:SetScript("OnEvent", function(self, event, addonName)
                if addonName == "Blizzard_TalentUI" then
                    hookTalents()
                    self:UnregisterEvent("ADDON_LOADED")
                end
            end)
        end
    end
end)

