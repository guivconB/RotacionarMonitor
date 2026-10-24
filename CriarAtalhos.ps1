# Cria os atalhos do Rotacionar Monitor na Área de Trabalho.
# Uso: clique com o botão direito > "Executar com o PowerShell"
#   ou: powershell -ExecutionPolicy Bypass -File .\CriarAtalhos.ps1 -Monitor 1 -OrientacaoB 3
param(
    [int]$Monitor = 1,       # número do monitor na lista (veja com -Listar). 0 = principal
    [int]$OrientacaoB = 3    # 1 = Retrato, 2 = Paisagem invertida, 3 = Retrato invertido
)

$script = Join-Path $PSScriptRoot 'RotacionarMonitor.ps1'
$ps     = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$desk   = [Environment]::GetFolderPath('Desktop')
$ws     = New-Object -ComObject WScript.Shell
$base   = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`" -Monitor $Monitor -OrientacaoB $OrientacaoB"

$s = $ws.CreateShortcut("$desk\Rotacionar Monitor.lnk")
$s.TargetPath   = $ps
$s.Arguments    = $base
$s.IconLocation = "$env:WINDIR\System32\shell32.dll,15"
$s.Description  = 'Abre a janela para girar o monitor'
$s.Save()

$s = $ws.CreateShortcut("$desk\Alternar Orientacao.lnk")
$s.TargetPath   = $ps
$s.Arguments    = "$base -Alternar"
$s.IconLocation = "$env:WINDIR\System32\shell32.dll,238"
$s.Description  = 'Alterna a orientação do monitor com um clique'
$s.Hotkey       = 'Ctrl+Alt+R'
$s.Save()

Write-Host "Atalhos criados em $desk"
