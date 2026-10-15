# Travel to Dungeon

A leader-focused dungeon coordination addon targeting WoW Forever 1.60.1 (interface 16001). Version 0.2.0 replaces the initial prototype's incorrect 3.3.5 target with modern group APIs and backdrop support. Actual Forever client testing is still required.

The board uses dark brown panels, bronze borders and buttons, and warm cream text inspired by Forever's UI. Status colors remain distinct for readability. No external artwork or UI addon is required.

A **Travel to Dungeon** map icon attaches beneath the Dungeon/Group Finder right-side tabs. It opens the same board as `/ttd`. Integration detects `PVEFrame` (or the legacy `LFDParentFrame`) after login or lazy loading, and defers attachment during combat. Custom replacements that expose neither frame can still use `/ttd`. Placement needs visual verification in the Forever beta.

The board hides during combat and pauses roster reads; reopen it afterward. Sharing, resetting and manual check-ins are unavailable in combat.

## Code organization

WoW loads the Lua files in the order listed in [TravelToDungeon.toc](./TravelToDungeon.toc). Each file receives the same private addon namespace through `local _, TTD = ...`; no `require()` or external library is needed.

- [Core.lua](./Core.lua): shared state, chat output, and client compatibility helpers.
- [Data.lua](./Data.lua): dungeon presets, status labels, and status colors.
- [Party.lua](./Party.lua): roster tracking, check-ins, timer state, and party announcements.
- [UI.lua](./UI.lua): bronze controls, meeting board layout, and display updates.
- [DungeonUI.lua](./DungeonUI.lua): the Dungeon/Group Finder launcher.
- [TravelToDungeon.lua](./TravelToDungeon.lua): startup, saved settings, events, and slash commands.

UI widgets stay private to the UI module. Shared transient values live in `TTD.State`; persistent preferences remain in `TravelToDungeonDB`. Modules define their functions before startup registers events, so cross-module calls happen only after all files have loaded.

## Installation steps

Copy the whole `TravelToDungeon` folder into `World of Warcraft/Interface/AddOns/`, so `TravelToDungeon.toc` sits directly inside it. Restart the client, enable Travel to Dungeon on the character-selection AddOns screen, and enter `/traveltodungeon` or `/ttd`.

## Use

1. Invite your dungeon party and open the board. Drag its background to move it.
2. Select a dungeon from the scrollable list on the Dungeons tab. It defaults to recommended dungeons for your current character level, sorted by minimum level and name. Enable **Show all dungeons** to choose any of the 19 presets. Selection sets the meeting point to the dungeon name, clears preparation notes, and resets check-ins. Filtering never clears an existing destination.
3. Open Party check-ins and optionally enter preparation notes. Party names use class colors.
4. Click each member's status to cycle through Not ready, Traveling, Nearby, and At entrance. All statuses begin as Not ready.
5. Click **Share to party** to announce the destination, optional notes, and each member's status. This sends several party-chat messages and has a ten-second cooldown.
6. Party members can reply `1` for traveling, `2` for nearby, `3` for at entrance, or `0` for not ready. Read those replies and update their rows manually.

Only the board owner needs the addon. Each installation has its own independent board; there is no addon synchronization, automatic chat parsing, location detection, or ETA calculation. The board shows ready only when every current member is marked At entrance and online. It does not perform a WoW ready check or verify location.

The waiting timer starts when a party is detected. **Reset** clears all statuses and restarts the timer. Use it for a new run, especially after manually changing the destination. Leaving the party stops the timer; departing players' statuses are discarded. Offline members remain visible and prevent the ready indication. Raids are unsupported.

Meeting point, notes, and window position persist across reloads account-wide. Statuses and the waiting timer intentionally reset on reload to avoid stale readiness.

Commands: `/ttd`, `/ttd share`, `/ttd reset`, `/ttd help`. Escape closes the board.

## In-game acceptance checks

- Open the Dungeon/Group Finder before and after opening Travel to Dungeon; verify one launcher appears, follows the panel, and toggles the board without covering queue controls.
- Enter combat before the Dungeon UI loads; verify attachment waits until combat ends, the board hides, and no blocked-action or restricted-unit-data errors occur.
- Verify the list defaults to your level range, including exact minimum/maximum levels. Enable Show all dungeons and scroll through all 19 presets. Select an out-of-range dungeon, turn the filter back on, and verify the destination remains. At levels below 13, check the empty-state message. Level changes refresh the filter outside combat. Verify bronze styling and readable text in both tabs.
- Open, close, drag, reload, and verify the position and meeting text persist.
- Select a preset and edit its meeting point and notes.
- Invite members; verify names and independent status cycling for each row.
- Mark everyone At entrance; verify ready appears only with everyone online.
- Disconnect a member, remove a member, and replace a member; verify offline handling and new members start Not ready.
- Share with a party member who has no addon; verify readable messages and the cooldown. Verify solo/raid sharing is blocked.
- Reset and reload; verify statuses and timer reset as documented.
- Convert to raid and back; verify the unsupported notice and party roster recovery.

This prototype needs in-game testing on the actual server client before release. No external dependencies or build step are required.

## Forever dungeon sources

The nine new presets are The Hall of Thanes, Ruins of Lordaeron, Excavation Site: Wetlands, City of Dalaran, The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold, and Shaper's Terrace. These are announced launch dungeons, not a claim that all are currently open in the beta. Notes are generic meeting instructions; no unverified keys, coordinates or attunements are asserted.

- [Blizzard's What's Next recap: all nine new dungeons](https://news.blizzard.com/en-us/article/24303862/world-of-warcraft-forever-whats-next-panel-recap)
- [Forever Compass: client-derived dungeon names and zones](https://forevercompass.com/dungeons)
- [VuloForeverUI: Forever client version and modern API baseline](https://github.com/mrvulo/VuloForeverUI)
- [Blizzard Group Finder frame source mirror](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_GroupFinder/Mainline/PVEFrame.xml)

Sources checked October 15, 2026. Beta builds may change interface versions and frame layouts.

When upgrading from WecMeetUp, remove the old addon folder before installing TravelToDungeon to avoid loading both addons. The renamed addon starts with fresh saved settings.

The dungeon picker uses recommended beta level ranges, not access restrictions. Combined Scarlet Monastery and Dire Maul presets span their wings. Show all dungeons defaults off each login. The compact 420 x 500 window uses separate Dungeons and Party check-ins tabs and is inspired by Dungeon Finder; exact visual matching still needs an in-game comparison.
