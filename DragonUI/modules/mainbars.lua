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


-- Register movers for XP and Reputation bars
local function RegisterStatusBarMovers()
    if not addon.CreateMover then return end

    if _G.MainMenuExpBar and not (addon.Movers and addon.Movers.registry and addon.Movers.registry.xpbar) then
        addon:CreateMover(_G.MainMenuExpBar, 'xpbar', 'XP Bar', {'BOTTOM', UIParent, 'BOTTOM', 0, 6}, {strictSize = true})
        _G.MainMenuExpBar:HookScript('OnShow', function() if addon.ApplyMover then addon:ApplyMover('xpbar') end end)
    end

    if _G.ReputationWatchBar and not (addon.Movers and addon.Movers.registry and addon.Movers.registry.repbar) then
        addon:CreateMover(_G.ReputationWatchBar, 'repbar', 'Reputation Bar', {'BOTTOM', UIParent, 'BOTTOM', 0, 22}, {strictSize = true})
        _G.ReputationWatchBar:HookScript('OnShow', function() if addon.ApplyMover then addon:ApplyMover('repbar') end end)
    end
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
		-- Re-apply mover position if active
		if addon and addon.Movers and addon.Movers.registry and addon.Movers.registry.repbar and addon.ApplyMover then
			addon:ApplyMover('repbar')
		end
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

-- Helper function to determine if a bar should use alpha-based visibility
local function ShouldUseAlphaVisibility(barName)
    local db = addon.db and addon.db.profile and addon.db.profile.actionbars
    if not db then return false end

    local showOnHover = db[barName .. "_show_on_hover"]
    local showInCombat = db[barName .. "_show_in_combat"]

    return showOnHover or showInCombat
end

function addon.RefreshActionBarVisibility()
    if InCombatLockdown() then
        -- Schedule for after combat
        addon:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    local db = addon.db and addon.db.profile and addon.db.profile.actionbars
    if not db then return end

    -- Normalise hover state so other bars don't get stuck in a hovered=true state
    local function normaliseHover(barName, frame)
        if not addon.visibilityStates or not addon.visibilityStates[barName] then return end
        if frame and frame.IsMouseOver and frame:IsMouseOver() then
            addon.visibilityStates[barName].hovered = true
        else
            addon.visibilityStates[barName].hovered = false
        end
    end
    normaliseHover("main", pUiMainBar)
    normaliseHover("bottom_left", MultiBarBottomLeft)
    normaliseHover("bottom_right", MultiBarBottomRight)
    normaliseHover("right", MultiBarRight)
    normaliseHover("right2", MultiBarLeft)

    -- Main Action Bar (pUiMainBar)
    if pUiMainBar then
        -- Delegate to the unified visibility logic so main behaves consistently
        addon.UpdateActionBarVisibility("main", pUiMainBar)
    end

    -- Bottom Left Bar (MultiBarBottomLeft)
    if MultiBarBottomLeft then
        addon.UpdateActionBarVisibility("bottom_left", MultiBarBottomLeft)
    end

    -- Bottom Right Bar (MultiBarBottomRight)
    if MultiBarBottomRight then
        addon.UpdateActionBarVisibility("bottom_right", MultiBarBottomRight)
    end

    -- Right Bar (MultiBarRight)
    if MultiBarRight then
        addon.UpdateActionBarVisibility("right", MultiBarRight)
    end

    -- Right Bar 2 (MultiBarLeft)
    if MultiBarLeft then
        addon.UpdateActionBarVisibility("right2", MultiBarLeft)
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

-- ============================================================================
-- VISIBILITY MANAGEMENT (HOVER & COMBAT)
-- ============================================================================

-- Visibility state tracking
addon.visibilityStates = addon.visibilityStates or {
    main = { hovered = false, inCombat = false },
    bottom_left = { hovered = false, inCombat = false },
    bottom_right = { hovered = false, inCombat = false },
    right = { hovered = false, inCombat = false },
    right2 = { hovered = false, inCombat = false }
}

-- Deeply apply alpha to main bar art and miscellaneous textures while excluding functional bars/buttons
local function SetMainBarArtAlphaDeep(alpha)
    local function shouldSkipFrame(f)
        if not f then return true end
        -- Skip functional bars and known frames we never want to fade here
        if f == MainMenuExpBar or f == ReputationWatchStatusBar or f == StanceBarFrame or f == ShapeshiftBarFrame then
            return true
        end
        local n = f.GetName and f:GetName() or ""
        -- Skip action buttons and pet/bonus/multi bar buttons
        if n and (n:find("ActionButton") or n:find("MultiBar") or n:find("BonusActionButton") or n:find("PetActionButton")) then
            return true
        end
        return false
    end

    local function setOnFrame(f)
        if not f or shouldSkipFrame(f) then return end
        for i = 1, (f.GetNumRegions and f:GetNumRegions() or 0) do
            local region = select(i, f:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                region:SetAlpha(alpha)
            end
        end
    end

    -- Apply to primary containers and their children
    for _, container in ipairs({ pUiMainBar, pUiMainBarArt, MainMenuBarArtFrame }) do
        setOnFrame(container)
        if container and container.GetNumChildren then
            for i = 1, container:GetNumChildren() do
                local child = select(i, container:GetChildren())
                setOnFrame(child)
            end
        end
    end
end


-- Update visibility based on hover and combat states
local function UpdateActionBarVisibility(barName, frame)
    if not frame or not addon.db or not addon.db.profile or not addon.db.profile.actionbars then
        return
    end

    local config = addon.db.profile.actionbars
    local state = addon.visibilityStates and addon.visibilityStates[barName]
    if not state then return end

    local isEnabled = config[barName .. "_enabled"]
    if barName == "main" then
        isEnabled = true
    end

    if not isEnabled and not ShouldUseAlphaVisibility(barName) then
        frame:Hide()
        return
    end

    local showOnHover = config[barName .. "_show_on_hover"]
    local showInCombat = config[barName .. "_show_in_combat"]

    -- Determine if bar should be visible
    local shouldShow = true

    -- If the bar is disabled in DragonUI, only show if hover/combat conditions are met
    if not isEnabled then
        shouldShow = false
    end

    if showOnHover and showInCombat then
        -- Show only when BOTH hovering AND in combat (and DragonUI enabled)
        shouldShow = shouldShow and state.hovered and state.inCombat
    elseif showOnHover then
        -- Show only when hovering (and DragonUI enabled)
        shouldShow = shouldShow and state.hovered
    elseif showInCombat then
        -- Show only when in combat (and DragonUI enabled)
        shouldShow = shouldShow and state.inCombat
    end
    -- If neither hover nor combat option is enabled, show based on DragonUI enabled state

    if barName == "main" then
        if shouldShow then
            for i = 1, 12 do
                local button = _G["ActionButton" .. i]
                if button then
                    button:SetAlpha(1)
                    button:Show()
                end
            end
        else
            for i = 1, 12 do
                local button = _G["ActionButton" .. i]
                if button then
                    if ShouldUseAlphaVisibility(barName) then
                        button:SetAlpha(0)
                        button:Show()
                    else
                        button:Hide()
                    end
                end
            end
        end
        -- Control main bar art (gryphons, page arrows, background) without affecting XP/Reputation/Stance bars
        local buttonsCfg = addon.db and addon.db.profile and addon.db.profile.buttons
        local baseArtAlpha = (buttonsCfg and buttonsCfg.hide_main_bar_background) and 0 or 1
        local artAlpha = shouldShow and baseArtAlpha or 0
        if pUiMainBarArt and pUiMainBarArt.SetAlpha then pUiMainBarArt:SetAlpha(artAlpha) end
        if MainMenuBarArtFrame and MainMenuBarArtFrame.SetAlpha then MainMenuBarArtFrame:SetAlpha(artAlpha) end
        if MainMenuBarLeftEndCap and MainMenuBarLeftEndCap.SetAlpha then MainMenuBarLeftEndCap:SetAlpha(artAlpha) end
        if MainMenuBarRightEndCap and MainMenuBarRightEndCap.SetAlpha then MainMenuBarRightEndCap:SetAlpha(artAlpha) end
        if ActionBarUpButton and ActionBarUpButton.SetAlpha then ActionBarUpButton:SetAlpha(artAlpha) end
        if ActionBarDownButton and ActionBarDownButton.SetAlpha then ActionBarDownButton:SetAlpha(artAlpha) end
        if MainMenuBarPageNumber and MainMenuBarPageNumber.SetAlpha then MainMenuBarPageNumber:SetAlpha(artAlpha) end
        if pUiMainBar and pUiMainBar.BorderArt and pUiMainBar.BorderArt.SetAlpha then pUiMainBar.BorderArt:SetAlpha(artAlpha) end
        if pUiMainBar and pUiMainBar.Background and pUiMainBar.Background.SetAlpha then pUiMainBar.Background:SetAlpha(artAlpha) end
        if pUiMainBar and pUiMainBar.divider_top and pUiMainBar.divider_top.SetAlpha then pUiMainBar.divider_top:SetAlpha(artAlpha) end
        if pUiMainBar and pUiMainBar.divider_mid and pUiMainBar.divider_mid.SetAlpha then pUiMainBar.divider_mid:SetAlpha(artAlpha) end
        if pUiMainBar and pUiMainBar.divider_bottom and pUiMainBar.divider_bottom.SetAlpha then pUiMainBar.divider_bottom:SetAlpha(artAlpha) end
        if MainMenuBarTexture0 and MainMenuBarTexture0.SetAlpha then MainMenuBarTexture0:SetAlpha(artAlpha) end
        if MainMenuBarTexture1 and MainMenuBarTexture1.SetAlpha then MainMenuBarTexture1:SetAlpha(artAlpha) end
        if MainMenuBarTexture2 and MainMenuBarTexture2.SetAlpha then MainMenuBarTexture2:SetAlpha(artAlpha) end
        if MainMenuBarTexture3 and MainMenuBarTexture3.SetAlpha then MainMenuBarTexture3:SetAlpha(artAlpha) end

        -- Deep fade pass to catch any unnamed art regions
        SetMainBarArtAlphaDeep(artAlpha)

        -- Always keep the main frame shown (for exp bar, stance bar, etc.)
        frame:Show()
    else
        if shouldShow then
            frame:SetAlpha(1)
        else
            frame:SetAlpha(0)
        end

        -- Always keep frame shown for hover detection to work (if it has hover behavior)
        if ShouldUseAlphaVisibility(barName) or isEnabled then
            frame:Show()
        else
            frame:Hide()
        end
    end
end

-- Setup hover detection for action bars with debouncing
local hoverTimers = {}
local function SetupActionBarHoverDetection(barName, frame)
    if not frame then return end

    -- Ensure the container frame can receive mouse events
    if frame.EnableMouse then frame:EnableMouse(true) end

    -- Map bar to its button prefix for supplemental hover hooks
    local buttonPrefix
    if barName == "main" then
        buttonPrefix = "ActionButton"
    elseif barName == "bottom_left" then
        buttonPrefix = "MultiBarBottomLeftButton"
    elseif barName == "bottom_right" then
        buttonPrefix = "MultiBarBottomRightButton"
    elseif barName == "right" then
        buttonPrefix = "MultiBarRightButton"
    elseif barName == "right2" then
        buttonPrefix = "MultiBarLeftButton"
    end

    -- Frame-level hover
    frame:SetScript("OnEnter", function()
        if hoverTimers[barName] then
            hoverTimers[barName]:Cancel(); hoverTimers[barName] = nil
        end
        if not addon.visibilityStates[barName].hovered then
            addon.visibilityStates[barName].hovered = true
            addon.UpdateActionBarVisibility(barName, frame)
        end
    end)

    frame:SetScript("OnLeave", function()
        if hoverTimers[barName] then hoverTimers[barName]:Cancel() end
        hoverTimers[barName] = C_Timer.NewTimer(0.25, function()
            addon.visibilityStates[barName].hovered = false
            addon.UpdateActionBarVisibility(barName, frame)
            hoverTimers[barName] = nil
        end)
    end)

    -- Button-level hover to stabilise when moving across gaps between buttons
    if buttonPrefix then
        for i = 1, 12 do
            local btn = _G[buttonPrefix .. i]
            if btn and not btn.__DragonUI_HoverHooked then
                btn:HookScript("OnEnter", function()
                    if hoverTimers[barName] then
                        hoverTimers[barName]:Cancel(); hoverTimers[barName] = nil
                    end
                    addon.visibilityStates[barName].hovered = true
                    addon.UpdateActionBarVisibility(barName, frame)
                end)
                btn:HookScript("OnLeave", function()
                    if hoverTimers[barName] then hoverTimers[barName]:Cancel() end
                    hoverTimers[barName] = C_Timer.NewTimer(0.25, function()
                        addon.visibilityStates[barName].hovered = false
                        addon.UpdateActionBarVisibility(barName, frame)
                        hoverTimers[barName] = nil
                    end)

                end)
                btn.__DragonUI_HoverHooked = true
            end
        end
    end
end

-- Combat state handler
local function OnCombatStateChanged(inCombat)
    for barName, state in pairs(addon.visibilityStates or {}) do
        state.inCombat = inCombat

        -- Get the appropriate frame for each bar
        local frame
        if barName == "main" then
            frame = pUiMainBar
        elseif barName == "bottom_left" then
            frame = MultiBarBottomLeft
        elseif barName == "bottom_right" then
            frame = MultiBarBottomRight
        elseif barName == "right" then
            frame = MultiBarRight
        elseif barName == "right2" then
            frame = MultiBarLeft
        end

        if frame then
            addon.UpdateActionBarVisibility(barName, frame)
        end
    end
end

-- Initialize visibility system
local function InitializeActionBarVisibility()
    SetupActionBarHoverDetection("main", pUiMainBar)
    for i = 1, 12 do
        local btn = _G["ActionButton" .. i]
        if btn and not btn.__DragonUI_HoverHooked then
            btn:HookScript("OnEnter", function()
                addon.visibilityStates.main.hovered = true
                addon.UpdateActionBarVisibility("main", pUiMainBar)
            end)
            btn.__DragonUI_HoverHooked = true
        end
    end

    SetupActionBarHoverDetection("bottom_left", MultiBarBottomLeft)
    SetupActionBarHoverDetection("bottom_right", MultiBarBottomRight)
    SetupActionBarHoverDetection("right", MultiBarRight)
    SetupActionBarHoverDetection("right2", MultiBarLeft)

    -- Register combat events
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatFrame:SetScript("OnEvent", function(self, event)
        local inCombat = (event == "PLAYER_REGEN_DISABLED")
        OnCombatStateChanged(inCombat)
    end)

    -- Hook Blizzard's action bar functions to maintain our control
    local function HookBlizzardActionBars()
        -- Hook MultiActionBar_Update to maintain our visibility settings
        if MultiActionBar_Update then
            hooksecurefunc("MultiActionBar_Update", function()
                -- Re-apply our visibility settings after Blizzard updates
                C_Timer.After(0.1, function()
                    if addon.RefreshActionBarVisibility then
                        addon.RefreshActionBarVisibility()
                    end
                end)
            end)
        end

        -- Hook individual bar show/hide functions with improved logic
        if MultiBarBottomLeft and MultiBarBottomLeft.Show then
            hooksecurefunc(MultiBarBottomLeft, "Show", function()
                local db = addon.db and addon.db.profile and addon.db.profile.actionbars
                if db and not db.bottom_left_enabled and not ShouldUseAlphaVisibility("bottom_left") then
                    C_Timer.After(0, function() MultiBarBottomLeft:Hide() end)
                end
            end)
        end

        if MultiBarBottomRight and MultiBarBottomRight.Show then
            hooksecurefunc(MultiBarBottomRight, "Show", function()
                local db = addon.db and addon.db.profile and addon.db.profile.actionbars
                if db and not db.bottom_right_enabled and not ShouldUseAlphaVisibility("bottom_right") then
                    C_Timer.After(0, function() MultiBarBottomRight:Hide() end)
                end
            end)
        end

        if MultiBarRight and MultiBarRight.Show then
            hooksecurefunc(MultiBarRight, "Show", function()
                local db = addon.db and addon.db.profile and addon.db.profile.actionbars
                if db and not db.right_enabled and not ShouldUseAlphaVisibility("right") then
                    C_Timer.After(0, function() MultiBarRight:Hide() end)
                end
            end)
        end

        if MultiBarLeft and MultiBarLeft.Show then
            hooksecurefunc(MultiBarLeft, "Show", function()
                local db = addon.db and addon.db.profile and addon.db.profile.actionbars
                if db and not db.right2_enabled and not ShouldUseAlphaVisibility("right2") then
                    C_Timer.After(0, function() MultiBarLeft:Hide() end)
                end
            end)
        end

    end

    -- Initial visibility update
    C_Timer.After(1, function()
        for barName in pairs(addon.visibilityStates or {}) do
            local frame
            if barName == "main" then
                frame = pUiMainBar
            elseif barName == "bottom_left" then
                frame = MultiBarBottomLeft
            elseif barName == "bottom_right" then
                frame = MultiBarBottomRight
            elseif barName == "right" then
                frame = MultiBarRight
            elseif barName == "right2" then
                frame = MultiBarLeft
            end

            if frame then
                addon.UpdateActionBarVisibility(barName, frame)
            end
        end

        -- Setup Blizzard hooks after initial setup
        HookBlizzardActionBars()
    end)
end


-- ============================================================================
-- Movers for secondary action bars (Bottom Left/Right, Right, Right 2)
-- ============================================================================
function addon.RegisterActionBarMovers()
    if not addon.CreateMover then return end

    local function makeDefault(p, rel, rp, x, y)
        return { p, rel or UIParent, rp or p, x or 0, y or 0 }
    end

    -- Bottom Left
    if _G.MultiBarBottomLeft and not (addon.Movers and addon.Movers.registry and addon.Movers.registry.bottomleft) then
        addon:CreateMover(_G.MultiBarBottomLeft, 'bottomleft', 'Bottom Left Bar', makeDefault('BOTTOM', UIParent, 'BOTTOM', 0, 120))
        _G.MultiBarBottomLeft:HookScript('OnShow', function() if addon.ApplyMover then addon:ApplyMover('bottomleft') end end)
    end

    -- Bottom Right
    if _G.MultiBarBottomRight and not (addon.Movers and addon.Movers.registry and addon.Movers.registry.bottomright) then
        -- Prefer relative default above bottom-left if available
        local rel = _G.MultiBarBottomLeft or UIParent
        local default = rel == UIParent and makeDefault('BOTTOM', UIParent, 'BOTTOM', 0, 170) or {'BOTTOMLEFT', rel, 'TOPLEFT', 0, 8}
        addon:CreateMover(_G.MultiBarBottomRight, 'bottomright', 'Bottom Right Bar', default)
        _G.MultiBarBottomRight:HookScript('OnShow', function() if addon.ApplyMover then addon:ApplyMover('bottomright') end end)
    end

    -- Right bar
    if _G.MultiBarRight and not (addon.Movers and addon.Movers.registry and addon.Movers.registry.right) then
        addon:CreateMover(_G.MultiBarRight, 'right', 'Right Bar', makeDefault('RIGHT', UIParent, 'RIGHT', -5, -70))
        _G.MultiBarRight:HookScript('OnShow', function() if addon.ApplyMover then addon:ApplyMover('right') end end)
    end

    -- Right 2 bar (Blizzard: MultiBarLeft)
    if _G.MultiBarLeft and not (addon.Movers and addon.Movers.registry and addon.Movers.registry.right2) then
        local rel = _G.MultiBarRight
        local default = rel and {'RIGHT', rel, 'LEFT', -5, 0} or makeDefault('RIGHT', UIParent, 'RIGHT', -52, -70)
        addon:CreateMover(_G.MultiBarLeft, 'right2', 'Right Bar 2', default)
        _G.MultiBarLeft:HookScript('OnShow', function() if addon.ApplyMover then addon:ApplyMover('right2') end end)
    end
end

-- Export functions for external use
addon.UpdateActionBarVisibility = UpdateActionBarVisibility
addon.InitializeActionBarVisibility = InitializeActionBarVisibility

function MainMenuBarMixin:initialize()
	self:actionbutton_setup();
	self:actionbar_setup();
	self:actionbar_art_setup();
	self:statusbar_setup();

	-- Initialize action bar visibility (only if database is ready)
	if addon.db and addon.db.profile then
		addon.RefreshActionBarVisibility();
	end

		-- Register movers for status bars (XP/Rep) and apply if present
		RegisterStatusBarMovers()
		if addon.ApplyMover and addon.Movers and addon.Movers.registry then
			if addon.Movers.registry.xpbar then addon:ApplyMover('xpbar') end
			if addon.Movers.registry.repbar then addon:ApplyMover('repbar') end
		end

end
addon.pUiMainBar = pUiMainBar;

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
            -- Register movers for secondary bars once frames exist
            if addon.RegisterActionBarMovers then addon.RegisterActionBarMovers() end
            if addon.ApplyMover and addon.Movers and addon.Movers.registry then
                if addon.Movers.registry.bottomleft then addon:ApplyMover('bottomleft') end
                if addon.Movers.registry.bottomright then addon:ApplyMover('bottomright') end
                if addon.Movers.registry.right then addon:ApplyMover('right') end
                if addon.Movers.registry.right2 then addon:ApplyMover('right2') end
            end


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

        -- Initialize the main bar mixin now that database is ready
        if MainMenuBarMixin and MainMenuBarMixin.initialize then
            MainMenuBarMixin:initialize();
        end

        -- Initialise hover/combat visibility system once
        -- Register ElvUI-style mover for the main action bar (default bottom center)
        if addon.CreateMover and addon.pUiMainBar then
            addon:CreateMover(addon.pUiMainBar, 'mainbar', 'Player Action Bar', {'BOTTOM', UIParent, 'BOTTOM', 0, 75})
        end

        if addon.InitializeActionBarVisibility then
            addon.InitializeActionBarVisibility()
        end


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