local addon = select(2,...);
local config = addon.config;
local event = addon.package;
local class = addon._class;
local pUiMainBar = addon.pUiMainBar;
local unpack = unpack;
local select = select;
local pairs = pairs;
local _G = getfenv(0);

-- const
local InCombatLockdown = InCombatLockdown;
local GetNumShapeshiftForms = GetNumShapeshiftForms;
local GetShapeshiftFormInfo = GetShapeshiftFormInfo;
local GetShapeshiftFormCooldown = GetShapeshiftFormCooldown;
local CreateFrame = CreateFrame;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local UnitAffectingCombat = UnitAffectingCombat;

-- WOTLK 3.3.5a Constants
local NUM_SHAPESHIFT_SLOTS = 10; -- Fixed value for 3.3.5a compatibility

local stance = {
	['DEATHKNIGHT'] = 'show',
	['DRUID'] = 'show',
	['PALADIN'] = 'show',
	['PRIEST'] = 'show',
	['ROGUE'] = 'show',
	['WARLOCK'] = 'show',
	['WARRIOR'] = 'show'
};

-- ============================================================================
-- STANCE BAR VISIBILITY MANAGEMENT (HOVER & COMBAT)
-- ============================================================================

-- Stance bar visibility state
local stanceVisibilityState = {
    hovered = false,
    inCombat = false
};

-- Update stance bar visibility based on hover and combat states
local function UpdateStanceBarVisibility()
    local frame = pUiStanceHolder;
    if not frame or not addon.db or not addon.db.profile or not addon.db.profile.additional or not addon.db.profile.additional.stance then
        return;
    end

    local config = addon.db.profile.additional.stance;
    local showOnHover = config.show_on_hover;
    local showInCombat = config.show_in_combat;

    -- Determine if stance bar should be visible
    local shouldShow = true;

    if showOnHover and showInCombat then
        -- Show only when BOTH hovering AND in combat
        shouldShow = stanceVisibilityState.hovered and stanceVisibilityState.inCombat;
    elseif showOnHover then
        -- Show only when hovering
        shouldShow = stanceVisibilityState.hovered;
    elseif showInCombat then
        -- Show only when in combat
        shouldShow = stanceVisibilityState.inCombat;
    end
    -- If neither option is enabled, always show (shouldShow remains true)

    if shouldShow then
        frame:SetAlpha(1);
    else
        frame:SetAlpha(0);
    end

    -- Always keep frame shown for hover detection to work
    frame:Show();
end

-- Setup hover detection for stance bar
local function SetupStanceBarHoverDetection()
    local frame = pUiStanceHolder;
    if not frame then return; end

    frame:SetScript("OnEnter", function()
        stanceVisibilityState.hovered = true;
        UpdateStanceBarVisibility();
    end);

    frame:SetScript("OnLeave", function()
        stanceVisibilityState.hovered = false;
        UpdateStanceBarVisibility();
    end);
end

-- Combat state handler for stance bar
local function OnStanceCombatStateChanged(inCombat)
    stanceVisibilityState.inCombat = inCombat;
    UpdateStanceBarVisibility();
end

-- Initialize stance bar visibility system
local function InitializeStanceBarVisibility()
    -- Setup hover detection
    SetupStanceBarHoverDetection();

    -- Register combat events
    local combatFrame = CreateFrame("Frame");
    combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED"); -- Entering combat
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");  -- Leaving combat
    combatFrame:SetScript("OnEvent", function(self, event)
        local inCombat = (event == "PLAYER_REGEN_DISABLED");
        OnStanceCombatStateChanged(inCombat);
    end);

    -- Initial visibility update
    C_Timer.After(1, function()
        UpdateStanceBarVisibility();
    end);
end

-- Export functions
addon.UpdateStanceBarVisibility = UpdateStanceBarVisibility;
addon.InitializeStanceBarVisibility = InitializeStanceBarVisibility;

-- @param: config number - these will be read dynamically
-- Base Y position (52) is now hardcoded for optimal pretty_actionbar compatibility
-- Individual Y offsets are available per bar for fine-tuning
-- local offsetX = config.additional.stance.x_position;
-- local leftbarOffset = config.additional.leftbar_offset;
-- local rightbarOffset = config.additional.rightbar_offset;

local anchor = CreateFrame('Frame', 'pUiStanceHolder', pUiMainBar)
-- Set initial position - will be updated by stancebar_update when config is ready
anchor:SetPoint('TOPLEFT', UIParent, 'BOTTOM', 0, 105) -- Fallback position slightly above pet bar
anchor:SetSize(37, 37)

-- Register mover for Stance Bar holder (resizes with buttons)
if addon.CreateMover and not (addon.Movers and addon.Movers.registry and addon.Movers.registry.stancebar) then
    addon:CreateMover(anchor, 'stancebar', 'Stance Bar', {'BOTTOM', UIParent, 'BOTTOM', 0, 160})
    anchor:HookScript('OnShow', function() if addon.ApplyMover then addon:ApplyMover('stancebar') end end)
end

-- Queue system to prevent multiple simultaneous updates
local updateQueue = {};
local isUpdating = false;

local function ProcessUpdateQueue()
	if isUpdating or InCombatLockdown() or UnitAffectingCombat('player') then
		return;
	end
	
	if #updateQueue > 0 then
		isUpdating = true;
		-- Clear queue first
		updateQueue = {};
		
		-- Safe update execution with additional protection
		if anchor and anchor.stancebar_update and not InCombatLockdown() then
			anchor:stancebar_update();
		end
		
		isUpdating = false;
	end
end

-- Queue an update request
local function QueueUpdate(reason)
	table.insert(updateQueue, reason or "unknown");
	-- Process queue after a brief delay to batch updates
	local frame = CreateFrame("Frame");
	frame:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil);
		ProcessUpdateQueue();
	end);
end

-- method update position using relative anchoring
function anchor:stancebar_update()
	if not InCombatLockdown() and not UnitAffectingCombat('player') then
			-- If using mover, do not auto-reposition
			if addon and addon.Movers and addon.Movers.registry and addon.Movers.registry.stancebar then
				return
			end
		-- Read config values dynamically each time
		local offsetX = config.additional.stance.x_position;
		local offsetY = config.additional.stance.y_offset or 0;  -- Additional Y offset for fine-tuning
		local override = config.additional.stance.override or false;

		-- ✅ INDEPENDENT POSITIONING MODE
		if override then
			-- Independent positioning - not tied to any other bars
			-- Use y_position if available (from options), otherwise use y_position from editor mode
			local yPos = config.additional.stance.y_position or 200;
			local anchorFrame = config.additional.stance.anchorFrame or "UIParent";
			local anchor = config.additional.stance.anchor or "BOTTOMLEFT";
			local anchorParent = config.additional.stance.anchorParent or "BOTTOMLEFT";

			self:ClearAllPoints();
			self:SetPoint(anchor, _G[anchorFrame] or UIParent, anchorParent, offsetX, yPos + offsetY);
			return;
		end

		-- ✅ SMART ANCHORING MODE (original behavior)
		-- Check if Pet Bar exists and is visible first (stance should be above pet bar)
		local petBarHolder = _G["pUiPetBarHolder"];
		if petBarHolder and petBarHolder:IsShown() then
			-- Anchor above Pet Bar
			self:ClearAllPoints();
			self:SetPoint('BOTTOM', petBarHolder, 'TOP', offsetX, 5 + offsetY);
		else
			-- No Pet Bar, check if pretty_actionbar addon is loaded
			if IsAddOnLoaded('pretty_actionbar') and _G.pUiMainBar then
				-- Use pretty_actionbar's exact logic (same as pet bar)
				local mainBar = _G.pUiMainBar;
				local leftbar = MultiBarBottomLeft:IsShown();
				local rightbar = MultiBarBottomRight:IsShown();
				
				-- Values from configuration (compatible with pretty_actionbar)
				local nobar = 52;          -- Hardcoded optimal position for pretty_actionbar compatibility
				local leftbarOffset = config.additional.leftbar_offset or 90;  -- Offset when bottom left is shown  
				local rightbarOffset = config.additional.rightbar_offset or 40; -- Offset when bottom right is shown
				local leftOffset = nobar + leftbarOffset;   -- 142
				local rightOffset = nobar + rightbarOffset; -- 92
				
				self:ClearAllPoints();
				
				if leftbar and rightbar then
					-- Both bars shown, use leftOffset (positions above bottom right which is highest)
					self:SetPoint('TOPLEFT', mainBar, 'TOPLEFT', offsetX, leftOffset + offsetY);
				elseif leftbar then
					-- Only left bar shown, use rightOffset (lower position)
					self:SetPoint('TOPLEFT', mainBar, 'TOPLEFT', offsetX, rightOffset + offsetY);
				elseif rightbar then
					-- Only right bar shown, use leftOffset (higher position)
					self:SetPoint('TOPLEFT', mainBar, 'TOPLEFT', offsetX, leftOffset + offsetY);
				else
					-- No extra bars, use default position
					self:SetPoint('TOPLEFT', mainBar, 'TOPLEFT', offsetX, nobar + offsetY);
				end
			else
				-- Fallback to standard Blizzard frames (relative anchoring)
				local leftbar = MultiBarBottomLeft:IsShown();
				local rightbar = MultiBarBottomRight:IsShown();
				local anchorFrame, anchorPoint, relativePoint, yOffset;
				
				if leftbar or rightbar then
					-- If extra bars are shown, anchor above the highest one
					if leftbar and rightbar then
						-- Both bars shown, bottom right is higher, so anchor to it
						anchorFrame = MultiBarBottomRight;
					elseif leftbar then
						anchorFrame = MultiBarBottomLeft;
					else
						anchorFrame = MultiBarBottomRight;
					end
					anchorPoint = 'TOP';
					relativePoint = 'BOTTOM';
					yOffset = 5;
				else
					-- No extra bars, anchor above main bar
					anchorFrame = pUiMainBar or MainMenuBar;
					anchorPoint = 'TOP';
					relativePoint = 'BOTTOM';
					yOffset = 5;
				end
				
				self:ClearAllPoints();
				self:SetPoint(relativePoint, anchorFrame, anchorPoint, offsetX, yOffset + offsetY);
			end
		end
	end
end

event:RegisterEvents(function()
	anchor:stancebar_update();
end,
	'PLAYER_LOGIN','ADDON_LOADED'
);

-- Force stance bar initialization with single controlled initialization
local function ForceStanceBarInitialization()
	if not InCombatLockdown() and not UnitAffectingCombat('player') then
		if config and config.additional then
			-- Force button positioning
			if stancebutton_position then
				stancebutton_position()
			end
			-- Force anchor update
			if anchor and anchor.stancebar_update then
				anchor:stancebar_update()
			end
			-- Show the stance bar frame
			if stancebar then
				stancebar:Show()
			end
		end
	end
end

-- Multiple initialization triggers
addon.core.RegisterMessage(addon, "DRAGONUI_READY", ForceStanceBarInitialization);

local MultiBarBottomLeft = _G["MultiBarBottomLeft"]
local MultiBarBottomRight = _G["MultiBarBottomRight"]

for _,bar in pairs({_G["MultiBarBottomLeft"], _G["MultiBarBottomRight"]}) do
	if bar then
		bar:HookScript('OnShow',function()
			if not InCombatLockdown() and not UnitAffectingCombat('player') then
				QueueUpdate("bar_show");
			end
		end);
		bar:HookScript('OnHide',function()
			if not InCombatLockdown() and not UnitAffectingCombat('player') then
				QueueUpdate("bar_hide");
			end
		end);
	end
end;

local stancebar = CreateFrame('Frame', 'pUiStanceBar', anchor, 'SecureHandlerStateTemplate')
stancebar:SetAllPoints(anchor)

local function stancebutton_update()
	if not InCombatLockdown() then
		_G.ShapeshiftButton1:SetPoint('BOTTOMLEFT', anchor, 'BOTTOMLEFT', 0, 0)
	end
end

local function stancebutton_position()
	-- Read config values dynamically
	local btnsize = config.additional.size;
	local space = config.additional.spacing;
	
	for index=1, NUM_SHAPESHIFT_SLOTS do
		local button = _G['ShapeshiftButton'..index]
		button:ClearAllPoints()
		button:SetParent(stancebar)
		button:SetSize(btnsize, btnsize)
		if index == 1 then
			button:SetPoint('BOTTOMLEFT', anchor, 'BOTTOMLEFT', 0, 0)
		else
			local previous = _G['ShapeshiftButton'..index-1]
			button:SetPoint('LEFT', previous, 'RIGHT', space, 0)
		end
		local _,name = GetShapeshiftFormInfo(index)
		if name then
			button:Show()
		else
			button:Hide()
		end
	end
	-- Resize holder to match layout (mover follows this). Use fixed max slots for 3.3.5a.
	local totalWidth = (btnsize * 10) + (space * 9)
	anchor:SetSize(totalWidth, btnsize)
	RegisterStateDriver(stancebar, 'visibility', stance[class] or 'hide')
	hooksecurefunc('ShapeshiftBar_Update', function()
		if not InCombatLockdown() and not UnitAffectingCombat('player') then
			stancebutton_update()
		end
	end)
end

local function stancebutton_updatestate()
	local numForms = GetNumShapeshiftForms()
	local texture, name, isActive, isCastable;
	local button, icon, cooldown;
	local start, duration, enable;
	for index=1, NUM_SHAPESHIFT_SLOTS do
		button = _G['ShapeshiftButton'..index]
		icon = _G['ShapeshiftButton'..index..'Icon']
		if index <= numForms then
			texture, name, isActive, isCastable = GetShapeshiftFormInfo(index)
			icon:SetTexture(texture)
			cooldown = _G['ShapeshiftButton'..index..'Cooldown']
			if texture then
				cooldown:SetAlpha(1)
			else
				cooldown:SetAlpha(0)
			end
			start, duration, enable = GetShapeshiftFormCooldown(index)
			CooldownFrame_SetTimer(cooldown, start, duration, enable)
			if isActive then
				ShapeshiftBarFrame.lastSelected = button:GetID()
				button:SetChecked(1)
			else
				button:SetChecked(0)
			end
			if isCastable then
				icon:SetVertexColor(255/255, 255/255, 255/255)
			else
				icon:SetVertexColor(102/255, 102/255, 102/255)
			end
		end
	end
end

local function stancebutton_setup()
	if InCombatLockdown() then return end
	for index=1, NUM_SHAPESHIFT_SLOTS do
		local button = _G['ShapeshiftButton'..index]
		local _, name = GetShapeshiftFormInfo(index)
		if name then
			button:Show()
		else
			button:Hide()
		end
	end
	stancebutton_updatestate();
end

local function OnEvent(self,event,...)
	if GetNumShapeshiftForms() < 1 then return; end
	if event == 'PLAYER_LOGIN' then
		stancebutton_position();
	elseif event == 'UPDATE_SHAPESHIFT_FORMS' then
		stancebutton_setup();
	elseif event == 'PLAYER_ENTERING_WORLD' then
		self:UnregisterEvent('PLAYER_ENTERING_WORLD');
		addon.stancebuttons_template();
	else
		stancebutton_updatestate();
	end
end

stancebar:RegisterEvent('PLAYER_LOGIN');
stancebar:RegisterEvent('PLAYER_ENTERING_WORLD');
stancebar:RegisterEvent('UPDATE_SHAPESHIFT_FORMS');
stancebar:RegisterEvent('UPDATE_SHAPESHIFT_USABLE');
stancebar:RegisterEvent('UPDATE_SHAPESHIFT_COOLDOWN');
stancebar:RegisterEvent('UPDATE_SHAPESHIFT_FORM');
stancebar:RegisterEvent('ACTIONBAR_PAGE_CHANGED');
stancebar:SetScript('OnEvent', OnEvent);

-- Single controlled initialization when player enters world
event:RegisterEvents(function()
	-- Force initialization after a short delay when player enters world
	local initFrame = CreateFrame("Frame")
	local elapsed = 0
	initFrame:SetScript("OnUpdate", function(self, dt)
		elapsed = elapsed + dt
		if elapsed >= 1.0 then -- Wait 1 second after entering world
			self:SetScript("OnUpdate", nil)
			-- Force initialization only once
			ForceStanceBarInitialization()
		end
	end)
end, 'PLAYER_ENTERING_WORLD');

-- Refresh function for stance bar configuration changes
function addon.RefreshStance()
	if not _G.pUiStanceBar or InCombatLockdown() or UnitAffectingCombat('player') then
		return
	end

	-- Apply scaling
	local scale = config.mainbars and config.mainbars.scale_stance or 0.9;
	if _G.pUiStanceHolder then
		_G.pUiStanceHolder:SetScale(scale);
	end

	-- Update button size and spacing
	local btnsize = config.additional.size;
	local space = config.additional.spacing;
	
	-- Reposition stance buttons
	for i = 1, 10 do -- Use fixed number instead of NUM_SHAPESHIFT_SLOTS for 3.3.5a compatibility
		local button = _G["ShapeshiftButton"..i];
		if button then
			button:SetSize(btnsize, btnsize);
			if i == 1 then
				button:SetPoint('BOTTOMLEFT', 0, 0);
			else
				local prevButton = _G["ShapeshiftButton"..(i-1)];
				if prevButton then
					button:SetPoint('LEFT', prevButton, 'RIGHT', space, 0);
				end
			end
		end
	end
	
	-- Update holder size so mover reflects current layout
	local totalWidth = (btnsize * 10) + (space * 9)
	anchor:SetSize(totalWidth, btnsize)
	-- Update position using relative anchoring (no more absolute Y coordinates)
	if anchor then
		anchor:stancebar_update();
		if addon and addon.Movers and addon.Movers.registry and addon.Movers.registry.stancebar and addon.ApplyMover then
			addon:ApplyMover('stancebar')
		end
	end

	-- Initialize visibility system for hover/combat behavior
	if addon.InitializeStanceBarVisibility then
		addon.InitializeStanceBarVisibility();
	end
end