local addon = select(2, ...)

-- DragonUI UI Skins bridge for select Blizzard frames
-- Safe, minimal hooks for: CharacterFrame (+subframes), Friends/Who/Guild, SpellBook, QuestLog, and common CloseButtons
-- Notes:
-- - Textures are bundled under DragonUI/assets/ui/.
-- - This module avoids touching layout logic of DragonUI.

local texBase = "Interface\\AddOns\\DragonUI\\assets\\ui\\"

local function safeHookScript(frame, script, func)
    if frame and frame.HookScript then
        frame:HookScript(script, func)
    elseif _G.HookScript then
        _G.HookScript(frame, script, func)
    end
end

-- Replace the 4 background texture quadrants on a UIPanel (paperdoll style)
local function ReplacePanelBackground(frame)
    if not frame then return end

    local parts = {
        texBase .. "paperdoll_top_left.tga",
        texBase .. "paperdoll_top_right.tga",
        texBase .. "paperdoll_bot_left.tga",
        texBase .. "paperdoll_bot_right.tga",
    }

    local regions = { frame:GetRegions() }
    local idx = 1
    for i = 1, #regions do
        local r = regions[i]
        if r and r.GetObjectType and r:GetObjectType() == "Texture" then
            local name = r.GetName and r:GetName()
            -- keep portraits as-is; replace the four background quads
            if not name or not string.find(name, "Portrait") then
                r:ClearAllPoints()
                if idx == 1 then
                    r:SetPoint("TOPLEFT", 0, 0)
                elseif idx == 2 then
                    r:SetPoint("TOPLEFT", 256, 0)
                elseif idx == 3 then
                    r:SetPoint("TOPLEFT", 0, -256)
                elseif idx == 4 then
                    r:SetPoint("TOPLEFT", 256, -256)
                end
                if parts[idx] then
                    r:SetTexture(parts[idx])
                end
                idx = idx + 1
                if idx > #parts then break end
            end
        end
    end
end

-- Apply 4 custom textures over a frame (when originals are not easily replaceable)
local function OverlayPanelBackground(target)
    if not target or target.customTopLeft then return end

    local tl = target:CreateTexture(nil, "OVERLAY")
    tl:SetTexture(texBase .. "paperdoll_top_left.tga")
    tl:SetSize(256, 256)
    tl:SetPoint("TOPLEFT", target, "TOPLEFT", -3, 0)

    local tr = target:CreateTexture(nil, "OVERLAY")
    tr:SetTexture(texBase .. "paperdoll_top_right.tga")
    tr:SetSize(128, 256)
    tr:SetPoint("TOPRIGHT", target, "TOPRIGHT", -3, 0)

    local bl = target:CreateTexture(nil, "OVERLAY")
    bl:SetTexture(texBase .. "paperdoll_bot_left.tga")
    bl:SetSize(256, 256)
    bl:SetPoint("TOPLEFT", target, "TOPLEFT", -3, -256)

    local br = target:CreateTexture(nil, "OVERLAY")
    br:SetTexture(texBase .. "paperdoll_bot_right.tga")
    br:SetSize(128, 256)
    br:SetPoint("TOPLEFT", target, "TOPLEFT", 253, -256)

    target.customTopLeft = tl
    target.customTopRight = tr
    target.customBottomLeft = bl
    target.customBottomRight = br
end

-- Close button re-skinning (smaller circular DF-style)
local function ReskinCloseButton(button, parent, offX, offY)
    if not button then return end
    button:SetNormalTexture(texBase .. "close_normal.tga")
    button:SetPushedTexture(texBase .. "close_pushed.tga")
    button:SetHighlightTexture(texBase .. "close_normal.tga")
    button:SetSize(17, 17)
    if parent and offX and offY then
        button:ClearAllPoints()
        button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", offX, offY)
    end
end

-- Spellbook specific tweaks
local function StyleSpellButtons()
    for i = 1, 12 do
        local bg = _G["SpellButton" .. i .. "Background"]
        if bg then
            bg:SetTexture(texBase .. "spell_bg.tga")
            bg:SetSize(44, 44)
        end
        local sub = _G["SpellButton" .. i .. "SubSpellName"]
        if sub and sub.SetTextColor then
            sub:SetTextColor(0.9, 0.9, 0.8, 0.6)
        end
    end
end

-- QuestLog background swap (left/right parchment)
local function StyleQuestLog()
    local frame = _G.QuestLogFrame
    if not frame then return end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local tex = region:GetTexture()
            if tex == "Interface\\QuestFrame\\UI-QuestLog-Left" then
                region:SetTexture(texBase .. "questlog_left.tga")
            elseif tex == "Interface\\QuestFrame\\UI-QuestLog-Right" then
                region:SetTexture(texBase .. "questlog_right.tga")
            end
        end
    end
end

local function ApplyCharacterFrameSkin()
    if not _G.CharacterFrame then return end
    ReplacePanelBackground(_G.CharacterFrame)
    local subs = { "PaperDollFrame", "PetPaperDollFrame", "ReputationFrame", "SkillFrame", "HonorFrame" }
    for _, name in ipairs(subs) do
        local f = _G[name]
        if f then ReplacePanelBackground(f) end
    end
end

local function ApplyFriendsGuildWhoSkin()
    if _G.FriendsFrame then OverlayPanelBackground(_G.FriendsFrame) end
    if _G.WhoFrame then OverlayPanelBackground(_G.WhoFrame) end
    if _G.GuildFrame then OverlayPanelBackground(_G.GuildFrame) end
end

local function ApplySpellbookSkin()
    if not _G.SpellBookFrame then return end
    OverlayPanelBackground(_G.SpellBookFrame)
    StyleSpellButtons()
end

local function ApplyQuestLogSkin()
    StyleQuestLog()
end

-- Entry point: defer work until UI is present
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    local skins = (addon.db and addon.db.profile and addon.db.profile.skins) or {}
    local function enabled(key) return skins[key] ~= false end -- default to true if nil

    -- Character Frame and subframes
    if enabled('character') and _G.CharacterFrame then
        safeHookScript(_G.CharacterFrame, "OnShow", function() ApplyCharacterFrameSkin() end)
        ApplyCharacterFrameSkin()
    end

    -- Friends / Who / Guild
    if enabled('friends') then
        if _G.FriendsFrame then
            safeHookScript(_G.FriendsFrame, "OnShow", function() ApplyFriendsGuildWhoSkin() end)
        end
        ApplyFriendsGuildWhoSkin()
    end

    -- Spellbook
    if enabled('spellbook') and _G.SpellBookFrame then
        safeHookScript(_G.SpellBookFrame, "OnShow", function() ApplySpellbookSkin() end)
        ApplySpellbookSkin()
    end

    -- QuestLog
    if enabled('questlog') and _G.QuestLogFrame then
        safeHookScript(_G.QuestLogFrame, "OnShow", function() ApplyQuestLogSkin() end)
        ApplyQuestLogSkin()
    end

    -- Close buttons on common panels
    if enabled('closebuttons') then
        local closeTargets = {
            { frame = _G.CharacterFrame, btn = _G.CharacterFrame and _G.CharacterFrameCloseButton, x = -36, y = -16 },
            { frame = _G.SpellBookFrame, btn = _G.SpellBookCloseButton, x = -36, y = -15 },
            { frame = _G.TalentFrame, btn = _G.TalentFrameCloseButton, x = -36, y = -17 },
            { frame = _G.QuestLogFrame, btn = _G.QuestLogFrameCloseButton, x = -36, y = -15 },
            { frame = _G.FriendsFrame, btn = _G.FriendsFrameCloseButton, x = -36, y = -15 },
            { frame = _G.ShopFrame, btn = _G.ShopFrameFrameCloseButton, x = -9, y = -17 },
            { frame = _G.HelpFrame, btn = _G.HelpFrameCloseButton, x = -50, y = -10 },
            { frame = _G.QuestFrame, btn = _G.QuestFrameCloseButton, x = -34, y = -22 },
        }
        for _, t in ipairs(closeTargets) do
            if t.btn then ReskinCloseButton(t.btn, t.frame, t.x, t.y) end
        end

        -- Bags 1..5 close buttons (classic WotLK)
        for i = 1, 5 do
            local fName = "ContainerFrame"..i
            local frame = _G[fName]
            local btn = _G[fName .. "CloseButton"]
            if frame and btn then
                ReskinCloseButton(btn, frame, -8, -8)
            end
        end
    end
end)

