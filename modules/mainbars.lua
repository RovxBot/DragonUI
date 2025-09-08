local addon = select(2,...);
local config = addon.config;
local event = addon.package;
local do_action = addon.functions;
local select = select;
local pairs = pairs;
local ipairs = ipairs;
local format = string.format;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local UnitFactionGroup = UnitFactionGroup;
local _G = getfenv(0);

-- constants
local faction = UnitFactionGroup('player');
local old = (config.style.xpbar == 'old');
local new = (config.style.xpbar == 'new');
local MainMenuBarMixin = {};
local pUiMainBar = CreateFrame(
	'Frame',
	'pUiMainBar',
	UIParent,
	'MainMenuBarUiTemplate'
);
local pUiMainBarArt = CreateFrame(
	'Frame',
	'pUiMainBarArt',
	pUiMainBar
);
pUiMainBar:SetScale(config.mainbars.scale_actionbar);
pUiMainBarArt:SetFrameStrata('HIGH');
pUiMainBarArt:SetFrameLevel(pUiMainBar:GetFrameLevel() + 4);
pUiMainBarArt:SetAllPoints(pUiMainBar);

local function UpdateGryphonStyle()
    -- ensure gryphon elements exist before modification
    if not MainMenuBarLeftEndCap or not MainMenuBarRightEndCap then return end
    
    -- get current style settings
    local db_style = addon.db and addon.db.profile and addon.db.profile.style
    if not db_style then db_style = config.style end

    local faction = UnitFactionGroup('player')

    if db_style.gryphons == 'old' then
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -85, -22)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 84, -22)
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    elseif db_style.gryphons == 'new' then
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -95, -23)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 95, -23)
        if faction == 'Alliance' then
            MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-thick-left', true)
            MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-thick-right', true)
        else
            MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-wyvern-thick-left', true)
            MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-wyvern-thick-right', true)
        end
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    elseif db_style.gryphons == 'flying' then
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -80, -21)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 80, -21)
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    else
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
    end
end

-- =========================================================================
-- ✅ ACTION BAR LAYOUT SYSTEM
-- =========================================================================

-- Calculate frame size needed for a given layout
local function CalculateFrameSize(rows, columns)
    local buttonSize = 37
    local spacing = 7
    local padding = 4

    local width = (buttonSize * columns) + (spacing * (columns - 1)) + padding
    local height = (buttonSize * rows) + (spacing * (rows - 1)) + padding

    return width, height
end

-- Arrange action bar buttons in a grid layout
function addon.ArrangeActionBarButtons(buttonPrefix, parentFrame, anchorFrame, rows, columns, buttonsShown)
    if InCombatLockdown() then return end

    local buttonSize = 37
    local spacing = 7
    local startX = 2
    local startY = 2

    -- Arrange buttons in grid
    for index = 1, NUM_ACTIONBAR_BUTTONS do
        local button = _G[buttonPrefix .. index]
        if button then
            button:SetParent(parentFrame)

            if index <= buttonsShown then
                -- Calculate grid position (0-based for math)
                local gridIndex = index - 1
                local row = math.floor(gridIndex / columns)
                local col = gridIndex % columns

                -- Calculate pixel position
                local x = startX + (col * (buttonSize + spacing))
                local y = startY + (row * (buttonSize + spacing))

                button:SetClearPoint('BOTTOMLEFT', anchorFrame, 'BOTTOMLEFT', x, y)
                button:Show()
            else
                -- Hide buttons beyond the limit
                button:Hide()
            end
        end
    end

    -- Resize parent frame to fit the layout
    if parentFrame and parentFrame.SetSize then
        local width, height = CalculateFrameSize(rows, columns)
        parentFrame:SetSize(width, height)
    end
end

function MainMenuBarMixin:actionbutton_setup()
	for _,obj in ipairs({MainMenuBar:GetChildren(),MainMenuBarArtFrame:GetChildren()}) do
		obj:SetParent(pUiMainBar)
	end

	for index=1, NUM_ACTIONBAR_BUTTONS do
		pUiMainBar:SetFrameRef('ActionButton'..index, _G['ActionButton'..index])
	end

	for index=1, NUM_ACTIONBAR_BUTTONS -1 do
		local ActionButtons = _G['ActionButton'..index]
		do_action.SetThreeSlice(ActionButtons);
	end

	-- ✅ Use new layout system for main action bar only
	local db = addon.db and addon.db.profile and addon.db.profile.mainbars
	if db and db.player then
		-- Main action bar with custom layout
		addon.ArrangeActionBarButtons('ActionButton', pUiMainBar, pUiMainBar,
			db.player.rows or 1, db.player.columns or 12, db.player.buttons_shown or 12)
	else
		-- Fallback to original linear layout for main bar
		for index=2, NUM_ACTIONBAR_BUTTONS do
			local ActionButtons = _G['ActionButton'..index]
			ActionButtons:SetParent(pUiMainBar)
			ActionButtons:SetClearPoint('LEFT', _G['ActionButton'..(index-1)], 'RIGHT', 7, 0)
		end
	end

	-- ✅ Keep secondary bars in their original linear layout for now
	-- These will be positioned properly in actionbar_setup()
	for index=2, NUM_ACTIONBAR_BUTTONS do
		local BottomLeftButtons = _G['MultiBarBottomLeftButton'..index]
		if BottomLeftButtons then
			BottomLeftButtons:SetClearPoint('LEFT', _G['MultiBarBottomLeftButton'..(index-1)], 'RIGHT', 7, 0)
		end

		local BottomRightButtons = _G['MultiBarBottomRightButton'..index]
		if BottomRightButtons then
			BottomRightButtons:SetClearPoint('LEFT', _G['MultiBarBottomRightButton'..(index-1)], 'RIGHT', 7, 0)
		end

		local BonusActionButtons = _G['BonusActionButton'..index]
		if BonusActionButtons then
			BonusActionButtons:SetClearPoint('LEFT', _G['BonusActionButton'..(index-1)], 'RIGHT', 7, 0)
		end
	end
end

function MainMenuBarMixin:actionbar_art_setup()
    -- setup art frames
    MainMenuBarArtFrame:SetParent(pUiMainBar)
    for _,art in pairs({MainMenuBarLeftEndCap, MainMenuBarRightEndCap}) do
        art:SetParent(pUiMainBarArt)
        art:SetDrawLayer('ARTWORK')
    end
    
    -- apply background settings
    self:update_main_bar_background()
    
    -- apply gryphon styling
    UpdateGryphonStyle()
end

function MainMenuBarMixin:update_main_bar_background()
    local alpha = (addon.db and addon.db.profile and addon.db.profile.buttons and addon.db.profile.buttons.hide_main_bar_background) and 0 or 1
    
    -- handle button background textures
    for i = 1, NUM_ACTIONBAR_BUTTONS do
        local button = _G["ActionButton" .. i]
        if button then
            if button.NormalTexture then button.NormalTexture:SetAlpha(alpha) end
            for j = 1, button:GetNumRegions() do
                local region = select(j, button:GetRegions())
                if region and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" and region ~= button:GetNormalTexture() then
                    region:SetAlpha(alpha)
                end
            end
        end
    end
    
    
    if pUiMainBar then
        -- hide loose textures within pUiMainBar
        for i = 1, pUiMainBar:GetNumRegions() do
            local region = select(i, pUiMainBar:GetRegions())
            if region and region:GetObjectType() == "Texture" then
                local texPath = region:GetTexture()
                if texPath and not string.find(texPath, "ICON") then
                    region:SetAlpha(alpha)
                end
            end
        end

        -- hide child frame textures with protection for UI elements
        for i = 1, pUiMainBar:GetNumChildren() do
            local child = select(i, pUiMainBar:GetChildren())
            local name = child and child:GetName()
            
            -- protect important UI elements from being hidden
            if child and name ~= "pUiMainBarArt" 
                    and not string.find(name or "", "ActionButton")
                    and name ~= "MainMenuExpBar" 
                    and name ~= "ReputationWatchBar"
                    and name ~= "MultiBarBottomLeft"
                    and name ~= "MultiBarBottomRight"
                    and name ~= "MicroButtonAndBagsBar"
                    and not string.find(name or "", "MicroButton")
                    and not string.find(name or "", "Bag")
                    and name ~= "CharacterMicroButton"
                    and name ~= "SpellbookMicroButton"
                    and name ~= "TalentMicroButton"
                    and name ~= "AchievementMicroButton"
                    and name ~= "QuestLogMicroButton"
                    and name ~= "SocialsMicroButton"
                    and name ~= "PVPMicroButton"
                    and name ~= "LFGMicroButton"
                    and name ~= "MainMenuMicroButton"
                    and name ~= "HelpMicroButton" then
                
                for j = 1, child:GetNumRegions() do
                    local region = select(j, child:GetRegions())
                    if region and region:GetObjectType() == "Texture" then
                        region:SetAlpha(alpha)
                    end
                end
            end
        end
    end
end


function MainMenuBarMixin:actionbar_setup()
	-- Set up main action bar first button
	ActionButton1:SetParent(pUiMainBar)
	ActionButton1:SetClearPoint('BOTTOMLEFT', pUiMainBar, 2, 2)

	-- Position secondary bars - these will be updated by RefreshUpperActionBarsPosition later
	-- For now, position them with default offsets
	if MultiBarBottomLeftButton1 then
		MultiBarBottomLeftButton1:SetClearPoint('BOTTOMLEFT', ActionButton1, 'BOTTOMLEFT', 0, 48)
	end
	
	if config.buttons.pages.show then
		do_action.SetNumPagesButton(ActionBarUpButton, pUiMainBarArt, 'pageuparrow', 8)
		do_action.SetNumPagesButton(ActionBarDownButton, pUiMainBarArt, 'pagedownarrow', -14)
		
		MainMenuBarPageNumber:SetParent(pUiMainBarArt)
		MainMenuBarPageNumber:SetClearPoint('CENTER', ActionBarDownButton, -1, 12)
		local pagesFont = config.buttons.pages.font
		MainMenuBarPageNumber:SetFont(pagesFont[1], pagesFont[2], pagesFont[3])
		MainMenuBarPageNumber:SetShadowColor(0, 0, 0, 1)
		MainMenuBarPageNumber:SetShadowOffset(1.2, -1.2)
		MainMenuBarPageNumber:SetDrawLayer('OVERLAY', 7)
	else
		ActionBarUpButton:Hide();
		ActionBarDownButton:Hide();
		MainMenuBarPageNumber:Hide();
	end
	-- ✅ Don't parent secondary bars to pUiMainBar - they should be independent
	-- MultiBarBottomLeft:SetParent(pUiMainBar)
	-- MultiBarBottomRight:SetParent(pUiMainBar)

	-- Instead, ensure they're parented to UIParent for independent positioning
	if MultiBarBottomLeft then
		MultiBarBottomLeft:SetParent(UIParent)
	end
	if MultiBarBottomRight then
		MultiBarBottomRight:SetParent(UIParent)
	end
	MultiBarBottomRight:EnableMouse(false)
	MultiBarBottomRight:SetClearPoint('BOTTOMLEFT', MultiBarBottomLeftButton1, 'TOPLEFT', 0, 8)
	-- MultiBarRight:SetClearPoint('TOPRIGHT', UIParent, 'RIGHT', -6, (Minimap:GetHeight() * 1.3))
	MultiBarRight:SetScale(config.mainbars.scale_rightbar)
	MultiBarLeft:SetScale(config.mainbars.scale_leftbar)

	-- MultiBarLeft:SetParent(UIParent)
	-- MultiBarLeft:SetClearPoint('TOPRIGHT', MultiBarRight, 'TOPLEFT', -7, 0)
end

function addon.PositionActionBars()
    if InCombatLockdown() then return end
    
    local db = addon.db and addon.db.profile and addon.db.profile.mainbars
    if not db then return end

    -- ✅ OBTENER LA ESCALA DE LA UI UNA SOLA VEZ
    local scale = UIParent:GetEffectiveScale()

    -- 1. Barra Principal (pUiMainBar)
    if pUiMainBar then
        pUiMainBar:SetMovable(true)
        pUiMainBar:ClearAllPoints()

        -- Apply scaling
        pUiMainBar:SetScale(db.scale_actionbar or 0.9)

        if db.player.override then
            -- MODO MANUAL: Posición guardada por el usuario.
            -- ✅ CORRECCIÓN: Dividimos por la escala para convertir píxeles a puntos.
            pUiMainBar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (db.player.x or 0) / scale, (db.player.y or 0) / scale)
        else
            -- MODO AUTOMÁTICO: Posicionamiento por defecto.
            pUiMainBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, db.player.y_position_offset or 75)
        end
        pUiMainBar:SetUserPlaced(db.player.override)
    end

    -- 2. Barra Derecha (MultiBarRight)
    if MultiBarRight then
        MultiBarRight:SetMovable(true)
        MultiBarRight:ClearAllPoints()

        -- Apply scaling
        MultiBarRight:SetScale(db.scale_rightbar or 0.9)

        -- Apply layout to right bar buttons
        if db.right then
            addon.ArrangeActionBarButtons('MultiBarRightButton', MultiBarRight, MultiBarRight,
                db.right.rows or 1, db.right.columns or 12, db.right.buttons_shown or 12)
        end

        if db.right.override then
            -- MODO MANUAL
            -- ✅ CORRECCIÓN: Dividimos por la escala.
            MultiBarRight:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (db.right.x or 0) / scale, (db.right.y or 0) / scale)
        else
            -- MODO AUTOMÁTICO
            MultiBarRight:SetPoint("RIGHT", UIParent, "RIGHT", -5, -70)
        end
        MultiBarRight:SetUserPlaced(db.right.override)
    end

    -- 3. Barra Izquierda (MultiBarLeft)
    if MultiBarLeft then
        MultiBarLeft:SetMovable(true)
        MultiBarLeft:ClearAllPoints()

        -- Apply scaling
        MultiBarLeft:SetScale(db.scale_leftbar or 0.9)

        -- Apply layout to left bar buttons
        if db.left then
            addon.ArrangeActionBarButtons('MultiBarLeftButton', MultiBarLeft, MultiBarLeft,
                db.left.rows or 1, db.left.columns or 12, db.left.buttons_shown or 12)
        end

        if db.left.override then
            -- MODO MANUAL
            -- ✅ CORRECCIÓN: Dividimos por la escala.
            MultiBarLeft:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (db.left.x or 0) / scale, (db.left.y or 0) / scale)
        else
            -- MODO AUTOMÁTICO: Anclada a la barra derecha si esta no ha sido movida.
            if not db.right.override then
                 MultiBarLeft:SetPoint("RIGHT", MultiBarRight, "LEFT", -5, 0)
            else
                -- Si la barra derecha fue movida, la izquierda se ancla a la pantalla para no quedar huérfana.
                MultiBarLeft:SetPoint("RIGHT", MultiBarRight, "LEFT", -5, 0)
            end
        end
        MultiBarLeft:SetUserPlaced(db.left.override)
    end

    -- ========================================
    -- ✅ 4. BOTTOM BARS POSITIONING
    -- ========================================

    -- 4a. Bottom Left Bar (MultiBarBottomLeft)
    if MultiBarBottomLeft then
        MultiBarBottomLeft:SetMovable(true)
        MultiBarBottomLeft:ClearAllPoints()

        -- Apply scaling
        MultiBarBottomLeft:SetScale(db.scale_bottom_left or 0.9)

        -- Apply layout to bottom left bar buttons
        if db.bottom_left then
            addon.ArrangeActionBarButtons('MultiBarBottomLeftButton', MultiBarBottomLeft, MultiBarBottomLeft,
                db.bottom_left.rows or 1, db.bottom_left.columns or 12, db.bottom_left.buttons_shown or 12)
        end

        if db.bottom_left.override then
            -- MODO MANUAL: User-defined position
            MultiBarBottomLeft:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (db.bottom_left.x or 0) / scale, (db.bottom_left.y or 0) / scale)
        else
            -- MODO AUTOMÁTICO: Independent positioning - NOT tied to ActionButton1
            -- This will be handled by RefreshUpperActionBarsPosition
            MultiBarBottomLeft:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 120)
        end
        MultiBarBottomLeft:SetUserPlaced(db.bottom_left.override)
    end

    -- 4b. Bottom Right Bar (MultiBarBottomRight)
    if MultiBarBottomRight then
        MultiBarBottomRight:SetMovable(true)
        MultiBarBottomRight:ClearAllPoints()

        -- Apply scaling
        MultiBarBottomRight:SetScale(db.scale_bottom_right or 0.9)

        -- Apply layout to bottom right bar buttons
        if db.bottom_right then
            addon.ArrangeActionBarButtons('MultiBarBottomRightButton', MultiBarBottomRight, MultiBarBottomRight,
                db.bottom_right.rows or 1, db.bottom_right.columns or 12, db.bottom_right.buttons_shown or 12)
        end

        if db.bottom_right.override then
            -- MODO MANUAL: User-defined position
            MultiBarBottomRight:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (db.bottom_right.x or 0) / scale, (db.bottom_right.y or 0) / scale)
        else
            -- MODO AUTOMÁTICO: Default positioning above bottom left bar
            -- This will be handled by RefreshUpperActionBarsPosition
            MultiBarBottomRight:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 170)
        end
        MultiBarBottomRight:SetUserPlaced(db.bottom_right.override)
    end
end



function MainMenuBarMixin:statusbar_setup()
	for _,bar in pairs({MainMenuExpBar,ReputationWatchStatusBar}) do
		bar:GetStatusBarTexture():SetDrawLayer('BORDER')
		bar.status = bar:CreateTexture(nil, 'ARTWORK')
		if old then
			bar:SetSize(545, 10)
			bar.status:SetPoint('CENTER', 0, -1)
			bar.status:SetSize(545, 14)
			bar.status:set_atlas('ui-hud-experiencebar')
		elseif new then
			bar:SetSize(537, 10)
			bar.status:SetPoint('CENTER', 0, -2)
			bar.status:set_atlas('ui-hud-experiencebar-round', true)
			ReputationWatchStatusBar:SetStatusBarTexture(addon._dir..'statusbarfill.tga')
			ReputationWatchStatusBarBackground:set_atlas('ui-hud-experiencebar-background', true)
			ExhaustionTick:GetNormalTexture():set_atlas('ui-hud-experiencebar-frame-pip')
			ExhaustionTick:GetHighlightTexture():set_atlas('ui-hud-experiencebar-frame-pip-mouseover')
			ExhaustionTick:GetHighlightTexture():SetBlendMode('ADD')
		else
			bar.status:Hide()
		end
	end
	
	MainMenuExpBar:SetClearPoint('BOTTOM', UIParent, 0, 6)
	MainMenuExpBar:SetFrameLevel(10)
	ReputationWatchBar:SetParent(pUiMainBar)
	ReputationWatchBar:SetFrameLevel(10)
	ReputationWatchBar:SetWidth(ReputationWatchStatusBar:GetWidth())
	ReputationWatchBar:SetHeight(ReputationWatchStatusBar:GetHeight())
	
	MainMenuBarExpText:SetParent(MainMenuExpBar)
	MainMenuBarExpText:SetClearPoint('CENTER', MainMenuExpBar, 'CENTER', 0, old and 0 or 1)
	
	if new then
		for _,obj in pairs{MainMenuExpBar:GetRegions()} do 
			if obj:GetObjectType() == 'Texture' and obj:GetDrawLayer() == 'BACKGROUND' then
				obj:set_atlas('ui-hud-experiencebar-background', true)
			end
		end
	end
end

event:RegisterEvents(function(self)
	self:UnregisterEvent('PLAYER_ENTERING_WORLD');
	local exhaustionStateID = GetRestState();
	ExhaustionTick:SetParent(pUiMainBar);
	ExhaustionTick:SetFrameLevel(MainMenuExpBar:GetFrameLevel() +2);
	if new then
		ExhaustionLevelFillBar:SetHeight(MainMenuExpBar:GetHeight());
		ExhaustionLevelFillBar:set_atlas('ui-hud-experiencebar-fill-prediction');
		ExhaustionTick:SetSize(10, 14);
		ExhaustionTick:SetClearPoint('CENTER', ExhaustionLevelFillBar, 'RIGHT', 0, 2);

		MainMenuExpBar:SetStatusBarTexture(addon._dir..'uiexperiencebar');
		MainMenuExpBar:SetStatusBarColor(1, 1, 1, 1);
		if exhaustionStateID == 1 then
			ExhaustionTick:Show();
			MainMenuExpBar:GetStatusBarTexture():SetTexCoord(574/2048, 1137/2048, 34/64, 43/64);
			ExhaustionLevelFillBar:SetVertexColor(0.0, 0, 1, 0.45);
		elseif exhaustionStateID == 2 then
			MainMenuExpBar:GetStatusBarTexture():SetTexCoord(1/2048, 570/2048, 42/64, 51/64);
			ExhaustionLevelFillBar:SetVertexColor(0.58, 0.0, 0.55, 0.45);
		end
	else
		if exhaustionStateID == 1 then
			ExhaustionTick:Show();
		end
	end
end,
	'PLAYER_ENTERING_WORLD',
	'UPDATE_EXHAUSTION'
);



hooksecurefunc('ReputationWatchBar_Update',function()
	local name = GetWatchedFactionInfo();
	if name then
		local abovexp = config.xprepbar.repbar_abovexp_offset;
		local default = config.xprepbar.repbar_offset;
		ReputationWatchBar:SetClearPoint('BOTTOM', UIParent, 0, MainMenuExpBar:IsShown() and abovexp or default);
		ReputationWatchBarOverlayFrame:SetClearPoint('BOTTOM', UIParent, 0, MainMenuExpBar:IsShown() and abovexp or default);
		ReputationWatchStatusBar:SetHeight(10)
		ReputationWatchStatusBar:SetClearPoint('TOPLEFT', ReputationWatchBar, 0, 3)
		ReputationWatchStatusBarText:SetClearPoint('CENTER', ReputationWatchStatusBar, 'CENTER', 0, old and 0 or 1);
		ReputationWatchStatusBarBackground:SetAllPoints(ReputationWatchStatusBar)
	end
end)






local MainMenuExpBar = _G["MainMenuExpBar"]
local ReputationWatchBar = _G["ReputationWatchBar"]

for _,bar in pairs({MainMenuExpBar, ReputationWatchBar}) do
    if bar then
        bar:HookScript('OnShow',function()
            if not InCombatLockdown() and not (addon.EditorMode and addon.EditorMode:IsActive()) then
                addon.PositionActionBars() -- ✅ Usar la nueva función
            end
        end);
        bar:HookScript('OnHide',function()
            if not InCombatLockdown() and not (addon.EditorMode and addon.EditorMode:IsActive()) then
                addon.PositionActionBars() -- ✅ Usar la nueva función
            end
        end);
    end
end;



function addon.RefreshRepBarPosition()
	if ReputationWatchBar_Update then
		ReputationWatchBar_Update()
	end
end

-- update position for secondary action bars
function addon.RefreshUpperActionBarsPosition()
    if InCombatLockdown() then return end

    local db = addon.db and addon.db.profile and addon.db.profile.mainbars
    if not db or not db.player then
        -- Fallback to original positioning if no config
        if MultiBarBottomLeftButton1 then
            MultiBarBottomLeftButton1:SetClearPoint('BOTTOMLEFT', ActionButton1, 'BOTTOMLEFT', 0, 48)
        end
        if MultiBarBottomRight then
            MultiBarBottomRight:SetClearPoint('BOTTOMLEFT', MultiBarBottomLeftButton1, 'TOPLEFT', 0, 8)
        end
        return
    end

    -- Calculate the height of the main bar based on its layout
    local mainBarRows = db.player.rows or 1
    local buttonSize = 37
    local spacing = 7
    local mainBarHeight = (buttonSize * mainBarRows) + (spacing * (mainBarRows - 1))

    -- calculate offset based on background visibility and main bar height
    local yOffset1, yOffset2
    if addon.db and addon.db.profile.buttons and addon.db.profile.buttons.hide_main_bar_background then
        -- values when background is hidden
        yOffset1 = mainBarHeight + 8  -- Position above main bar
        yOffset2 = 8
    else
        -- default values when background is visible
        yOffset1 = mainBarHeight + 11  -- Position above main bar with background
        yOffset2 = 8
    end

    -- reposition the bars only if they exist and are not manually positioned
    if MultiBarBottomLeftButton1 and not (db.bottom_left and db.bottom_left.override) then
        MultiBarBottomLeftButton1:SetClearPoint('BOTTOMLEFT', ActionButton1, 'BOTTOMLEFT', 0, yOffset1)
    end

    if MultiBarBottomRight and MultiBarBottomLeftButton1 and not (db.bottom_right and db.bottom_right.override) then
        MultiBarBottomRight:SetClearPoint('BOTTOMLEFT', MultiBarBottomLeftButton1, 'TOPLEFT', 0, yOffset2)
    end
end

-- ========================================
-- ✅ ACTION BAR VISIBILITY MANAGEMENT
-- ========================================
function addon.RefreshActionBarVisibility()
    if InCombatLockdown() then
        -- Schedule for after combat
        addon:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    local db = addon.db and addon.db.profile and addon.db.profile.actionbars
    if not db then return end

    -- Bottom Left Bar (MultiBarBottomLeft)
    if MultiBarBottomLeft then
        if db.bottom_left_enabled then
            MultiBarBottomLeft:Show()
            -- Ensure buttons are properly shown and positioned
            for i = 1, 12 do
                local button = _G["MultiBarBottomLeftButton" .. i]
                if button then
                    button:Show()
                    -- Make sure button is properly parented
                    if button:GetParent() ~= MultiBarBottomLeft then
                        button:SetParent(MultiBarBottomLeft)
                    end
                end
            end
        else
            MultiBarBottomLeft:Hide()
        end
    end

    -- Bottom Right Bar (MultiBarBottomRight)
    if MultiBarBottomRight then
        if db.bottom_right_enabled then
            MultiBarBottomRight:Show()
            -- Ensure buttons are properly shown and positioned
            for i = 1, 12 do
                local button = _G["MultiBarBottomRightButton" .. i]
                if button then
                    button:Show()
                    -- Make sure button is properly parented
                    if button:GetParent() ~= MultiBarBottomRight then
                        button:SetParent(MultiBarBottomRight)
                    end
                end
            end
        else
            MultiBarBottomRight:Hide()
        end
    end

    -- Right Bar (MultiBarRight)
    if MultiBarRight then
        if db.right_enabled then
            MultiBarRight:Show()
            -- Ensure buttons are properly shown and positioned
            for i = 1, 12 do
                local button = _G["MultiBarRightButton" .. i]
                if button then
                    button:Show()
                    -- Make sure button is properly parented
                    if button:GetParent() ~= MultiBarRight then
                        button:SetParent(MultiBarRight)
                    end
                end
            end
        else
            MultiBarRight:Hide()
        end
    end

    -- Right Bar 2 (MultiBarLeft)
    if MultiBarLeft then
        if db.right2_enabled then
            MultiBarLeft:Show()
            -- Ensure buttons are properly shown and positioned
            for i = 1, 12 do
                local button = _G["MultiBarLeftButton" .. i]
                if button then
                    button:Show()
                    -- Make sure button is properly parented
                    if button:GetParent() ~= MultiBarLeft then
                        button:SetParent(MultiBarLeft)
                    end
                end
            end
        else
            MultiBarLeft:Hide()
        end
    end

    -- Update positioning after visibility changes
    C_Timer.After(0.1, function()
        if addon.RefreshUpperActionBarsPosition then
            addon.RefreshUpperActionBarsPosition()
        end
    end)
end

-- Handle combat lockdown for visibility changes
local function OnEvent(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        addon:UnregisterEvent("PLAYER_REGEN_ENABLED")
        addon.RefreshActionBarVisibility()
    end
end

if not addon.visibilityEventFrame then
    addon.visibilityEventFrame = CreateFrame("Frame")
    addon.visibilityEventFrame:SetScript("OnEvent", OnEvent)
end

-- ========================================
-- ✅ ACTION BAR VALIDATION FUNCTION
-- ========================================
function addon.ValidateActionBars()
    local issues = {}

    -- Check if all action bar frames exist
    local bars = {
        {frame = MultiBarBottomLeft, name = "Bottom Left Bar", buttons = "MultiBarBottomLeftButton"},
        {frame = MultiBarBottomRight, name = "Bottom Right Bar", buttons = "MultiBarBottomRightButton"},
        {frame = MultiBarRight, name = "Right Bar", buttons = "MultiBarRightButton"},
        {frame = MultiBarLeft, name = "Right Bar 2", buttons = "MultiBarLeftButton"}
    }

    for _, bar in pairs(bars) do
        if not bar.frame then
            table.insert(issues, bar.name .. " frame not found")
        else
            -- Check if buttons exist
            local buttonCount = 0
            for i = 1, 12 do
                local button = _G[bar.buttons .. i]
                if button then buttonCount = buttonCount + 1 end
            end
            if buttonCount < 12 then
                table.insert(issues, bar.name .. " missing buttons (" .. buttonCount .. "/12)")
            end
        end
    end

    if #issues == 0 then
        print("DragonUI: All action bars validated successfully ✅")
        return true
    else
        print("DragonUI: Action bar validation found issues:")
        for _, issue in pairs(issues) do
            print("  ❌ " .. issue)
        end
        return false
    end
end

function MainMenuBarMixin:initialize()
	self:actionbutton_setup();
	self:actionbar_setup();
	self:actionbar_art_setup();
	self:statusbar_setup();

	-- Initialize action bar visibility
	addon.RefreshActionBarVisibility();
end
addon.pUiMainBar = pUiMainBar;
MainMenuBarMixin:initialize();

-- configuration refresh function
function addon.RefreshMainbars()
    if not pUiMainBar then return end

    local db = addon.db and addon.db.profile
    if not db then return end

    local db_mainbars = db.mainbars
    local db_style = db.style
    local db_buttons = db.buttons

    -- ========================================
    -- ✅ POSICIONAR BARRAS (NUEVO Y SIMPLIFICADO)
    -- ========================================
    addon.PositionActionBars()

    -- ========================================
    -- ✅ APLICAR NUEVOS LAYOUTS DE BOTONES
    -- ========================================
    if db_mainbars and db_mainbars.player then
        -- Apply main bar layout
        addon.ArrangeActionBarButtons('ActionButton', pUiMainBar, pUiMainBar,
            db_mainbars.player.rows or 1,
            db_mainbars.player.columns or 12,
            db_mainbars.player.buttons_shown or 12)
    end

    -- Apply bottom bar layouts
    if db_mainbars and db_mainbars.bottom_left then
        addon.ArrangeActionBarButtons('MultiBarBottomLeftButton', MultiBarBottomLeft, MultiBarBottomLeft,
            db_mainbars.bottom_left.rows or 1,
            db_mainbars.bottom_left.columns or 12,
            db_mainbars.bottom_left.buttons_shown or 12)
    end

    if db_mainbars and db_mainbars.bottom_right then
        addon.ArrangeActionBarButtons('MultiBarBottomRightButton', MultiBarBottomRight, MultiBarBottomRight,
            db_mainbars.bottom_right.rows or 1,
            db_mainbars.bottom_right.columns or 12,
            db_mainbars.bottom_right.buttons_shown or 12)
    end

    -- ========================================
    -- ✅ REFRESH ACTION BAR VISIBILITY
    -- ========================================
    addon.RefreshActionBarVisibility()

    -- ========================================
    -- ✅ ALWAYS UPDATE SECONDARY BAR POSITIONS
    -- ========================================
    -- This ensures secondary bars are positioned correctly regardless of main bar layout
    addon.RefreshUpperActionBarsPosition()

    -- ========================================
    -- ✅ RESTO DE CONFIGURACIONES (se mantiene igual)
    -- ========================================
    
    -- Update scales
    pUiMainBar:SetScale(db_mainbars.scale_actionbar);
    if MultiBarLeft then MultiBarLeft:SetScale(db_mainbars.scale_leftbar); end
    if MultiBarRight then MultiBarRight:SetScale(db_mainbars.scale_rightbar); end
    if VehicleMenuBar then VehicleMenuBar:SetScale(db_mainbars.scale_vehicle); end
    
    -- Update page buttons
    if db_buttons.pages.show then
        ActionBarUpButton:Show()
        ActionBarDownButton:Show()
        MainMenuBarPageNumber:Show()
    else
        ActionBarUpButton:Hide()
        ActionBarDownButton:Hide()
        MainMenuBarPageNumber:Hide()
    end
    
    -- Update backgrounds
    MainMenuBarMixin:update_main_bar_background()
    addon.RefreshUpperActionBarsPosition()
    
    -- Update grids and gryphons
    if addon.actionbuttons_grid then
        addon.actionbuttons_grid()
    end
    UpdateGryphonStyle()
    
    -- Update XP bar textures
    if MainMenuExpBar then 
        MainMenuExpBar:SetStatusBarTexture(db_style.xpbar == 'old' and "Interface\\MainMenuBar\\UI-XP-Bar" or "Interface\\MainMenuBar\\UI-ExperienceBar")
    end
    if ReputationWatchStatusBar then 
        ReputationWatchStatusBar:SetStatusBarTexture(db_style.xpbar == 'old' and "Interface\\MainMenuBar\\UI-XP-Bar" or "Interface\\MainMenuBar\\UI-ExperienceBar")
    end
end

local function OnProfileChange()
    -- Esta función se llamará cada vez que el perfil cambie, se resetee o se copie.
    -- Llama directamente a la función de refresco principal.
    if addon.RefreshMainbars then
        addon.RefreshMainbars()
       
    end
end

local initializationFrame = CreateFrame("Frame")
initializationFrame:RegisterEvent("PLAYER_LOGIN")
initializationFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Nos aseguramos de que la base de datos (AceDB) esté lista.
        if not addon.db then return end

        -- Registramos nuestra función 'OnProfileChange' para que se ejecute automáticamente
        -- cuando AceDB detecte un cambio de perfil.
        addon.db.RegisterCallback(addon, "OnProfileChanged", OnProfileChange)
        addon.db.RegisterCallback(addon, "OnProfileCopied", OnProfileChange)
        addon.db.RegisterCallback(addon, "OnProfileReset", OnProfileChange)
        
        -- Forzamos un refresco inicial al entrar al juego para aplicar la configuración del perfil cargado.
        OnProfileChange()

        -- Ya no necesitamos escuchar este evento.
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- ✅ FUNCIONES PÚBLICAS PARA DEBUGGING/MANUAL (se mantienen)
function addon.TestProfileCallbacks()

    if addon.db then
   
        if addon.db.GetCurrentProfile then
       
        end
    end
end

function addon.ForceProfileRefresh()
    OnProfileChange()
end

function addon.TestSecondaryBars()

    local config = addon.db.profile.mainbars
    if not config then
       
        return
    end
    
       
    if MultiBarLeft then
        local point, _, _, x, y = MultiBarLeft:GetPoint()
    
    end
    
    if MultiBarRight then
        local point, _, _, x, y = MultiBarRight:GetPoint()
      
    end
    
   
    addon.PositionActionBars()
end

-- ✅ FUNCIÓN PARA FORZAR SOLO BARRAS SECUNDARIAS
function addon.ForceSecondaryBarsPosition()
    addon.PositionActionBars()
end