# Changelog

All notable changes to Ipasty are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.1.0] - 2026-11-24

### Added

- **Settings window** (menu bar icon → Settings…, the ⚙️ button in the panel, or <kbd>⌘,</kbd>): launch at login, global shortcut, auto-paste, visible tabs, history size, saving images, and Accessibility permission status.
- Choose the global shortcut: <kbd>⇧⌘V</kbd>, <kbd>⌥⌘V</kbd>, <kbd>⌃⌘V</kbd> or <kbd>⌃⌥V</kbd>.
- Turn the Favorites, Emoji, GIFs, Kaomoji and Special characters tabs on or off.
- **Favorite button** (♡) next to the pin button on clipboard cards, plus <kbd>⌘F</kbd> to favorite the selected item.
- **Reset permission** button that clears a stale Accessibility entry and asks again.
- Opening Ipasty again from Finder, Launchpad or Spotlight shows Settings.

### Changed

- **Launch at login is now on by default** on first run (can be turned off in Settings).
- The macOS Accessibility prompt is shown only once, instead of on every launch. The Settings window updates by itself once permission is granted.
- Documentation, release notes and repository description are now in English. The Portuguese README lives in `README.pt-BR.md`.

### Fixed

- **macOS kept asking for the Accessibility permission after every update.** The app is now signed with a stable designated requirement (its bundle identifier) instead of a per-build hash, so the permission survives updates. Users coming from 1.0.0 need to grant it once more (Settings → Permissions → Reset permission).

## [1.0.0] - 2026-11-16

First public release. 🎉

### Added

- Menu bar panel that opens with <kbd>⇧⌘V</kbd> next to the cursor.
- **Clipboard:** text and image history with search, pinned items, delete and clear all.
- **Favorites and recents** for emoji, GIFs, symbols, kaomoji and text.
- **Emoji** from macOS in 9 categories, with search in Portuguese and English.
- **GIFs** via GIPHY, with a free key configured inside the app.
- **Kaomoji** grouped by mood.
- **Special characters** with the Character Viewer categories and full Unicode, with names and code points.
- Auto-paste into the active app (with Accessibility permission).
- Open at login option.
- Custom icon, light and dark mode.
- Automatic migration of history from the beta (when the app was called "Copiado").

[Unreleased]: https://github.com/augusttogu/ipasty/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/augusttogu/ipasty/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/augusttogu/ipasty/releases/tag/v1.0.0
