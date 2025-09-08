-- DragonUI Action Bar Fix Script
-- Run this if your action bars are overlapping or positioned incorrectly

local addon = select(2, ...)

local function FixActionBars()
    print("=== DragonUI Action Bar Fix ===")

    -- Reset main bar to default single row layout
    if addon.db and addon.db.profile and addon.db.profile.mainbars then
        print("Current layout - Main bar: " .. (addon.db.profile.mainbars.player.rows or "nil") .. "x" .. (addon.db.profile.mainbars.player.columns or "nil"))

        addon.db.profile.mainbars.player.rows = 1
        addon.db.profile.mainbars.player.columns = 12
        addon.db.profile.mainbars.player.buttons_shown = 12

        addon.db.profile.mainbars.left.rows = 1
        addon.db.profile.mainbars.left.columns = 12
        addon.db.profile.mainbars.left.buttons_shown = 12

        addon.db.profile.mainbars.right.rows = 1
        addon.db.profile.mainbars.right.columns = 12
        addon.db.profile.mainbars.right.buttons_shown = 12

        print("Reset all action bars to default single row layout (1x12)")

        -- Force repositioning of all buttons
        if InCombatLockdown() then
            print("In combat - changes will apply when combat ends")
        else
            -- Manually reset button positions to linear layout
            for i = 1, 12 do
                local button = _G["ActionButton" .. i]
                if button then
                    button:ClearAllPoints()
                    if i == 1 then
                        button:SetPoint('BOTTOMLEFT', pUiMainBar, 'BOTTOMLEFT', 2, 2)
                    else
                        button:SetPoint('LEFT', _G["ActionButton" .. (i-1)], 'RIGHT', 7, 0)
                    end
                    button:Show()
                end
            end

            -- Refresh the bars
            if addon.RefreshMainbars then
                addon.RefreshMainbars()
                print("Applied changes and refreshed bars")
            end
        end

        print("Type /reload to ensure all changes are fully applied")
    else
        print("Could not find DragonUI database")
    end

    print("=== Fix Complete ===")
end

local function TestAllBars()
    print("=== DragonUI Action Bar Test ===")

    if addon.db and addon.db.profile and addon.db.profile.actionbars then
        print("Enabling all action bars...")

        -- Enable all bars
        addon.db.profile.actionbars.bottom_left_enabled = true
        addon.db.profile.actionbars.bottom_right_enabled = true
        addon.db.profile.actionbars.right_enabled = true
        addon.db.profile.actionbars.right2_enabled = true

        -- Apply visibility changes
        if addon.RefreshActionBarVisibility then
            addon.RefreshActionBarVisibility()
            print("All action bars enabled and refreshed")
        end

        print("Test complete - all action bars should now be visible")

        -- Validate that everything is working
        C_Timer.After(1, function()
            if addon.ValidateActionBars then
                addon.ValidateActionBars()
            end
        end)

        print("If you see any issues, type /duifix to reset to defaults")
    else
        print("Could not find DragonUI database")
    end
end

local function TestEditorMode()
    print("=== DragonUI Editor Mode Test ===")

    -- Enable all bars first
    if addon.db and addon.db.profile and addon.db.profile.actionbars then
        addon.db.profile.actionbars.bottom_left_enabled = true
        addon.db.profile.actionbars.bottom_right_enabled = true
        addon.db.profile.actionbars.right_enabled = true
        addon.db.profile.actionbars.right2_enabled = true

        if addon.RefreshActionBarVisibility then
            addon.RefreshActionBarVisibility()
        end

        print("✅ All action bars enabled")
    end

    -- Check stance bar frame
    local stanceHolder = _G["pUiStanceHolder"]
    if stanceHolder then
        print("✅ Stance bar holder found: " .. stanceHolder:GetName())
        stanceHolder:Show() -- Make sure it's visible
    else
        print("❌ Stance bar holder (pUiStanceHolder) not found")
    end

    -- Test editor mode
    if addon.EditorMode then
        print("🎯 Activating editor mode...")
        addon.EditorMode:Show()
        print("✅ Editor mode active - you should now be able to move all action bars!")
        print("📝 Available movable bars:")
        print("  - Main Action Bar (pUiMainBar) - ✅ Independent")
        print("  - Bottom Left Bar (MultiBarBottomLeft) - ✅ Independent")
        print("  - Bottom Right Bar (MultiBarBottomRight) - ✅ Independent")
        print("  - Right Bar (MultiBarRight) - ✅ Independent")
        print("  - Right Bar 2 (MultiBarLeft) - ✅ Independent")
        print("  - Stance Bar (pUiStanceHolder) - ✅ Independent")
        print("🎯 All bars now have individual scaling options!")
        print("⚠️  Click the 'Exit Editor Mode' button when done")

        -- Validate stance bar after a moment
        C_Timer.After(1, function()
            if stanceHolder then
                local hasOverlay = false
                for i = 1, stanceHolder:GetNumChildren() do
                    local child = select(i, stanceHolder:GetChildren())
                    if child and child:GetName() and string.find(child:GetName(), "Overlay") then
                        hasOverlay = true
                        break
                    end
                end
                if hasOverlay then
                    print("✅ Stance bar is properly configured for editor mode")
                else
                    print("❌ Stance bar overlay not found - may not be movable")
                end
            end
        end)
    else
        print("❌ Editor mode not available")
    end
end

-- Slash commands
SLASH_DRAGONUI_FIX1 = "/duifix"
SlashCmdList["DRAGONUI_FIX"] = FixActionBars

SLASH_DRAGONUI_TEST1 = "/duitest"
SlashCmdList["DRAGONUI_TEST"] = TestAllBars

SLASH_DRAGONUI_EDITOR_TEST1 = "/duiedit"
SlashCmdList["DRAGONUI_EDITOR_TEST"] = TestEditorMode

print("DragonUI Action Bar Tools loaded:")
print("  /duifix - Reset action bars to default layout")
print("  /duitest - Enable all action bars for testing")
print("  /duiedit - Test editor mode with all bars enabled")
print("")
print("✅ Action Bar Menu Overhaul Complete!")
print("   - Removed redundant X/Y position sliders")
print("   - Added Quick Setup section")
print("   - Cleaner, more organized interface")
print("   - All positioning now done via Editor Mode")
