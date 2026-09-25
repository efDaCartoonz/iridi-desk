# iRidiDesk

iRidiDesk is a branded, incoming-support client based on
[RustDesk](https://github.com/rustdesk/rustdesk). It is intended for receiving
remote assistance from iRidi support staff, not as a general-purpose remote
desktop client.

## What the support client provides

- incoming remote-control sessions, text chat, and file transfer;
- macOS system audio capture through ScreenCaptureKit, without microphone access;
- a compact, fixed-size support window with the device ID, one-time password,
  and connection status;
- a password menu for a permanent password, one-time-password refresh and
  length, session acceptance, password verification, and 2FA where available;
- English and Russian interface languages;
- a minimal user-facing menu with language selection and About iRidiDesk.

The client does not expose outgoing connections, server or proxy settings,
address book, terminal, or installation settings in its support interface.

## Windows 1.0.1 (64-bit & 32-bit)

iRidiDesk 1.0.1 is available for Windows 10, 11, and Windows Server in both 64-bit (`x64`) and 32-bit (`x86`) packages.

### Install and connect

1. Extract the release ZIP (`iRidiDesk-1.0.1-win64.zip` or `iRidiDesk-1.0.1-win32.zip`).
2. Run `iRidiDesk.exe`.
3. Provide the displayed device ID and one-time password to your support specialist.

## macOS 1.0.1

iRidiDesk 1.0.1 is supported and recommended on **macOS 13 Ventura or newer**.
The current macOS package is a Universal application for both Apple Silicon
(`arm64`) and Intel (`x86_64`) Macs. The application bundle includes the
iRidiDesk icon and macOS metadata. Older macOS releases may start when their
hardware supports the included architecture, but they are not a supported
release configuration.

### Install and connect

1. Open the Universal DMG and drag **iRidiDesk** to **Applications**.
2. Start iRidiDesk and give the displayed device ID and one-time password to
   your support specialist.
3. When macOS asks, allow iRidiDesk in:
   - **Privacy & Security → Screen & System Audio Recording**;
   - **Privacy & Security → Accessibility**.

Those permissions are required for a support specialist to view the screen and
control the mouse and keyboard. Screen & System Audio Recording also allows
sharing sounds played by the Mac. iRidiDesk does not request microphone access.
The client can still be used for chat or file transfer when a particular
permission is not granted.

Use the three-dot button beside the device ID to change the interface language.
Use the pencil beside the one-time password to configure password-related
options, including a permanent password.

## Building from source

Production connection parameters are supplied only at build time through a
local, ignored `.env` file. Do not commit that file or production values.

Detailed Windows and macOS build instructions, prerequisites, and output names
are in [BUILDING-iRidiDesk.md](BUILDING-iRidiDesk.md).

### Windows build (PowerShell)

```powershell
# 64-bit build (default):
.\scripts\build-release.ps1 -Version 1.0.1 -Arch x64

# 32-bit build:
.\scripts\build-release.ps1 -Version 1.0.1 -Arch x86
```

Output packages are placed in `dist/` (e.g. `dist/iRidiDesk-1.0.1-win64.zip`).

### macOS build (Bash)

```bash
./scripts/build-macos.sh 1.0.1 universal
```

The generated `.app`, `.dmg`, and `.zip` files are local build artifacts in
`dist/` and are not committed.

## Origin and license

iRidiDesk is a modified version of RustDesk and is distributed under the
[GNU AGPLv3](LICENSE-AGPL-3.0.txt), consistent with the upstream project.
Original RustDesk copyright notices are preserved.

See also:

- [NOTICE-iRidiDesk.txt](NOTICE-iRidiDesk.txt)
- [THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt)
- [SOURCE-OFFER.txt](SOURCE-OFFER.txt)
- [iRidiDesk source repository](https://github.com/efDaCartoonz/irididesk)
