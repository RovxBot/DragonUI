# Feature Matrix: DragonUI (WotLK 3.3.5a) vs DragonflightUI Classic (reference)

Scope: compare the current addon (`modules`, `unitframes`) with the modern DragonflightUI Classic reference in `WoW-DragonflightUI-main/Modules`. Focus on functional parity and polish to guide porting work.

Legend: ✅ Present, ⚠️ Partial/backported, ⭕ Missing, ➜ Action item.

| Feature / Area | DragonUI status | Reference module(s) | Notes / Next step |
| --- | --- | --- | --- |
| Action bars & paging | ⚠️ mainbars.lua, buttons.lua, cooldowns.lua | Actionbar, Flyout | Layout controls (rows/cols/spacing/alpha, orientation, mouseover/combat hide) and live snap are in; still need retail-style flyouts, hover/press states, paging map UI, vehicle swap polish. |
| Quick keybind | ⚠️ keybinding.lua | Actionbar (QuickKeybind) | Core works; add conflict feedback, stance/vehicle/flyout coverage, on-screen hints. |
| Micro menu & bags | ⚠️ micromenu.lua | UI (Micromenu/Bags) | Visuals close but lacks retail bag skin/animations; add bag search/highlight and faction/PvP badge polish. |
| Minimap | ✅ minimap.lua | Minimap | Present; align mask/art with reference, add calendar/mail indicators and hover tooltips matching DF skin. |
| Castbars | ✅ castbar.lua | Castbar | Style present; consider latency spark, safe zone, uninterruptible shield art from reference. |
| Buffs/Auras | ⚠️ BuffFrame.lua | Buffs | Basic; add consolidated sorting, weapon enchants, duration styling, cancel buttons, resize sliders. |
| Unitframes (player/target/focus/party/pet/tot/tof) | ⚠️ unitframes/* | Unitframe | Core frames present; missing boss frames, rare/elite markers, cast overlays, absorb shields; add focus/ToF parity polish. |
| Boss frames | ⭕ | Bossframe | Not implemented; determine 3.3.5a API events, port minimal boss frame layout. |
| Tooltip skin | ⭕ | Tooltip | Add DF tooltip backdrop, health bar, item quality borders, anchor logic; hook classic API safely. |
| Chat skin | ⭕ | Chat | No chat module; port styling (tabs, editbox, URL copy), keep optional toggle. |
| Dark mode theme | ⭕ | Darkmode | Add global color set and toggles; gate assets for low memory. |
| Utility tools | ⭕ | Utility | Missing conveniences (durability/repair, friends/queue widgets); pick subset suitable for 3.3.5a. |
| Edit Mode / movers | ⚠️ editor_mode.lua | UI (Editmode) | Grid toggle/size + snap, live XY readout, hover nudge buttons, inspector (anchor/parent/X/Y/scale/orientation), active highlight done; still missing presets/revert, keyboard nudging, focus ring styling, nine-slice + fade, anchor-parent-point helper. |
| Quest tracker | ✅ questtracker.lua | Utility (Quest tweaks) | Present; revisit for DF styling and module toggles. |
| Vehicle & stance | ⚠️ vehicle.lua, stance.lua, multicast.lua | Actionbar/Compatibility | Functioning but buggy per README; mirror reference handling and test DK/vehicles/pet classes. |
| Compatibility layer | ⚠️ compatibility.lua | Compatibility | Basic; port shims/version checks, add VIP/Version logic for updates. |
| Configuration UI & profiles | ✅ options.lua, database.lua, config.lua | __Settings.lua, Config.lua | AceConfig present; consider auto-building options from settings schema; widen default window already done. |
| Shared media / fonts | ⚠️ Textures/, assets/ | SharedMedia.lua | Import consistent textures (status bars, masks, gradients) and font stack to unify look. |
| Localization | ⭕ | LocalizationData.lua | Currently English-only; add locale table hooks if desired. |

Immediate focus candidates (highest payoff): Tooltip, Darkmode, Buffs, Flyout polish, Bossframe (if server supports), Chat skin. These bring visible DF polish quickly and have contained blast radius.

Follow-up setup: add a `compat` shim file mirroring reference Compatibility module, and reuse the reference `__Settings.lua` pattern to generate option groups while keeping AceDB profiles intact.
