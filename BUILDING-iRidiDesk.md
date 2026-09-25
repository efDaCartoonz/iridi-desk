# Building iRidiDesk

iRidiDesk is a modified incoming-support build based on RustDesk.

## License

This source package is provided under the GNU AGPLv3 terms, following the original RustDesk license.

## Build-time parameters

Production server parameters are not stored in this source package.

Create a local `.env` file based on `.env.example`:

```bash
cp .env.example .env
```

Do not commit production .env files.

## Windows Release Builds (x64 and x86)

### Prerequisites

1. Install the Rust toolchain with MSVC targets:
   ```bash
   rustup toolchain install stable-x86_64-pc-windows-msvc
   rustup target add x86_64-pc-windows-msvc i686-pc-windows-msvc
   ```

2. Install **Desktop development with C++** and **MSVC v143 – VS 2022 C++ x64/x86 build tools** via Visual Studio Installer.

3. Install static C/C++ dependencies via vcpkg:
   ```bash
   vcpkg install libsodium:x64-windows-static libvpx:x64-windows-static libyuv:x64-windows-static opus:x64-windows-static aom:x64-windows-static libjpeg-turbo:x64-windows-static
   vcpkg install libsodium:x86-windows-static libvpx:x86-windows-static libyuv:x86-windows-static opus:x86-windows-static aom:x86-windows-static libjpeg-turbo:x86-windows-static
   ```

4. Verify build readiness:
   ```powershell
   .\scripts\Test-BuildPrerequisites.ps1
   ```

### Building release packages

Build from PowerShell:

```powershell
# 64-bit Windows release (default)
.\scripts\build-release.ps1 -Version 1.0.1 -Arch x64

# 32-bit Windows release
.\scripts\build-release.ps1 -Version 1.0.1 -Arch x86

# Or build both architectures
.\scripts\build-release.ps1 -Version 1.0.1 -Arch all
```

The script builds `iRidiDesk.exe`, packages the service, Sciter runtime and UI files, producing:
- `dist/iRidiDesk-1.0.1-win64.zip`
- `dist/iRidiDesk-1.0.1-win32.zip`

The `.env` file stays local and is never packaged or committed.

## macOS Release Build (Apple Silicon ARM64, Intel x86_64, Universal)

### Prerequisites

1. Install Rust targets:
   ```bash
   rustup target add aarch64-apple-darwin x86_64-apple-darwin
   ```

2. Install build tools via Homebrew:
   ```bash
   brew install nasm yasm pkg-config
   ```

3. Install C/C++ dependencies via vcpkg:
   ```bash
   export VCPKG_ROOT=$HOME/vcpkg
   vcpkg install libvpx:arm64-osx libyuv:arm64-osx opus:arm64-osx aom:arm64-osx libjpeg-turbo:arm64-osx
   vcpkg install libvpx:x64-osx libyuv:x64-osx opus:x64-osx aom:x64-osx libjpeg-turbo:x64-osx
   ```

4. Universal `libsciter.dylib` is placed in `res/libsciter.dylib`.

### Building packages

Run the build script:

```bash
# Build Universal binary (.app, .dmg, .zip)
./scripts/build-macos.sh 1.0.1 universal

# Or target specific architectures:
./scripts/build-macos.sh 1.0.1 arm64
./scripts/build-macos.sh 1.0.1 x86_64
```

The output bundles and disk images are generated in `dist/`:
- `iRidiDesk-1.0.1-macos-arm64.dmg` & `.zip`
- `iRidiDesk-1.0.1-macos-x86_64.dmg` & `.zip`
- `iRidiDesk-1.0.1-macos-universal.dmg` & `.zip`

## Notes

This build is intended only for receiving incoming iRidi remote support connections.
Outgoing connection UI and server configuration UI are intentionally removed or hidden.
