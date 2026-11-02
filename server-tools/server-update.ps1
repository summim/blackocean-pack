# 블랙오션 서버 모드 자동 업데이트
# 서버시작.bat 이 서버를 켜기 직전에 매번 최신 버전을 받아서 실행합니다.
# 하는 일:
#   1. GitHub 모드팩(manifest.json)을 읽음
#   2. 서버에 필요한 모드만 내려받음 (시청자 PC 전용 모드는 건너뜀)
#   3. 같은 모드의 옛 버전, 시청자 전용 모드는 mods_old 폴더로 옮김 (지우지 않음)
#   4. 직접 넣은 다른 서버 모드는 건드리지 않음
#   5. config 는 서버에 없는 파일만 새로 넣음 (서버에서 바꾼 설정은 덮어쓰지 않음)
param(
    [string]$Root = $PSScriptRoot,
    [string]$ManifestUrl = 'https://raw.githubusercontent.com/summim/blackocean-pack/main/manifest.json'
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'   # 진행 막대를 끄면 다운로드가 훨씬 빠름

$modsDir  = Join-Path $Root 'mods'
$oldDir   = Join-Path $Root 'mods_old'
$stateFile = Join-Path $Root '.blackocean-sync.json'
$tmpDir   = Join-Path $Root '.blackocean-tmp'

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }

function Get-Sha1($path) {
    (Get-FileHash -Algorithm SHA1 -LiteralPath $path).Hash.ToLowerInvariant()
}

# "blackocean_skills-1.1.1.jar" -> "blackocean_skills", "sable-neoforge-1.21.1-2.0.6.jar" -> "sable-neoforge"
function Get-Stem($name) {
    $base = [IO.Path]::GetFileNameWithoutExtension($name)
    if ($base -match '^(.+?)-\d') { return $Matches[1].ToLowerInvariant() }
    return $base.ToLowerInvariant()
}

function Move-Old($file, $why) {
    New-Item -ItemType Directory -Force -Path $oldDir | Out-Null
    $dest = Join-Path $oldDir $file.Name
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
    Move-Item -LiteralPath $file.FullName -Destination $dest
    Say ("  - 치움   {0}  ({1})" -f $file.Name, $why) 'DarkYellow'
}

Say ''
Say '=== 블랙오션 서버 모드 업데이트 ===' 'Cyan'

# 1. manifest 읽기 (GitHub 캐시를 피하려고 주소 뒤에 시간을 붙임)
try {
    if ($ManifestUrl -like 'http*') {
        $url = $ManifestUrl + '?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $manifest = Invoke-RestMethod -UseBasicParsing -Uri $url -Headers @{ 'Cache-Control' = 'no-cache' } -TimeoutSec 30
    } else {
        $manifest = Get-Content -LiteralPath ([Uri]$ManifestUrl).LocalPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
} catch {
    Say "모드팩 정보를 못 받았어요 (인터넷 확인). 업데이트 없이 지금 모드 그대로 서버를 켭니다." 'Red'
    Say ("  이유: " + $_.Exception.Message) 'DarkGray'
    exit 0
}
Say ("모드팩 v{0}  (마인크래프트 {1}, NeoForge {2})" -f $manifest.version, $manifest.mc, $manifest.neoforge)

New-Item -ItemType Directory -Force -Path $modsDir, $tmpDir | Out-Null

$prev = @()
if (Test-Path -LiteralPath $stateFile) {
    try { $prev = @((Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json).installed) } catch { $prev = @() }
}

$serverMods = @{}     # 파일 이름(소문자) -> manifest 항목
$serverStems = @{}
$clientStems = @{}
foreach ($f in $manifest.files) {
    if (-not $f.path.StartsWith('mods/')) { continue }
    $name = $f.path.Substring(5)
    if ($f.side -eq 'client') { $clientStems[(Get-Stem $name)] = $true; continue }
    $serverMods[$name.ToLowerInvariant()] = $f
    $serverStems[(Get-Stem $name)] = $true
}

# 2. 필요한 모드 받기
$added = 0; $failed = 0
foreach ($key in $serverMods.Keys) {
    $f = $serverMods[$key]
    $name = $f.path.Substring(5)
    $dest = Join-Path $modsDir $name
    if ((Test-Path -LiteralPath $dest) -and ((Get-Sha1 $dest) -eq $f.sha1)) { continue }
    $tmp = Join-Path $tmpDir $name
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $f.url -OutFile $tmp -TimeoutSec 300
        if ((Get-Sha1 $tmp) -ne $f.sha1) { throw "파일이 깨졌어요 (확인값 불일치)" }
        Move-Item -LiteralPath $tmp -Destination $dest -Force
        Say ("  + 설치   {0}" -f $name) 'Green'
        $added++
    } catch {
        Say ("  ! 실패   {0}  ({1})" -f $name, $_.Exception.Message) 'Red'
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
        $failed++
    }
}

# 3. 옛 버전·시청자 전용 모드 치우기
$moved = 0
foreach ($file in @(Get-ChildItem -LiteralPath $modsDir -File -Filter '*.jar')) {
    $lower = $file.Name.ToLowerInvariant()
    if ($serverMods.ContainsKey($lower)) { continue }
    $stem = Get-Stem $file.Name
    if ($prev -contains $file.Name) { Move-Old $file '모드팩에서 빠짐'; $moved++ }
    elseif ($serverStems.ContainsKey($stem)) { Move-Old $file '옛 버전'; $moved++ }
    elseif ($clientStems.ContainsKey($stem)) { Move-Old $file '시청자 PC 전용 모드'; $moved++ }
}

# 4. config: 서버에 없는 파일만
foreach ($f in $manifest.files) {
    if (-not $f.path.StartsWith('config/') -or $f.side -eq 'client') { continue }
    $dest = Join-Path $Root ($f.path -replace '/', '\')
    if (Test-Path -LiteralPath $dest) { continue }
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
        Invoke-WebRequest -UseBasicParsing -Uri $f.url -OutFile $dest -TimeoutSec 60
        Say ("  + 설정   {0}" -f $f.path) 'Green'
    } catch {
        Say ("  ! 설정 실패 {0}" -f $f.path) 'Red'
    }
}

Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
$installed = @($serverMods.Values | ForEach-Object { $_.path.Substring(5) })
@{ version = $manifest.version; installed = $installed } | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding UTF8

if ($added -eq 0 -and $moved -eq 0 -and $failed -eq 0) {
    Say '이미 최신이에요.' 'Green'
} else {
    Say ("완료: 설치 {0}개, 치움 {1}개, 실패 {2}개" -f $added, $moved, $failed) $(if ($failed -gt 0) { 'Yellow' } else { 'Green' })
}
if ($failed -gt 0) { exit 1 }
exit 0
