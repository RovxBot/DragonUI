local addon = select(2, ...);

local EditorMode = {};
addon.EditorMode = EditorMode;

local gridOverlay = nil;
local exitEditorButton = nil;
local resetAllButton = nil;
local gridSize = 32;
local snapToGrid = true;
local inspectorFrame = nil;
local activeMover = nil;
local inspectorLinkedLayoutKey = nil; -- for action bars orientation/scale
local activeHighlight = nil;
local keyCatcher = nil;
local presetDropdown = nil;
local presetNameBox = nil;
local helperButtons = {};
local helperFrames = {
    { label = "UIParent", value = "UIParent" },
    { label = "Target", value = "TargetFrame" },
    { label = "Focus", value = "FocusFrame" },
    { label = "Pick Cursor", value = "cursor" },
}
local function getPresetStore()
    if not addon.db or not addon.db.profile then return nil end
    addon.db.profile.editmode = addon.db.profile.editmode or {}
    addon.db.profile.editmode.presets = addon.db.profile.editmode.presets or {}
    return addon.db.profile.editmode.presets
end

-- StaticPopup para reiniciar UI después de salir del modo editor
StaticPopupDialogs["DRAGONUI_RELOAD_UI"] = {
    text = "UI elements have been repositioned. Reload UI to ensure all graphics display correctly?",
    button1 = "Reload Now",
    button2 = "Later",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

--  BOTÓN DE SALIDA DEL MODO EDITOR
local function createExitButton()
    if exitEditorButton then return; end

    -- Crear el botón con estilo profesional
    exitEditorButton = CreateFrame("Button", "DragonUIExitEditorButton", UIParent, "UIPanelButtonTemplate");
    exitEditorButton:SetText("Exit Edit Mode");
    exitEditorButton:SetSize(140, 28); -- Mismo tamaño que Reset button
    exitEditorButton:SetPoint("CENTER", UIParent, "CENTER", 0, 200); -- Posición flotante centrada
    exitEditorButton:SetFrameStrata("DIALOG"); -- Asegura que esté por encima de otros elementos
    exitEditorButton:SetFrameLevel(100);

    
    -- Estilo profesional: Mismo color rojo que Reset button
    local normalTexture = exitEditorButton:GetNormalTexture()
    if normalTexture then
        normalTexture:SetVertexColor(0.8, 0.3, 0.3, 1) -- Rojo profesional (igual que Reset)
    end
    
    local highlightTexture = exitEditorButton:GetHighlightTexture()
    if highlightTexture then
        highlightTexture:SetVertexColor(1, 0.4, 0.4, 1) -- Rojo claro al pasar ratón (igual que Reset)
    end
    
    local pushedTexture = exitEditorButton:GetPushedTexture()
    if pushedTexture then
        pushedTexture:SetVertexColor(0.6, 0.2, 0.2, 1) -- Rojo oscuro al presionar (igual que Reset)
    end
    
    -- Texto en blanco para contraste
    local fontString = exitEditorButton:GetFontString()
    if fontString then
        fontString:SetTextColor(1, 1, 1, 1) -- Texto blanco
        fontString:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- Fuente profesional
    end

    -- Asignar la acción de salida
    exitEditorButton:SetScript("OnClick", function()
        EditorMode:Toggle();
    end);

    exitEditorButton:Hide(); -- Oculto por defecto
end

local function findMoverEntryByFrame(frame)
    if not addon.MoverSystem or not frame then return nil end
    for name, entry in pairs(addon.MoverSystem.movers) do
        if entry.frame == frame then
            return name, entry
        end
    end
end

local function applyPosition(name, entry, opts)
    if not name or not entry then return end
    local cfgPath = entry.configPath
    if not cfgPath then return end

    local point = opts.anchor or "CENTER"
    local parentName = opts.anchorParent or "UIParent"
    local parentFrame = _G[parentName] or UIParent
    local x = opts.x or 0
    local y = opts.y or 0
    local scale = opts.scale or entry.frame:GetScale() or 1

    local frame = entry.frame
    if not frame then return end
    if InCombatLockdown() then return end

    frame:ClearAllPoints()
    frame:SetPoint(point, parentFrame, opts.anchorParentPoint or point, x, y)
    frame:SetScale(scale)

    if #cfgPath == 2 then
        SaveUIFramePosition(frame, cfgPath[1], cfgPath[2])
    else
        SaveUIFramePosition(frame, cfgPath[1])
    end
end

local function getCurrentPosition(entry)
    if not entry or not entry.frame then return {} end
    local point, relativeTo, relativePoint, x, y = entry.frame:GetPoint(1)
    local parentName = relativeTo and relativeTo:GetName() or "UIParent"
    return {
        anchor = point or "CENTER",
        anchorParent = parentName,
        anchorParentPoint = relativePoint or point or "CENTER",
        x = x or 0,
        y = y or 0,
        scale = entry.frame:GetScale() or 1
    }
end

local function ensureInspectorFrame()
    if inspectorFrame then return inspectorFrame end

    local f = CreateFrame("Frame", "DragonUIInspectorFrame", UIParent, "BackdropTemplate")
    f:SetSize(260, 250)
    f:SetPoint("CENTER", UIParent, "CENTER", 320, 120)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(120)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetAlpha(0)
    f.fadeIn = UIFrameFadeIn
    f.fadeOut = UIFrameFadeOut

    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    f:SetBackdropColor(0.02, 0.04, 0.08, 0.94)
    f:SetBackdropBorderColor(0.1, 0.55, 0.95, 0.9)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -8)
    title:SetText("Frame Inspector")
    f.title = title

    local function makeLabel(text, y)
        local l = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        l:SetPoint("TOPLEFT", 12, y)
        l:SetText(text)
        return l
    end

    local anchorLabel = makeLabel("Anchor", -28)
    local anchors = {"CENTER","TOP","BOTTOM","LEFT","RIGHT","TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}
    local anchorDrop = CreateFrame("Frame", "DragonUIInspectorAnchorDrop", f, "UIDropDownMenuTemplate")
    anchorDrop:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", -14, -2)

    local parentLabel = makeLabel("Anchor Parent", -78)
    local parentBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    parentBox:SetSize(140, 18)
    parentBox:SetPoint("TOPLEFT", parentLabel, "BOTTOMLEFT", 0, -4)
    parentBox:SetAutoFocus(false)

    local orientationLabel = makeLabel("Orientation", -118)
    local orientationDrop = CreateFrame("Frame", "DragonUIInspectorOrientationDrop", f, "UIDropDownMenuTemplate")
    orientationDrop:SetPoint("TOPLEFT", orientationLabel, "BOTTOMLEFT", -14, -2)

    local anchorParentPointLabel = makeLabel("Parent Point", -118)
    local parentPointDrop = CreateFrame("Frame", "DragonUIInspectorParentPointDrop", f, "UIDropDownMenuTemplate")
    parentPointDrop:SetPoint("TOPLEFT", anchorParentPointLabel, "BOTTOMLEFT", -14, -2)

    local helperLabel = makeLabel("Anchor Helpers", -158)
    local helperContainer = CreateFrame("Frame", nil, f)
    helperContainer:SetSize(220, 22)
    helperContainer:SetPoint("TOPLEFT", helperLabel, "BOTTOMLEFT", 0, -4)
    local last
    for i, info in ipairs(helperFrames) do
        local btn = CreateFrame("Button", nil, helperContainer, "UIPanelButtonTemplate")
        btn:SetSize(70, 20)
        btn:SetText(info.label)
        if not last then
            btn:SetPoint("LEFT", helperContainer, "LEFT", 0, 0)
        else
            btn:SetPoint("LEFT", last, "RIGHT", 4, 0)
        end
        helperButtons[#helperButtons + 1] = btn
        last = btn
    end

    local xLabel = makeLabel("X", -208)
    local xSlider = CreateFrame("Slider", "DragonUIInspectorX", f, "OptionsSliderTemplate")
    xSlider:SetPoint("TOPLEFT", xLabel, "BOTTOMLEFT", 0, -6)
    xSlider:SetWidth(180)
    xSlider:SetMinMaxValues(-1000, 1000)
    xSlider:SetValueStep(1)
    _G[xSlider:GetName() .. "Low"]:SetText("-1000")
    _G[xSlider:GetName() .. "High"]:SetText("1000")

    local yLabel = makeLabel("Y", -258)
    local ySlider = CreateFrame("Slider", "DragonUIInspectorY", f, "OptionsSliderTemplate")
    ySlider:SetPoint("TOPLEFT", yLabel, "BOTTOMLEFT", 0, -6)
    ySlider:SetWidth(180)
    ySlider:SetMinMaxValues(-1000, 1000)
    ySlider:SetValueStep(1)
    _G[ySlider:GetName() .. "Low"]:SetText("-1000")
    _G[ySlider:GetName() .. "High"]:SetText("1000")

    scaleSlider:SetPoint("TOPLEFT", ySlider, "BOTTOMLEFT", 0, -20)

    local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetBtn:SetSize(70, 20)
    resetBtn:SetPoint("BOTTOMLEFT", 12, 10)
    resetBtn:SetText("Reset")

    presetNameBox = CreateFrame("EditBox", "DragonUIPresetNameBox", f, "InputBoxTemplate")
    presetNameBox:SetSize(100, 18)
    presetNameBox:SetPoint("LEFT", resetBtn, "RIGHT", 6, 0)
    presetNameBox:SetAutoFocus(false)
    presetNameBox:SetText(addon.db and addon.db.profile and addon.db.profile.editmode and addon.db.profile.editmode.selectedPreset or "")

    local revertBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    revertBtn:SetSize(70, 20)
    revertBtn:SetPoint("LEFT", presetNameBox, "RIGHT", 6, 0)
    revertBtn:SetText("Revert")

    presetDropdown = CreateFrame("Frame", "DragonUIPresetDropdown", f, "UIDropDownMenuTemplate")
    presetDropdown:SetPoint("LEFT", revertBtn, "RIGHT", -4, -2)

    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(70, 20)
    saveBtn:SetPoint("LEFT", presetDropdown, "RIGHT", -12, 2)
    saveBtn:SetText("Save")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    closeBtn:SetSize(70, 20)
    closeBtn:SetPoint("LEFT", saveBtn, "RIGHT", 6, 0)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    f.anchorDrop = anchorDrop
    f.parentBox = parentBox
    f.orientationDrop = orientationDrop
    f.parentPointDrop = parentPointDrop
    f.xSlider = xSlider
    f.ySlider = ySlider
    f.scaleSlider = scaleSlider
    f.resetBtn = resetBtn
    f.revertBtn = revertBtn
    f.saveBtn = saveBtn
    f.presetDropdown = presetDropdown
    f.helperButtons = helperButtons
    f.anchorLabel = anchorLabel

    inspectorFrame = f
    return f
end

local function refreshInspector(entryName, entry)
    if not inspectorFrame or not entry then return end
    local pos = getCurrentPosition(entry)

    inspectorFrame.title:SetText(entryName or "Frame Inspector")
    UIDropDownMenu_SetSelectedValue(inspectorFrame.anchorDrop, pos.anchor)
    UIDropDownMenu_SetText(inspectorFrame.anchorDrop, pos.anchor)
    inspectorFrame.parentBox:SetText(pos.anchorParent or "UIParent")
    inspectorFrame.xSlider:SetValue(pos.x or 0)
    inspectorFrame.ySlider:SetValue(pos.y or 0)
    inspectorFrame.scaleSlider:SetValue(pos.scale or 1)
    UIDropDownMenu_SetSelectedValue(inspectorFrame.parentPointDrop, pos.anchorParentPoint or pos.anchor or "CENTER")
    UIDropDownMenu_SetText(inspectorFrame.parentPointDrop, pos.anchorParentPoint or pos.anchor or "CENTER")
    if addon.db and addon.db.profile and addon.db.profile.editmode then
        presetNameBox:SetText(addon.db.profile.editmode.selectedPreset or "")
    end

    -- Orientation dropdown only meaningful for action bars
    if inspectorLinkedLayoutKey and addon.db and addon.db.profile and addon.db.profile.mainbars and addon.db.profile.mainbars.layout then
        local layout = addon.db.profile.mainbars.layout[inspectorLinkedLayoutKey] or {}
        local orientation = (layout.rows == 1) and "HORIZONTAL" or "VERTICAL"
        UIDropDownMenu_SetSelectedValue(inspectorFrame.orientationDrop, orientation)
        UIDropDownMenu_SetText(inspectorFrame.orientationDrop, orientation)
        inspectorFrame.orientationDrop:Show()
        inspectorFrame.orientationDrop.label:Show()
    else
        inspectorFrame.orientationDrop:Hide()
        inspectorFrame.orientationDrop.label:Hide()
    end

    -- Highlight stays on active mover
    if activeHighlight and activeMover then
        activeHighlight:ClearAllPoints()
        activeHighlight:SetAllPoints(activeMover)
        activeHighlight:Show()
    end
end

local function initAnchorDropdown(frame)
    UIDropDownMenu_Initialize(frame, function(self, level)
        for _, v in ipairs({"CENTER","TOP","BOTTOM","LEFT","RIGHT","TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = v
            info.value = v
            info.func = function()
                UIDropDownMenu_SetSelectedValue(frame, v)
                UIDropDownMenu_SetText(frame, v)
                if activeMover and inspectorFrame then
                    local name, entry = findMoverEntryByFrame(activeMover)
                    if entry then
                        local pos = getCurrentPosition(entry)
                        pos.anchor = v
                        applyPosition(name, entry, pos)
                        refreshInspector(name, entry)
                    end
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

local function initParentPointDropdown(frame)
    frame.label = frame.label or frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 16, 2)
    frame.label:SetText("Anchor Parent Point")

    UIDropDownMenu_Initialize(frame, function(self, level)
        for _, v in ipairs({"CENTER","TOP","BOTTOM","LEFT","RIGHT","TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = v
            info.value = v
            info.func = function()
                UIDropDownMenu_SetSelectedValue(frame, v)
                UIDropDownMenu_SetText(frame, v)
                if activeMover then
                    local name, entry = findMoverEntryByFrame(activeMover)
                    if entry then
                        local pos = getCurrentPosition(entry)
                        pos.anchorParentPoint = v
                        applyPosition(name, entry, pos)
                        refreshInspector(name, entry)
                    end
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

local function initOrientationDropdown(frame)
    frame.label = frame.label or frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 16, 2)
    frame.label:SetText("Orientation")

    UIDropDownMenu_Initialize(frame, function(self, level)
        for _, v in ipairs({"HORIZONTAL", "VERTICAL"}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = v
            info.value = v
            info.func = function()
                UIDropDownMenu_SetSelectedValue(frame, v)
                UIDropDownMenu_SetText(frame, v)
                if inspectorLinkedLayoutKey and addon.db and addon.db.profile and addon.db.profile.mainbars then
                    addon.db.profile.mainbars.layout = addon.db.profile.mainbars.layout or {}
                    addon.db.profile.mainbars.layout[inspectorLinkedLayoutKey] = addon.db.profile.mainbars.layout[inspectorLinkedLayoutKey] or {}
                    local layout = addon.db.profile.mainbars.layout[inspectorLinkedLayoutKey]
                    if v == "HORIZONTAL" then
                        layout.rows = 1
                        layout.cols = 12
                    else
                        layout.rows = 12
                        layout.cols = 1
                    end
                    if addon.PositionActionBars then
                        addon.PositionActionBars()
                    end
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

local function wireInspectorHandlers()
    if not inspectorFrame then return end
    initAnchorDropdown(inspectorFrame.anchorDrop)
    initParentPointDropdown(inspectorFrame.parentPointDrop)
    initOrientationDropdown(inspectorFrame.orientationDrop)
    refreshPresetDropdown()

    inspectorFrame.parentBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if activeMover then
            local name, entry = findMoverEntryByFrame(activeMover)
            if entry then
                local pos = getCurrentPosition(entry)
                pos.anchorParent = self:GetText()
                applyPosition(name, entry, pos)
                refreshInspector(name, entry)
            end
        end
    end)

    local function sliderHandler(slider, axis)
        slider:SetScript("OnValueChanged", function(self, val)
            if activeMover then
                local name, entry = findMoverEntryByFrame(activeMover)
                if entry then
                    local pos = getCurrentPosition(entry)
                    pos[axis] = val
                    applyPosition(name, entry, pos)
                    refreshInspector(name, entry)
                end
            end
        end)
    end
    sliderHandler(inspectorFrame.xSlider, "x")
    sliderHandler(inspectorFrame.ySlider, "y")
    sliderHandler(inspectorFrame.scaleSlider, "scale")

    inspectorFrame.resetBtn:SetScript("OnClick", function()
        if not activeMover then return end
        local name, entry = findMoverEntryByFrame(activeMover)
        if not entry then return end
        if entry.defaults then
            local cfgPath = entry.configPath
            if cfgPath then
                if #cfgPath == 2 then
                    addon.db.profile[cfgPath[1]][cfgPath[2]] = addon:CopyTable(entry.defaults)
                else
                    addon.db.profile.widgets[cfgPath[1]] = addon:CopyTable(entry.defaults)
                end
            end
            applyPosition(name, entry, {
                anchor = entry.defaults.anchor or "CENTER",
                anchorParent = entry.defaults.anchorParent or "CENTER",
                anchorParentPoint = entry.defaults.anchorParent or "CENTER",
                x = entry.defaults.posX or entry.defaults.x or 0,
                y = entry.defaults.posY or entry.defaults.y or 0,
                scale = entry.defaults.scale or 1
            })
            refreshInspector(name, entry)
        end
    end)

    inspectorFrame.revertBtn:SetScript("OnClick", function()
        if not activeMover then return end
        local store = getPresetStore()
        if not store then return end
        local name, entry = findMoverEntryByFrame(activeMover)
        if not entry then return end
        local selected = addon.db.profile.editmode.selectedPreset
        local preset = selected and store[selected] or store[name]
        if preset then
            applyPosition(name, entry, preset)
            refreshInspector(name, entry)
        end
    end)

    inspectorFrame.saveBtn:SetScript("OnClick", function()
        if not activeMover then return end
        local store = getPresetStore()
        if not store then return end
        local name, entry = findMoverEntryByFrame(activeMover)
        if not entry then return end
        local presetName = presetNameBox:GetText()
        if not presetName or presetName == "" then
            presetName = name
        end
        store[presetName] = getCurrentPosition(entry)
        addon.db.profile.editmode.selectedPreset = presetName
        refreshPresetDropdown()
    end)

    -- Delete preset
    local deletePreset = CreateFrame("Button", nil, inspectorFrame, "UIPanelButtonTemplate")
    deletePreset:SetSize(70, 20)
    deletePreset:SetPoint("RIGHT", inspectorFrame.closeBtn or inspectorFrame.saveBtn, "LEFT", -6, 0)
    deletePreset:SetText("Delete")
    deletePreset:SetScript("OnClick", function()
        if not addon.db or not addon.db.profile or not addon.db.profile.editmode then return end
        local selected = addon.db.profile.editmode.selectedPreset
        local presets = addon.db.profile.editmode.presets or {}
        if selected and presets[selected] then
            presets[selected] = nil
            addon.db.profile.editmode.selectedPreset = ""
            presetNameBox:SetText("")
            refreshPresetDropdown()
        end
    end)
end

--  BOTÓN DE RESET ALL POSITIONS - ESTILO PROFESIONAL
local function createResetAllButton()
    if resetAllButton then return; end

    -- Crear el botón con estilo profesional sincronizado
    resetAllButton = CreateFrame("Button", "DragonUIResetAllButton", UIParent, "UIPanelButtonTemplate");
    resetAllButton:SetText("Reset All Positions");
    resetAllButton:SetSize(140, 28); -- Mismo tamaño que Exit button
    resetAllButton:SetPoint("CENTER", UIParent, "CENTER", 0, 165); -- Separación uniforme
    resetAllButton:SetFrameStrata("DIALOG");
    resetAllButton:SetFrameLevel(100);

    -- Estilo profesional: Rojo elegante para acción destructiva
    local normalTexture = resetAllButton:GetNormalTexture()
    if normalTexture then
        normalTexture:SetVertexColor(0.8, 0.3, 0.3, 1) -- Rojo profesional (menos saturado)
    end
    
    local highlightTexture = resetAllButton:GetHighlightTexture()
    if highlightTexture then
        highlightTexture:SetVertexColor(1, 0.4, 0.4, 1) -- Rojo claro al pasar ratón
    end
    
    local pushedTexture = resetAllButton:GetPushedTexture()
    if pushedTexture then
        pushedTexture:SetVertexColor(0.6, 0.2, 0.2, 1) -- Rojo oscuro al presionar
    end
    
    -- Texto en blanco para contraste perfecto
    local fontString = resetAllButton:GetFontString()
    if fontString then
        fontString:SetTextColor(1, 1, 1, 1) -- Texto blanco
        fontString:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- Fuente profesional
    end

    -- ESTRATEGIA: Mostrar confirmación directamente sin salir del editor mode
    resetAllButton:SetScript("OnClick", function()
        -- Mostrar solo el popup de confirmación específico para reset
        EditorMode:ShowResetConfirmation()
    end);

    resetAllButton:Hide(); -- Oculto por defecto
end

--  TU GRID MEJORADO - AHORA CUADRADOS SIMÉTRICOS
local function createGridOverlay()
    if gridOverlay then return; end

    --  CAMBIO: Hacer cuadrados SIMÉTRICOS con línea central EXACTA
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    
    --  ALGORITMO SIMÉTRICO: Partir desde el centro hacia afuera
    local cellSize = gridSize  -- Tamaño base de celda
    
    -- Calcular cuántas celdas completas caben desde el centro hacia cada lado
    local halfCellsHorizontal = math.floor((screenWidth / 2) / cellSize)
    local halfCellsVertical = math.floor((screenHeight / 2) / cellSize)
    
    -- Total de celdas (siempre par para que el centro sea exacto)
    local totalHorizontalCells = halfCellsHorizontal * 2
    local totalVerticalCells = halfCellsVertical * 2
    
    -- Recalcular el tamaño real de celda para que sea perfectamente simétrico
    local actualCellWidth = screenWidth / totalHorizontalCells
    local actualCellHeight = screenHeight / totalVerticalCells
    
    -- Posición exacta del centro
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    
    gridOverlay = CreateFrame('Frame', "DragonUIGridOverlay", UIParent)
    gridOverlay:SetAllPoints(UIParent)
    gridOverlay:SetFrameStrata("BACKGROUND")
    gridOverlay:SetFrameLevel(0)

    --  AÑADIR CAPA DE FONDO OSCURA SEMI-TRANSPARENTE
    local background = gridOverlay:CreateTexture("DragonUIGridBackground", 'BACKGROUND')
    background:SetAllPoints(gridOverlay)
    background:SetTexture(0.05, 0.1, 0.18, 0.35)  -- Azul grisáceo suave
    background:SetDrawLayer('BACKGROUND', -1)  -- Detrás de todo

    local lineThickness = 1

    -- === LÍNEAS VERTICALES SIMÉTRICAS ===
    for i = 0, totalHorizontalCells do
        local line = gridOverlay:CreateTexture("DragonUIGridV"..i, 'BACKGROUND')
        
        -- La línea central es exactamente en halfCellsHorizontal
        if i == halfCellsHorizontal then
            line:SetTexture(0.8, 0.2, 0.9, 0.9)  -- Línea central magenta
        else
            line:SetTexture(0.6, 0.8, 1, 0.25)  -- Líneas azul claro
        end
        
        local x = i * actualCellWidth
        line:SetPoint("TOPLEFT", gridOverlay, "TOPLEFT", x - (lineThickness / 2), 0)
        line:SetPoint('BOTTOMRIGHT', gridOverlay, 'BOTTOMLEFT', x + (lineThickness / 2), 0)
    end

    -- === LÍNEAS HORIZONTALES SIMÉTRICAS ===
    for i = 0, totalVerticalCells do
        local line = gridOverlay:CreateTexture("DragonUIGridH"..i, 'BACKGROUND')
        
        -- La línea central es exactamente en halfCellsVertical
        if i == halfCellsVertical then
            line:SetTexture(0.8, 0.2, 0.9, 0.9)  -- Línea central magenta
        else
            line:SetTexture(0.6, 0.8, 1, 0.25)  -- Líneas azul claro
        end
        
        local y = i * actualCellHeight
        line:SetPoint("TOPLEFT", gridOverlay, "TOPLEFT", 0, -y + (lineThickness / 2))
        line:SetPoint('BOTTOMRIGHT', gridOverlay, 'TOPRIGHT', 0, -y - (lineThickness / 2))
    end
    
    --  DEBUG: Mostrar información de simetría
    
    
    
    
    gridOverlay:Hide()
end

function EditorMode:UpdateGridSize(size)
    gridSize = size or gridSize
    if gridOverlay and gridOverlay:IsShown() then
        gridOverlay:Hide()
        gridOverlay = nil
        createGridOverlay()
        gridOverlay:Show()
    end
end

    function EditorMode:UpdateGridVisibility()
        if not gridOverlay then
            createGridOverlay()
        end
        if addon.db and addon.db.profile and addon.db.profile.editmode and addon.db.profile.editmode.showGrid then
            UIFrameFadeIn(gridOverlay, 0.08, gridOverlay:GetAlpha(), 1)
        else
            UIFrameFadeOut(gridOverlay, 0.08, gridOverlay:GetAlpha(), 0)
        end
    end

function EditorMode:Show()
    if InCombatLockdown() then
        
        return
    end

    -- Load current settings
    if addon.db and addon.db.profile and addon.db.profile.editmode then
        gridSize = addon.db.profile.editmode.gridSize or gridSize
        snapToGrid = addon.db.profile.editmode.snapToGrid ~= false
        if addon.MoverSystem then
            addon.MoverSystem:SetGridSize(gridSize)
        end
    end

    createGridOverlay()
    createExitButton()
    createResetAllButton()
    self:UpdateGridVisibility()
    exitEditorButton:Show()
    resetAllButton:Show()
    ensureInspectorFrame()
    wireInspectorHandlers()

    if not activeHighlight then
        activeHighlight = CreateFrame("Frame", "DragonUIActiveHighlight", UIParent)
        activeHighlight:SetFrameStrata("FULLSCREEN_DIALOG")
        activeHighlight:SetFrameLevel(200)
        local tex = activeHighlight:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        tex:SetTexture(0, 0.8, 1, 0.25)
        tex:SetBlendMode("ADD")
        activeHighlight.tex = tex
        activeHighlight:Hide()
    end

    if not keyCatcher then
        keyCatcher = CreateFrame("Frame", "DragonUIEditKeyCatcher", UIParent)
        keyCatcher:SetAllPoints(UIParent)
        keyCatcher:EnableKeyboard(true)
        keyCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
        keyCatcher:SetFrameLevel(201)
        keyCatcher:SetScript("OnKeyDown", function(_, key)
            if not activeMover or InCombatLockdown() then return end
            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
                return
            end
            local step = (addon.db and addon.db.profile and addon.db.profile.editmode and addon.db.profile.editmode.gridSize) or 32
            local deltaX, deltaY = 0, 0
            if key == "UP" or key == "W" then deltaY = step
            elseif key == "DOWN" or key == "S" then deltaY = -step
            elseif key == "LEFT" or key == "A" then deltaX = -step
            elseif key == "RIGHT" or key == "D" then deltaX = step
            else return end

            local name, entry = findMoverEntryByFrame(activeMover)
            if not entry then return end
            local pos = getCurrentPosition(entry)
            pos.x = (pos.x or 0) + deltaX
            pos.y = (pos.y or 0) + deltaY
            applyPosition(name, entry, pos)
            refreshInspector(name, entry)
        end)
    end
    keyCatcher:Show()

    --  NUEVO: USAR SISTEMA CENTRALIZADO - UNA SOLA LÍNEA
    addon:ShowAllEditableFrames()
    
    --  NEW: Enable action bar overlays for mouse blocking during editor mode
    if addon.EnableActionBarOverlays then
        addon.EnableActionBarOverlays()
    end
    
    --  HOOK: Mantener escalas configuradas durante editor mode
    EditorMode:InstallScaleHooks()
    
    -- Update overlay sizes after showing
    if addon.UpdateOverlaySizes then
        addon.UpdateOverlaySizes()
    end
    
    -- Refresh AceConfig to update button state
    self:RefreshOptionsUI()
    
    
end


function EditorMode:Hide(showReloadPopup)
    if gridOverlay then
        UIFrameFadeOut(gridOverlay, 0.1, gridOverlay:GetAlpha(), 0)
    end
    if exitEditorButton then exitEditorButton:Hide() end
    if resetAllButton then resetAllButton:Hide() end
    if inspectorFrame then UIFrameFadeOut(inspectorFrame, 0.1, inspectorFrame:GetAlpha(), 0) end
    if activeHighlight then
        UIFrameFadeOut(activeHighlight, 0.1, activeHighlight:GetAlpha(), 0)
    end
    if keyCatcher then keyCatcher:Hide() end
    activeMover = nil

    --  NUEVO: USAR SISTEMA CENTRALIZADO - UNA SOLA LÍNEA
    addon:HideAllEditableFrames(true) -- true = refresh and save positions
    
    --  NEW: Disable action bar overlays to allow normal interaction with action buttons
    if addon.DisableActionBarOverlays then
        addon.DisableActionBarOverlays()
    end
    
    --  UNHOOK: Remover hooks de escala cuando se sale del editor mode
    EditorMode:RemoveScaleHooks()
    
    -- Refresh AceConfig to update button state
    self:RefreshOptionsUI()
    
    -- NUEVO: Solo mostrar popup de reload UI si no viene desde reset positions
    if showReloadPopup ~= false then
        StaticPopup_Show("DRAGONUI_RELOAD_UI")
    end
    
    
end

function EditorMode:SetActiveMover(frame)
    if not frame then return end
    activeMover = frame
    if not inspectorFrame then
        ensureInspectorFrame()
        wireInspectorHandlers()
    end
    local name, entry = findMoverEntryByFrame(frame)
    if entry then
        UIFrameFadeIn(inspectorFrame, 0.1, inspectorFrame:GetAlpha(), 1)
        refreshInspector(name, entry)
        inspectorLinkedLayoutKey = nil
        -- If this mover matches an action bar, remember which layout to adjust for orientation later
        if entry.configPath and entry.configPath[1] == "widgets" then
            local key = entry.configPath[2]
            if key == "mainbar" then inspectorLinkedLayoutKey = "main"
            elseif key == "rightbar" then inspectorLinkedLayoutKey = "right"
            elseif key == "leftbar" then inspectorLinkedLayoutKey = "left"
            elseif key == "bottombarleft" then inspectorLinkedLayoutKey = "bottomleft"
            elseif key == "bottombarright" then inspectorLinkedLayoutKey = "bottomright"
            end
        end

        if activeHighlight and entry.frame then
            activeHighlight:ClearAllPoints()
            activeHighlight:SetAllPoints(entry.frame)
            if not activeHighlight.text then
                activeHighlight.text = activeHighlight:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                activeHighlight.text:SetPoint("TOP", activeHighlight, "BOTTOM", 0, -2)
            end
            activeHighlight.text:SetText(name or "")
            activeHighlight:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
            activeHighlight:SetBackdropBorderColor(0.1, 0.8, 1, 0.9)
            UIFrameFadeIn(activeHighlight, 0.08, activeHighlight:GetAlpha(), 0.6)
        end
    end
end

function EditorMode:RefreshOptionsUI()
    -- Refresh AceConfig interface to update button states
    -- Use scheduler to ensure it happens after state changes are complete
    addon.core:ScheduleTimer(function()
        local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
        if AceConfigRegistry then
            AceConfigRegistry:NotifyChange("DragonUI")
        end
    end, 0.1)
end

function EditorMode:Toggle()
    if self:IsActive() then 
        self:Hide(true) -- true = mostrar popup de reload UI (salida normal)
    else 
        self:Show() 
    end
end

function EditorMode:IsActive()
    -- Use grid visibility as the true indicator of editor state
    return gridOverlay and gridOverlay:IsShown()
end

--  COMANDO SLASH
SLASH_DRAGONUI_EDITOR1 = "/duiedit"
SLASH_DRAGONUI_EDITOR2 = "/dragonedit"
SlashCmdList["DRAGONUI_EDITOR"] = function()
    EditorMode:Toggle()
end

--  HOOKS PARA MANTENER ESCALAS DURANTE EDITOR MODE
local scaleHooks = {}

function EditorMode:InstallScaleHooks()
    --  DISABLED: Conflicting with RetailUI pattern in mainbars.lua
    -- Hook para MainMenuExpBar
    --[[ 
    if MainMenuExpBar and not scaleHooks.xpbar then
        scaleHooks.xpbar = function()
            if addon.db and addon.db.profile.xprepbar and addon.db.profile.xprepbar.expbar_scale then
                MainMenuExpBar:SetScale(addon.db.profile.xprepbar.expbar_scale)
            end
        end
        
        -- Hook a los eventos que pueden cambiar la escala
        hooksecurefunc(MainMenuExpBar, "SetScale", scaleHooks.xpbar)
        hooksecurefunc(MainMenuExpBar, "SetPoint", scaleHooks.xpbar)
        hooksecurefunc(MainMenuExpBar, "ClearAllPoints", scaleHooks.xpbar)
    end
    ]]--
    
    --  DISABLED: Conflicting with RetailUI pattern in mainbars.lua
    -- Hook para ReputationWatchBar
    --[[
    if ReputationWatchBar and not scaleHooks.repbar then
        scaleHooks.repbar = function()
            if addon.db and addon.db.profile.xprepbar and addon.db.profile.xprepbar.repbar_scale then
                ReputationWatchBar:SetScale(addon.db.profile.xprepbar.repbar_scale)
            end
        end
        
        -- Hook a los eventos que pueden cambiar la escala
        hooksecurefunc(ReputationWatchBar, "SetScale", scaleHooks.repbar)
        hooksecurefunc(ReputationWatchBar, "SetPoint", scaleHooks.repbar)
        hooksecurefunc(ReputationWatchBar, "ClearAllPoints", scaleHooks.repbar)
    end
    ]]--
end

function EditorMode:RemoveScaleHooks()
    -- Los hooks securefunc no se pueden remover directamente,
    -- así que simplemente marcamos como removidos para que no se ejecuten
    scaleHooks.xpbar = nil
    scaleHooks.repbar = nil
end

--  FUNCIÓN DE CONFIRMACIÓN PARA RESET ALL POSITIONS
function EditorMode:ShowResetConfirmation()
    StaticPopup_Show("DRAGONUI_RESET_ALL_POSITIONS")
end

--  FUNCIÓN PARA RESETEAR SOLO WIDGETS USANDO ACE3 (FUERA DEL EDITOR MODE)
function EditorMode:ResetAllPositions()
    if not addon.db or not addon.db.profile then
        return
    end
    
    -- Ocultar el editor mode sin mostrar el popup genérico
    if self:IsActive() then
        self:Hide(false) -- false = no mostrar popup de reload UI
    end
    
    -- Resetear solo la sección widgets usando los defaults de Ace3
    if addon.defaults and addon.defaults.profile and addon.defaults.profile.widgets then
        addon.db.profile.widgets = addon:CopyTable(addon.defaults.profile.widgets)
    else
        return
    end
    
    -- NUEVO: Resetear también additional.totem para multicast
    if addon.defaults and addon.defaults.profile and addon.defaults.profile.additional then
        if not addon.db.profile.additional then
            addon.db.profile.additional = {}
        end
        addon.db.profile.additional.totem = addon:CopyTable(addon.defaults.profile.additional.totem)
    end

    -- Reset movers registered in the new system
    if addon.MoverSystem then
        addon.MoverSystem:ResetAll()
    end
    
    -- Usar ReloadUI para aplicar completamente los cambios
    ReloadUI()
end

--  FUNCIÓN HELPER PARA DEEP COPY (si no existe ya en addon)
if not addon.CopyTable then
    function addon:CopyTable(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[addon:CopyTable(orig_key)] = addon:CopyTable(orig_value)
            end
            setmetatable(copy, addon:CopyTable(getmetatable(orig)))
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end
end

--  DEFINIR EL POPUP DE CONFIRMACIÓN
StaticPopupDialogs["DRAGONUI_RESET_ALL_POSITIONS"] = {
    text = "Are you sure you want to reset all interface elements to their default positions?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        EditorMode:ResetAllPositions()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
    local scaleLabel = makeLabel("Scale", -218)
    local scaleSlider = CreateFrame("Slider", "DragonUIInspectorScale", f, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -6)
    scaleSlider:SetWidth(180)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.01)
    _G[scaleSlider:GetName() .. "Low"]:SetText("0.5")
    _G[scaleSlider:GetName() .. "High"]:SetText("2.0")
local function refreshPresetDropdown()
    if not presetDropdown then return end
    UIDropDownMenu_Initialize(presetDropdown, function(self, level)
        if not addon.db or not addon.db.profile or not addon.db.profile.editmode then return end
        local presets = addon.db.profile.editmode.presets or {}
        local selected = addon.db.profile.editmode.selectedPreset
        for name, _ in pairs(presets) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.value = name
            info.func = function()
                UIDropDownMenu_SetSelectedValue(presetDropdown, name)
                UIDropDownMenu_SetText(presetDropdown, name)
                addon.db.profile.editmode.selectedPreset = name
                presetNameBox:SetText(name)
                if activeMover then
                    local moverName, entry = findMoverEntryByFrame(activeMover)
                    if entry and presets[name] then
                        applyPosition(moverName, entry, presets[name])
                        refreshInspector(moverName, entry)
                    end
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
        if selected then
            UIDropDownMenu_SetSelectedValue(presetDropdown, selected)
            UIDropDownMenu_SetText(presetDropdown, selected)
        end
    end)
end
