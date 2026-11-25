# Contributing to Ipasty

Thanks for wanting to help! 💜 Every contribution counts: reporting a bug, suggesting an idea, improving a text or writing code.

## Before you start

- Read the [Code of Conduct](CODE_OF_CONDUCT.md).
- Search the [issues](https://github.com/augusttogu/ipasty/issues) to see if the topic has been discussed.
- For big changes, **open an issue first** and agree on the idea before coding. That way nobody wastes time.

## Reporting a bug or suggesting something

Use the templates under [New issue](https://github.com/augusttogu/ipasty/issues/new/choose):

- 🐛 **Bug report**: include your macOS version, Ipasty version and steps to reproduce.
- 💡 **Feature request**: explain the problem the idea solves.

> Never paste clipboard history, API keys or personal data in an issue.

## Setting up

All you need is a Mac running macOS 14 or later and Apple's Command Line Tools:

```bash
xcode-select --install
git clone https://github.com/YOUR-USERNAME/ipasty.git   # after forking
cd ipasty
./build.sh            # builds, installs to ~/Applications and opens it
```

Other commands:

```bash
./build.sh --no-install   # only builds build/Ipasty.app
./build.sh --zip          # creates dist/Ipasty-<version>.zip (universal)
./tools/screenshots.sh    # regenerates the README screenshots with sample data
```

### Code signing and the Accessibility permission

`build.sh` signs the app ad hoc with a **stable designated requirement** (`identifier "io.github.augusttogu.ipasty"`), so macOS keeps the Accessibility permission between builds. If you have an `Apple Development` or `Developer ID Application` certificate in your Keychain it is used automatically; you can also force one with `SIGN_IDENTITY="…" ./build.sh`.

## Code layout

```
Sources/Ipasty/
├── main.swift         # App, menu bar, global shortcut, panel, pasting
├── Settings.swift     # Preferences (AppSettings) and the Settings window
├── Clipboard.swift    # History: model, storage, clipboard watcher, card view
├── Picker.swift       # Tabs, favorites and recents, emoji, characters, kaomoji
├── Giphy.swift        # GIPHY API integration and animated GIFs
├── Views.swift        # SwiftUI interface for every tab
└── SystemData.swift   # Data folder and reading emoji/character data from macOS
Resources/bundle/      # Files bundled inside the app (Unicode emoji-test.txt)
tools/                 # Icon, README screenshots and hero image
docs/                  # Install guide, maintenance, screenshots
```

Project rules:

- **No external dependencies.** Apple frameworks only (AppKit, SwiftUI, Carbon, CoreText, SQLite3, ServiceManagement).
- **Don't use `@State`/`@Observable`.** The Command Line Tools don't ship SwiftUI's macro plugins. Use `ObservableObject` with `@Published`.
- **Don't copy Apple files into the repository.** System data must be read at runtime (see `SystemData.swift`).
- **Never put API keys in the code.**
- The UI is currently in Brazilian Portuguese; docs and code comments for contributors are welcome in English.

## Sending a pull request

1. **Fork** the repository and create a branch from `main`:
   `git checkout -b feature/custom-shortcut`
2. Make small commits with clear messages, e.g. `Add shortcut picker to Settings`.
3. Run `./build.sh` and test on your Mac. For visual changes, run `./tools/screenshots.sh` and check the images.
4. Update [CHANGELOG.md](CHANGELOG.md) under **Unreleased**.
5. Open the pull request and fill in the template. For visual changes, include before/after screenshots.

### How review works

- The `main` branch is **protected**: nobody pushes directly to it.
- Every pull request needs to:
  - pass the **automatic build** (GitHub Actions);
  - be **approved by a maintainer** (see [`.github/CODEOWNERS`](.github/CODEOWNERS));
  - have all review conversations resolved.
- Pull requests are **squash merged**: each becomes a single commit on `main`.

## Releasing a version (maintainers)

See [docs/MANUTENCAO.md](docs/MANUTENCAO.md) (Portuguese).

Thanks for contributing! 🙌
