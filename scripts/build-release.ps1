param(
    [Parameter(Mandatory = $false)]
    [string]$Version = '1.0.1',
    [ValidateSet('x64', 'x86', 'all', 'win64', 'win32')]
    [string]$Arch = 'x64'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $projectRoot '.env'

if (-not (Test-Path -LiteralPath $envFile)) {
    throw 'Create a local .env from .env.example before building. Do not commit it.'
}

Get-Content -LiteralPath $envFile | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith('#')) { return }
    $match = [regex]::Match($line, '^(?<name>IRIDI_[A-Z_]+)=(?<value>.*)$')
    if ($match.Success) {
        Set-Item -Path ("Env:" + $match.Groups['name'].Value) -Value $match.Groups['value'].Value
    }
}

$required = @('IRIDI_RENDEZVOUS_SERVER', 'IRIDI_RELAY_SERVER', 'IRIDI_PUB_KEY')
foreach ($name in $required) {
    if ([string]::IsNullOrWhiteSpace((Get-Item -Path ("Env:" + $name) -ErrorAction SilentlyContinue).Value)) {
        throw "$name is required in .env"
    }
}

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    throw 'Rust toolchain is required. Install Rust via rustup.'
}

$gitCommand = 'C:\Program Files\Git\cmd\git.exe'
if (Test-Path -LiteralPath $gitCommand) {
    $env:Path = (Split-Path -Parent $gitCommand) + ';' + $env:Path
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere)) {
    throw 'Microsoft C++ Build Tools are required for the Windows linker.'
}
$vsInstallations = @((& $vswhere -products * -version '[17.0,18.0)' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json | Out-String | ConvertFrom-Json))
$msvc = $null
$vcVars = $null
foreach ($vs in $vsInstallations) {
    $candidateVcVars = Join-Path $vs.installationPath 'VC\Auxiliary\Build\vcvarsall.bat'
    $candidateMsvc = Get-ChildItem (Join-Path $vs.installationPath 'VC\Tools\MSVC') -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            (Test-Path (Join-Path $_.FullName 'lib\x64\msvcrt.lib')) -and
            (Test-Path (Join-Path $_.FullName 'lib\x86\msvcrt.lib'))
        } |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if ((Test-Path -LiteralPath $candidateVcVars) -and $candidateMsvc) {
        $vcVars = $candidateVcVars
        $msvc = $candidateMsvc
        break
    }
}
if ($null -eq $msvc) {
    throw 'Install the MSVC v143 C++ x64/x86 build tools component before building.'
}

$vcpkgRoot = $env:VCPKG_ROOT
if ([string]::IsNullOrWhiteSpace($vcpkgRoot)) {
    if (Test-Path -LiteralPath 'C:\dev\vcpkg') {
        $vcpkgRoot = 'C:\dev\vcpkg'
        $env:VCPKG_ROOT = $vcpkgRoot
    }
    else {
        throw 'Set %VCPKG_ROOT% before building.'
    }
}

$env:IRIDI_VCVARS_VERSION = ($msvc.Name.Split('.')[0..1] -join '.')

$targetsToBuild = switch ($Arch) {
    'x64'   { @('x64') }
    'win64' { @('x64') }
    'x86'   { @('x86') }
    'win32' { @('x86') }
    'all'   { @('x64', 'x86') }
}

Push-Location $projectRoot
try {
    foreach ($target in $targetsToBuild) {
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host " Building iRidiDesk for Windows ($target)" -ForegroundColor Cyan
        Write-Host " Version: $Version" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor Cyan

        if ($target -eq 'x64') {
            $cargoTarget = 'x86_64-pc-windows-msvc'
            $pkgSuffix = 'win64'
            $sciterRuntime = Join-Path $projectRoot 'third_party\sciter\win64\sciter.dll'
            $libsodium = Join-Path $vcpkgRoot 'installed\x64-windows-static\lib\libsodium.lib'
            if (-not (Test-Path -LiteralPath $sciterRuntime)) {
                Write-Host "Downloading 64-bit Sciter runtime..." -ForegroundColor Yellow
                New-Item -ItemType Directory -Path (Split-Path -Parent $sciterRuntime) -Force | Out-Null
                Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.win/x64/sciter.dll' -OutFile $sciterRuntime
            }
            if (-not (Test-Path -LiteralPath $libsodium)) {
                throw "The x64 static libsodium library is required at $libsodium."
            }

            $cargoCommand = 'call "' + $vcVars + '" x64 -vcvars_ver=' + $env:IRIDI_VCVARS_VERSION + ' >nul && set "VCPKG_ROOT=' + $vcpkgRoot + '" && cargo +stable-x86_64-pc-windows-msvc build --release --target ' + $cargoTarget
        }
        else {
            $cargoTarget = 'i686-pc-windows-msvc'
            $pkgSuffix = 'win32'
            $sciterRuntime = Join-Path $projectRoot 'third_party\sciter\win32\sciter.dll'
            $libsodium = Join-Path $vcpkgRoot 'installed\x86-windows-static\lib\libsodium.lib'
            if (-not (Test-Path -LiteralPath $sciterRuntime)) {
                Write-Host "Downloading 32-bit Sciter runtime..." -ForegroundColor Yellow
                New-Item -ItemType Directory -Path (Split-Path -Parent $sciterRuntime) -Force | Out-Null
                Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.win/x32/sciter.dll' -OutFile $sciterRuntime
            }
            if (-not (Test-Path -LiteralPath $libsodium)) {
                throw "The x86 static libsodium library is required at $libsodium."
            }

            $dynamicLinker = Join-Path $PSScriptRoot 'link-i686.cmd'
            "@echo off`r`ncall `"$vcVars`" x64_x86 -vcvars_ver=%IRIDI_VCVARS_VERSION% >nul`r`nlink.exe %*`r`n" | Set-Content -Path $dynamicLinker -Encoding ASCII
            $env:CARGO_TARGET_I686_PC_WINDOWS_MSVC_LINKER = $dynamicLinker

            $cargoCommand = 'call "' + $vcVars + '" x64 -vcvars_ver=' + $env:IRIDI_VCVARS_VERSION + ' >nul && set "VCPKG_ROOT=' + $vcpkgRoot + '" && cargo +stable-x86_64-pc-windows-msvc build --release --target ' + $cargoTarget
        }

        cmd.exe /d /s /c $cargoCommand
        if ($LASTEXITCODE -ne 0) {
            throw "Cargo build failed for $target with exit code $LASTEXITCODE"
        }

        $source = Join-Path $projectRoot "target\$cargoTarget\release"
        $package = Join-Path $projectRoot "dist\iRidiDesk-$pkgSuffix"
        $archive = Join-Path $projectRoot ("dist\iRidiDesk-$Version-$pkgSuffix.zip")

        Remove-Item -LiteralPath $package -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $package -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $source 'rustdesk.exe') -Destination (Join-Path $package 'iRidiDesk.exe')
        Copy-Item -LiteralPath (Join-Path $source 'service.exe') -Destination $package
        Copy-Item -LiteralPath $sciterRuntime -Destination $package
        $uiDestinationRoot = Join-Path $package 'src'
        New-Item -ItemType Directory -Path $uiDestinationRoot -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $projectRoot 'src\ui') -Destination $uiDestinationRoot -Recurse

        Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
        Compress-Archive -Path (Join-Path $package '*') -DestinationPath $archive -CompressionLevel Optimal
        Write-Host "Release package created: $archive" -ForegroundColor Green
    }
}
finally {
    Pop-Location
}

