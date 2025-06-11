# Screenshots That Need Updating

The plugin has been updated to use a pure subcommand interface. The following screenshots may show old command syntax and need to be updated:

## 📸 Images to Review/Update

### `docs/images/basic-display.png`
- **Status**: Likely OK (shows only display, not commands)
- **Check**: Verify no old command examples visible in terminal history

### `docs/images/customization-themes.png` 
- **Status**: Likely OK (shows display variations)
- **Check**: Verify no old command examples visible in terminal history

### `docs/images/toggle-controls.png`
- **Status**: NEEDS UPDATE
- **Issue**: Likely shows old toggle command syntax like `todo_toggle_affirmation`
- **New syntax**: Should show `todo toggle affirmation`, `todo hide`, `todo show`

## 🔄 Command Syntax Changes

Old commands that may appear in screenshots:
- `todo_help` → `todo help`
- `task_done "task"` → `todo done "task"`
- `todo_toggle_affirmation` → `todo toggle affirmation`
- `todo_toggle_box` → `todo toggle box`
- `todo_toggle_all` → `todo toggle all`

## 📝 New Screenshots Needed

Consider adding screenshots for:
- `todo help` output (showing new clean interface)
- `todo setup` wizard flow
- `todo config` management commands
- Progressive help system (`todo help` vs `todo help --full`)

## ✅ Action Items

1. Review existing screenshots for old command syntax
2. Update toggle-controls.png to show new toggle commands  
3. Consider new screenshots highlighting the improved UX
4. Ensure all terminal history in screenshots uses new interface

---

*Note: This file can be deleted once screenshot updates are complete.*