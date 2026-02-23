# WoW Dungeon Assist

A lightweight World of Warcraft addon that provides a compact, ElvUI-style raid control panel for party and raid content.

![Dungeon Assist panel](docs/dungeon-assist-panel.png)

## Features

- Collapsible panel titled `Dungeon Assist`.
- Auto-visibility when grouped (`party` or `raid`), hidden when solo.
- Movable in Blizzard Edit Mode.
- Class-colored title/text/icons.
- Secure action buttons for:
  - `Ready Check` (checkmark icon).
  - `Countdown 10` (clock icon + `10`).
  - `Clear Markers` (clears all raid target markers).
  - 8 target marker buttons:
    - Left-click sets that marker on your current target.
    - Right-click clears that specific marker from your current target (for example, right-click skull clears skull).
- Saved position and expanded/collapsed state.
- Slash command support via `/wda`.

## Game Version / API Notes

- TOC Interface in this repo: `120001`.
- Built with secure templates for modern protected-action handling:
  - `SecureHandlerStateTemplate` for visibility driver.
  - `SecureActionButtonTemplate` for protected actions (`readycheck`, `countdown`, raid markers).
  - Registers clicks with `AnyDown` and `AnyUp` for compatibility with `ActionButtonUseKeyDown` behavior.

## Installation

1. Download or clone this repo:
   - [https://github.com/Phrantiks-ai/wow-dungeon-assist](https://github.com/Phrantiks-ai/wow-dungeon-assist)
2. Place the addon folder here:
   - `World of Warcraft/_retail_/Interface/AddOns/WoW-Dungeon-Assist`
3. Confirm these files exist in that folder:
   - `WoW-Dungeon-Assist.toc`
   - `WoW-Dungeon-Assist.lua`
4. Launch the game and enable `WoW Dungeon Assist` in AddOns.
5. Run `/reload` after updates.

## Usage

- Join a party or raid: panel appears automatically.
- Left-click the header to expand/collapse the dropdown.
- Open Edit Mode to drag and reposition the panel.
- Use buttons in the dropdown:
  - `Clear Markers` clears all raid target markers.
  - Marker grid sets/clears individual target markers.
  - Bottom-left checkmark runs ready check.
  - Bottom-right clock runs `/countdown 10`.

## Slash Commands

| Command | Behavior |
| --- | --- |
| `/wda show` | Forces the panel visible even when not grouped. |
| `/wda auto` | Returns to automatic visibility (`show in group, hide solo`). |
| `/wda hide` | Alias of `/wda auto`. |
| `/wda reset` | Resets position to defaults and enables forced show. |
| `/wda where` | Prints the current saved anchor point/offset. |

## Permissions and Protected Actions

Blizzard protects raid-control actions. This addon uses secure buttons so clicks are executed through secure action attributes/macros.

You may still see actions fail if game permissions are not met, for example:

- You are not allowed to set markers in the current group context.
- You do not have a valid target when setting/clearing target markers.
- Group-role restrictions for ready checks/countdowns in a specific content type.

Combat restrictions:

- Header expand/collapse is blocked in combat lockdown.
- Visibility driver updates delayed by combat are applied after combat ends.

## Saved Variables

Saved variable name: `WoWDungeonAssistDB`

Stored keys:

- `point`
- `relativePoint`
- `x`
- `y`
- `expanded`

## Troubleshooting

### Addon loaded but panel is not visible

- If solo, this is expected in auto mode.
- Use `/wda show` to force it visible.
- Verify the folder path and addon name in the AddOns menu.

### Buttons do not trigger actions

- Ensure you are in a group context where action is permitted.
- Make sure you have a valid target for marker actions.
- Test out of combat first.
- If you updated files manually, run `/reload`.

### Panel cannot be moved

- Open Blizzard Edit Mode.
- Drag the panel while Edit Mode is active.

### Marker errors (`ADDON_ACTION_FORBIDDEN`)

- This usually indicates an outdated/insecure code path.
- Update to the latest version from this repository and `/reload`.

## Development Notes

- Main code file: `WoW-Dungeon-Assist.lua`.
- Entry event: `PLAYER_LOGIN`.
- Visibility state driver: `"[group] show; hide"`.
- Secure actions are configured once on frame creation; avoid non-secure calls for protected functions.
- Edit Mode integration uses `EventRegistry` callbacks (`EditMode.Enter`, `EditMode.Exit`).
- If updating for a new patch:
  - Update `## Interface` in `WoW-Dungeon-Assist.toc`.
  - Re-test secure actions (ready check, countdown, marker set/clear, clear-all).

## License

No license file is currently included in this repository. Add one if you want explicit reuse terms.
