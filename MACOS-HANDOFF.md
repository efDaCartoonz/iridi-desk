# iRidiDesk for macOS - functional brief

## Purpose

iRidiDesk is a branded RustDesk-based **thin support client**. It receives support sessions only; users must not be able to start connections to other devices. The client must retain incoming remote-control, chat, and file-transfer support. Terminal access is disabled.

The rendezvous server, relay server, and public key are injected at build time from a local, ignored `.env`. Never put those values in source, Git, logs, or handoff documents. The UI must not expose server, relay, API, proxy, WebSocket, or key settings.

## Main window

Use a compact, fixed-size support window: **560 x 390 logical pixels/points**. It must not be user-resizable or maximizable. The layout is a single support panel with a permanent status bar at the bottom.

Show:

- iRidi remote-support heading and short explanation that the client is for receiving support;
- the device ID, with a copyable/read-only value;
- the one-time password, with refresh;
- an edit control next to the password;
- bottom connection-status bar: ready / connecting / unavailable (and an action to start the service if it is stopped).

Do **not** show the remote-ID input, Connect button, or outbound file-transfer button.

## Password menu

The password edit control must remain available even though general settings are disabled. It provides:

- acceptance method: password, click-to-accept, or both;
- verification method: one-time password, permanent password, or both;
- create/change the permanent password;
- choose the one-time-password length and refresh it;
- 2FA settings, if supported by the macOS build.

## Main menu

The menu beside the local ID is deliberately small. Keep only user-facing support options:

- language selection: **English** and **Russian** only;
- **About iRidiDesk**.

The About dialog must identify iRidiDesk, state that it is based on RustDesk, retain the RustDesk **GNU AGPLv3** notice, and link to the source repository. Do not present it as an unrelated proprietary application.

Do not add server/network, proxy, account, address-book, terminal, outgoing-control, or installation settings to this menu.

### Menu interaction

The vertical three-dot control beside the ID opens this menu immediately on click. It must work even when optional controls (audio inputs, hardware enhancements, address book, etc.) are unavailable; do not initialize optional components before showing the menu.

The pencil beside the one-time password opens a separate password menu immediately on click. Its actions are the ones listed in **Password menu** above. Do not make either control a dead icon, and do not require an extra settings window before the menu can open.

## Visual rules

- Light, restrained iRidi support-client presentation; no empty placeholder screen.
- Keep the local ID and password visually primary.
- Put the status bar on its own bottom row with a colored state dot.
- Use the branded application name **iRidiDesk** in titles and metadata.
- Do not hide the password controls merely because the general-settings policy is enabled.

## Platform notes

Windows currently requests elevation on application start via a Windows manifest. That is Windows-specific; do not copy `requireAdministrator` to macOS. If macOS must always run elevated, agree on an Apple-native authorization/packaging approach before implementing it.

The Windows package loads external Sciter UI files from `src/ui`. For macOS, ensure the equivalent UI resources are bundled and resolved from the application bundle; a white window caused by a missing UI-resource path is not acceptable.
