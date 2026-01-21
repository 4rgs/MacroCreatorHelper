# MacroCreatorHelper

MacroCreatorHelper is a World of Warcraft addon for building macros with a guided UI, drag & drop, and native saving into the Blizzard macro panel.

## Features
- Macro builder UI with action types: Cast, Use, Equip, Equip Slot, Castsequence.
- Drag & drop from Spellbook, inventory, and equipment into action fields.
- Castsequence with reset options (target/combat/modifiers/seconds).
- Conditions for modifiers and targets, plus equipped/noequipped filters.
- Equip slot picker (with IDs) and equipment type picker (including Shield).
- Optional `#showtooltip` with drag & drop target.
- Minimap button (drag to reposition) and slash commands `/mch` and `/macrocreatorhelper`.
- Saves and updates macros using Blizzard's native macro system.

## Usage
1) Install the addon under `Interface/AddOns/MacroCreatorHelper`.
2) In game, open the UI with `/mch` or the minimap button.
3) Select an action type, drag a spell/item, and add lines.
4) Use **Create/Update** to save the macro in the Blizzard macro panel.

## Versioning
This addon uses semantic versioning. The current version is `0.1.1` (see `MacroCreatorHelper.toc`).

## Changelog
### 0.1.1
- Added macro picker to load existing macros and a new-macro name helper.
- Added condition selectors for stance/form, combat state, and target reaction.
- Auto-parses `#showtooltip` when loading macros and syncs the tooltip input.

### 0.1.0
- Initial release of the macro builder UI and core logic.
- Drag & drop support for spells/items and castsequence building.
- Equip/equipslot support with slot picker and equipped conditions.
- Optional `#showtooltip` control with tooltip target input.
- Minimap button and slash commands for quick access.
