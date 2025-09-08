# DragonUI Action Bar Layout System

## Overview
The DragonUI addon now supports customisable action bar layouts, allowing you to arrange your action buttons in different row and column configurations.

## Features

### Main Action Bar
- **Customisable Rows**: 1-4 rows
- **Customisable Columns**: 1-12 columns  
- **Button Limit**: Choose how many buttons to display (1-12)
- **Preset Layouts**: Quick setup options for common configurations

### Side Action Bars
- Left and Right action bars also support custom layouts
- Same row/column/button configuration options
- Independent settings for each bar

## Configuration

### Via Options Panel
1. Open DragonUI options (`/dragonui` or Interface > AddOns > DragonUI)
2. Navigate to "Action Bars" > "Main Bars"
3. Adjust the layout settings:
   - **Rows**: Number of button rows (1-4)
   - **Columns**: Number of button columns (1-12)
   - **Buttons Shown**: How many buttons to display (1-12)

### Preset Layouts
Quick preset buttons are available:
- **Single Row (1x12)**: Traditional horizontal layout
- **Double Row (2x6)**: Two rows of six buttons
- **Triple Row (3x4)**: Three rows of four buttons  
- **Quad Row (4x3)**: Four rows of three buttons (your preference!)

### Validation
The system automatically ensures:
- `rows × columns ≥ buttons_shown` (enough slots for visible buttons)
- Adjusts values automatically if conflicts arise
- Maximum 12 buttons per bar (WoW limitation)

## Technical Details

### Database Structure
```lua
mainbars = {
    player = {
        rows = 4,           -- Number of rows
        columns = 3,        -- Number of columns  
        buttons_shown = 12, -- Buttons to display
        -- ... existing position settings
    },
    left = {
        rows = 1,
        columns = 12,
        buttons_shown = 12,
        -- ... existing position settings
    },
    right = {
        rows = 1, 
        columns = 12,
        buttons_shown = 12,
        -- ... existing position settings
    }
}
```

### Key Functions
- `addon.ArrangeActionBarButtons()`: Core layout function
- `CalculateFrameSize()`: Determines required frame dimensions
- `addon.RefreshMainbars()`: Applies layout changes
- `addon.RefreshUpperActionBarsPosition()`: Updates secondary bar positions

## Usage Examples

### 4x3 Main Bar (Your Preference)
- Rows: 4
- Columns: 3  
- Buttons Shown: 12
- Result: Compact vertical layout, 4 rows of 3 buttons each

### 2x6 Main Bar
- Rows: 2
- Columns: 6
- Buttons Shown: 12  
- Result: Double-height horizontal layout

### Minimalist Setup
- Rows: 1
- Columns: 8
- Buttons Shown: 8
- Result: Single row with only 8 buttons visible

## Compatibility
- Works with existing editor mode (`/duiedit`)
- Compatible with all existing positioning and scaling options
- Maintains compatibility with other DragonUI features
- Secondary bars (MultiBarBottomLeft/Right) automatically adjust position

## Notes
- Changes apply immediately when adjusted in options
- Layout changes resize the action bar frames automatically
- Button spacing and size remain consistent (37px buttons, 7px spacing)
- Hidden buttons (beyond `buttons_shown` limit) are properly hidden but remain functional
