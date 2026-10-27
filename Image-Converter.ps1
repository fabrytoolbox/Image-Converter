# Image-Converter.ps1 - v2.0
# Convertitore immagini interattivo a livelli (WebP, PNG, JPEG)
# Auto-FFmpeg, Log su file, Supporto Ricorsivo

$ErrorActionPreference = "Continue"
$host.UI.RawUI.WindowTitle = "Image Converter - Fabry Toolbox"

# ============================================
# AUTO-FFMPEG
# ============================================
$script:workDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$script:ffmpegPath = Join-Path $script:workDir "ffmpeg.exe"

function Initialize-FFmpeg {
    if (Test-Path $script:ffmpegPath) { return $script:ffmpegPath }
    
    # Cerca nel PATH
    try {
        $sysPath = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
        if ($sysPath) { return $sysPath }
    } catch {}

    # Se non c'è, proponi download
    Write-Host "`n[!] FFmpeg non trovato nel sistema." -ForegroundColor Yellow
    $resp = Read-Host "Vuoi scaricarlo automaticamente? (~80 MB) (S/N)"
    if ($resp -ne 'S' -and $resp -ne 's') { return $null }
    
    Write-Host "`nDownload in corso..." -ForegroundColor Cyan
    $zip = Join-Path $env:TEMP "ffmpeg_dl.zip"
    $ext = Join-Path $env:TEMP "ffmpeg_ext"
    try {
        $url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
        Write-Host "Estrazione..." -ForegroundColor Cyan
        Expand-Archive -Path $zip -DestinationPath $ext -Force
        Get-ChildItem -Path $ext -Include "ffmpeg.exe", "ffprobe.exe" -Recurse | ForEach-Object {
            Move-Item $_.FullName $script:workDir -Force
        }
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
        Remove-Item $ext -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] FFmpeg scaricato." -ForegroundColor Green
        return $script:ffmpegPath
    } catch {
        Write-Host "[X] Errore download: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# ============================================
# FUNZIONI DI UTILITÀ
# ============================================
function Write-Step { param([string]$Message, [string]$Color = "Cyan") Write-Host ""; Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] $Message" -ForegroundColor $Color }
function Write-Success { param([string]$Message) Write-Host "  [OK] $Message" -ForegroundColor Green }
function Write-ErrorMsg { param([string]$Message) Write-Host "  [X] $Message" -ForegroundColor Red }
function Write-WarningMsg { param([string]$Message) Write-Host "  [!] $Message" -ForegroundColor Yellow }
function Write-Info { param([string]$Message) Write-Host "  [i] $Message" -ForegroundColor Cyan }

function Format-FileSize {
    param([long]$Size)
    if ($Size -gt 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    elseif ($Size -gt 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    elseif ($Size -gt 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    else { return "$Size bytes" }
}

$script:logFile = $null
function Write-Log { 
    param([string]$Message, [string]$Level="INFO")
    if ($script:logFile) {
        $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
        Add-Content -Path $script:logFile -Value $line -Encoding UTF8
    }
}

# ============================================
# AVVIO
# ============================================
Clear-Host
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "     IMAGE CONVERTER - FABRY TOOLBOX v2.0" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta

Write-Step "LIVELLO 1: Verifica FFmpeg" "Yellow"
$ffmpegExe = Initialize-FFmpeg
if (-not $ffmpegExe) {
    Write-ErrorMsg "FFmpeg necessario. Installalo da https://ffmpeg.org/download.html o mettilo in questa cartella."
    exit
}
Write-Success "FFmpeg pronto: $ffmpegExe"

Add-Type -AssemblyName System.Windows.Forms

# ============================================
# LIVELLO 2: Cartella
# ============================================
Write-Step "LIVELLO 2: Cartella Sorgente" "Yellow"
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Seleziona la cartella con le immagini"
if ($folderBrowser.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit }
$sourceFolder = $folderBrowser.SelectedPath
Write-Success "Cartella: $sourceFolder"

$ricorsivo = Read-Host "Includere le sottocartelle? (S/N, default N)"
if ($ricorsivo -eq 'S' -or $ricorsivo -eq 's') { $useRecurse = $true; Write-Success "Ricorsivo ON" }
else { $useRecurse = $false; Write-Success "Ricorsivo OFF" }

# Ricerca file
$searchParams = @{ Path = $sourceFolder; File = $true }
if ($useRecurse) { $searchParams.Recurse = $true }

$allFiles = Get-ChildItem @searchParams
$exts = @('.png', '.jpg', '.jpeg', '.bmp', '.tiff', '.tif', '.webp')
$imageFiles = @($allFiles | Where-Object { $exts -contains $_.Extension.ToLower() })

if ($imageFiles.Count -eq 0) {
    Write-ErrorMsg "Nessuna immagine trovata."
    exit
}

$totalSize = ($imageFiles | Measure-Object -Property Length -Sum).Sum
Write-Info "Trovate $($imageFiles.Count) immagini ($(Format-FileSize $totalSize))" 2>$null

# ============================================
# LIVELLO 3: Formato Output
# ============================================
Write-Step "LIVELLO 3: Formato Output" "Yellow"
Write-Host "  1. WebP Lossless"
Write-Host "  2. WebP Alta Qualita (90%)"
Write-Host "  3. PNG Ottimizzato"
Write-Host "  4. JPEG Alta Qualita"
Write-Host "  5. Mantieni formato (Ottimizzazione)"

do {
    $fmt = Read-Host "Scegli (1-5, default 1)"
    if ([string]::IsNullOrWhiteSpace($fmt)) { $fmt = "1" }
    if ($fmt -notmatch '^[1-5]$') { $fmt = $null }
} while (-not $fmt)

$outputFormat = switch ($fmt) { "1"{"webp"}; "2"{"webp"}; "3"{"png"}; "4"{"jpg"}; "5"{"original"} }
$isLossless = ($fmt -eq "1")

# ============================================
# LIVELLO 4: Sharpening
# ============================================
Write-Step "LIVELLO 4: Sharpening" "Yellow"
Write-Host "  1. Leggero / 2. Medio / 3. Forte / 4. Nessuno"
do {
    $shp = Read-Host "Scegli (1-4, default 1)"
    if ([string]::IsNullOrWhiteSpace($shp)) { $shp = "1" }
    if ($shp -notmatch '^[1-4]$') { $shp = $null }
} while (-not $shp)

$sharpenFilter = switch ($shp) {
    "1" { "unsharp=5:5:0.5:3:3:0.0" }
    "2" { "unsharp=5:5:1.0:5:5:0.0" }
    "3" { "unsharp=5:5:1.5:5:5:0.0" }
    default { $null }
}

# ============================================
# LIVELLO 5: Output
# ============================================
Write-Step "LIVELLO 5: Cartella Output" "Yellow"
Write-Host "  1. Sottocartella 'Convertiti'"
Write-Host "  2. Stessa cartella (sovrascrive!)"
do {
    $out = Read-Host "Scegli (1-2, default 1)"
    if ([string]::IsNullOrWhiteSpace($out)) { $out = "1" }
    if ($out -notmatch '^[1-2]$') { $out = $null }
} while (-not $out)

$outputFolder = if ($out -eq "1") { Join-Path $sourceFolder "Convertiti" } else { $sourceFolder }
if (-not (Test-Path $outputFolder)) { New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null }

# ============================================
# ESECUZIONE
# ============================================
Write-Step "AVVIO CONVERSIONE" "Green"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:logFile = Join-Path $outputFolder "image_converter_$timestamp.log"
"--- IMAGE CONVERTER LOG ---" | Set-Content $script:logFile -Encoding UTF8

$successi = 0; $fallimenti = 0; $counter = 0
$startTime = Get-Date

foreach ($file in $imageFiles) {
    $counter++
    $percentuale = [math]::Round(($counter / $imageFiles.Count) * 100, 1)
    
    $estensione = if ($outputFormat -eq "original") { $file.Extension } else { ".$outputFormat" }
    $outputFile = Join-Path $outputFolder "$($file.BaseName)$estensione"
    
    Write-Progress -Activity "Conversione..." -Status "[$counter/$($imageFiles.Count)] $percentuale% - $($file.Name)" -PercentComplete $percentuale
    Write-Host "[$counter/$($imageFiles.Count)] $($file.Name)" -ForegroundColor Gray
    
    try {
        $ffArgs = @("-i", $file.FullName)
        if ($sharpenFilter) { $ffArgs += @("-vf", $sharpenFilter) }
        
        switch ($outputFormat) {
            "webp" { 
                $ffArgs += @("-c:v", "libwebp")
                if ($isLossless) { $ffArgs += @("-lossless", "1", "-compression_level", "6") }
                else { $ffArgs += @("-q:v", "90") }
            }
            "png" { $ffArgs += @("-c:v", "png", "-compression_level", "9") }
            "jpg" { $ffArgs += @("-c:v", "mjpeg", "-q:v", "5") }
            "original" { $ffArgs += @("-c:v", "copy") }
        }
        $ffArgs += @("-y", $outputFile)
        
        $null = & $ffmpegExe $ffArgs 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0 -and (Test-Path $outputFile)) {
            $sizeAfter = (Get-Item $outputFile).Length
            $comp = [math]::Round((($file.Length - $sizeAfter) / $file.Length) * 100, 1)
            Write-Success "$($file.Name) -> $(Format-FileSize $sizeAfter) ($comp%)"
            Write-Log "OK: $($file.Name) -> $sizeAfter bytes" "OK"
            $successi++
        } else {
            Write-ErrorMsg "Errore: $($file.Name) (exit $exitCode)"
            Write-Log "ERROR: $($file.Name) (exit $exitCode)" "ERROR"
            $fallimenti++
        }
    } catch {
        Write-ErrorMsg "Eccezione: $($file.Name)"
        Write-Log "EXCEPTION: $($file.Name) - $($_.Exception.Message)" "ERROR"
        $fallimenti++
    }
}

Write-Progress -Activity "Conversione..." -Completed

# ============================================
# FINE
# ============================================
$elapsed = ((Get-Date) - $startTime).TotalSeconds
Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "              CONVERSIONE COMPLETATA" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Tempo:      $([math]::Round($elapsed, 1)) secondi" -ForegroundColor White
Write-Host "  Successi:   $successi di $($imageFiles.Count)" -ForegroundColor Green
if ($fallimenti -gt 0) { Write-Host "  Fallimenti: $fallimenti" -ForegroundColor Red }
Write-Host "  Log:        $script:logFile" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Green

# Chiedi se aprire la cartella
$apri = Read-Host "`nVuoi aprire la cartella con le immagini convertite? (S/N)"
if ($apri -eq 'S' -or $apri -eq 's') {
    if (Test-Path $outputFolder) {
        Invoke-Item $outputFolder
    } else {
        Write-Host "  [!] La cartella specificata non esiste." -ForegroundColor Yellow
    }
}
Write-Host "`nPremi un tasto per uscire..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
