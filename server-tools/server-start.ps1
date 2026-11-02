# 블랙오션 서버 시작기 (서버시작.bat 이 매번 최신으로 받아서 실행)
#   1. 모드 업데이트 (server-update.ps1)
#   2. NeoForge 서버 실행
#   3. 서버가 꺼지면 10초 뒤 1번부터 다시 (창을 닫거나 Ctrl+C 로 완전히 종료)
param([string]$Root = $(if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }))

$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
Set-Location -LiteralPath $Root

$base = 'https://raw.githubusercontent.com/summim/blackocean-pack/main/server-tools/'
$updater = Join-Path $Root '.blackocean-update.ps1'

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }

function Find-NeoArgs {
    $dir = Join-Path $Root 'libraries\net\neoforged\neoforge'
    if (-not (Test-Path -LiteralPath $dir)) { return $null }
    # 버전 폴더가 여러 개면 가장 최신 (숫자로 비교)
    $best = Get-ChildItem -LiteralPath $dir -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'win_args.txt') } |
        Sort-Object { try { [version]($_.Name -replace '[^0-9.].*$', '') } catch { [version]'0.0' } } |
        Select-Object -Last 1
    if ($best) { return (Join-Path $best.FullName 'win_args.txt') }
    return $null
}

while ($true) {
    Say ''
    Say '[1/2] 모드 업데이트 확인 중...' 'Cyan'
    try {
        $tmp = $updater + '.tmp'
        Invoke-WebRequest -UseBasicParsing -Uri ($base + 'server-update.ps1?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) -OutFile $tmp -TimeoutSec 30
        Move-Item -Force -LiteralPath $tmp -Destination $updater
    } catch {
        Say '  업데이트 도구를 새로 못 받았어요. 저장된 것을 씁니다.' 'DarkYellow'
    }
    if (Test-Path -LiteralPath $updater) {
        # 따로 실행해야 업데이트 도구가 끝나도 이 창이 닫히지 않음
        & powershell -NoProfile -ExecutionPolicy Bypass -File $updater -Root $Root
    } else {
        Say '  업데이트 도구가 없어서 지금 모드 그대로 켭니다.' 'DarkYellow'
    }

    Say ''
    Say '[2/2] 서버 시작' 'Cyan'
    $neoArgs = Find-NeoArgs
    if (-not $neoArgs) {
        Say '[오류] NeoForge 서버 파일을 못 찾았어요.' 'Red'
        Say '  서버시작.bat 을 서버 폴더 (run.bat, libraries 폴더가 있는 곳) 에 넣었는지 확인해 주세요.' 'Red'
        Say ('  지금 위치: ' + $Root) 'DarkGray'
        exit 1
    }
    if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
        Say '[오류] java 를 찾을 수 없어요. 자바 21 을 설치해 주세요 (https://adoptium.net).' 'Red'
        exit 1
    }

    $rel = $neoArgs.Substring($Root.TrimEnd('\').Length + 1)
    $javaArgs = @()
    if (Test-Path -LiteralPath (Join-Path $Root 'user_jvm_args.txt')) { $javaArgs += '@user_jvm_args.txt' }
    $javaArgs += ('@' + $rel)
    $javaArgs += 'nogui'
    Say ('  java ' + ($javaArgs -join ' ')) 'DarkGray'
    & java @javaArgs
    $code = $LASTEXITCODE

    Say ''
    if ($env:BLACKOCEAN_NOLOOP) { Say ('서버 종료 (코드 ' + $code + ')'); exit $code }
    Say '서버가 꺼졌어요. 10초 뒤 업데이트 확인 후 다시 켭니다.' 'Yellow'
    Say '완전히 끄려면 지금 이 창을 닫거나 Ctrl+C 를 누르세요.' 'Yellow'
    Start-Sleep -Seconds 10
}
