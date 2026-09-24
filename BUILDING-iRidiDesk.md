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

## Windows x86 release build

Install the Rust toolchain once, including the 32-bit MSVC target:

```bash
rustup toolchain install stable-x86_64-pc-windows-msvc --force-non-host
rustup target add i686-pc-windows-msvc --toolchain stable-x86_64-pc-windows-msvc
```

On an ARM64 build computer, the script intentionally uses the x64 Rust toolchain through Windows' built-in x64 emulation: RustDesk's bundled build dependencies include x64-only libraries. Install **Desktop development with C++** and the **MSVC v143 – VS 2022 C++ x64/x86 build tools** component. The final package remains x86 (32-bit).

Then create the local release archive from PowerShell:

```powershell
.\scripts\build-release.ps1 -Version 1.0.2
```

The command builds `iRidiDesk.exe`, packages the required service, Sciter runtime and UI files, and produces `dist/iRidiDesk-<version>-win32.zip`. The `.env` file stays local and is never packaged or committed.

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
