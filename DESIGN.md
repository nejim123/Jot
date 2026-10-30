# Jot design

Jot exists to catch a task in under two seconds and get out of the way.

## Surfaces

- **Drawer.** A glass panel pinned to the top-right corner, above every app and on every Space.
  - Opens with ⌃⇧Space, with the cursor in the add field.
  - Peeks when the pointer rests on the top of the screen's right edge for 0.2s.
  - A peek closes 0.4s after the pointer leaves the drawer and its corner.
  - Once you click in or type, only Escape or a click elsewhere closes it. "Esc closes" shows from then on.
  - Launching from Finder or Spotlight opens it. A login launch stays closed, so it never takes your typing.
- **In progress.** Hovering an open task shows a ▶ pill beside the copy pill. One click marks it in progress: the circle half fills in the accent and the task moves to the top. ■ stops it. Checking it off works as usual, and reopening it puts it back in progress.
- **Copying.** Hovering a task shows a copy pill at the end of its first line. One click copies the title, and the icon turns into a check for 1.2s. The pill floats over the text, so titles keep their full width. In a peek the click doesn't take the keyboard, so the peek still closes on its own and ⌘V lands in the app you were using.
- **Menu bar item.** Show Tasks, Open at Login, Quit. There's no Dock icon.
- **Shortcuts and Siri.** "Add a task in Jot" saves a task without opening anything.

## Order of attention

1. The add field: first in the keyboard path, with an accent ring when focused.
2. In-progress tasks, most recently started first.
3. The other open tasks, newest first, so a new task lands right under what you're working on.
4. The Done section, collapsed by default, with its count.
5. Shortcut hints in the footer, quietest of all.

The drawer hugs its content, up to 520pt, so a short list doesn't sit in empty glass. The hover zone on the edge is as tall as the drawer.

## Tokens

All type, spacing and shape values live in `Jot/Shared/Style.swift`. Colors use system roles only.

Jot is light only. `AppDelegate` pins the app to the Aqua appearance, even when macOS is in Dark Mode. Increase Contrast still applies.

| Role | Value |
| --- | --- |
| Title | SF Rounded 20 bold |
| Date | SF 12 medium, secondary label |
| Task | SF 14, label; done is secondary label with a strikethrough |
| In progress | Half-filled circle in the accent |
| Section | SF Rounded 13 semibold, secondary label; its count is secondary label too |
| Counts | SF Rounded 12 semibold, tabular figures; the header pill is label on an accent tint |
| Hints | SF 11, secondary label. Tertiary measured about 2:1 on glass |
| Accent | App AccentColor (indigo) when the system accent is Multicolor, otherwise the user's accent |
| Field fill | quaternary label color |
| Hover | quaternary system fill, matching the table's selection shape |

## Motion

| Move | Duration | Curve |
| --- | --- | --- |
| Slide in | 0.28s | ease out |
| Slide out | 0.2s | ease in |
| Resize to fit | 0.2s | ease out, after the slide lands |
| Checked task | stays 0.6s, then moves to Done | |

Reduce Motion swaps every slide for a fade, and makes resizes and list changes instant.

## Accessibility decisions

- **One VoiceOver stop per task.** The checkbox carries the title. Mark Done, Start Working, Edit, Copy and Delete are row actions. The hover pills are hidden from VoiceOver. An in-progress task reads as "title, in progress".
- **Full keyboard path.**
  - ⌃⇧Space opens the drawer. Return adds a task.
  - On a selected row, Space marks it done, Return renames it and ⌫ deletes it. The selection stays in place, so you can repeat.
  - ⌘C copies the selected tasks, one per line. ⌘K toggles done. ⌘P starts or stops working on a task. ⌘⇧H shows or hides Done. ⌘⇧⌫ clears Done.
  - ⌘Z undoes a check, a start or a delete.
  - Escape closes the drawer.
- **The shortcut avoids ⌃⌥.** That's VoiceOver's modifier. ⌥Space is taken by the ChatGPT app.
- **Announcements.** VoiceOver hears adds, completions, starts, deletes and restores without focus moving.
- **Click targets.** Clear and the Done disclosure are at least 20pt tall.
