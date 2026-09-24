param(
    [Parameter(Mandatory = $true)]
    [string]$Version
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

$sciterRuntime = Join-Path $projectRoot 'third_party\sciter\win32\sciter.dll'
if (-not (Test-Path -LiteralPath $sciterRuntime)) {
    throw 'The x86 Sciter runtime is required at third_party\sciter\win32\sciter.dll before building a release package.'
}

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    throw 'Rust toolchain is required. Install Rust, then add i686-pc-windows-msvc with rustup.'
}

$gitCommand = 'C:\Program Files\Git\cmd\git.exe'
if (-not (Test-Path -LiteralPath $gitCommand)) {
    throw 'Git for Windows is required to obtain RustDesk build dependencies.'
}
$env:Path = (Split-Path -Parent $gitCommand) + ';' + $env:Path

Push-Location $projectRoot
try {
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
    $libsodium = if ($vcpkgRoot) { Join-Path $vcpkgRoot 'installed\x86-windows-static\lib\libsodium.lib' }
    if ([string]::IsNullOrWhiteSpace($vcpkgRoot) -or -not (Test-Path -LiteralPath $libsodium)) {
        throw 'The x86 static libsodium library is required at %VCPKG_ROOT%\installed\x86-windows-static\lib\libsodium.lib.'
    }
    $env:IRIDI_VCVARS_VERSION = ($msvc.Name.Split('.')[0..1] -join '.')
    $env:CARGO_TARGET_I686_PC_WINDOWS_MSVC_LINKER = Join-Path $PSScriptRoot 'link-i686.cmd'
    $cargoCommand = 'call "' + $vcVars + '" x64 -vcvars_ver=' + $env:IRIDI_VCVARS_VERSION + ' >nul && set "VCPKG_ROOT=' + $vcpkgRoot + '" && cargo +stable-x86_64-pc-windows-msvc build --release --target i686-pc-windows-msvc'
    cmd.exe /d /s /c $cargoCommand
    if ($LASTEXITCODE -ne 0) {
        throw "Cargo build failed with exit code $LASTEXITCODE"
    }

    $source = Join-Path $projectRoot 'target\i686-pc-windows-msvc\release'
    $package = Join-Path $projectRoot 'dist\iRidiDesk-win32'
    $archive = Join-Path $projectRoot ("dist\iRidiDesk-" + $Version + "-win32.zip")

    Remove-Item -LiteralPath $package -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $package -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $source 'rustdesk.exe') -Destination (Join-Path $package 'iRidiDesk.exe')
    Copy-Item -LiteralPath (Join-Path $source 'service.exe') -Destination $package
    Copy-Item -LiteralPath $sciterRuntime -Destination $package
    $uiDestinationRoot = Join-Path $package 'src'
    New-Item -ItemType Directory -Path $uiDestinationRoot -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot 'src\ui') -Destination $uiDestinationRoot -Recurse

    Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
    Compress-Archive -LiteralPath (Join-Path $package '*') -DestinationPath $archive -CompressionLevel Optimal
    Write-Host "Release package created: $archive"
}
finally {
    Pop-Location
}
