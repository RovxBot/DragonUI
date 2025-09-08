local addon = select(2, ...);

-- #################################################################
-- ##              DragonUI Editor Mode Integrado                  ##
-- ##          Sincroniza con sliders X/Y de options.lua          ##
-- #################################################################

local EditorMode = {};
addon.EditorMode = EditorMode;

-- =================================================================
-- VARIABLES Y CONFIGURACIÓN
-- =================================================================

local isEditorActive = false;
local editableFrames = {};
local gridOverlay = nil; -- ✅ Variable para nuestra rejilla
local exitEditorButton = nil;


-- =================================================================
-- ✅ BOTÓN DE SALIDA DEL MODO EDITOR
-- =================================================================
local function createExitButton()
    if exitEditorButton then return; end

    -- Crear el botón
    exitEditorButton = CreateFrame("Button", "DragonUIExitEditorButton", UIParent, "UIPanelButtonTemplate");
    exitEditorButton:SetText("Exit Edit Mode");
    exitEditorButton:SetSize(160, 32);
    exitEditorButton:SetPoint("CENTER", UIParent, "CENTER", 0, 200); -- Posición flotante
    exitEditorButton:SetFrameStrata("DIALOG"); -- Asegura que esté por encima de otros elementos
    exitEditorButton:SetFrameLevel(100);

    -- Asignar la acción de salida
    exitEditorButton:SetScript("OnClick", function()
        EditorMode:Toggle();
    end);

    exitEditorButton:Hide(); -- Oculto por defecto
end


-- =================================================================
-- ✅ SISTEMA DE REJILLA DE FONDO (GRID) - CORRECCIÓN DE COMPATIBILIDAD 3.3.5a
-- =================================================================
local function createGridOverlay()
    -- Optimización: No recrear el grid si ya existe.
    if gridOverlay then return; end

    local boxSize = 32 -- Número de celdas de la rejilla.
    
    -- Frame principal que contendrá todas las líneas.
    gridOverlay = CreateFrame('Frame', "DragonUIGridOverlayFrame", UIParent) 
    gridOverlay:SetAllPoints(UIParent)
    gridOverlay:SetFrameStrata("BACKGROUND");
    gridOverlay:SetFrameLevel(0);

    local lineThickness = 1 
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()

    -- === DIBUJAR LÍNEAS VERTICALES ===
    local wStep = screenWidth / boxSize
    for i = 0, boxSize do 
        -- Usamos nombres únicos para máxima seguridad
        local line = gridOverlay:CreateTexture("DragonUIGridLineV"..i, 'BACKGROUND') 
        
        if i == boxSize / 2 then 
            -- ✅ CORRECCIÓN: Usar SetTexture, que es más compatible con 3.3.5a
            line:SetTexture(1, 0, 0, 0.5) 
        else 
            line:SetTexture(0, 0, 0, 0.5) 
        end 
        
        line:SetPoint("TOPLEFT", gridOverlay, "TOPLEFT", (i * wStep) - (lineThickness / 2), 0) 
        line:SetPoint('BOTTOMRIGHT', gridOverlay, 'BOTTOMLEFT', (i * wStep) + (lineThickness / 2), 0) 
    end 

    -- === DIBUJAR LÍNEAS HORIZONTALES ===
    local hStep = screenHeight / boxSize
    for i = 0, boxSize do
        -- Usamos nombres únicos para máxima seguridad
        local line = gridOverlay:CreateTexture("DragonUIGridLineH"..i, 'BACKGROUND')
        
        if i == boxSize / 2 then
            -- ✅ CORRECCIÓN: Usar SetTexture, que es más compatible con 3.3.5a
            line:SetTexture(1, 0, 0, 0.5)
        else
            line:SetTexture(0, 0, 0, 0.5)
        end
        
        line:SetPoint("TOPLEFT", gridOverlay, "TOPLEFT", 0, -(i * hStep) + (lineThickness / 2))
        line:SetPoint('BOTTOMRIGHT', gridOverlay, 'TOPRIGHT', 0, -(i * hStep) - (lineThickness / 2))
    end
    
    gridOverlay:Hide() -- Oculta por defecto
end


-- =================================================================
-- UTILIDADES DE COORDENADAS
-- =================================================================

-- Obtener valor de la base de datos usando path
local function getDbValue(dbPath, key)
    local current = addon.db.profile;
    for _, pathPart in ipairs(dbPath) do
        if not current or not current[pathPart] then return nil; end
        current = current[pathPart];
    end
    return current[key];
end

-- Establecer valor en la base de datos usando path
local function setDbValue(dbPath, key, value)
    local current = addon.db.profile;
    for i, pathPart in ipairs(dbPath) do
        if not current[pathPart] then current[pathPart] = {}; end
        if i == #dbPath then
            current[pathPart][key] = value;
        else
            current = current[pathPart];
        end
    end
end

-- Convertir posición del frame a coordenadas BOTTOMLEFT de UIParent
local function getBottomLeftCoordinates(frame)
    local scale = UIParent:GetEffectiveScale()
    local frameLeft = frame:GetLeft() * scale;
    local frameBottom = frame:GetBottom() * scale;
    return frameLeft, frameBottom
end

-- Función especial para obtener el frame correcto de action bars
local function getActionBarFrame(frameName)
    if frameName == "pUiMainBar" then
        return addon.pUiMainBar or _G["pUiMainBar"];
    else
        return _G[frameName];
    end
end

-- =================================================================
-- MAPEO DE CONFIGURACIÓN
-- =================================================================

-- Mapeo de módulos a sus configuraciones en la base de datos
local moduleConfig = {
    -- Castbars
    ["DragonUIPlayerCastbar"] = { dbPath = {"castbar"}, xKey = "x_position", yKey = "y_position", refreshFunc = "RefreshCastbar", displayName = "Player Castbar", castbar = true },
    ["DragonUITargetCastbar"] = { dbPath = {"castbar", "target"}, xKey = "x_position", yKey = "y_position", refreshFunc = "RefreshTargetCastbar", displayName = "Target Castbar", castbar = true },
    ["DragonUIFocusCastbar"] = { dbPath = {"castbar", "focus"}, xKey = "x_position", yKey = "y_position", refreshFunc = "RefreshFocusCastbar", displayName = "Focus Castbar", castbar = true },

    -- Unit Frames
    ["PlayerFrame"] = { dbPath = {"unitframe", "player"}, xKey = "x", yKey = "y", refreshFunc = "RefreshUnitFrames", displayName = "Player Frame", unitframe = true },
    ["TargetFrame"] = { dbPath = {"unitframe", "target"}, xKey = "x", yKey = "y", refreshFunc = "RefreshUnitFrames", displayName = "Target Frame", unitframe = true },
    ["FocusFrame"] = { dbPath = {"unitframe", "focus"}, xKey = "x", yKey = "y", refreshFunc = "RefreshUnitFrames", displayName = "Focus Frame", unitframe = true },
    ["PetFrame"] = { dbPath = {"unitframe", "pet"}, xKey = "x", yKey = "y", refreshFunc = "RefreshUnitFrames", displayName = "Pet Frame", unitframe = true },

    -- =========================================================================
    -- ✅ ACTION BARS - CONFIGURACIÓN ACTUALIZADA
    -- =========================================================================
    ["pUiMainBar"] = {
        dbPath = {"mainbars", "player"}, -- Ruta a la config de la barra principal
        xKey = "x",
        yKey = "y",
        refreshFunc = "PositionActionBars",
        displayName = "Main Action Bar",
        actionbar = true
    },
    ["MultiBarLeft"] = {
        dbPath = {"mainbars", "left"}, -- Ruta a la config de la barra izquierda
        xKey = "x",
        yKey = "y",
        refreshFunc = "PositionActionBars",
        displayName = "Left Action Bar",
        actionbar = true
    },
    ["MultiBarRight"] = {
        dbPath = {"mainbars", "right"}, -- Ruta a la config de la barra derecha
        xKey = "x",
        yKey = "y",
        refreshFunc = "PositionActionBars",
        displayName = "Right Action Bar",
        actionbar = true
    },

    -- ✅ Bottom action bars support
    ["MultiBarBottomLeft"] = {
        dbPath = {"mainbars", "bottom_left"}, -- Ruta a la config de la barra inferior izquierda
        xKey = "x",
        yKey = "y",
        refreshFunc = "PositionActionBars",
        displayName = "Bottom Left Action Bar",
        actionbar = true
    },

    ["MultiBarBottomRight"] = {
        dbPath = {"mainbars", "bottom_right"}, -- Ruta a la config de la barra inferior derecha
        xKey = "x",
        yKey = "y",
        refreshFunc = "PositionActionBars",
        displayName = "Bottom Right Action Bar",
        actionbar = true
    },

     ["DragonUIPartyMoveFrame"] = {
        dbPath = {"unitframe", "party"},
        xKey = "x",
        yKey = "y",
        refreshFunc = "RefreshUnitFrames",
        displayName = "Party Frames",
        partyframe = true -- Flag para lógica especial
    },

    -- Stance Bar, Pet Bar, etc. (sin cambios)
    ["pUiStanceHolder"] = { dbPath = {"additional", "stance"}, xKey = "x_position", yKey = "y_position", refreshFunc = "RefreshStance", displayName = "Stance Bar", independent = true },
    ["PetActionBarFrame"] = { dbPath = {"additional", "pet"}, xKey = "x_position", yKey = "y_position", refreshFunc = "RefreshPetbar", displayName = "Pet Bar" },
    ["MicroButtonAndBagsBar"] = { dbPath = {"micromenu"}, xKey = "x_position", yKey = "y_position", refreshFunc = "RefreshMicromenu", displayName = "Micro Menu" },
    ["ChatFrame1"] = { dbPath = {"chat"}, xKey = "x_position", yKey = "y_position", refreshFunc = "RefreshChat", displayName = "Chat Frame" }
};

-- =================================================================
-- SISTEMA DE OVERLAY VISUAL
-- =================================================================

local function createOverlay(frame, config)
    local overlay = CreateFrame("Frame", nil, frame);
    overlay:SetAllPoints(frame);
    overlay:SetFrameLevel(frame:GetFrameLevel() + 10);
    overlay:SetFrameStrata("DIALOG");
    overlay:EnableMouse(true);
    overlay:SetMovable(true);

    local bg = overlay:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetTexture(0, 0.5, 1, 0.2);

    local border = overlay:CreateTexture(nil, "BORDER");
    border:SetAllPoints();
    border:SetTexture(1, 1, 1, 0.6);

    local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    text:SetPoint("CENTER");
    text:SetText(config.displayName);
    text:SetTextColor(1, 1, 1, 0.9);
    text:SetShadowOffset(1, -1);
    text:SetShadowColor(0, 0, 0, 1);

    overlay:Hide();
    return overlay;
end

-- =================================================================
-- SISTEMA DE ARRASTRAR Y SOLTAR (LÓGICA CENTRAL)
-- =================================================================

local function makeFrameMovable(frame, config)
    if editableFrames[frame] then return; end

    frame:SetMovable(true);
    frame:EnableMouse(true);

    local overlay = createOverlay(frame, config);
    overlay:EnableMouse(true);
    overlay:RegisterForDrag("LeftButton");

    overlay:SetScript("OnDragStart", function()
        if InCombatLockdown() then return end
        frame:StartMoving();
    end);

    overlay:SetScript("OnDragStop", function()
        if InCombatLockdown() then return end
        frame:StopMovingOrSizing();

        -- ✅ =================================================================
        -- ✅ LÓGICA DE GUARDADO DE POSICIONES
        -- ✅ =================================================================

        if config.actionbar then
            -- === LÓGICA ESPECÍFICA PARA BARRAS DE ACCIÓN ===
            setDbValue(config.dbPath, "override", true)
            local x, y = getBottomLeftCoordinates(frame)
            setDbValue(config.dbPath, config.xKey, x)
            setDbValue(config.dbPath, config.yKey, y)
           

            -- Llamamos a la función de refresco de las barras
           if addon[config.refreshFunc] then
                addon[config.refreshFunc]()
            end
        
        elseif config.castbar then
            -- === LÓGICA ESPECÍFICA PARA CASTBARS ===
            setDbValue(config.dbPath, "override", true)
            local x, y = getBottomLeftCoordinates(frame)
            setDbValue(config.dbPath, config.xKey, x)
            setDbValue(config.dbPath, config.yKey, y)
            
            -- Llamamos a la función de refresco de la castbar específica
            if addon[config.refreshFunc] then
                addon[config.refreshFunc]()
            end

       elseif config.partyframe then
           -- === LÓGICA ESPECÍFICA PARA PARTY FRAMES (CORREGIDO) ===
            -- ✅ CORRECCIÓN: Obtenemos las coordenadas directamente sin la escala
            -- para evitar el "salto" del marco del grupo.
            local x, y = frame:GetLeft(), frame:GetBottom()
            
            -- Lógica de guardado simplificada y correcta.
            setDbValue(config.dbPath, "override", true)
            setDbValue(config.dbPath, "anchor", "BOTTOMLEFT")
            setDbValue(config.dbPath, "anchorParent", "UIParent")
            setDbValue(config.dbPath, "anchorPoint", "BOTTOMLEFT")
            setDbValue(config.dbPath, config.xKey, x)
            setDbValue(config.dbPath, config.yKey, y)
            
           
            
            if addon.RefreshUnitFrames then
                addon:RefreshUnitFrames()
            end

        elseif config.independent then
            -- === LÓGICA ESPECÍFICA PARA FRAMES INDEPENDIENTES (STANCE BAR) ===
            -- Get the current position but don't apply UI scale correction since we're saving screen coordinates
            local x, y = frame:GetLeft(), frame:GetBottom()

            -- Enable independent positioning mode
            setDbValue(config.dbPath, "override", true)
            setDbValue(config.dbPath, "anchor", "BOTTOMLEFT")
            setDbValue(config.dbPath, "anchorParent", "BOTTOMLEFT")
            setDbValue(config.dbPath, "anchorFrame", "UIParent")
            setDbValue(config.dbPath, config.xKey, x)
            -- For stance bar, save Y position to the correct key
            if config.displayName == "Stance Bar" then
                setDbValue(config.dbPath, "y_position", y)
                -- Clear the y_offset to prevent double-offsetting
                setDbValue(config.dbPath, "y_offset", 0)
            else
                setDbValue(config.dbPath, config.yKey, y)
            end

        else
            -- === LÓGICA GENÉRICA PARA TODOS LOS DEMÁS FRAMES ===
            local x, y
            if config.unitframe then
                -- Para UnitFrames, usamos coordenadas absolutas y activamos override
                -- ✅ CORRECCIÓN: Obtenemos las coordenadas directas sin la escala, igual que con el party frame.
                x, y = frame:GetLeft(), frame:GetBottom()
                setDbValue(config.dbPath, "override", true)
                setDbValue(config.dbPath, "anchor", "BOTTOMLEFT")
                setDbValue(config.dbPath, "anchorParent", "UIParent")
                setDbValue(config.dbPath, "anchorPoint", "BOTTOMLEFT")
            else
                -- Para el resto (Pet, etc.), usamos offsets del punto de anclaje
                local _, _, _, xOfs, yOfs = frame:GetPoint()
                x, y = xOfs, yOfs
            end

            setDbValue(config.dbPath, config.xKey, x)
            setDbValue(config.dbPath, config.yKey, y)

        end

        -- Notificar a AceConfig para que los sliders se actualicen
        if LibStub and LibStub("AceConfigRegistry", true) then
            LibStub("AceConfigRegistry"):NotifyChange("DragonUI");
        end
    end);

    editableFrames[frame] = {
        overlay = overlay,
        config = config,
        originalMovable = frame:IsMovable(),
        originalMouseEnabled = frame:IsMouseEnabled()
    };
end

-- =================================================================
-- FUNCIONES PÚBLICAS (Show, Hide, Toggle)
-- =================================================================
function EditorMode:Show()
    if InCombatLockdown() then return; end
    isEditorActive = true;
    local frameCount = 0;

    -- ✅ Mostrar la rejilla y el botón de salida
    createGridOverlay();
    createExitButton(); -- Asegura que el botón exista
    if gridOverlay then gridOverlay:Show(); end
    if exitEditorButton then exitEditorButton:Show(); end

    -- Forzar mostrar frames para edición
    if TargetFrame then TargetFrame:Show(); end
    if FocusFrame then FocusFrame:Show(); end
    if PetFrame then PetFrame:Show(); end
    if StanceBarFrame then StanceBarFrame:Show(); end
    if _G["pUiStanceHolder"] then _G["pUiStanceHolder"]:Show(); end
    if PetActionBarFrame then PetActionBarFrame:Show(); end
    if addon.pUiMainBar then addon.pUiMainBar:Show(); end
    if MultiBarLeft then MultiBarLeft:Show(); end
    if MultiBarRight then MultiBarRight:Show(); end
    if MultiBarBottomLeft then MultiBarBottomLeft:Show(); end
    if MultiBarBottomRight then MultiBarBottomRight:Show(); end
-- ✅ CORRECCIÓN: Forzar la visibilidad de TODOS los componentes de las castbars.
    -- Esto asegura que se muestren correctamente incluso si fueron ocultadas por el ciclo de vida normal del addon.
    if _G["DragonUIPlayerCastbar"] then _G["DragonUIPlayerCastbar"]:Show() end
    if _G["DragonUIPlayerCastbarTextBG"] then _G["DragonUIPlayerCastbarTextBG"]:Show() end

    if _G["DragonUITargetCastbar"] then _G["DragonUITargetCastbar"]:Show() end
    if _G["DragonUITargetCastbarTextBG"] then _G["DragonUITargetCastbarTextBG"]:Show() end
    if _G["DragonUITargetCastbarBackground"] then _G["DragonUITargetCastbarBackground"]:Show() end

    if _G["DragonUIFocusCastbar"] then _G["DragonUIFocusCastbar"]:Show() end
    if _G["DragonUIFocusCastbarTextBG"] then _G["DragonUIFocusCastbarTextBG"]:Show() end
    if _G["DragonUIFocusCastbarBackground"] then _G["DragonUIFocusCastbarBackground"]:Show() end

    -- ✅ CORRECCIÓN 2: Forzar un refresco de las barras DESPUÉS de mostrarlas.
    -- Esto recalcula su posición y estado en el contexto del modo editor.
    if addon.RefreshCastbar then addon.RefreshCastbar() end
    if addon.RefreshTargetCastbar then addon.RefreshTargetCastbar() end
    if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end

    -- ✅ Lógica para los Party Frames (CORREGIDO)
    if GetNumPartyMembers() == 0 then
        -- No estamos en grupo, mostrar frames falsos
        if addon.unitframe and addon.unitframe.ForceInitPartyFrames then
            addon.unitframe.ForceInitPartyFrames()
        end
        if _G["DragonUIPartyMoveFrame"] then
            _G["DragonUIPartyMoveFrame"]:Show()
            for i = 1, 4 do
                if _G["PartyMemberFrame"..i] then _G["PartyMemberFrame"..i]:Show() end
            end
        end
    end

     -- Configurar todos los frames disponibles
    for frameName, config in pairs(moduleConfig) do
        local frame
        if config.actionbar then
            frame = getActionBarFrame(frameName)
        elseif config.partyframe then
            frame = _G[frameName] or (addon.unitframe and addon.unitframe.PartyMoveFrame)
        elseif config.castbar then
            frame = _G[frameName]
        else
            frame = _G[frameName]
        end
        
        if frame then
            makeFrameMovable(frame, config);
            if editableFrames[frame] then
                editableFrames[frame].overlay:Show();
                frameCount = frameCount + 1;
            end
        end
    end


end
function EditorMode:Hide()
    isEditorActive = false;
    
    if gridOverlay then gridOverlay:Hide(); end
    if exitEditorButton then exitEditorButton:Hide(); end -- ✅ Ocultar el botón de salida
    
    for frame, data in pairs(editableFrames) do
        data.overlay:Hide();
        frame:SetMovable(data.originalMovable);
        frame:EnableMouse(data.originalMouseEnabled);
    end
    
    -- Refrescar todos los módulos principales al salir
    if addon.PositionActionBars then addon.PositionActionBars(); end
    if addon.RefreshUnitFrames then addon.RefreshUnitFrames(); end
    
    -- ✅ Restaurar visibilidad normal de TODOS los frames
    if TargetFrame and not UnitExists("target") then TargetFrame:Hide(); end
    if FocusFrame and not UnitExists("focus") then FocusFrame:Hide(); end
    if PetFrame and not UnitExists("pet") then PetFrame:Hide(); end
    if StanceBarFrame and not GetNumShapeshiftForms() > 0 then StanceBarFrame:Hide(); end
    if PetActionBarFrame and not HasPetUI() then PetActionBarFrame:Hide(); end
     -- Ocultar castbars si no se está casteando nada (usando el estado interno)
     -- ✅ CORRECCIÓN DEFINITIVA: Ocultar todas las partes de las castbars si no están en uso.
    -- Esto asegura una limpieza completa al salir del modo editor.
    if addon.castbarStates then
        -- Player
        if addon.castbarStates.player and not addon.castbarStates.player.casting then
            if _G["DragonUIPlayerCastbar"] then _G["DragonUIPlayerCastbar"]:Hide() end
            if _G["DragonUIPlayerCastbarTextBG"] then _G["DragonUIPlayerCastbarTextBG"]:Hide() end
        end
        -- Target
        if addon.castbarStates.target and not addon.castbarStates.target.casting then
            if _G["DragonUITargetCastbar"] then _G["DragonUITargetCastbar"]:Hide() end
            if _G["DragonUITargetCastbarTextBG"] then _G["DragonUITargetCastbarTextBG"]:Hide() end
            if _G["DragonUITargetCastbarBackground"] then _G["DragonUITargetCastbarBackground"]:Hide() end
        end
        -- Focus
        if addon.castbarStates.focus and not addon.castbarStates.focus.casting then
            if _G["DragonUIFocusCastbar"] then _G["DragonUIFocusCastbar"]:Hide() end
            if _G["DragonUIFocusCastbarTextBG"] then _G["DragonUIFocusCastbarTextBG"]:Hide() end
            if _G["DragonUIFocusCastbarBackground"] then _G["DragonUIFocusCastbarBackground"]:Hide() end
        end
    end

    -- ✅ Apply action bar visibility settings
    if addon.RefreshActionBarVisibility then
        addon.RefreshActionBarVisibility()
    end

    -- ✅ Ocultar los party frames si no estamos en grupo
    if GetNumPartyMembers() == 0 then
        if _G["DragonUIPartyMoveFrame"] then
            _G["DragonUIPartyMoveFrame"]:Hide()
        end
    end

   
end

function EditorMode:Toggle()
    if isEditorActive then self:Hide(); else self:Show(); end
end

function EditorMode:IsActive()
    return isEditorActive;
end

-- =================================================================
-- COMANDOS SLASH
-- =================================================================

SLASH_DRAGONUI_EDITOR1 = "/duiedit";
SlashCmdList["DRAGONUI_EDITOR"] = function()
    EditorMode:Toggle();
end;