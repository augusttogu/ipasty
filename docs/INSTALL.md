# Installing Ipasty on your Mac

← [Back to README](../README.md) · [Português](INSTALACAO.md)

## Requirements

- **macOS 14 Sonoma** or later
- An **Apple Silicon** (M1, M2, M3, M4…) or **Intel** Mac

---

## Option 1 — Download the ready-made app

### 1. Download

On the [latest release page](https://github.com/augusttogu/ipasty/releases/latest), under **Assets**, click **`Ipasty-x.y.z.zip`**.

### 2. Install

1. Open the `.zip` (Finder unzips it automatically).
2. Drag **Ipasty.app** into your **Applications** folder.

### 3. First launch

Ipasty is free and doesn't have Apple's paid notarization yet, so macOS shows a warning like _"Apple could not verify Ipasty is free of malware"_ the first time. To allow it:

1. Double-click Ipasty and dismiss the warning (**Done**).
2. Open **System Settings → Privacy & Security**.
3. Scroll to **Security**. You'll see _"Ipasty was blocked…"_. Click **Open Anyway**.
4. Confirm with your password or Touch ID.

You only need to do this once.

<details>
<summary>Terminal alternative</summary>

```bash
xattr -dr com.apple.quarantine /Applications/Ipasty.app
open /Applications/Ipasty.app
```

This removes the "downloaded from the internet" flag from Ipasty only.
</details>

> 🔍 Want to check what's running? All the code is in this repository, and every release is built automatically by GitHub Actions from it (see the **Actions** tab).

---

## Option 2 — Build from source

### 1. Install Apple's tools

You don't need full Xcode, only the Command Line Tools:

```bash
xcode-select --install
```

### 2. Clone and build

```bash
git clone https://github.com/augusttogu/ipasty.git
cd ipasty
./build.sh
```

The app is built, installed to `~/Applications/Ipasty.app` and opened. Since you built it yourself, macOS doesn't show the security warning.

### Updating

```bash
cd ipasty
git pull
./build.sh
```

---

## After installing

### Paste with one click (Accessibility)

On first launch Ipasty asks for the **Accessibility** permission (only once; it keeps working after updates):

1. **System Settings → Privacy & Security → Accessibility**.
2. Turn on **Ipasty** (if it's not listed, click **+** and pick the app in Applications).

You can also check the status in **Ipasty Settings → Permissions**. Without this permission a click only copies the item, and you paste with <kbd>⌘V</kbd>.

### Enable GIFs (optional)

1. Open Ipasty (<kbd>⇧⌘V</kbd>) and go to the **GIF** tab.
2. Click **Open developers.giphy.com** and sign in (or create a free account).
3. Click **Create an API Key**, choose **API** and name it **Ipasty**.
4. Copy the key, paste it in the GIF tab and click **Save**.

The free key allows up to 100 searches per hour.

### Launch at login

On by default. To turn it off: Ipasty menu bar icon → **Settings…** → **Launch at login**.

---

## Troubleshooting

| Problem | What to do |
|---|---|
| The shortcut doesn't open anything | Check the clipboard icon is in the menu bar. If not, open Ipasty again from Applications. Also check which shortcut is selected in Settings. |
| Clicking an item doesn't paste | Open **Settings → Permissions**. If Ipasty is on in the system list but still doesn't paste, click **Reset permission**. |
| "Invalid GIPHY key" | In the GIF tab, click the gear → **Change GIPHY key** and paste it again. |
| "GIPHY limit reached" | The free key allows 100 searches per hour. Wait a bit. |
| An emoji doesn't show up | Ipasty only shows emoji your macOS version can draw. Update macOS to see the newest ones. |

Still stuck? [Open an issue](https://github.com/augusttogu/ipasty/issues/new/choose).

## Uninstall

1. Click the Ipasty icon → **Quit Ipasty**.
2. Delete **Ipasty.app** from Applications.
3. To also delete history and favorites:

```bash
rm -rf ~/Library/Application\ Support/Ipasty
defaults delete io.github.augusttogu.ipasty
tccutil reset Accessibility io.github.augusttogu.ipasty
```
