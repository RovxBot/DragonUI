local addon = select(2, ...)

-- DragonUI Mover Manager (Phase 1)
-- Unified ElvUI-like mover core: CreateMover, sticky/grid snap, save/restore

local M = {}
addon.Movers = M

-- Config defaults
local GRID_SIZE = 32
local SNAP_DIST = 10

-- Root parent similar to ElvUI's E.UIParent
if not _G.DragonUIParent then
    local root = CreateFrame('Frame', 'DragonUIParent', UIParent)
    root:SetAllPoints(UIParent)
    root:SetFrameStrata('BACKGROUND')
    root:SetFrameLevel(0)
end

-- Storage helpers -----------------------------------------------------------
local function ensureDB()
    -- Never overwrite addon.db; use it if available, otherwise fall back to a local table
    if addon.db and addon.db.profile then
        addon.db.profile.movers = addon.db.profile.movers or {}
        return addon.db.profile.movers
    end
    addon.__fallbackMovers = addon.__fallbackMovers or {}
    return addon.__fallbackMovers
end

local function serializePoint(frame)
    local p, rel, rp, x, y = frame:GetPoint(1)
    rel = rel or DragonUIParent
    local relName = rel.GetName and rel:GetName() or 'DragonUIParent'
    return { point = p or 'CENTER', relativeTo = relName, relativePoint = rp or 'CENTER', x = x or 0, y = y or 0 }
end

local function applyPoint(frame, data, fallback)
    local p = data and data.point or (fallback and fallback[1]) or 'CENTER'
    local relName = data and data.relativeTo or (fallback and (fallback[2] and (fallback[2].GetName and fallback[2]:GetName() or nil))) or 'DragonUIParent'
    local rp = data and data.relativePoint or (fallback and fallback[3]) or p
    local x = data and data.x or (fallback and fallback[4]) or 0
    local y = data and data.y or (fallback and fallback[5]) or 0
    local rel = _G[relName] or DragonUIParent
    frame:ClearAllPoints()
    frame:SetPoint(p, rel, rp, x, y)
end

-- Utility: grid and sticky --------------------------------------------------
local function snapToGrid(x, y)
    local gs = GRID_SIZE
    local function roundTo(v, m)
        return m * math.floor((v + (m/2)) / m)
    end
    return roundTo(x, gs), roundTo(y, gs)
end

local function getEdges(frame)
    local l = frame:GetLeft() or 0
    local r = frame:GetRight() or 0
    local t = frame:GetTop() or 0
    local b = frame:GetBottom() or 0
    return l, r, t, b
end

local function stickyToScreen(frame, x, y)
    local l, r, t, b = getEdges(frame)
    local sl, sr, st, sb = UIParent:GetLeft(), UIParent:GetRight(), UIParent:GetTop(), UIParent:GetBottom()
    local dxL = math.abs(l - sl)
    local dxR = math.abs(sr - r)
    local dyT = math.abs(st - t)
    local dyB = math.abs(b - sb)
    local snappedX, snappedY = x, y
    if dxL <= SNAP_DIST then
        -- snap left edge
        local width = frame:GetWidth()
        snappedX = (sl - (UIParent:GetLeft() or 0))
        snappedX = snappedX + (frame:GetWidth() and 0 or 0) -- keep as-is
    elseif dxR <= SNAP_DIST then
        -- snap right edge
        snappedX = (sr - (UIParent:GetRight() or 0))
    end
    if dyT <= SNAP_DIST then
        snappedY = (st - (UIParent:GetTop() or 0))
    elseif dyB <= SNAP_DIST then
        snappedY = (sb - (UIParent:GetBottom() or 0))
    end
    return snappedX, snappedY
end

-- Registry ------------------------------------------------------------------
M.registry = {}

function addon:CreateMover(frame, key, name, defaultPoint, opts)
    if not frame or not key then return end
    if M.registry[key] then return M.registry[key] end
    opts = opts or {}

    -- Holder overlay (drag handle) - top-level so it can't be hidden behind child strata
    local holder = CreateFrame('Frame', nil, DragonUIParent)
    holder:SetFrameStrata('TOOLTIP')
    holder:SetFrameLevel(100)
    holder:Hide()
    -- Anchor to the moved frame so it follows size and position
    holder:ClearAllPoints()
    holder:SetPoint('TOPLEFT', frame, 'TOPLEFT')
    holder:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')

    local bg = holder:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetTexture(0, 0.6, 1, 0.18)

    local border = holder:CreateTexture(nil, 'BORDER')
    border:SetAllPoints()
    border:SetTexture(1, 1, 1, 0.6)

    local label = holder:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    label:ClearAllPoints()
    label:SetPoint('TOP', holder, 'TOP', 0, -6)
    label:SetText(name or key)

    -- Ensure the handle is sizable even if the frame is tiny
    local function syncHolder()
        holder:ClearAllPoints()
        local w = frame:GetWidth() or 0
        local h = frame:GetHeight() or 0
        if opts and opts.strictSize then
            holder:SetPoint('TOPLEFT', frame, 'TOPLEFT')
            holder:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
        else
            if w < 40 or h < 20 then
                holder:SetSize(math.max(120, w), math.max(60, h))
                holder:SetPoint('CENTER', frame, 'CENTER')
            else
                holder:SetPoint('TOPLEFT', frame, 'TOPLEFT')
                holder:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
            end
        end
    end
    syncHolder()
    frame:HookScript('OnSizeChanged', syncHolder)

    holder:EnableMouse(true)
    holder:SetMovable(true)

    holder:SetScript('OnMouseDown', function()
        if InCombatLockdown() then return end
        frame:SetMovable(true)
        frame:SetUserPlaced(true)
        frame:SetClampedToScreen(true)
        frame:StartMoving()
    end)

    holder:SetScript('OnMouseUp', function()
        if InCombatLockdown() then return end
        frame:StopMovingOrSizing()
        -- Read the point BEFORE clearing; Blizzard returns nils if we clear first
        local p, rel, rp, x, y = frame:GetPoint(1)
        p = p or 'CENTER'; rp = rp or p; x = x or 0; y = y or 0
        -- Re-anchor relative to our root
        frame:ClearAllPoints()
        frame:SetPoint(p, DragonUIParent, rp, x, y)

        -- Apply grid snap only (edge-sticky temporarily disabled)
        local sx, sy = snapToGrid(x, y)
        frame:ClearAllPoints()
        frame:SetPoint(p, DragonUIParent, rp, sx, sy)

        -- Store
        local db = ensureDB()
        db[key] = { point = p, relativeTo = 'DragonUIParent', relativePoint = rp, x = sx, y = sy }
    end)

    -- Small nudge controls (Up/Down/Left/Right + Reset)
    local n = CreateFrame('Frame', nil, holder)
    n:SetSize(90, 60)
    n:SetPoint('CENTER', holder, 'CENTER', 0, 0)

    local function mkBtn(txt, ox, oy, cb)
        local b = CreateFrame('Button', nil, n, 'UIPanelButtonTemplate')
        b:SetSize(16, 16)
        b:SetPoint('CENTER', ox, oy)
        b:SetText(txt)
        b:SetScript('OnClick', cb)
        return b
    end
    local function nudge(dx, dy)
        if InCombatLockdown() then return end
        local p, _, rp, x, y = frame:GetPoint(1)
        x, y = (x or 0) + dx, (y or 0) + dy
        frame:ClearAllPoints(); frame:SetPoint(p or 'CENTER', DragonUIParent, rp or 'CENTER', x, y)
        local db = ensureDB(); db[key] = serializePoint(frame)
    end
    mkBtn('◀', -22, 0, function() nudge(IsControlKeyDown() and -10 or -1, 0) end)
    mkBtn('▶',  22, 0, function() nudge(IsControlKeyDown() and  10 or  1, 0) end)
    mkBtn('▲',   0, 8, function() nudge(0, IsControlKeyDown() and 10 or 1) end)
    mkBtn('▼',   0,-8, function() nudge(0, IsControlKeyDown() and -10 or -1) end)
    mkBtn('R',  44, 0, function() addon:ResetMover(key) end)

    M.registry[key] = { frame = frame, holder = holder, key = key, name = name, default = defaultPoint, opts = opts }

    -- Apply saved or default point now
    addon:ApplyMover(key)

    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("DragonUI: mover registered - "..tostring(key)) end

    return holder
end

function addon:ApplyMover(key)
    local entry = M.registry[key]; if not entry then return end
    local db = ensureDB(); local data = db[key]
    if data then
        applyPoint(entry.frame, data, entry.default)
    elseif entry.default then
        applyPoint(entry.frame, nil, entry.default)
    end
    -- adjust holder to be visible even if frame is tiny
    local holder, frame = entry.holder, entry.frame
    if holder and frame then
        holder:ClearAllPoints()
        local w = frame:GetWidth() or 0
        local h = frame:GetHeight() or 0
        if entry.opts and entry.opts.strictSize then
            holder:SetPoint('TOPLEFT', frame, 'TOPLEFT')
            holder:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
        else
            if w < 40 or h < 20 then
                holder:SetSize(math.max(120, w), math.max(60, h))
                holder:SetPoint('CENTER', frame, 'CENTER')
            else
                holder:SetPoint('TOPLEFT', frame, 'TOPLEFT')
                holder:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
            end
        end
    end
end

function addon:ResetMover(key)
    local entry = M.registry[key]; if not entry then return end
    local db = ensureDB(); db[key] = nil
    if entry.default then applyPoint(entry.frame, nil, entry.default) end
end

-- Ensure default movers exist for key frames even if modules failed to register
local function ensureBuiltInMovers()
    if not M.registry['minimap'] and _G.MinimapCluster then
        addon:CreateMover(_G.MinimapCluster, 'minimap', 'Minimap', {'TOPRIGHT', UIParent, 'TOPRIGHT', -24, -40})
    end
    if not M.registry['micromenu'] and _G.pUiMicroMenu then
        addon:CreateMover(_G.pUiMicroMenu, 'micromenu', 'Micro Menu', {'BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -166, -53}, {strictSize = true})
    end
    if not M.registry['bagsbar'] and _G.pUiBagsBar then
        addon:CreateMover(_G.pUiBagsBar, 'bagsbar', 'Bags Bar', {'BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', 1, 41})
    end
    if not M.registry['chat'] and _G.ChatFrame1 then
        addon:CreateMover(_G.ChatFrame1, 'chat', 'Chat', {'BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 32, 36})
        _G.ChatFrame1:HookScript('OnShow', function() if addon and addon.ApplyMover then addon:ApplyMover('chat') end end)
    end
    if not M.registry['worldmap'] and _G.WorldMapFrame then
        addon:CreateMover(_G.WorldMapFrame, 'worldmap', 'World Map', {'CENTER', UIParent, 'CENTER', 0, 60})
        _G.WorldMapFrame:HookScript('OnShow', function() if addon and addon.ApplyMover then addon:ApplyMover('worldmap') end end)
    end
end
-- Re-apply movers after the UI has fully loaded to prevent modules from overriding
local reapply = CreateFrame('Frame')
reapply:RegisterEvent('PLAYER_ENTERING_WORLD')
reapply:SetScript('OnEvent', function()
    ensureBuiltInMovers()
    for key in pairs(M.registry) do
        addon:ApplyMover(key)
    end
end)


function addon:ShowMovers()
    -- Make sure essential movers exist even if a module failed to register
    ensureBuiltInMovers()
    local count = 0
    for _, v in pairs(M.registry) do
        if v.frame and v.holder then
            -- ensure holder matches frame bounds unless oversized handles are desired
            local w = v.frame:GetWidth() or 0
            local h = v.frame:GetHeight() or 0
            v.holder:ClearAllPoints()
            if v.opts and v.opts.strictSize then
                v.holder:SetPoint('TOPLEFT', v.frame, 'TOPLEFT')
                v.holder:SetPoint('BOTTOMRIGHT', v.frame, 'BOTTOMRIGHT')
            else
                if w < 40 or h < 20 then
                    v.holder:SetSize(math.max(120, w), math.max(60, h))
                    v.holder:SetPoint('CENTER', v.frame, 'CENTER')
                else
                    v.holder:SetPoint('TOPLEFT', v.frame, 'TOPLEFT')
                    v.holder:SetPoint('BOTTOMRIGHT', v.frame, 'BOTTOMRIGHT')
                end
            end
            v.holder:Show()
            count = count + 1
        end
    end
    if count == 0 then print("DragonUI: No movers registered yet. If you just reloaded, try /duimove again in a couple of seconds.") end
end
function addon:HideMovers()
    for _, v in pairs(M.registry) do if v.holder then v.holder:Hide() end end
end
-- Optional grid overlay -------------------------------------------------------
local grid
local function showGrid()
    if grid then grid:Show(); return end
    grid = CreateFrame('Frame', nil, DragonUIParent)
    grid:SetAllPoints(DragonUIParent)
    grid:SetFrameStrata('TOOLTIP')
    grid:EnableMouse(false)
    local w = DragonUIParent:GetWidth() or UIParent:GetWidth()
    local h = DragonUIParent:GetHeight() or UIParent:GetHeight()
    local step = GRID_SIZE
    grid.lines = {}
    for x = 0, math.floor(w), step do
        local t = grid:CreateTexture(nil, 'BACKGROUND')
        t:SetColorTexture(1,1,1,0.05)
        t:SetPoint('TOPLEFT', DragonUIParent, 'TOPLEFT', x, 0)
        t:SetPoint('BOTTOMLEFT', DragonUIParent, 'BOTTOMLEFT', x, 0)
        t:SetWidth(1)
        table.insert(grid.lines, t)
    end
    for y = 0, math.floor(h), step do
        local t = grid:CreateTexture(nil, 'BACKGROUND')
        t:SetColorTexture(1,1,1,0.05)
        t:SetPoint('TOPLEFT', DragonUIParent, 'TOPLEFT', 0, -y)
        t:SetPoint('TOPRIGHT', DragonUIParent, 'TOPRIGHT', 0, -y)
        t:SetHeight(1)
        table.insert(grid.lines, t)
    end
end
local function hideGrid()
    if grid then grid:Hide() end
end
-- Hook grid into Show/Hide
local _origShowMovers = addon.ShowMovers
function addon:ShowMovers()
    showGrid()
    return _origShowMovers(self)
end
local _origHideMovers = addon.HideMovers
function addon:HideMovers()
    hideGrid()
    return _origHideMovers(self)
end


-- Slash commands
SLASH_DRAGONUIMOVERS1 = '/duimove'
SLASH_DRAGONUIMOVERS2 = '/duimover'
SlashCmdList["DRAGONUIMOVERS"] = function()
    addon:ShowMovers()
end

SLASH_DRAGONUILOCK1 = '/duilock'
SlashCmdList["DRAGONUILOCK"] = function()
    addon:HideMovers()
end

