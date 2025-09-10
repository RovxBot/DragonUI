# DragonUI for WotLK 3.3.5a

![Interface Version](https://img.shields.io/badge/Interface-30300-blue)
![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-orange)
![Status](https://img.shields.io/badge/Status-Stable-green)

A personal project bringing Dragonflight UI aesthetics to WotLK 3.3.5a.

![DragonUI Interface](https://i.postimg.cc/L8MPT006/1.png)

![DragonUI Features](https://i.postimg.cc/KYk0MWKc/3.png)


## Features

- Action Bars
  - Custom layouts per bar: rows, columns, and buttons shown (per‑bar)
  - Independent movers for Bottom Left, Bottom Right, Right and Right 2 bars
  - Per‑bar scale and manual override positions with profile saving
  - Smart positioning that adapts to main bar height and background visibility
  - Hover and combat visibility per bar (show on hover and/or in combat)
  - Optional main bar art/background hiding and multiple gryphon styles (old/new/flying; faction aware)
  - Page buttons restyled with page number; validation helper to detect missing buttons

- Main Bar, XP & Reputation
  - Dragonflight‑style XP bar with exhaustion tick and proper fill prediction
  - Reputation bar with automatic offset above XP when both are shown
  - Precise movers for XP and Reputation bars (strict‑size overlays)

- Cast Bars
  - Modern styled cast bars (player supported) with a precise mover

- Micro Menu & Bags
  - Redesigned micro menu with player portrait and faction‑aware PvP indicators
  - Configurable scale and icon spacing; grayscale or coloured icon modes
  - Micro menu mover with strict‑size overlay for accurate placement
  - Bags bar enhancements including Keyring support and a compact toggle arrow

- Minimap
  - Modern skinning and layout with a built‑in mover

- World Map
  - Lightweight skin with symmetric backdrop in small/large modes
  - Reskinned close button and corrected offsets; small‑map toggle support
  - World Map mover with saved position support

- Movers / Edit Mode
  - ElvUI‑like mover system: grid overlay, snap‑to‑grid, save/restore per profile
  - Built‑in movers for minimap, micromenu, bags bar, chat and world map
  - Strict‑size option so handles match the exact frame size when needed
  - Slash commands: `/duimove` to show movers, `/duilock` to hide

- Options & Profiles
  - Separate load‑on‑demand options addon (DragonUI_Options)
  - Comprehensive settings for positioning, scaling, layouts and styles
  - Profile support to save and switch configurations per character

- Compatibility
  - Sensible defaults and hooks designed to coexist with common addons

## Installation

1. Download the latest `DragonUI.zip` from the [Releases page](https://github.com/NeticSoul/DragonUI/releases)
2. Extract the ZIP file to your `Interface\AddOns` folder
3. Enable the addon in-game
4. Open the configuration panel via ESC menu > DragonUI button or type `/dragonui`
5. Customize positioning, scaling and visual elements to your preference

## Notes

This addon is not finished and may contain bugs. I'm working on it alone while still learning, so some parts of the code might look a bit wild - but that's the plan, to improve it over time.

If you're interested in helping develop it or making improvements, contributions are welcome! There's definitely room for optimization and fixes.

## Known Issues

- **Party Frames Vehicle Bug:** Party frames do not display correctly when party members enter vehicles.
- Many other bugs are still present and will be polished over time.

## Credits

This project combines and adapts code from several sources:

- **[s0h2x](https://github.com/s0h2x)** - Two specific addons: one for action bars and another for minimap, which have been merged and integrated into DragonUI
- **[KarlHeinz_Schneider - Dragonflight UI (Classic)](https://www.curseforge.com/wow/addons/dragonflight-ui-classic)** - Original addon from which many elements have been taken and backported/adapted to 3.3.5a, including the micro menu and other features built from scratch based on this design
- **[Raz0r1337 - RetailUI](https://github.com/Raz0r1337/RetailUI)** - Reference and inspiration for UI elements and implementation approaches

## Special Thanks

- **CromieCraft Community** - For helping test and provide feedback on various addon features
- **Teknishun** - Special thanks for extensive testing and valuable feedback
- **Project Epoch Community and Staff** - For their help and feedback during development and testing

