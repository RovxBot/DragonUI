local addon = select(2,...);
local config = addon.config;
local map = addon._map;
local atlas = addon.minimap_SetAtlas;
local shown = addon.minimap_SetShown;
local select = select;
local format = string.format;

local GameTimeFrame = GameTimeFrame;
local CalendarGetDate = CalendarGetDate;
if (not IsAddOnLoaded('Blizzard_TimeManager')) then
    LoadAddOn('Blizzard_TimeManager')
end

function map:SetCalendarDate()
	if not config.times.calendar then
		GameTimeFrame:Hide()
		return
	end
	
	local _, _, day = CalendarGetDate();
	local atlasFormat = "ui-hud-calendar-%d-%s";
	
	GameTimeFrame:ClearAllPoints()
	GameTimeFrame:SetSize(21, 19)
	GameTimeFrame:SetPoint('TOPRIGHT', Minimap.BorderTop, 22, -1)
	GameTimeFrame:SetHitRectInsets(0, 0, 0, 0)
	GameTimeFrame:GetFontString():Hide()
	
	local normal, pushed, highlight;
	normal = GameTimeFrame:GetNormalTexture();
	pushed = GameTimeFrame:GetPushedTexture();
	highlight = GameTimeFrame:GetHighlightTexture();
	
	atlas(normal, atlasFormat:format(day, "up"));
	atlas(pushed, atlasFormat:format(day, "down"));
	atlas(highlight, atlasFormat:format(day, "mouseover"));
end

TimeManagerClockButton:GetRegions():Hide()
TimeManagerClockButton:ClearAllPoints()
TimeManagerClockButton:SetWidth(40)
TimeManagerClockButton:SetHeight(18)
TimeManagerClockButton:SetPoint('TOPRIGHT', Minimap.BorderTop)

TimeManagerClockTicker:SetFont(config.assets.font, config.times.clock_font_size)
TimeManagerClockTicker:SetShadowOffset(1.25, -1.25)
TimeManagerClockTicker:SetPoint('TOPRIGHT', TimeManagerClockButton, -10, -2)
shown(TimeManagerClockTicker, config.times.clock)

TimeManagerAlarmFiredTexture:SetTexture(nil)

-- Refresh function for minimap time configuration changes
function addon.RefreshMinimapTime()
	local clockEnabled = config.times.clock;
	local calendarEnabled = config.times.calendar;
	local clockFontSize = config.times.clock_font_size;
	
	-- Update clock visibility
	if TimeManagerClockTicker then
		if clockEnabled then
			TimeManagerClockTicker:Show();
		else
			TimeManagerClockTicker:Hide();
		end
		
		-- Update clock font size
		if clockFontSize then
			local currentFont = TimeManagerClockTicker:GetFont();
			if currentFont then
				TimeManagerClockTicker:SetFont(currentFont, clockFontSize, "OUTLINE");
			end
		end
	end
	
	-- Update calendar visibility
	if GameTimeFrame then
		if calendarEnabled then
			GameTimeFrame:Show();
		else
			GameTimeFrame:Hide();
		end
	end
	
	-- Update calendar date if enabled
	if calendarEnabled and GameTimeCalendarInvitesTexture then
		local weekday, month, day, year = CalendarGetDate();
		if map and map.SetCalendarDate then
			map:SetCalendarDate(day);
		end
	end
end