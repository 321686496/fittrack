$baseDir = "d:\app\projects\health_training\fittrack_flutter\assets\images\exercises"
$apiBase = "https://image.pollinations.ai/prompt"

# 确保目标目录存在
if (-not (Test-Path $baseDir)) {
    New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
}

# 16 个动作的卡通风格封面图配置
# 使用 flux 模型（解剖结构更准确）+ 简化 prompt + 约束 single person
$exercises = @(
    @{file="e1_barbell_bench_press.png"; prompt="single person lying on flat bench pressing barbell upward, bench press exercise, flat vector illustration, minimalist cartoon style, gym background, side view, anatomically correct, clean simple design"},
    @{file="e2_dumbbell_fly.png"; prompt="single person lying on bench with arms wide open holding dumbbells, dumbbell fly exercise, flat vector illustration, minimalist cartoon style, gym background, anatomically correct, clean simple design"},
    @{file="e3_incline_bench_press.png"; prompt="single person on incline bench pressing barbell upward, incline bench press exercise, flat vector illustration, minimalist cartoon style, gym background, anatomically correct, clean simple design"},
    @{file="e4_cable_cross.png"; prompt="single person standing between cable machines arms crossed in front, cable crossover exercise, flat vector illustration, minimalist cartoon style, gym background, anatomically correct, clean simple design"},
    @{file="e5_pull_up.png"; prompt="single person hanging from pull-up bar pulling body up, pull-up exercise, flat vector illustration, minimalist cartoon style, gym background, side view, anatomically correct, clean simple design"},
    @{file="e6_barbell_row.png"; prompt="single person bent over holding barbell rowing motion, barbell row exercise, flat vector illustration, minimalist cartoon style, gym background, side view, anatomically correct, clean simple design"},
    @{file="e7_lat_pulldown.png"; prompt="single person seated at lat pulldown machine pulling bar down to chest, lat pulldown exercise, flat vector illustration, minimalist cartoon style, gym background, anatomically correct, clean simple design"},
    @{file="e8_seated_row.png"; prompt="single person seated at cable row machine pulling handle, seated row exercise, flat vector illustration, minimalist cartoon style, gym background, anatomically correct, clean simple design"},
    @{file="e9_barbell_squat.png"; prompt="single person standing with barbell on shoulders doing squat, squat exercise, flat vector illustration, minimalist cartoon style, gym background, front view, anatomically correct, clean simple design"},
    @{file="e10_leg_press.png"; prompt="single person seated on leg press machine pushing footplate, leg press exercise, flat vector illustration, minimalist cartoon style, gym background, anatomically correct, clean simple design"},
    @{file="e11_dumbbell_shoulder_press.png"; prompt="single person seated on bench pressing dumbbells overhead, shoulder press exercise, flat vector illustration, minimalist cartoon style, gym background, anatomically correct, clean simple design"},
    @{file="e12_lateral_raise.png"; prompt="single person standing raising dumbbells out to sides at shoulder height, lateral raise exercise, flat vector illustration, minimalist cartoon style, gym background, front view, anatomically correct, clean simple design"},
    @{file="e13_dumbbell_curl.png"; prompt="single person standing curling dumbbell upward, bicep curl exercise, flat vector illustration, minimalist cartoon style, gym background, side view, anatomically correct, clean simple design"},
    @{file="e14_hammer_curl.png"; prompt="single person standing curling dumbbells with neutral grip, hammer curl exercise, flat vector illustration, minimalist cartoon style, gym background, anatomically correct, clean simple design"},
    @{file="e15_plank.png"; prompt="single person holding plank position on forearms and toes, plank exercise, flat vector illustration, minimalist cartoon style, gym background, side view, anatomically correct, clean simple design"},
    @{file="e16_crunch.png"; prompt="single person lying on floor doing abdominal crunch, crunch exercise, flat vector illustration, minimalist cartoon style, gym background, side view, anatomically correct, clean simple design"}
)

$successCount = 0
$failCount = 0

foreach ($ex in $exercises) {
    $encodedPrompt = [uri]::EscapeDataString($ex.prompt)
    # 使用 flux 模型（解剖结构更准确）
    $url = "${apiBase}/${encodedPrompt}?width=512&height=512&nologo=true&model=flux"
    $outputPath = Join-Path $baseDir $ex.file
    Write-Host "[$($exercises.IndexOf($ex) + 1)/$($exercises.Count)] Downloading $($ex.file)..."
    try {
        $response = Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing -TimeoutSec 120
        $fileSize = (Get-Item $outputPath).Length
        $hash = (Get-FileHash $outputPath -Algorithm MD5).Hash
        Write-Host "  OK: $outputPath ($fileSize bytes, MD5: $hash)"
        $successCount++
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)"
        $failCount++
    }
    Start-Sleep -Seconds 3
}

Write-Host ""
Write-Host "Done! Success: $successCount, Failed: $failCount"
