# 在 Windows PowerShell 里安装 course-ppt-maker 到 Codex 的用户技能目录。
$ErrorActionPreference = 'Stop'
$SkillName = 'course-ppt-maker'
$InstallDir = if ($env:CODEX_SKILLS_DIR) { $env:CODEX_SKILLS_DIR } else { Join-Path $HOME '.agents\skills' }
$Target = Join-Path $InstallDir $SkillName
$ZipUrl = 'https://github.com/laughing-glitch/course-ppt-maker-skill/archive/refs/heads/main.zip'

$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cpm-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp | Out-Null
try {
  Write-Host '正在下载 Skill...'
  $Zip = Join-Path $Tmp 'repo.zip'
  Invoke-WebRequest -Uri $ZipUrl -OutFile $Zip -UseBasicParsing
  Expand-Archive -Path $Zip -DestinationPath $Tmp
  $Source = Get-ChildItem -Path $Tmp -Recurse -Directory | Where-Object { $_.FullName -like "*skills\$SkillName" } | Select-Object -First 1
  if (-not $Source) { throw '下载的内容里没有找到 Skill，请检查网络后重试。' }
  New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
  if (Test-Path $Target) {
    $BackupRoot = Join-Path (Split-Path $InstallDir -Parent) 'skill-backups'
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $Backup = Join-Path $BackupRoot ("$SkillName-" + (Get-Date -Format 'yyyyMMddHHmmss'))
    Move-Item $Target $Backup
    Write-Host "已把旧版本备份到：$Backup"
  }
  Copy-Item -Path $Source.FullName -Destination $Target -Recurse
  Write-Host "安装完成：$Target"
  Write-Host ''
  Write-Host '重新打开 Codex，新建对话后这样说：'
  Write-Host '使用 course-ppt-maker，把这份讲稿做成一套直播课件。'
} finally {
  Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
