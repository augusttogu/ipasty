# Privacy and terms of use

_Last updated: November 24, 2026_

Ipasty is built to run **entirely on your Mac**. This page explains what the app stores, where your data goes (spoiler: nowhere) and the terms of use.

## What Ipasty stores

Everything lives in `~/Library/Application Support/Ipasty`, on your computer:

| File | Contents |
|---|---|
| `history.json` | Copied text, the app it came from, the date and whether it's pinned |
| `images/` | Copied images, as PNG (can be turned off in Settings) |
| `favorites.json` | Your favorites (emoji, symbols, kaomoji, text and GIF links) |
| `recents.json` | The last items used in the emoji, GIF, kaomoji and character tabs |

Preferences (for example, your GIPHY key and the options in Settings) are stored in the app's macOS preferences (`io.github.augusttogu.ipasty`).

- The history keeps up to **300 unpinned items** by default (50 to 1000, configurable in Settings). Older items are deleted automatically.
- Items marked as **passwords or transient content** by password managers (such as 1Password and Bitwarden) are **never stored**.
- You can delete an item (<kbd>⌘⌫</kbd>), clear everything with **Clear all** or in Settings, or delete the folder above to remove all data.

> ⚠️ Ipasty stores **everything** you copy, including sensitive text copied from ordinary places (like a token pasted in an email). If you copy something secret, delete it from the history.

## What leaves your Mac

- **Nothing**, except when you use the **GIF tab**. There, the app sends GIPHY your search text, your API key and the language, and downloads the GIF images. This follows the [GIPHY privacy policy](https://giphy.com/privacy).
- Ipasty has **no** telemetry, usage analytics, ads, accounts or servers of its own.

## Permissions the app asks for

| Permission | What for | Required? |
|---|---|---|
| **Accessibility** | Send <kbd>⌘V</kbd> to the app you were using, so a click pastes | No. Without it you paste manually |
| **Open at login** | Start with your Mac (on by default, can be turned off in Settings) | No |

Ipasty does **not** ask for access to files, camera, microphone, location or contacts.

## Terms of use

1. Ipasty is free software, distributed under the [MIT License](LICENSE).
2. It is provided **"as is"**, without warranty of any kind. The authors are not liable for data loss or other damages arising from its use.
3. When using the GIF tab, you are responsible for your GIPHY key and agree to GIPHY's terms. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
4. Use the app in accordance with applicable laws and respect the copyright of the content you copy and share.

Questions? Open an [issue](https://github.com/augusttogu/ipasty/issues). For security problems, see [SECURITY.md](SECURITY.md).
