local addon = select(2, ...)

local BuffsModule = {}
addon.BuffsModule = BuffsModule

local function makeHeader(name, filter)
    local header = CreateFrame("Frame", name, UIParent, "SecureAuraHeaderTemplate")
    header:SetMovable(true)
    header:SetClampedToScreen(true)
    header:SetAttribute("filter", filter)
    return header
end

local function applyHeaderSettings(header, cfg)
    if not header or not cfg then return end

    header:SetAttribute("filter", cfg.filter)
    header:SetAttribute("separateOwn", cfg.separateOwn or "0")
    header:SetAttribute("sortMethod", cfg.sortMethod or "INDEX")
    header:SetAttribute("sortDirection", cfg.sortDirection or "+")
    header:SetAttribute("point", cfg.point or "TOPRIGHT")

    local xOff = (cfg.orientation == "RL") and -(cfg.paddingX or 5) or (cfg.paddingX or 5)
    local yOff = (cfg.growth == "UP") and (cfg.paddingY or 14) or -(cfg.paddingY or 14)

    header:SetAttribute("xOffset", xOff)
    header:SetAttribute("yOffset", yOff)
    header:SetAttribute("wrapAfter", cfg.wrapAfter or 12)
    header:SetAttribute("maxWraps", cfg.maxWraps or 3)
    header:SetAttribute("wrapXOffset", 0)
    header:SetAttribute("wrapYOffset", (cfg.growth == "UP") and (cfg.paddingY or 14) or -(cfg.paddingY or 14))
    header:SetAttribute("template", "AuraButtonTemplate")

    header:ClearAllPoints()
    header:SetPoint(cfg.anchor or "TOPRIGHT", UIParent, cfg.anchorParent or "TOPRIGHT", cfg.posX or 0, cfg.posY or 0)
    header:SetScale(cfg.scale or 1)
end

local function applyVisibility(header, cfg)
    if not header or not cfg then return end
    local alpha = cfg.alphaNormal or 1
    header:SetAlpha(alpha)

    header:RegisterEvent("PLAYER_REGEN_DISABLED")
    header:RegisterEvent("PLAYER_REGEN_ENABLED")
    header:SetScript("OnEvent", function(self, event)
        if cfg.hideCombat then
            if event == "PLAYER_REGEN_DISABLED" then
                self:SetAlpha(0)
            else
                self:SetAlpha(alpha)
            end
        end
    end)
end

local function styleButtons(header, cfg)
    if not header then return end
    for i = 1, header:GetNumChildren() do
        local btn = select(i, header:GetChildren())
        if btn and btn.Icon then
            btn.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        if cfg.hideDurationText and btn.duration then
            btn.duration:Hide()
        end
        if cfg.hideCooldownText and btn.duration then
            btn.duration:Hide()
        end
    end
end

function BuffsModule:Refresh()
    if not addon.db or not addon.db.profile then return end
    local bcfg = addon.db.profile.buffs
    local dcfg = addon.db.profile.debuffs

    if not self.buffHeader then
        self.buffHeader = makeHeader("DragonUIBuffHeader", "HELPFUL")
        addon:RegisterEditableFrame({ name = "buffs", frame = self.buffHeader, configPath = {"buffs"} })
    end
    if not self.debuffHeader then
        self.debuffHeader = makeHeader("DragonUIDebuffHeader", "HARMFUL")
        addon:RegisterEditableFrame({ name = "debuffs", frame = self.debuffHeader, configPath = {"debuffs"} })
    end

    bcfg.filter = "HELPFUL"
    dcfg.filter = "HARMFUL"

    applyHeaderSettings(self.buffHeader, bcfg)
    applyHeaderSettings(self.debuffHeader, dcfg)
    applyVisibility(self.buffHeader, bcfg)
    applyVisibility(self.debuffHeader, dcfg)
    styleButtons(self.buffHeader, bcfg)
    styleButtons(self.debuffHeader, dcfg)

    self.buffHeader:Show()
    self.debuffHeader:Show()
end

function BuffsModule:Enable()
    self:Refresh()
end

function BuffsModule:Disable()
    if self.buffHeader then self.buffHeader:Hide() end
    if self.debuffHeader then self.debuffHeader:Hide() end
end

hooksecurefunc(addon, "RefreshBuffFrame", function()
    if BuffsModule then BuffsModule:Refresh() end
end)

