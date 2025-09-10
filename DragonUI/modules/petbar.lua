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
local GetPetActionInfo = GetPetActionInfo;
local RegisterStateDriver = RegisterStateDriver;
local CreateFrame = CreateFrame;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;

-- @param: config number - these will be read dynamically
-- local offsetX = config.additional.pet.x_position;
-- local nobar = config.additional.y_position;
-- local exOffs = config.additional.leftbar_offset;
-- local exOffs2 = config.additional.rightbar_offset;
-- local leftOffset, rightOffset = nobar + exOffs, nobar + exOffs2;

local anchor = CreateFrame('Frame', 'pUiPetBarHolder', UIParent)
-- Set initial position - will be updated by petbar_update when config is ready
anchor:SetPoint('TOPLEFT', UIParent, 'BOTTOM', -134, 100) -- Fallback position using current database default
anchor:SetSize(37, 37)

-- Register mover for Pet Bar holder (resizes with buttons)
if addon.CreateMover and not (addon.Movers and addon.Movers.registry and addon.Movers.registry.petbar) then
    addon:CreateMover(anchor, 'petbar', 'Pet Bar', {'BOTTOM', UIParent, 'BOTTOM', -180, 120})
    anchor:HookScript('OnShow', function() if addon.ApplyMover then addon:ApplyMover('petbar') end end)
end

-- method update position using relative anchoring
function anchor:petbar_update()
	if not InCombatLockdown() and not UnitAffectingCombat('player') then
			-- If using mover, do not auto-reposition
			if addon and addon.Movers and addon.Movers.registry and addon.Movers.registry.petbar then
				return
			end
		-- Read config values dynamically each time
		local offsetX = config.additional.pet.x_position;
		local offsetY = config.additional.pet.y_offset or 0;  -- Additional Y offset for fine-tuning
		
		-- Check if pretty_actionbar addon is loaded and use its positioning system
		if IsAddOnLoaded('pretty_actionbar') and _G.pUiMainBar then
			-- Use pretty_actionbar's exact logic (replicated from working port)
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
				yOffset = 5 + offsetY; -- Add custom Y offset
			else
				-- No extra bars, anchor above main bar
				anchorFrame = pUiMainBar or MainMenuBar;
				anchorPoint = 'TOP';
				relativePoint = 'BOTTOM';
				yOffset = 5 + offsetY; -- Add custom Y offset
			end
			
			self:ClearAllPoints();
			self:SetPoint(relativePoint, anchorFrame, anchorPoint, offsetX, yOffset);
		end
	end
end

-- Force pet bar initialization regardless of conditions
local function ForcePetBarInitialization()
    if config and config.additional then
        -- Force anchor update
        if anchor and anchor.petbar_update then
            anchor:petbar_update()
        end
        --[[ -- REMOVED to prevent ADDON_ACTION_BLOCKED errors
        -- Show the pet bar frame if it exists
        if _G.pUiPetBar then
            _G.pUiPetBar:Show()
        end
        -- Show anchor frame
        if anchor then
            anchor:Show()
        end
        --]]
    end
end

-- Delayed initialization to ensure everything is loaded
local function DelayedPetInit()
	local delayFrame = CreateFrame("Frame")
	local elapsed = 0
	local attempts = 0
	local maxAttempts = 20 -- Try for up to 10 seconds
	
	delayFrame:SetScript("OnUpdate", function(self, dt)
		elapsed = elapsed + dt
		if elapsed >= 0.5 then -- Every 0.5 seconds
			elapsed = 0
			attempts = attempts + 1
			
			-- Try to initialize
			ForcePetBarInitialization()
			
			-- Stop after max attempts
			if attempts >= maxAttempts then
				delayFrame:SetScript("OnUpdate", nil)
			end
		end
	end)
end

-- Set initial position when DragonUI is fully initialized
addon.core.RegisterMessage(addon, "DRAGONUI_READY", ForcePetBarInitialization);

local MultiBarBottomLeft = _G["MultiBarBottomLeft"]
local MultiBarBottomRight = _G["MultiBarBottomRight"]

for _,bar in pairs({MultiBarBottomLeft,MultiBarBottomRight}) do
	if bar then
		bar:HookScript('OnShow',function()
			anchor:petbar_update();
		end);
		bar:HookScript('OnHide',function()
			anchor:petbar_update();
		end);
	end
end;

local petbar = CreateFrame('Frame', 'pUiPetBar', UIParent, 'SecureHandlerStateTemplate')
petbar:SetAllPoints(anchor)

local function petbutton_updatestate(self, event)
	local petActionButton, petActionIcon, petAutoCastableTexture, petAutoCastShine
	for index=1, NUM_PET_ACTION_SLOTS, 1 do
		local buttonName = 'PetActionButton'..index
		petActionButton = _G[buttonName]
		petActionIcon = _G[buttonName..'Icon']
		petAutoCastableTexture = _G[buttonName..'AutoCastable']
		petAutoCastShine = _G[buttonName..'Shine']
		
		local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(index)
		if not isToken then
			petActionIcon:SetTexture(texture)
			petActionButton.tooltipName = name
		else
			petActionIcon:SetTexture(_G[texture])
			petActionButton.tooltipName = _G[name]
		end
		petActionButton.isToken = isToken
		petActionButton.tooltipSubtext = subtext
		if isActive and name ~= 'PET_ACTION_FOLLOW' then
			petActionButton:SetChecked(true)
			if IsPetAttackAction(index) then
				PetActionButton_StartFlash(petActionButton)
			end
		else
			petActionButton:SetChecked(false)
			if IsPetAttackAction(index) then
				PetActionButton_StopFlash(petActionButton)
			end
		end
		if autoCastAllowed then
			petAutoCastableTexture:Show()
		else
			petAutoCastableTexture:Hide()
		end
		if autoCastEnabled then
			AutoCastShine_AutoCastStart(petAutoCastShine)
		else
			AutoCastShine_AutoCastStop(petAutoCastShine)
		end
		if name then
			if not config.additional.pet.grid then
				petActionButton:SetAlpha(1)
			end
		else
			if not config.additional.pet.grid then
				petActionButton:SetAlpha(0)
			end
		end
		if texture then
			if GetPetActionSlotUsable(index) then
				SetDesaturation(petActionIcon, nil)
			else
				SetDesaturation(petActionIcon, 1)
			end
			petActionIcon:Show()
		else
			petActionIcon:Hide()
		end
		if not PetHasActionBar() and texture and name ~= 'PET_ACTION_FOLLOW' then
			PetActionButton_StopFlash(petActionButton)
			SetDesaturation(petActionIcon, 1)
			petActionButton:SetChecked(false)
		end
	end
end

local function petbutton_position()
	if InCombatLockdown() then return end
	-- Read config values dynamically
	local btnsize = config.additional.size;
	local space = config.additional.spacing;
	
	local button
	for index=1, 10 do
		button = _G['PetActionButton'..index];
		button:ClearAllPoints();
		button:SetParent(pUiPetBar);
		button:SetSize(btnsize, btnsize);
		if index == 1 then
			button:SetPoint('BOTTOMLEFT', 0, 0);
		else
			button:SetPoint('LEFT', _G['PetActionButton'..index-1], 'RIGHT', space, 0);
		end
		button:Show();
		petbar:SetAttribute('addchild', button);
	end
	-- Resize holder to match layout (mover follows this)
	local totalWidth = (btnsize * 10) + (space * 9)
	anchor:SetSize(totalWidth, btnsize)
	-- FIXED: Don't force showgrid = 1, let our grid configuration control this
	-- PetActionBarFrame.showgrid = 1;
	RegisterStateDriver(petbar, 'visibility', '[pet,novehicleui,nobonusbar:5] show; hide');
	hooksecurefunc('PetActionBar_Update', petbutton_updatestate);
end

local function OnEvent(self,event,...)
	-- if not UnitIsVisible('pet') then return; end
	local arg1 = ...;
	if event == 'PLAYER_LOGIN' then
		petbutton_position();
		-- FIXED: Apply grid configuration after initial positioning
		if addon.RefreshPetbar then
			addon.RefreshPetbar();
		end
	elseif event == 'PET_BAR_UPDATE'
	or event == 'UNIT_PET' and arg1 == 'player'
	or event == 'PLAYER_CONTROL_LOST'
	or event == 'PLAYER_CONTROL_GAINED'
	or event == 'PLAYER_FARSIGHT_FOCUS_CHANGED'
	or event == 'UNIT_FLAGS'
	or arg1 == 'pet' and event == 'UNIT_AURA' then
		petbutton_updatestate();
	elseif event == 'PET_BAR_UPDATE_COOLDOWN' then
		PetActionBar_UpdateCooldowns();
	else
		addon.petbuttons_template();
	end
end

petbar:RegisterEvent('PET_BAR_HIDE');
petbar:RegisterEvent('PET_BAR_UPDATE');
petbar:RegisterEvent('PET_BAR_UPDATE_COOLDOWN');
petbar:RegisterEvent('PET_BAR_UPDATE_USABLE');
petbar:RegisterEvent('PLAYER_CONTROL_GAINED');
petbar:RegisterEvent('PLAYER_CONTROL_LOST');
petbar:RegisterEvent('PLAYER_FARSIGHT_FOCUS_CHANGED');
petbar:RegisterEvent('PLAYER_LOGIN');
petbar:RegisterEvent('UNIT_AURA');
petbar:RegisterEvent('UNIT_FLAGS');
petbar:RegisterEvent('UNIT_PET');
petbar:SetScript('OnEvent',OnEvent);

-- Additional late initialization when player is fully loaded (moved here so petbutton_position is defined)
event:RegisterEvents(function()
	-- Force initialization after a short delay when player enters world
	local initFrame = CreateFrame("Frame")
	local elapsed = 0
	initFrame:SetScript("OnUpdate", function(self, dt)
		elapsed = elapsed + dt
		if elapsed >= 1.0 then -- Wait 1 second after entering world
			self:SetScript("OnUpdate", nil)
			-- Force button positioning explicitly (now petbutton_position is defined)
			if _G.pUiPetBar then
				petbutton_position()
			end
			ForcePetBarInitialization()
			DelayedPetInit() -- Start the delayed retry system
		end
	end)
end, 'PLAYER_ENTERING_WORLD');

-- Refresh function for pet bar configuration changes
function addon.RefreshPetbar()

	if InCombatLockdown() then return end
	if not pUiPetBar then return end
	
	-- Update button size and spacing
	local btnsize = config.additional.size;
	local space = config.additional.spacing;
	
	-- Reposition pet buttons
	for i = 1, NUM_PET_ACTION_SLOTS do
		local button = _G["PetActionButton"..i];
		if button then
			button:SetSize(btnsize, btnsize);
			if i == 1 then
				button:SetPoint('BOTTOMLEFT', 0, 0);
			else
				button:SetPoint('LEFT', _G["PetActionButton"..(i-1)], 'RIGHT', space, 0);
			end
		end
	end
	
	-- Update grid visibility - FIXED: Proper empty slot handling
	local grid = config.additional.pet.grid;
	for i = 1, NUM_PET_ACTION_SLOTS do
		local button = _G["PetActionButton"..i];
		if button then
			local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(i);
			
			if grid then
				-- Show all slots when grid is enabled
				button:Show();
				-- If slot is empty, show a background texture to indicate it's an empty slot
				if not name then
					-- Show empty slot appearance
					local icon = _G["PetActionButton"..i.."Icon"];
					if icon then
						icon:SetTexture("Interface\\Buttons\\UI-EmptySlot");
						icon:SetVertexColor(0.5, 0.5, 0.5, 0.5); -- Dimmed appearance
					end
					button:SetChecked(false);
				end
			else
				-- Hide empty slots when grid is disabled
				if not name then
					button:Hide();
				end
			end
		end
	end
	
	-- Update holder size so mover reflects current layout
	local totalWidth = (btnsize * 10) + (space * 9)
	anchor:SetSize(totalWidth, btnsize)
	-- Update position using relative anchoring (no more absolute Y coordinates)
	if anchor then
		anchor:petbar_update();
		if addon and addon.Movers and addon.Movers.registry and addon.Movers.registry.petbar and addon.ApplyMover then
			addon:ApplyMover('petbar')
		end
	end
end