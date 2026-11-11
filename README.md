# Claude Profiles

> **Outdated (November 2026).** This copy-and-re-sign approach stopped working with Claude 5.1231.x: re-signed copies still chat, but can no longer link a session to the Mac ("Couldn't link this session to a computer"), because the device key lives in the Secure Enclave and only the Anthropic-signed app can use it.
>
> **Use [claude-dual-accounts](https://github.com/stajulian5/claude-dual-accounts) instead.** It runs the official `/Applications/Claude.app` twice, each with its own data folder, so both accounts stay linked to the computer and update themselves. (That repo is private.)

Run two (or more) Claude desktop apps side by side on macOS, each signed in to a different account. In this setup that means **Mica** (work) and **Personal**.

## How it works

`rebuild-profiles.sh` makes copies of `/Applications/Claude.app` in `~/Applications/Claude Profiles/`. Each copy:

- gets its own name and bundle ID (`com.claudeprofiles.<slug>`), so macOS treats it as a separate app
- starts through a small compiled launcher that passes `--user-data-dir=~/Library/Application Support/ClaudeProfiles/<slug>`, so each copy keeps its own login, settings and history
- leaves `claude://` links to the main Claude app
- gets a recolored icon so you can tell the copies apart (Mica = orange, Personal = black and white)
- is re-signed ad hoc and registered with Launch Services

## Setup on a new Mac

Requirements: Claude installed in `/Applications`, plus the Xcode command-line tools (`xcode-select --install`) for `clang` and `swiftc`.

```bash
git clone https://github.com/stajulian5/claude-profiles.git ~/claude-profiles
cd ~/claude-profiles
./rebuild-profiles.sh
open ~/Applications/Claude\ Profiles/Mica.app ~/Applications/Claude\ Profiles/Personal.app
```

Sign in to one account in each window. That's it.

## After every Claude update

The copies don't update themselves. Re-run:

```bash
~/claude-profiles/rebuild-profiles.sh
```

Logins are kept because they live in `~/Library/Application Support/ClaudeProfiles/`, not inside the apps.

## Add or rename a profile

Edit the `build …` lines at the bottom of `rebuild-profiles.sh`:

```bash
build Mica     mica     0       # name, data-folder slug, hue (radians) or "gray"
build Personal personal gray
build Side     side     2.1     # e.g. a third, blue-ish one
```
