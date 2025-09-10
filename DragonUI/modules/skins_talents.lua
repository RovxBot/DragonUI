local addon = select(2, ...)

-- Simplified Talents Overhaul inspired by -DragonflightReloaded (WotLK)
-- Creates a large three-tree talents window and replaces ToggleTalentFrame when enabled

local texBase = "Interface\\AddOns\\DragonUI\\assets\\ui\\"

local function Enabled()
    return addon and addon.db and addon.db.profile and addon.db.profile.skins and addon.db.profile.skins.talents ~= false
end

local TalentUI = { frame = nil, trees = {}, buttons = {}, header = {}, branchArrays = {}, branchTextures = {}, arrowTextures = {} }

local function CreateHeader(parent)
    local left = parent:CreateTexture(nil, 'ARTWORK')
    left:SetTexture(texBase .. 'top_ui_header_left.tga')
    left:SetSize(50, 50)
    left:SetPoint('BOTTOMRIGHT', parent, 'TOPLEFT', 33, -10)

    local prev
    for i = 1, 5 do
        local layer = (i == 5) and 'BACKGROUND' or 'ARTWORK'
        local mid = parent:CreateTexture(nil, layer)
        mid:SetTexture(texBase .. 'top_ui_header.tga')
        mid:SetSize(240, 50)
        if i == 1 then
            mid:SetPoint('LEFT', left, 'RIGHT', -25, -1)
        elseif i == 5 then
            mid:SetPoint('LEFT', prev, 'RIGHT', -140, 0)
        else
            mid:SetPoint('LEFT', prev, 'RIGHT', -17, 0)
        end
        prev = mid
    end

    local right = parent:CreateTexture(nil, 'ARTWORK')
    right:SetTexture(texBase .. 'top_ui_header_right.tga')
    right:SetSize(50, 50)
    right:SetPoint('BOTTOMLEFT', parent, 'TOPRIGHT', -33, -11)
end

local function CreateMainFrame()
    if TalentUI.frame then return end

    local f = CreateFrame('Frame', 'DRAGONUI_TalentFrame', UIParent)
    f:SetSize(1020, 600)
    f:SetFrameStrata('HIGH')
    f:SetPoint('CENTER')
    f:SetBackdrop({ bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background' })
    f:SetBackdropColor(0, 0, 0, 1)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetScript('OnMouseDown', function(self) self:StartMoving() end)
    f:SetScript('OnMouseUp', function(self) self:StopMovingOrSizing() end)

    CreateHeader(f)

    local close = CreateFrame('Button', nil, f)
    close:SetSize(18, 18)
    close:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -10, 25)
    close:SetNormalTexture(texBase .. 'close_normal.tga')
    close:SetPushedTexture(texBase .. 'close_pushed.tga')
    close:SetHighlightTexture(texBase .. 'close_normal.tga')
    close:SetScript('OnClick', function() f:Hide(); UpdateMicroButtons() end)

    local title = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    title:SetText('Talents')
    title:SetPoint('TOP', 0, 23)

    local points = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    points:SetPoint('BOTTOM', 0, 20)
    f.pointsLeft = points

    -- Small scale toggle (persist not implemented; just local for session)
    local small = CreateFrame('CheckButton', nil, f, 'UICheckButtonTemplate')
    small.text:SetText('Small')
    small:SetPoint('BOTTOMLEFT', 50, 17)
    small:SetScript('OnClick', function(self) f:SetScale(self:GetChecked() and 0.8 or 1.0) end)

    f:Hide()
    table.insert(UISpecialFrames, f:GetName())

    TalentUI.frame = f
end

local function CreateTreeFrames()
    if #TalentUI.trees > 0 then return end
    local f = TalentUI.frame
    local xOffsets = {0, 340, 680}

    for i = 1, 3 do
        local tree = CreateFrame('Frame', nil, f)
        tree:SetSize(300, 500)
        tree:SetPoint('TOPLEFT', f, 'TOPLEFT', xOffsets[i] + 20, -50)

        local header = tree:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
        header:SetPoint('TOP', 0, 20)

        local pointsText = tree:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        pointsText:SetPoint('TOP', 0, 0)
        pointsText:SetTextColor(1, 1, 1)

        -- layers for branches/arrows
        local branchFrame = CreateFrame('Frame', nil, tree)
        branchFrame:SetAllPoints()
        local arrowFrame = CreateFrame('Frame', nil, tree)
        arrowFrame:SetAllPoints()

        -- class background
        local bgTL = tree:CreateTexture(nil, 'BACKGROUND')
        bgTL:SetSize(200, 300)
        bgTL:SetPoint('TOPLEFT', 20, -30)
        local bgTR = tree:CreateTexture(nil, 'BACKGROUND')
        bgTR:SetSize(100, 300)
        bgTR:SetPoint('TOPRIGHT', 20, -30)
        local bgBL = tree:CreateTexture(nil, 'BACKGROUND')
        bgBL:SetSize(200, 200)
        bgBL:SetPoint('BOTTOMLEFT', 20, -30)
        local bgBR = tree:CreateTexture(nil, 'BACKGROUND')
        bgBR:SetSize(100, 200)
        bgBR:SetPoint('BOTTOMRIGHT', 20, -30)

        local _, _, _, fileName = GetTalentTabInfo(i)
        local base = fileName and ('Interface\\TalentFrame\\' .. fileName .. '-') or 'Interface\\TalentFrame\\MageFire-'
        bgTL:SetTexture(base .. 'TopLeft');     bgTL:SetAlpha(0.7)
        bgTR:SetTexture(base .. 'TopRight');    bgTR:SetAlpha(0.7)
        bgBL:SetTexture(base .. 'BottomLeft');  bgBL:SetAlpha(0.7)
        bgBR:SetTexture(base .. 'BottomRight'); bgBR:SetAlpha(0.7)

        TalentUI.trees[i] = { frame = tree, header = header, pointsText = pointsText, branchFrame = branchFrame, arrowFrame = arrowFrame }

        -- init arrays and texture pools for this tree
        TalentUI.branchArrays[i] = {}
        for tier = 1, 8 do
            TalentUI.branchArrays[i][tier] = {}
            for col = 1, 4 do
                TalentUI.branchArrays[i][tier][col] = { id=nil, up=0, down=0, left=0, right=0, leftArrow=0, rightArrow=0, topArrow=0 }
            end
        end
        TalentUI.branchTextures[i] = {}
        TalentUI.arrowTextures[i]  = {}
    end
end

-- Branch/arrow rendering
local TALENT_BRANCH_TEXTURECOORDS = {
    up = {[1] = {0.12890625, 0.25390625, 0, 0.484375}, [-1] = {0.12890625, 0.25390625, 0.515625, 1.0}},
    down = {[1] = {0, 0.125, 0, 0.484375},     [-1] = {0, 0.125, 0.515625, 1.0}},
    left = {[1] = {0.2578125, 0.3828125, 0, 0.5},  [-1] = {0.2578125, 0.3828125, 0.5, 1.0}},
    right= {[1] = {0.2578125, 0.3828125, 0, 0.5},  [-1] = {0.2578125, 0.3828125, 0.5, 1.0}},
    topright = {[1] = {0.515625, 0.640625, 0, 0.5}, [-1] = {0.515625, 0.640625, 0.5, 1.0}},
    topleft  = {[1] = {0.640625, 0.515625, 0, 0.5}, [-1] = {0.640625, 0.515625, 0.5, 1.0}},
    bottomright = {[1] = {0.38671875, 0.51171875, 0, 0.5}, [-1] = {0.38671875, 0.51171875, 0.5, 1.0}},
    bottomleft  = {[1] = {0.51171875, 0.38671875, 0, 0.5}, [-1] = {0.51171875, 0.38671875, 0.5, 1.0}},
    tdown = {[1] = {0.64453125, 0.76953125, 0, 0.5}, [-1] = {0.64453125, 0.76953125, 0.5, 1.0}},
    tup   = {[1] = {0.7734375, 0.8984375, 0, 0.5}, [-1] = {0.7734375, 0.8984375, 0.5, 1.0}},
}

local TALENT_ARROW_TEXTURECOORDS = {
    top   = {[1] = {0, 0.5, 0, 0.5},  [-1] = {0, 0.5, 0.5, 1.0}},
    right = {[1] = {1.0, 0.5, 0, 0.5},[-1] = {1.0, 0.5, 0.5, 1.0}},
    left  = {[1] = {0.5, 1.0, 0, 0.5},[-1] = {0.5, 1.0, 0.5, 1.0}},
}

local function ResetBranches(tabIndex)
    local arr = TalentUI.branchArrays[tabIndex]
    if not arr then return end
    for tier = 1, 8 do
        for col = 1, 4 do
            local node = arr[tier][col]
            node.id = nil; node.up=0; node.down=0; node.left=0; node.right=0; node.leftArrow=0; node.rightArrow=0; node.topArrow=0
        end
    end
    for _, t in ipairs(TalentUI.branchTextures[tabIndex]) do t:Hide() end
    for _, t in ipairs(TalentUI.arrowTextures[tabIndex]) do t:Hide() end
end

local function GetTexture(tabIndex, isBranch)
    local pool = isBranch and TalentUI.branchTextures[tabIndex] or TalentUI.arrowTextures[tabIndex]
    for i = 1, #pool do
        if not pool[i]:IsShown() then pool[i]:Show(); return pool[i] end
    end
    local parent = isBranch and TalentUI.trees[tabIndex].branchFrame or TalentUI.trees[tabIndex].arrowFrame
    local layer  = isBranch and 'ARTWORK' or 'OVERLAY'
    local texPath= isBranch and 'Interface\\TalentFrame\\UI-TalentBranches' or 'Interface\\TalentFrame\\UI-TalentArrows'
    local tx = parent:CreateTexture(nil, layer)
    tx:SetTexture(texPath)
    tx:SetSize(32, 32)
    table.insert(pool, tx)
    tx:Show()
    return tx
end

local function SetBranchTexture(tabIndex, texCoords, xOffset, yOffset)
    local tx = GetTexture(tabIndex, true)
    tx:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
    tx:ClearAllPoints()
    tx:SetPoint('TOPLEFT', TalentUI.trees[tabIndex].branchFrame, 'TOPLEFT', xOffset+8, yOffset)
end

local function SetArrowTexture(tabIndex, texCoords, xOffset, yOffset)
    local tx = GetTexture(tabIndex, false)
    tx:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
    tx:ClearAllPoints()
    tx:SetPoint('TOPLEFT', TalentUI.trees[tabIndex].arrowFrame, 'TOPLEFT', xOffset+8, yOffset)
end

local function DrawTalentLines(tabIndex, buttonTier, buttonColumn, tier, column, requirementsMet)
    local req = requirementsMet and 1 or -1
    local arr = TalentUI.branchArrays[tabIndex]
    if buttonColumn == column then
        for i = tier, buttonTier - 1 do
            arr[i][buttonColumn].down = req
            if (i + 1) <= (buttonTier - 1) then
                arr[i + 1][buttonColumn].up = req
            end
        end
        arr[buttonTier][buttonColumn].topArrow = req
    elseif buttonTier == tier then
        local left = math.min(buttonColumn, column)
        local right = math.max(buttonColumn, column)
        for i = left, right - 1 do
            arr[tier][i].right = req
            arr[tier][i+1].left = req
        end
        if buttonColumn < column then
            arr[buttonTier][buttonColumn].rightArrow = req
        else
            arr[buttonTier][buttonColumn].leftArrow = req
        end
    end
end

local function SetTalentPrereqs(tabIndex, buttonTier, buttonColumn, forceDesaturated, tierUnlocked, ...)
    local requirementsMet = (tierUnlocked and not forceDesaturated) and 1 or nil
    local n = select('#', ...)
    for i = 1, n, 3 do
        local tier = select(i, ...)
        local column = select(i+1, ...)
        local isLearnable = select(i+2, ...)
        if not isLearnable or forceDesaturated then requirementsMet = nil end
        if tier and column then DrawTalentLines(tabIndex, buttonTier, buttonColumn, tier, column, requirementsMet) end
    end
    return requirementsMet
end

local function DrawBranches(tabIndex)
    local arr = TalentUI.branchArrays[tabIndex]
    for tier = 1, 8 do
        for col = 1, 4 do
            local node = arr[tier][col]
            local xOffset = (col - 1) * 63 + 35 + 2
            local yOffset = -(tier - 1) * 63 - 50 - 2
            if node.id then
                if node.up ~= 0    then SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS.up[node.up], xOffset, yOffset + 32) end
                if node.down ~= 0  then SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS.down[node.down], xOffset, yOffset - 32 + 1) end
                if node.left ~= 0  then SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS.left[node.left], xOffset - 32, yOffset) end
                if node.right ~= 0 then SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS.right[node.right], xOffset + 32 + 1, yOffset) end
                if node.rightArrow ~= 0 then SetArrowTexture(tabIndex, TALENT_ARROW_TEXTURECOORDS.right[node.rightArrow], xOffset + 16 + 5, yOffset) end
                if node.leftArrow  ~= 0 then SetArrowTexture(tabIndex, TALENT_ARROW_TEXTURECOORDS.left[node.leftArrow], xOffset - 16 - 5, yOffset) end
                if node.topArrow   ~= 0 then SetArrowTexture(tabIndex, TALENT_ARROW_TEXTURECOORDS.top[node.topArrow], xOffset, yOffset + 16 + 5) end
            else
                if node.up ~= 0 and node.down ~= 0 then
                    SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS.up[node.up], xOffset, yOffset)
                    SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS.down[node.down], xOffset, yOffset - 32)
                elseif node.left ~= 0 and node.right ~= 0 then
                    SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS.right[node.right], xOffset + 32, yOffset)
                    SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS.left[node.left], xOffset + 1, yOffset)
                end
            end
        end
    end
end


local function CreateTalentButton(tabIndex, talentIndex, tier, column)
    local tree = TalentUI.trees[tabIndex].frame
    local btn = CreateFrame('Button', nil, tree)
    btn:SetSize(32, 32)
    local x = (column - 1) * 63 + 35
    local y = -(tier - 1) * 63 - 50
    btn:SetPoint('TOPLEFT', x + 10, y)

    local icon = btn:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()

    local border = btn:CreateTexture(nil, 'OVERLAY')
    border:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
    border:SetBlendMode('ADD')
    border:SetSize(64, 64)
    border:SetPoint('CENTER')

    local hover = btn:CreateTexture(nil, 'OVERLAY')
    hover:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
    hover:SetBlendMode('ADD')
    hover:SetSize(64, 64)
    hover:SetPoint('CENTER')
    hover:SetVertexColor(1, 0.82, 0)
    hover:Hide()

    local rankBg = btn:CreateTexture(nil, 'OVERLAY')
    rankBg:SetTexture(0, 0, 0, .5)
    rankBg:SetSize(37, 12)
    rankBg:SetPoint('TOP', btn, 'BOTTOM', 0, -2)

    local rank = btn:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    rank:SetPoint('BOTTOM', btn, 'BOTTOM', 0, -12)

    btn:SetScript('OnEnter', function(self)
        hover:Show(); GameTooltip:SetOwner(self, 'ANCHOR_RIGHT'); GameTooltip:SetTalent(tabIndex, talentIndex)
    end)
    btn:SetScript('OnLeave', function() hover:Hide(); GameTooltip:Hide() end)
    btn:SetScript('OnClick', function()
        local _, _, _, _, r, maxr = GetTalentInfo(tabIndex, talentIndex)
        if r < maxr and UnitCharacterPoints('player') > 0 then LearnTalent(tabIndex, talentIndex) end
    end)

    btn.icon, btn.border, btn.hover, btn.rank = icon, border, hover, rank
    return btn
end

local function CreateAllButtons()
    for tab = 1, 3 do
        local num = GetNumTalents(tab)
        for t = 1, num do
            local name, _, tier, col = GetTalentInfo(tab, t)
            if name then
                local key = tab .. '_' .. t
                if not TalentUI.buttons[key] then
                    TalentUI.buttons[key] = CreateTalentButton(tab, t, tier, col)
                end
            end
        end
    end
end

local function UpdateTalents()
    local f = TalentUI.frame
    if not f or not f:IsShown() then return end

    for tab = 1, 3 do
        local name, _, pts = GetTalentTabInfo(tab)
        if name then
            TalentUI.trees[tab].header:SetText(name)
            TalentUI.trees[tab].pointsText:SetText(pts .. ' points')
        end

        -- reset and rebuild branch arrays for this tab
        ResetBranches(tab)
        local pointsSpent = select(3, GetTalentTabInfo(tab)) or 0

        local num = GetNumTalents(tab)
        for t = 1, num do
            local key = tab .. '_' .. t
            local btn = TalentUI.buttons[key]
            local _, iconTex, tier, column, rank, maxRank = GetTalentInfo(tab, t)
            if btn then
                btn.icon:SetTexture(iconTex)
                btn.rank:SetText(rank .. '/' .. maxRank)
                if rank >= maxRank then
                    btn.border:SetVertexColor(1.0, 0.82, 0, 1.0)
                    btn.icon:SetDesaturated(nil)
                elseif rank > 0 then
                    btn.border:SetVertexColor(1.0, 0.82, 0, .4)
                    btn.icon:SetDesaturated(nil)
                else
                    btn.border:SetVertexColor(0.5, 0.5, 0.5)
                    btn.icon:SetDesaturated(1)
                end
            end

            -- mark node and set any prereq branches for this talent
            if tier and column then
                TalentUI.branchArrays[tab][tier][column].id = t
                local tierUnlocked = pointsSpent >= ((tier - 1) * 5)
                local forceDesaturated = (rank == 0) and not tierUnlocked
                SetTalentPrereqs(tab, tier, column, forceDesaturated, tierUnlocked, GetTalentPrereqs(tab, t))
            end
        end

        -- draw all branches for this tab
        DrawBranches(tab)
    end

    local points = UnitCharacterPoints('player')
    f.pointsLeft:SetText('Talent Points Available: |cFFFFFFFF' .. points .. '|r')
end

local origToggle, origUpdateMicro

local function Toggle()
    if not Enabled() then if origToggle then origToggle() end return end
    if not TalentUI.frame then
        CreateMainFrame(); CreateTreeFrames(); CreateAllButtons()
    end
    if TalentUI.frame:IsShown() then
        TalentUI.frame:Hide()
    else
        TalentUI.frame:Show(); UpdateTalents()
    end
    UpdateMicroButtons()
end

local function HookMicro()
    if origUpdateMicro then return end
    origUpdateMicro = UpdateMicroButtons
    _G.UpdateMicroButtons = function()
        origUpdateMicro()
        if TalentUI.frame and TalentUI.frame:IsShown() then
            TalentMicroButton:SetButtonState('PUSHED', 1)
        else
            TalentMicroButton:SetButtonState('NORMAL')
        end
    end
end

local function OnEvent()
    if not Enabled() then return end
    if not origToggle then origToggle = _G.ToggleTalentFrame end
    _G.ToggleTalentFrame = Toggle
    HookMicro()

    local ef = CreateFrame('Frame')
    ef:RegisterEvent('CHARACTER_POINTS_CHANGED')
    ef:RegisterEvent('PLAYER_LEVEL_UP')
    ef:SetScript('OnEvent', UpdateTalents)
end

local f = CreateFrame('Frame')
f:RegisterEvent('PLAYER_LOGIN')
f:SetScript('OnEvent', OnEvent)

