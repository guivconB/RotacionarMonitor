<#
  Rotacionar Monitor
  - Sem parametros: abre a janela com botoes.
  - -Alternar: alterna Paisagem <-> Retrato no monitor principal (sem janela).
  - -Listar: mostra os monitores e a orientacao atual.
#>
param(
    [switch]$Alternar,
    [switch]$Listar,
    [int]$Monitor = 1,       # 1, 2... (numero da lista). 0 = monitor principal
    [int]$OrientacaoB = 3    # alterna entre Paisagem (0) e esta: 1 = Retrato, 2 = Paisagem inv., 3 = Retrato inv.
)

$codigo = @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class Tela {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX; public int dmPositionY;
        public int dmDisplayOrientation; public int dmDisplayFixedOutput;
        public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight;
        public int dmDisplayFlags; public int dmDisplayFrequency;
        public int dmICMMethod; public int dmICMIntent; public int dmMediaType; public int dmDitherType;
        public int dmReserved1; public int dmReserved2; public int dmPanningWidth; public int dmPanningHeight;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DISPLAY_DEVICE {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
    }

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern bool EnumDisplayDevices(string device, uint devNum, ref DISPLAY_DEVICE dd, uint flags);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern int ChangeDisplaySettingsEx(string deviceName, ref DEVMODE devMode, IntPtr hwnd, uint flags, IntPtr lParam);

    const int ENUM_CURRENT_SETTINGS = -1;
    const int DM_DISPLAYORIENTATION = 0x80;
    const int DM_PELSWIDTH = 0x80000;
    const int DM_PELSHEIGHT = 0x100000;
    const uint CDS_UPDATEREGISTRY = 0x01;
    const int ATTACHED_TO_DESKTOP = 0x01;
    const int PRIMARY_DEVICE = 0x04;

    public class Monitor {
        public string Device;
        public string Nome;
        public bool Principal;
        public int Orientacao;
        public int Largura;
        public int Altura;
    }

    public static List<Monitor> Listar() {
        var lista = new List<Monitor>();
        for (uint i = 0; ; i++) {
            var dd = new DISPLAY_DEVICE();
            dd.cb = Marshal.SizeOf(dd);
            if (!EnumDisplayDevices(null, i, ref dd, 0)) break;
            if ((dd.StateFlags & ATTACHED_TO_DESKTOP) == 0) continue;

            var dm = new DEVMODE();
            dm.dmSize = (short)Marshal.SizeOf(dm);
            if (!EnumDisplaySettings(dd.DeviceName, ENUM_CURRENT_SETTINGS, ref dm)) continue;

            // Tenta pegar o nome do monitor (ex.: "Generic PnP Monitor")
            string nome = dd.DeviceString;
            var mon = new DISPLAY_DEVICE();
            mon.cb = Marshal.SizeOf(mon);
            if (EnumDisplayDevices(dd.DeviceName, 0, ref mon, 0) && !string.IsNullOrEmpty(mon.DeviceString))
                nome = mon.DeviceString;

            var m = new Monitor();
            m.Device = dd.DeviceName;
            m.Nome = nome;
            m.Principal = (dd.StateFlags & PRIMARY_DEVICE) != 0;
            m.Orientacao = dm.dmDisplayOrientation;
            m.Largura = dm.dmPelsWidth;
            m.Altura = dm.dmPelsHeight;
            lista.Add(m);
        }
        return lista;
    }

    // orientacao: 0 = Paisagem, 1 = Retrato, 2 = Paisagem invertida, 3 = Retrato invertido
    public static int Girar(string device, int orientacao) {
        var dm = new DEVMODE();
        dm.dmSize = (short)Marshal.SizeOf(dm);
        if (!EnumDisplaySettings(device, ENUM_CURRENT_SETTINGS, ref dm)) return -100;

        if ((dm.dmDisplayOrientation % 2) != (orientacao % 2)) {
            int t = dm.dmPelsWidth;
            dm.dmPelsWidth = dm.dmPelsHeight;
            dm.dmPelsHeight = t;
        }
        dm.dmDisplayOrientation = orientacao;
        dm.dmFields = DM_DISPLAYORIENTATION | DM_PELSWIDTH | DM_PELSHEIGHT;
        return ChangeDisplaySettingsEx(device, ref dm, IntPtr.Zero, CDS_UPDATEREGISTRY, IntPtr.Zero);
    }
}
"@

if (-not ('Tela' -as [type])) { Add-Type -TypeDefinition $codigo }

$nomes = @('Paisagem', 'Retrato', 'Paisagem (invertida)', 'Retrato (invertido)')

# ---------- Modo lista ----------
if ($Listar) {
    foreach ($m in [Tela]::Listar()) {
        $p = if ($m.Principal) { ' [principal]' } else { '' }
        "{0} - {1}{2}: {3} ({4}x{5})" -f $m.Device, $m.Nome, $p, $nomes[$m.Orientacao], $m.Largura, $m.Altura
    }
    return
}

# ---------- Modo alternar rapido ----------
if ($Alternar) {
    $lista = @([Tela]::Listar())
    if ($Monitor -ge 1 -and $Monitor -le $lista.Count) { $m = $lista[$Monitor - 1] }
    else { $m = $lista | Where-Object { $_.Principal } | Select-Object -First 1 }
    $nova = if ($m.Orientacao -eq 0) { $OrientacaoB } else { 0 }
    [void][Tela]::Girar($m.Device, $nova)
    return
}

# ---------- Janela ----------
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$fonte      = New-Object System.Drawing.Font('Segoe UI', 10)
$fonteTit   = New-Object System.Drawing.Font('Segoe UI Semibold', 13)
$fonteSeta  = New-Object System.Drawing.Font('Segoe UI Symbol', 18)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Rotacionar Monitor'
$form.ClientSize = New-Object System.Drawing.Size(360, 400)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 246, 248)
$form.Font = $fonte

$titulo = New-Object System.Windows.Forms.Label
$titulo.Text = 'Monitor:'
$titulo.Font = $fonteTit
$titulo.Location = New-Object System.Drawing.Point(20, 16)
$titulo.AutoSize = $true
$form.Controls.Add($titulo)

$combo = New-Object System.Windows.Forms.ComboBox
$combo.DropDownStyle = 'DropDownList'
$combo.Location = New-Object System.Drawing.Point(20, 50)
$combo.Width = 320
$form.Controls.Add($combo)

$status = New-Object System.Windows.Forms.Label
$status.Location = New-Object System.Drawing.Point(20, 84)
$status.Size = New-Object System.Drawing.Size(320, 24)
$status.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$form.Controls.Add($status)

$script:monitores = @()

function Atualizar([int]$manterIndice = 0) {
    $script:monitores = @([Tela]::Listar())
    $combo.Items.Clear()
    $i = 1
    foreach ($m in $script:monitores) {
        $p = if ($m.Principal) { ' (principal)' } else { '' }
        [void]$combo.Items.Add("$i. $($m.Nome)$p")
        $i++
    }
    if ($combo.Items.Count -gt 0) {
        $combo.SelectedIndex = [Math]::Min($manterIndice, $combo.Items.Count - 1)
    }
}

function Mostrar-Status {
    if ($combo.SelectedIndex -lt 0) { return }
    $m = $script:monitores[$combo.SelectedIndex]
    $status.Text = "Agora: $($nomes[$m.Orientacao])  -  $($m.Largura) x $($m.Altura)"
}

function Aplicar([int]$orientacao) {
    if ($combo.SelectedIndex -lt 0) { return }
    $idx = $combo.SelectedIndex
    $m = $script:monitores[$idx]
    $r = [Tela]::Girar($m.Device, $orientacao)
    if ($r -ne 0) {
        [System.Windows.Forms.MessageBox]::Show("Nao foi possivel girar este monitor (codigo $r).", 'Rotacionar Monitor') | Out-Null
    }
    Atualizar $idx
    Mostrar-Status
}

$combo.Add_SelectedIndexChanged({ Mostrar-Status })

# Botao grande de alternar
$btnAlt = New-Object System.Windows.Forms.Button
$btnAlt.Text = "Alternar  Paisagem <-> $($nomes[$OrientacaoB])"
$btnAlt.Location = New-Object System.Drawing.Point(20, 116)
$btnAlt.Size = New-Object System.Drawing.Size(320, 56)
$btnAlt.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$btnAlt.ForeColor = [System.Drawing.Color]::White
$btnAlt.FlatStyle = 'Flat'
$btnAlt.FlatAppearance.BorderSize = 0
$btnAlt.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 11)
$btnAlt.Add_Click({
    $m = $script:monitores[$combo.SelectedIndex]
    $nova = if ($m.Orientacao -eq 0) { $OrientacaoB } else { 0 }
    Aplicar $nova
})
$form.Controls.Add($btnAlt)

# Quatro botoes de orientacao
$botoes = @(
    @{ T = "▭  Paisagem";            O = 0; X = 20;  Y = 188 },
    @{ T = "▯  Retrato";             O = 1; X = 185; Y = 188 },
    @{ T = "▭  Paisagem invertida";  O = 2; X = 20;  Y = 248 },
    @{ T = "▯  Retrato invertido";   O = 3; X = 185; Y = 248 }
)
foreach ($b in $botoes) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $b.T
    $btn.Tag = $b.O
    $btn.Location = New-Object System.Drawing.Point($b.X, $b.Y)
    $btn.Size = New-Object System.Drawing.Size(155, 50)
    $btn.BackColor = [System.Drawing.Color]::White
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(200, 200, 205)
    $btn.Add_Click({ param($s, $e) Aplicar ([int]$s.Tag) })
    $form.Controls.Add($btn)
}

$dica = New-Object System.Windows.Forms.Label
$dica.Text = "Dica: Ctrl+Alt+setas tambem funcionam em alguns PCs.`nSe a tela ficar estranha, clique em 'Paisagem'."
$dica.Location = New-Object System.Drawing.Point(20, 316)
$dica.Size = New-Object System.Drawing.Size(320, 44)
$dica.ForeColor = [System.Drawing.Color]::Gray
$dica.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
$form.Controls.Add($dica)

$btnAtual = New-Object System.Windows.Forms.Button
$btnAtual.Text = 'Atualizar lista'
$btnAtual.Location = New-Object System.Drawing.Point(20, 362)
$btnAtual.Size = New-Object System.Drawing.Size(120, 28)
$btnAtual.FlatStyle = 'Flat'
$btnAtual.Add_Click({ Atualizar $combo.SelectedIndex; Mostrar-Status })
$form.Controls.Add($btnAtual)

$inicial = 0
Atualizar
if ($Monitor -ge 1 -and $Monitor -le $script:monitores.Count) { $inicial = $Monitor - 1 }
else { for ($i = 0; $i -lt $script:monitores.Count; $i++) { if ($script:monitores[$i].Principal) { $inicial = $i } } }
$combo.SelectedIndex = $inicial
Mostrar-Status

[void]$form.ShowDialog()
