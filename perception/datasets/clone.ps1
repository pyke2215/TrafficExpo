# Tai video hanh trinh de gan nhan. Khong tai lai VIA hay HCMC.
# Chay tu bat ky dau:  powershell -File perception/datasets/clone.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $root "raw\journeys"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$videos = @(
    @{
        name = "hue-motorcycle.webm"
        url  = "https://upload.wikimedia.org/wikipedia/commons/3/39/Veturado_sur_motorciklo_apud_Hue.webm"
    },
    @{
        name = "mixkit-25275-pov-motorcycle.mp4"
        url  = "https://assets.mixkit.co/videos/25275/25275-720.mp4"
    },
    @{
        name = "mixkit-31974-pov-motorcycle.mp4"
        url  = "https://assets.mixkit.co/videos/31974/31974-720.mp4"
    },
    @{
        name = "pexels-19581985-motorcycle.mp4"
        url  = "https://videos.pexels.com/video-files/19581985/19581985-hd_1920_1080_30fps.mp4"
    }
)

foreach ($video in $videos) {
    $path = Join-Path $dest $video.name
    if (Test-Path $path) {
        Write-Output "da co $($video.name)"
        continue
    }
    Write-Output "tai $($video.name)"
    curl.exe -L --fail --retry 3 --retry-delay 2 -A "Mozilla/5.0" -o $path $video.url
    if ($LASTEXITCODE -ne 0) { throw "tai that bai: $($video.url)" }
}

Write-Output "xong"
Get-ChildItem $dest | ForEach-Object { "{0}  {1}" -f $_.Name, $_.Length }
