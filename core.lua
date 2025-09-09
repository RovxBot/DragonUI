local addon = select(2,...);

-- Create addon object using AceAddon
addon.core = LibStub("AceAddon-3.0"):NewAddon("DragonUI", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0");

-- Function to recursively copy tables
local function deepCopy(source, target)
	for key, value in pairs(source) do
		if type(value) == "table" then
			if not target[key] then
				target[key] = {};
			end
			deepCopy(value, target[key]);
		else
			if target[key] == nil then
				target[key] = value;
			end
		end
	end
end

function addon.core:OnInitialize()
	-- Replace the temporary addon.db with the real AceDB
	addon.db = LibStub("AceDB-3.0"):New("DragonUIDB", addon.defaults);
	
	-- Force defaults to be written to profile (check for specific key that should always exist)
	if not addon.db.profile.mainbars or not addon.db.profile.mainbars.scale_actionbar then
		-- Copy all defaults to profile to ensure they exist in SavedVariables
		deepCopy(addon.defaults.profile, addon.db.profile);
	end
	
	-- Register callbacks for configuration changes
	addon.db.RegisterCallback(addon, "OnProfileChanged", "RefreshConfig");
	addon.db.RegisterCallback(addon, "OnProfileCopied", "RefreshConfig");
	addon.db.RegisterCallback(addon, "OnProfileReset", "RefreshConfig");
	
	-- Apply current profile configuration immediately
	-- This ensures the profile is loaded when the addon starts
	addon:RefreshConfig();
end

-- Callback function that refreshes all modules when configuration changes
function addon:RefreshConfig()
	-- Initialize cooldown system if it hasn't been already
	if addon.InitializeCooldowns then
		addon.InitializeCooldowns()
	end

	local failed = {};
	
	-- Try to apply each configuration and track failures
	if addon.RefreshMainbars then 
		local success, err = pcall(addon.RefreshMainbars);
		if not success then table.insert(failed, "RefreshMainbars") end
	end
	
	if addon.RefreshButtons then 
		local success, err = pcall(addon.RefreshButtons);
		if not success then table.insert(failed, "RefreshButtons") end
	end
	
	if addon.RefreshMicromenu then 
		local success, err = pcall(addon.RefreshMicromenu);
		if not success then table.insert(failed, "RefreshMicromenu") end
	end
	
	if addon.RefreshMinimap then 
		local success, err = pcall(addon.RefreshMinimap);
		if not success then table.insert(failed, "RefreshMinimap") end
	end
	
	if addon.RefreshStance then 
		local success, err = pcall(addon.RefreshStance);
		if not success then table.insert(failed, "RefreshStance") end
	end
	
	if addon.RefreshPetbar then 
		local success, err = pcall(addon.RefreshPetbar);
		if not success then table.insert(failed, "RefreshPetbar") end
	end
	
	if addon.RefreshVehicle then 
		local success, err = pcall(addon.RefreshVehicle);
		if not success then table.insert(failed, "RefreshVehicle") end
	end
	
	if addon.RefreshMulticast then 
		local success, err = pcall(addon.RefreshMulticast);
		if not success then table.insert(failed, "RefreshMulticast") end
	end
	
	if addon.RefreshCooldowns then 
		local success, err = pcall(addon.RefreshCooldowns);
		if not success then table.insert(failed, "RefreshCooldowns") end
	end

	if addon.RefreshXpRepBarPosition then
		pcall(addon.RefreshXpRepBarPosition)
	end

	if addon.RefreshRepBarPosition then
		pcall(addon.RefreshRepBarPosition)
	end
	
	if addon.RefreshMinimapTime then 
		local success, err = pcall(addon.RefreshMinimapTime);
		if not success then table.insert(failed, "RefreshMinimapTime") end
	end
	
	if addon.RefreshCastbar then 
		-- Delay castbar refresh to ensure Blizzard UI is fully loaded
		addon.core:ScheduleTimer(function()
			local success, err = pcall(addon.RefreshCastbar);
			if not success then table.insert(failed, "RefreshCastbar") end
		end, 1.5);
	end
	
	-- If some configurations failed, retry them after 2 seconds
	if #failed > 0 then
		addon.core:ScheduleTimer(function()
			for _, funcName in ipairs(failed) do
				if addon[funcName] then
					pcall(addon[funcName]);
				end
			end
		end, 2);
	end
end

function addon.core:OnEnable()
	if addon.CreateOptionsTable then
		addon.options = addon:CreateOptionsTable();

		local profilesOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db);
		addon.options.args.profiles = profilesOptions;
		addon.options.args.profiles.order = 10;

		LibStub("AceConfig-3.0"):RegisterOptionsTable("DragonUI", addon.options);
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DragonUI", "DragonUI");
	end

	-- Register slash commands
	self:RegisterChatCommand("dragonui", "SlashCommand");
	self:RegisterChatCommand("pi", "SlashCommand");

	-- Fire custom event to signal that DragonUI is fully initialized
	-- This ensures modules get the correct config values
	self:SendMessage("DRAGONUI_READY");
end

function addon.core:SlashCommand(input)
	if not input or input:trim() == "" then
		LibStub("AceConfigDialog-3.0"):Open("DragonUI");
	elseif input:lower() == "config" then
		LibStub("AceConfigDialog-3.0"):Open("DragonUI");
	elseif input:lower() == "edit" or input:lower() == "editor" then
		if addon.EditorMode then
			addon.EditorMode:Toggle();
		else
			self:Print("Editor mode not available. Make sure the editor_mode module is loaded.");
		end
	else
		self:Print("Commands:");
		self:Print("/dragonui config - Open configuration");
		self:Print("/dragonui edit - Toggle editor mode for moving UI elements");
	end
end

