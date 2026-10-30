# Jot

I do a lot of important stuff, and random ideas show up in the middle of it. They need to be written down fast, so I can send them to my agents later and get back to what I was doing.

Jot is that place. A small native Mac app that lives in the top-right corner of the screen, always on top, and gets out of the way.

## What it does

- **Hover the top-right edge** and the drawer slides out. Move away and it closes.
- **⌃⇧Space** opens it from anywhere, with the cursor ready to type.
- **Return** saves the idea. That's it.
- **Copy** any task with one click on hover, then paste it straight into an agent.
- **In progress** marks what you're working on and pins it to the top.
- **Done** tasks fold away under their own section.
- Fully keyboard and VoiceOver friendly. ⌘C copies, ⌘K checks off, ⌘P starts, ⌘Z undoes.
- Local only. Your tasks stay in one JSON file on your Mac.

## Build

Needs macOS 26 and Xcode 26.

```sh
xcodebuild -project Jot.xcodeproj -scheme Jot -destination 'platform=macOS' -derivedDataPath build/DerivedData build
open build/DerivedData/Build/Products/Debug/Jot.app
```

## Read more

- `DESIGN.md`: the product and design decisions
- `AGENTS.md`: how the code is laid out, for agents working on it
