# Jot

Native macOS 26 AppKit app, Swift 6 with MainActor default isolation, sandboxed, menu bar only. See `DESIGN.md` for the product decisions.

## Layout

- `Jot/App`: entry point, app delegate, hidden main menu (routes ⌘C/⌘V/⌘Z/⌘K), menu bar item
- `Jot/Drawer`: the floating panel, the edge hover trigger, the Carbon global shortcut
- `Jot/Tasks`: the list view controller and its views (header, add field, cells, Done header, empty state)
- `Jot/Store`: `TaskItem`, `TaskStore` (`@Observable`), `TaskFile` (JSON with atomic writes; unreadable files are moved aside, never overwritten)
- `Jot/Shared`: style tokens, small reusable views and helpers
- `Jot/Intents`: the Add Task App Intent and its Siri phrases
- `Jot/AppIcon.icon`: Icon Composer source for the app icon

The project uses synchronized folders, so new files join the target without editing `project.pbxproj`.

## Commands

```sh
xcodebuild -project Jot.xcodeproj -scheme Jot -destination 'platform=macOS' -derivedDataPath build/DerivedData build
xcodebuild -project Jot.xcodeproj -scheme Jot -destination 'platform=macOS' -derivedDataPath build/DerivedData test
open build/DerivedData/Build/Products/Debug/Jot.app
```

The tests are hosted in the app, so running them opens the drawer.

## Rules

- Design values go in `Jot/Shared/Style.swift`. Use system color roles.
- Store mutations go through `TaskStore`, which saves on every change.
- Every action needs a keyboard path and a VoiceOver path. `TaskAction` feeds the menus and the VoiceOver actions.
- Row views come from the diffable source's `rowViewProvider`. The table never asks the delegate's `rowViewForRow`.
- VoiceOver reads a control's cell, not the view. Hide or label buttons, text fields and image views through `cell`. Task actions sit on the checkbox's cell, since AppKit never asks row views for custom actions.
- Apply a snapshot's moves before its reloads. One pass that both moves and reloads a row fills it with another task's view.
- Test views with an offscreen `swiftc` harness against the real `TasksViewController`, not a stand-in data source.
