-- Test script for action bar layout system
-- This can be run in-game to test the new layout functionality

local addon = select(2, ...)

-- Test function to verify layout system
local function TestActionBarLayout()
    print("=== DragonUI Action Bar Layout Test ===")
    
    -- Check if database has layout settings
    if addon.db and addon.db.profile and addon.db.profile.mainbars and addon.db.profile.mainbars.player then
        local player = addon.db.profile.mainbars.player
        print("Current main bar layout:")
        print("  Rows: " .. (player.rows or "nil"))
        print("  Columns: " .. (player.columns or "nil"))
        print("  Buttons shown: " .. (player.buttons_shown or "nil"))
        
        -- Test the layout function
        if addon.ArrangeActionBarButtons then
            print("ArrangeActionBarButtons function exists - OK")
            
            -- Try to apply current layout
            if pUiMainBar then
                print("pUiMainBar exists - OK")
                addon.ArrangeActionBarButtons('ActionButton', pUiMainBar, pUiMainBar, 
                    player.rows or 1, player.columns or 12, player.buttons_shown or 12)
                print("Layout applied successfully")
            else
                print("ERROR: pUiMainBar not found")
            end
        else
            print("ERROR: ArrangeActionBarButtons function not found")
        end
    else
        print("ERROR: Database structure not found")
    end
    
    print("=== Test Complete ===")
end

-- Slash command for testing
SLASH_DRAGONUI_LAYOUT_TEST1 = "/duilayouttest"
SlashCmdList["DRAGONUI_LAYOUT_TEST"] = TestActionBarLayout

print("DragonUI Layout Test loaded. Use /duilayouttest to run tests.")
