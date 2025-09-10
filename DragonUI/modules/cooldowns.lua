local addon = select(2,...)
local unpack = unpack
local ceil = math.ceil
local GetTime = GetTime
local hooksecurefunc = hooksecurefunc

-- Create a table within the main addon object to hold our functions
addon.cooldownMixin = {}

function addon.cooldownMixin:update_cooldown(elapsed)
	if not self:GetParent().action then return end
	if not self.remain then return end

	local text = self.text
	local remaining = self.remain - GetTime()
    
	if remaining > 0 then
        local db = addon.db.profile.buttons.cooldown
        if remaining <= 2 then
            text:SetTextColor(1, 0, .2)
            text:SetFormattedText('%.1f',remaining)
        elseif remaining <= 60 then
            text:SetTextColor(unpack(db.color))
            text:SetText(ceil(remaining))
        elseif remaining <= 3600 then
            text:SetText(ceil(remaining/60)..'m')
            text:SetTextColor(1, 1, 1)
        else
            text:SetText(ceil(remaining/3600)..'h')
            text:SetTextColor(.6, .6, .6)
        end
    else
        self.remain = nil
		text:Hide()
		text:SetText''
    end
end

function addon.cooldownMixin:create_string()
	local text = self:CreateFontString(nil, 'OVERLAY')
	text:SetPoint('CENTER')
	self.text = text
	self:SetScript('OnUpdate', addon.cooldownMixin.update_cooldown)
	return text
end

function addon.cooldownMixin:set_cooldown(start, duration)
    local db = addon.db.profile.buttons.cooldown
    if not db then return end

	if db.show and start > 0 and duration > db.min_duration then
		self.remain = start + duration

		local text = self.text or addon.cooldownMixin.create_string(self)
		text:SetFont(unpack(db.font))
		text:SetPoint(unpack(db.position))
		text:Show()
	else
		if self.text then
			self.text:Hide()
		end
		self.remain = nil
	end
end

function addon.RefreshCooldowns()
	if not addon.buttons_iterator then return end
	for button in addon.buttons_iterator() do
		if button then
			local cooldown = _G[button:GetName()..'Cooldown']
			if cooldown and cooldown.GetCooldown then
				local start, duration = cooldown:GetCooldown()
				if start and start > 0 then
					addon.cooldownMixin.set_cooldown(cooldown, start, duration)
				end
			end
		end
	end
end

-- This function will be called from core.lua to ensure the hook is applied only once and at the right time.
local isHooked = false
function addon.InitializeCooldowns()
    if isHooked then return end
    
    local methods = getmetatable(_G.ActionButton1Cooldown).__index
    if methods and methods.SetCooldown then
        hooksecurefunc(methods, 'SetCooldown', addon.cooldownMixin.set_cooldown)
        isHooked = true
    end
end