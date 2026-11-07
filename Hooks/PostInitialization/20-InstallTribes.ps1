#Requires -Modules Logging
#Requires -Modules Hooks
#Requires -Modules OverlayFS

# Starsiege: Tribes has no official server download. Use an existing install in /config/Server, or
# set TRIBES_ARCHIVE_URL to a zip of the game folder (the one that contains Tribes.exe, at the zip
# root or in a single top-level folder), e.g. a LANCommander archive.

Invoke-Hook "PreInstallTribes"

$exe = Join-Path $Env:SERVER_DIR 'Tribes.exe'

if (Test-Path -Path $exe) {
    Write-Log "Tribes found in $Env:SERVER_DIR"
} elseif ($Env:TRIBES_ARCHIVE_URL) {
    Write-Log "Downloading Tribes from $Env:TRIBES_ARCHIVE_URL"

    $zip     = '/tmp/tribes.zip'
    $extract = '/tmp/tribes'

    curl -fL --retry 3 --output $zip "$Env:TRIBES_ARCHIVE_URL"
    if ($LASTEXITCODE -ne 0) { throw "Download failed: $Env:TRIBES_ARCHIVE_URL" }

    Remove-Item -Recurse -Force -Path $extract -ErrorAction SilentlyContinue
    unzip -q -o $zip -d $extract
    if ($LASTEXITCODE -ne 0) { throw "Could not extract $zip" }

    # Accept Tribes.exe at the zip root or inside one top-level folder
    $root = Get-ChildItem -Path $extract -Filter 'Tribes.exe' -Recurse -File -Depth 1 |
        Select-Object -First 1 -ExpandProperty Directory
    if (-not $root) { throw "Tribes.exe not found in $Env:TRIBES_ARCHIVE_URL" }

    New-Item -ItemType Directory -Path $Env:SERVER_DIR -Force | Out-Null
    Move-Item -Force -Path (Join-Path $root.FullName '*') -Destination $Env:SERVER_DIR
    chown -R "$($Env:UID):$($Env:GID)" $Env:SERVER_DIR

    Remove-Item -Recurse -Force -Path $zip, $extract

    # The overlay was mounted before Server/ was populated, and overlayfs doesn't reliably show
    # lower-dir changes made while mounted.
    mountpoint -q $Env:SERVER_ROOT
    if ($LASTEXITCODE -eq 0) {
        umount $Env:SERVER_ROOT
        Remove-Item -Path "$Env:WORK_DIR/*" -Recurse -Force -ErrorAction SilentlyContinue
        Mount-Overlay -MountPoint $Env:SERVER_ROOT -LowerDir $Env:SERVER_DIR -UpperDir $Env:OVERLAY_DIR -WorkDir $Env:WORK_DIR -RequireEmptyWorkDir -OverlayOption "xino=on"
        Write-Log "OverlayFS remounted"
    }

    Write-Log "Tribes installed"
} else {
    Write-Log -Level Error "Tribes.exe not found in $Env:SERVER_DIR. Copy a Tribes install there or set TRIBES_ARCHIVE_URL."
}

Invoke-Hook "PostInstallTribes"

Set-Location $Env:SERVER_ROOT
