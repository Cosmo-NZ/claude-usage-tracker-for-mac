# Floating Claude Usage Tracker

A small macOS menu-bar / floating-panel app that shows your Claude.ai usage
limits at a glance — Session (5-hour) and Weekly windows, with optional Opus
and Fable weekly tracking and API spend.

> **Unofficial.** Not affiliated with or endorsed by Anthropic. It reads your
> own usage by using your logged-in Claude.ai session locally on your Mac;
> nothing is sent anywhere except to Claude.ai. Use at your own discretion and
> in line with Anthropic's terms.

## Download & install

1. Go to the [**Releases**](../../releases) page and download the latest
   `Floating Claude Usage Tracker.dmg`.
2. Open the DMG and **drag the app onto the Applications folder**.
3. Launch it from Applications. The app is signed with a Developer ID and
   notarized by Apple, so it opens normally (you may get a one-time
   "downloaded from the internet — Open?" prompt).
4. The app lives in the menu bar / as a floating panel. Open **Settings ▸
   Connect** and sign in to Claude.ai to start seeing your usage.

## Using it

- **Session / Weekly** bars show how much of each limit you've used; the thin
  vertical marker shows how far through the window you are time-wise.
- **Settings ▸ Additional Tracking** adds optional Opus and Fable weekly rows,
  and API spend.
- **Settings ▸ Appearance** controls bar colour, light/dark mode, opacity, and
  "always on top".
- **Settings ▸ General** picks whether the menu-bar % shows Session or Weekly,
  and the refresh interval.
- Full guide: **Settings ▸ About & Help ▸ Open Help**.

## Build from source

Open `Floating Claude Usage Tracker.xcodeproj` in Xcode and run, or:

```sh
xcodebuild -project "Floating Claude Usage Tracker.xcodeproj" \
  -scheme "Floating Claude Usage Tracker" -configuration Debug build
```

Run the tests with `⌘U` in Xcode.

## Releasing (maintainer notes)

The DMG is produced by [`scripts/release.sh`](scripts/release.sh), which
archives, signs with your Developer ID, notarizes with Apple, staples, and
builds the drag-to-install DMG.

**One-time setup:**

1. Create a **Developer ID Application** certificate:
   Xcode ▸ Settings ▸ Accounts ▸ Manage Certificates ▸ **+** ▸
   *Developer ID Application*.
2. Create an **app-specific password** at
   <https://appleid.apple.com> (Sign-In & Security ▸ App-Specific Passwords).
3. Store notarization credentials once (replace the placeholders):

   ```sh
   xcrun notarytool store-credentials notary-profile \
     --apple-id "you@example.com" --team-id "YOURTEAMID" --password "app-specific-pw"
   ```

   > Ensure the **Floating Claude Usage Tracker** scheme is marked *Shared*
   > (Xcode ▸ Product ▸ Scheme ▸ Manage Schemes… ▸ Shared) so `xcodebuild`
   > can find it.

**Each release:**

```sh
./scripts/release.sh
# then attach the resulting build/*.dmg to a GitHub Release:
gh release create v1.0.0 "build/Floating Claude Usage Tracker.dmg" \
  --title "v1.0.0" --notes "First public build."
```
