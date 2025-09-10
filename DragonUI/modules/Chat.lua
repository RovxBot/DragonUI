local addon = select(2,...);

-- DragonUI Chat Module
-- Store original chat frame settings for restoration
local originalChatSettings = {
	originalPoint = nil,
	originalSize = nil,
	originalScale = nil,
	wasUserPlaced = nil,
	isModified = false
};

local function StoreChatOriginalSettings()
	if not originalChatSettings.originalPoint then
		local point, relativeTo, relativePoint, xOfs, yOfs = ChatFrame1:GetPoint();
		originalChatSettings.originalPoint = {point, relativeTo, relativePoint, xOfs, yOfs};
		local width, height = ChatFrame1:GetSize();
		originalChatSettings.originalSize = {width, height};
		-- Also store the original scale
		originalChatSettings.originalScale = ChatFrame1:GetScale();
		-- Store if it was user placed originally
		originalChatSettings.wasUserPlaced = ChatFrame1:IsUserPlaced();
	end
end

local function ApplyChatSettings()
	-- Check if database is available and chat is enabled
	if not addon.db or not addon.db.profile or not addon.db.profile.chat or not addon.db.profile.chat.enabled then
		return;
	end
	
	local cfg = addon.db.profile.chat;
	
	-- Store original settings before modifying
	StoreChatOriginalSettings();
	
	-- Apply custom position and size
	if addon and addon.Movers and addon.Movers.registry and addon.Movers.registry.chat then
		-- When mover is active, let mover control position; just apply size/scale and reapply mover
		ChatFrame1:SetSize(cfg.size_x, cfg.size_y);
		ChatFrame1:SetScale(cfg.scale);
		if addon.ApplyMover then addon:ApplyMover('chat') end
	else
		ChatFrame1:ClearAllPoints();
		ChatFrame1:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', cfg.x_position, cfg.y_position);
		ChatFrame1:SetSize(cfg.size_x, cfg.size_y);
		ChatFrame1:SetScale(cfg.scale);
		-- CRITICAL: Tell WoW that this frame has been manually positioned
		ChatFrame1:SetUserPlaced(true);
	end

	originalChatSettings.isModified = true;
end

local function RestoreChatSettings()
	if not originalChatSettings.isModified then return; end
	
	-- Restore original position and size
	ChatFrame1:ClearAllPoints();
	if originalChatSettings.originalPoint then
		local point, relativeTo, relativePoint, xOfs, yOfs = unpack(originalChatSettings.originalPoint);
		ChatFrame1:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs);
	else
		-- Fallback to default position if we don't have the original
		ChatFrame1:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 42, 35);
	end
	
	if originalChatSettings.originalSize then
		local width, height = unpack(originalChatSettings.originalSize);
		ChatFrame1:SetSize(width, height);
	else
		-- Fallback to default size
		ChatFrame1:SetSize(460, 207);
	end
	
	-- Reset scale to default
	ChatFrame1:SetScale(1);
	
	originalChatSettings.isModified = false;
end

local function OnEvent(self, event, ...)
	if event == 'PLAYER_ENTERING_WORLD' then
		-- Apply settings when entering world
		addon.RefreshChat();
	end
end

-- Initialize function
local function Initialize()
	-- Create event frame
	local eventFrame = CreateFrame('Frame');
	eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD');
	eventFrame:SetScript('OnEvent', OnEvent);
	
	-- Apply settings
	addon.RefreshChat();
end

-- Refresh function for settings changes
function addon.RefreshChat()
	-- Check if database is available
	if not addon.db or not addon.db.profile or not addon.db.profile.chat then
		return;
	end
	
	local cfg = addon.db.profile.chat;
	
	-- Handle enable/disable
	if cfg.enabled then
		-- Apply custom chat settings
		ApplyChatSettings();
		-- Re-apply mover if present
		if addon and addon.Movers and addon.Movers.registry and addon.Movers.registry.chat and addon.ApplyMover then
			addon:ApplyMover('chat')
		end
	else
		-- Restore original chat settings
		RestoreChatSettings();
	end
end

-- Initialize when addon is ready
if addon.eventManager then
	addon.eventManager:RegisterEvent('PLAYER_LOGIN', Initialize);
else
	local initFrame = CreateFrame('Frame');
	initFrame:RegisterEvent('PLAYER_LOGIN');
	initFrame:SetScript('OnEvent', function()
		Initialize();
	end);
end
