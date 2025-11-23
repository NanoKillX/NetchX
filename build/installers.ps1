[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    [string]$Platform = 'Any CPU',
    [string]$OutputRoot = 'release',
    [string]$PackageName = 'NetchX',
    [string]$Publisher = 'NanoKillX Software'
)

$ErrorActionPreference = 'Stop'

function Write-Section {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path $scriptRoot -Parent
$projectFile = Join-Path $repoRoot 'Netch\Netch.csproj'
$versionSource = Join-Path $repoRoot 'Netch\Controllers\UpdateChecker.cs'

if (-not (Test-Path $versionSource)) {
    throw "Unable to locate version source at $versionSource"
}

$versionMatch = Select-String -Path $versionSource -Pattern 'AssemblyVersion\s*=\s*@?\"([\d\.]+)\"' -AllMatches | Select-Object -First 1
if (-not $versionMatch) {
    throw 'Could not determine assembly version from UpdateChecker.cs'
}

$assemblyVersion = $versionMatch.Matches[0].Groups[1].Value
$appxVersion = "$assemblyVersion.0"

$releaseRoot = Join-Path $repoRoot $OutputRoot
$payloadDir = Join-Path $releaseRoot 'payload'
$payloadBin = Join-Path $payloadDir 'bin'
$assetDir = Join-Path $releaseRoot 'assets'
$manifestDir = Join-Path $releaseRoot 'manifest'
$configDir = Join-Path $releaseRoot 'config'
$msixLayout = Join-Path $releaseRoot 'msix'

$msixOutput = Join-Path $releaseRoot "$PackageName.msix"
$exeOutput = Join-Path $releaseRoot "$PackageName-Setup.exe"

Write-Section 'Preparing output folders'
$pathsToCreate = @($payloadDir, $payloadBin, $assetDir, $manifestDir, $configDir, $msixLayout)
foreach ($path in $pathsToCreate) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path
    }
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

Write-Section 'Building application'
$publishArgs = @(
    'publish',
    $projectFile,
    '-c', $Configuration,
    "-p:Platform=$Platform",
    '-p:PublishSingleFile=false',
    '-p:SelfContained=false',
    '-p:IncludeNativeLibrariesForSelfExtract=false',
    '-p:PublishReadyToRun=false',
    '-p:AppendTargetFrameworkToOutputPath=false',
    '-p:AppendRuntimeIdentifierToOutputPath=false',
    '-o', (Join-Path $payloadDir '.')
)
& dotnet @publishArgs

Write-Section 'Copying storage assets and native helpers'
$storageRoot = Join-Path $repoRoot 'Storage'
$storageItems = @('i18n', 'mode', 'stun.txt', 'nfdriver.sys', 'aiodns.conf', 'tun2socks.bin', 'README.md')
foreach ($item in $storageItems) {
    $source = Join-Path $storageRoot $item
    if (Test-Path $source) {
        $destination = ($item -like '*.txt' -or $item -like '*.sys' -or $item -like '*.conf' -or $item -like '*.bin' -or $item -like '*.md') ? $payloadBin : $payloadDir
        Copy-Item -Recurse -Force $source $destination
    }
}

$otherRelease = Join-Path $repoRoot 'Other\release'
if (-not (Test-Path $otherRelease)) {
    $otherBuild = Join-Path $repoRoot 'Other\build.ps1'
    if (Test-Path $otherBuild) {
        Write-Section 'Building additional binaries (Other/build.ps1)'
        & $otherBuild
    }
}
if (Test-Path $otherRelease) {
    Copy-Item -Recurse -Force (Join-Path $otherRelease '*') $payloadBin
}

Write-Section 'Generating icons and logo assets'
$sourceIcon = Join-Path $repoRoot 'Netch\Resources\Netch.ico'
$targetIcon = Join-Path $assetDir 'NetchX.ico'
Copy-Item -Force $sourceIcon $targetIcon

Add-Type -AssemblyName System.Drawing
function New-LogoAsset {
    param(
        [string]$IconPath,
        [string]$OutputPath,
        [int]$Size
    )
    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bmp)
    $graphics.Clear([System.Drawing.Color]::FromArgb(20,20,24))
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($IconPath)
    $graphics.DrawIcon($icon, 0, 0)
    $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bmp.Dispose()
}

New-LogoAsset -IconPath $sourceIcon -OutputPath (Join-Path $assetDir 'Logo44.png') -Size 44
New-LogoAsset -IconPath $sourceIcon -OutputPath (Join-Path $assetDir 'Logo124.png') -Size 124
New-LogoAsset -IconPath $sourceIcon -OutputPath (Join-Path $assetDir 'Logo256.png') -Size 256

Write-Section 'Writing installer metadata'
$installerConfig = [ordered]@{
    packageName   = $PackageName
    publisher     = $Publisher
    configuration = $Configuration
    platform      = $Platform
    version       = $assemblyVersion
    payloadFolder = 'payload'
    manifestPath  = 'manifest/AppxManifest.xml'
    msixOutput    = "$PackageName.msix"
    exeOutput     = "$PackageName-Setup.exe"
    icon          = 'assets/NetchX.ico'
    logos         = @{ logo44 = 'assets/Logo44.png'; logo124 = 'assets/Logo124.png'; logo256 = 'assets/Logo256.png' }
}
$installerConfig | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $configDir 'installer-config.json')

$appxManifestPath = Join-Path $manifestDir 'AppxManifest.xml'
$appxTemplate = @"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
         IgnorableNamespaces="uap rescap">
  <Identity Name="$PackageName"
            Publisher="CN=$Publisher"
            Version="$appxVersion"
            ProcessorArchitecture="x64" />
  <Properties>
    <DisplayName>$PackageName</DisplayName>
    <PublisherDisplayName>$Publisher</PublisherDisplayName>
    <Description>Modern optimized proxy client for Windows.</Description>
    <Logo>Assets\\Logo44.png</Logo>
    <Square150x150Logo>Assets\\Logo124.png</Square150x150Logo>
    <Square44x44Logo>Assets\\Logo44.png</Square44x44Logo>
  </Properties>
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0" MaxVersionTested="10.0.19045.0" />
  </Dependencies>
  <Resources>
    <Resource Language="en-us" />
  </Resources>
  <Applications>
    <Application Id="$PackageName"
                 Executable="Netch.exe"
                 EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="$PackageName"
                          Description="Modern optimized proxy client for Windows."
                          BackgroundColor="transparent"
                          Square150x150Logo="Assets\\Logo124.png"
                          Square44x44Logo="Assets\\Logo44.png">
        <uap:DefaultTile Square310x310Logo="Assets\\Logo256.png"
                         Wide310x150Logo="Assets\\Logo256.png"
                         Square71x71Logo="Assets\\Logo44.png" />
        <uap:SplashScreen Image="Assets\\Logo256.png" />
      </uap:VisualElements>
    </Application>
  </Applications>
  <Capabilities>
    <Capability Name="internetClient" />
    <rescap:Capability Name="runFullTrust" />
  </Capabilities>
</Package>
"@
$appxTemplate | Set-Content -Encoding UTF8 $appxManifestPath

$setupScriptPath = Join-Path $configDir 'setup.iss'
$setupScript = @"
#define MyAppName "$PackageName"
#define MyAppVersion "$assemblyVersion"
#define MyAppPublisher "$Publisher"
#define MyAppExeName "Netch.exe"
#define SourcePayload "..\\payload"
#define AssetRoot "..\\assets"

[Setup]
AppId={{2EAB3702-0B77-4DBF-9E43-3B0C44D1A3E1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppComments=Modern optimized proxy client for Windows.
DefaultDirName={pf}\\$PackageName
DefaultGroupName={#MyAppName}
DisableDirPage=no
OutputDir=..\\
OutputBaseFilename=$PackageName-Setup
SetupIconFile={#AssetRoot}\\NetchX.ico
UninstallDisplayIcon={app}\\{#MyAppExeName}
ArchitecturesInstallIn64BitMode=x64
Compression=lzma
SolidCompression=yes
WizardStyle=modern
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "{#SourcePayload}\\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{commondesktop}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"; Tasks: desktopicon; WorkingDir: "{app}"

[Run]
Filename: "{app}\\{#MyAppExeName}"; Description: "Launch $PackageName"; Flags: nowait postinstall skipifsilent
"@
$setupScript | Set-Content -Encoding UTF8 $setupScriptPath

Write-Section 'Staging MSIX layout'
$assetsTarget = Join-Path $msixLayout 'Assets'
New-Item -ItemType Directory -Force -Path $assetsTarget | Out-Null
Copy-Item -Force (Join-Path $assetDir 'Logo*.png') $assetsTarget
Copy-Item -Force $appxManifestPath (Join-Path $msixLayout 'AppxManifest.xml')
Copy-Item -Recurse -Force (Join-Path $payloadDir '*') $msixLayout

Write-Section 'Packaging commands'
$makeAppx = 'MakeAppx.exe pack /h SHA256 /d "{0}" /p "{1}"' -f $msixLayout, $msixOutput
$iscc = 'iscc.exe "{0}"' -f $setupScriptPath
"MSIX: $makeAppx" | Set-Content -Encoding UTF8 (Join-Path $releaseRoot 'package-msix.cmd')
"EXE : $iscc" | Add-Content -Encoding UTF8 (Join-Path $releaseRoot 'package-msix.cmd')
"$iscc" | Set-Content -Encoding UTF8 (Join-Path $releaseRoot 'package-exe.cmd')

Write-Section 'Done'
Write-Host "Installer assets staged in $releaseRoot" -ForegroundColor Green
Write-Host "Run the following on Windows:" -ForegroundColor Yellow
Write-Host "  $makeAppx" -ForegroundColor Yellow
Write-Host "  $iscc" -ForegroundColor Yellow
