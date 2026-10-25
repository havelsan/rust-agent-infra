# Tetris in Rust with gtk-rs: Requirements

## 1. Goal

A desktop Tetris game for Linux, written entirely in Rust, with a GTK4 UI (gtk4-rs). The game rules must live in a UI-independent core.

## 2. Constraints

- **C-1** Language is Rust only.
- **C-2** Use gtk4-rs (GTK 4) for the UI. 
- **C-5** Any decision that is critical or ambiguous goes back to the Human through a Gitea issue.


## 4. Gameplay

- **G-1** The playfield is 10 columns by 20 visible rows, with a hidden buffer above it.
- **G-2** All 7 tetrominoes (I, O, T, S, Z, J, L) spawn at the top, centred.
- **G-3** Pieces come from a 7-bag randomizer.
- **G-4** Rotation uses the Super Rotation System, including wall kicks, in both directions.
- **G-5** Movement: left, right, soft drop and hard drop.
- **G-6** Lock delay: a piece locks after it rests on the stack for a short, configurable time.
- **G-7** Line clearing works for 1 to 4 lines at once.
- **G-8** Preview of the next piece (at least 1, ideally 3).
- **G-9** Hold piece, usable once per drop.
- **G-10** Ghost piece shows where the current piece will land.
- **G-11** Scoring follows the guideline: soft drop and hard drop points, with a bonus for multi-line clears.
- **G-12** Level increases every 10 lines, and gravity speeds up with each level.
- **G-13** Game over when a new piece cannot spawn.

## 5. UI and controls

- **U-1** A main window with the playfield, next, hold, score, level and lines.
- **U-2** Playfield rendering with `DrawingArea` and Cairo. Block size scales when the window is resized.
- **U-3** The game loop uses `glib` timers. The UI thread is never blocked.
- **U-4** Keyboard handling with `EventControllerKey`, with auto-repeat (DAS/ARR) for left and right.
- **U-5** Default keys: arrows for move, soft drop and rotate; Space for hard drop; C for hold; P for pause; Esc for menu; R for restart.
- **U-6** Start, pause and game-over overlays.
- **U-7** Distinct colour per tetromino, with a colour-blind-friendly palette as an option.

## 6. Persistence

- **P-1** The high score is saved to the XDG data directory (for example as JSON) and loaded on start.
- **P-2** Settings (keys, ghost on or off, palette) are saved to the XDG config directory.
- **P-3** Corrupt or missing files fall back to defaults without crashing.

## 7. Quality

- **Q-1** Unit tests for the core cover every rule above: rotation and kicks, bag randomizer, line clears, scoring, hold, game over.
- **Q-2** Property tests for invariants, for example that a piece never overlaps the stack.
- **Q-3** `cargo clippy` and `cargo fmt` pass with no warnings.
- **Q-4** The core can be exercised headlessly in CI, with no display needed.
- **Q-5** The UI runs at a steady 60 FPS on ordinary hardware.

## 8. Delivery

- **D-1** Release build of `tetris-gtk`.
- **D-2** Qa builds the final rpm and deb packages with a desktop entry and an icon.
- **D-3** README with build, run and controls, plus a wiki page on the architecture.

## 9. Suggested order for the Coordinator

1. Researcher: gtk4-rs and supporting crates.
2. Architect: workspace and domain model.
3. Developer: `tetris-core`, test-first.
4. Designer: layout and palette.
5. Developer: `tetris-gtk`.
6. Reviewer and Tester.
7. Qa: packages.

## 10. Out of scope (first version)

Multiplayer, online leaderboards, sound, mobile and Windows/macOS builds.

## Open decisions

- **Sound.** Out of scope to keep the first iteration small. Add it as a later requirement if wanted.
- **Rotation system.** SRS is the standard, but a simpler classic rotation would reduce the work for a faster first pass.
