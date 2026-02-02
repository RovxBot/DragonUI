local addon = select(2, ...)

-- Centralized mover system for 3.3.5a
-- Keeps compatibility with the existing EditableFrames registry while
-- providing a single place to apply, reset, and reapply positions.

local MoverSystem = {
    movers = {},
    gridSize = 32,
}

addon.MoverSystem = MoverSystem

-- Helpers --------------------------------------------------------------

local function copyTable(src)
    local dst = {}
    for k, v in pairs(src or {}) do
        if type(v) == "table" then
            dst[k] = copyTable(v)
        else
            dst[k] = v
        end
    end
    return dst
end

local function getDefaultForPath(path1, path2)
    local defaults = addon.defaults and addon.defaults.profile
    if not defaults then return nil end

    if path2 then
        return defaults[path1] and defaults[path1][path2]
    end

    if path1 == "widgets" then
        return defaults.widgets
    end

    return defaults[path1]
end

local function ensureConfig(path1, path2, defaults)
    if not addon.db or not addon.db.profile then return end

    local profile = addon.db.profile
    local target

    if path2 then
        profile[path1] = profile[path1] or {}
        profile[path1][path2] = profile[path1][path2] or copyTable(defaults or {})
        target = profile[path1][path2]
    else
        profile.widgets = profile.widgets or {}
        profile.widgets[path1] = profile.widgets[path1] or copyTable(defaults or {})
        target = profile.widgets[path1]
    end

    return target
end

local function getConfig(path1, path2)
    local profile = addon.db and addon.db.profile
    if not profile then return nil end

    if path2 then
        return profile[path1] and profile[path1][path2]
    end

    if profile.widgets then
        return profile.widgets[path1]
    end
end

-- Core API -------------------------------------------------------------

-- frameInfo: {name, frame, configPath={section, key?}, defaults=?, onShow=?, onHide=?, showTest=?, hideTest=?, hasTarget=?}
function MoverSystem:RegisterFromEditableFrame(frameInfo)
    if not frameInfo or not frameInfo.frame or not frameInfo.configPath then return end

    local path1 = frameInfo.configPath[1]
    local path2 = frameInfo.configPath[2]

    -- derive defaults from addon.defaults if not provided
    local defaults = frameInfo.defaults or getDefaultForPath(path1, path2) or { anchor = "CENTER", posX = 0, posY = 0 }
    ensureConfig(path1, path2, defaults)

    self.movers[frameInfo.name] = {
        frame = frameInfo.frame,
        configPath = frameInfo.configPath,
        defaults = copyTable(defaults),
        onShow = frameInfo.onShow,
        onHide = frameInfo.onHide,
        showTest = frameInfo.showTest,
        hideTest = frameInfo.hideTest,
        hasTarget = frameInfo.hasTarget,
        module = frameInfo.module
    }

    self:ApplyPosition(frameInfo.name)
end

function MoverSystem:ApplyPosition(name)
    local entry = self.movers[name]
    if not entry or not entry.frame then return end

    local path1, path2 = entry.configPath[1], entry.configPath[2]
    local cfg = getConfig(path1, path2) or entry.defaults

    if not cfg then return end

    local anchor = cfg.anchor or cfg.anchorPoint or "CENTER"
    local anchorParent = cfg.anchorParent or "CENTER"
    local anchorParentPoint = cfg.anchorParentPoint or anchor
    local x = cfg.posX or cfg.x or 0
    local y = cfg.posY or cfg.y or 0
    local scale = cfg.scale or entry.frame:GetScale() or 1

    entry.frame:ClearAllPoints()
    entry.frame:SetPoint(anchor, _G[anchorParent] or UIParent, anchorParentPoint, x, y)
    entry.frame:SetScale(scale)
end

function MoverSystem:ApplyAll()
    for name in pairs(self.movers) do
        self:ApplyPosition(name)
    end
end

function MoverSystem:ShowAll()
    for name, entry in pairs(self.movers) do
        if entry.frame then
            HideUIFrame(entry.frame) -- reuse existing overlay logic
            if entry.showTest then entry.showTest() end
            if entry.onShow then entry.onShow() end
        end
    end
end

function MoverSystem:HideAll(save)
    for name, entry in pairs(self.movers) do
        if entry.frame then
            ShowUIFrame(entry.frame)
            if entry.hideTest then entry.hideTest() end

            if save then
                local path1, path2 = entry.configPath[1], entry.configPath[2]
                if path2 then
                    SaveUIFramePosition(entry.frame, path1, path2)
                else
                    SaveUIFramePosition(entry.frame, path1)
                end
            end

            if entry.onHide then entry.onHide() end
        end
    end
end

function MoverSystem:ResetAll()
    for name, entry in pairs(self.movers) do
        if entry.defaults then
            local path1, path2 = entry.configPath[1], entry.configPath[2]
            ensureConfig(path1, path2, entry.defaults)
            self:ApplyPosition(name)
        end
    end
end

-- Expose grid size change for future snapping logic
function MoverSystem:SetGridSize(size)
    if type(size) == "number" and size > 0 then
        self.gridSize = size
    end
end
