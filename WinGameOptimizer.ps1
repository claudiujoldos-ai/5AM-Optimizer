# WinGame Optimizer v2 - Gaming Edition (WPF, Windows 11)
# Fara diacritice in fisier, ca sa mearga corect in Windows PowerShell 5.1
Add-Type -AssemblyName PresentationFramework

# ---------- Auto-elevare ----------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ($PSCommandPath) { Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" }
    else { [Windows.MessageBox]::Show('Ruleaza aplicatia ca Administrator.') | Out-Null }
    exit
}

# ---------- Backup registry (Undo) ----------
$bkDir = "$env:APPDATA\WinGameOptimizer"; $bkFile = "$bkDir\backup.json"
$script:bk = @{}
if (Test-Path $bkFile) { foreach ($e in @(Get-Content $bkFile -Raw | ConvertFrom-Json)) { $script:bk["$($e.Path)|$($e.Name)"] = $e } }
function Save-Backup {
    if (-not (Test-Path $bkDir)) { New-Item $bkDir -ItemType Directory -Force | Out-Null }
    @($script:bk.Values) | ConvertTo-Json -Depth 4 | Set-Content $bkFile -Encoding UTF8
}
function RegSet {
    param($p, $n, $v, $t = 'DWord')
    $key = "$p|$n"
    if (-not $script:bk.ContainsKey($key)) {
        $ex = $false; $old = $null; $kind = 'DWord'
        try { $it = Get-Item -Path $p -ErrorAction Stop
              if ($it.GetValueNames() -contains $n) { $ex = $true; $old = $it.GetValue($n); $kind = $it.GetValueKind($n).ToString() } } catch {}
        $script:bk[$key] = [pscustomobject]@{ Path = $p; Name = $n; Existed = $ex; Value = $old; Kind = $kind }
    }
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name $n -Value $v -Type $t -Force
}

function Remove-AppPkg {
    param($names)
    if (-not $global:WGprov) { try { $global:WGprov = @(Get-AppxProvisionedPackage -Online) } catch { $global:WGprov = @() } }
    foreach ($n in $names) {
        Get-AppxPackage -AllUsers $n -ErrorAction SilentlyContinue |
            ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }
        $global:WGprov | Where-Object { $_.DisplayName -like $n } |
            ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null }
    }
}

# ---------- Detectie placi video (AMD / NVIDIA / Intel) ----------
$script:gpuAdapters = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -and $_.Name -notmatch 'Basic|Remote|Virtual|Parsec|Mirage|Indirect|Meta' })
$gpuVendors = @($script:gpuAdapters | ForEach-Object {
    if ($_.Name -match 'AMD|Radeon|ATI') { 'AMD' } elseif ($_.Name -match 'NVIDIA|GeForce|RTX|GTX|Quadro') { 'NVIDIA' } elseif ($_.Name -match 'Intel') { 'INTEL' } })

# ---------- Optimizari (P = profilul minim care le include: 1 Minim, 2 Mediu, 3 Maxim) ----------
$tweaks = @(
 @{G='AI SI COPILOT'; S=$true; P=1; L='Dezactiveaza Copilot (politica + buton taskbar)'; Do={
    RegSet 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    RegSet 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
    RegSet 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton' 0 }},
 @{G='AI SI COPILOT'; P=1; L='Fara sugestii web / Bing in cautarea Windows'; Do={
    RegSet 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
    RegSet 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1 }},
 @{G='AI SI COPILOT'; P=2; L='Fara sugestii, reclame si continut promovat'; Do={
    $c = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    foreach ($n in 'SubscribedContent-338388Enabled','SubscribedContent-338389Enabled','SubscribedContent-353694Enabled','SubscribedContent-353696Enabled','SystemPaneSuggestionsEnabled','SoftLandingEnabled') { RegSet $c $n 0 } }},
 @{G='AI SI COPILOT'; P=3; L='Widgets (feed cu AI) oprite'; Do={
    RegSet 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0 }},
 @{G='AI SI COPILOT'; P=3; L='Sterge aplicatia Copilot (definitiv)'; Do={
    Get-AppxPackage -AllUsers '*Copilot*' | ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue } }},

 @{G='AI SI COPILOT'; P=2; L='AI oprit in Notepad si Paint (rewrite, Cocreator, Generative Fill)'; Do={
    RegSet 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsNotepad' 'DisableAIFeatures' 1
    $pt = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Paint'
    RegSet $pt 'DisableCocreator' 1; RegSet $pt 'DisableGenerativeFill' 1; RegSet $pt 'DisableImageCreator' 1 }},
 @{G='AI SI COPILOT'; P=3; L='Sterge AI Manager, Office Actions Server, AI Fabric (definitiv)'; Do={
    $names = 'aimgr','Microsoft.Office.ActionsServer','Microsoft.AIFabric.CBS*'
    foreach ($n in $names) {
        Get-AppxPackage -AllUsers $n | ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $n } |
            ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null }
    }
    $left = @($names | ForEach-Object { Get-AppxPackage -AllUsers $_ } | ForEach-Object { $_.Name })
    if ($left.Count) { throw "au ramas (protejate de sistem): $($left -join ', ')" } }},

 @{G='PRIVACY'; P=1; L='Fara ID de reclame si experiente personalizate'; Do={
    RegSet 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
    RegSet 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0 }},
 @{G='PRIVACY'; P=1; L='Istoric de activitate (Timeline) oprit'; Do={
    $k = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
    RegSet $k 'EnableActivityFeed' 0; RegSet $k 'PublishUserActivities' 0; RegSet $k 'UploadUserActivities' 0 }},
 @{G='PRIVACY'; P=2; L='Locatie dezactivata (microfon si camera raman neatinse)'; Do={
    RegSet 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' 'Value' 'Deny' 'String' }},
 @{G='PRIVACY'; P=2; L='Fara feedback, colectare tastare/cerneala si vorbire online'; Do={
    RegSet 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 1
    RegSet 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1
    RegSet 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1
    RegSet 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 0 }},
 @{G='PRIVACY'; P=2; L='Fara tracking in Start, lista de limbi pentru site-uri, Spotlight pe lockscreen'; Do={
    RegSet 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 0
    RegSet 'HKCU:\Control Panel\International\User Profile' 'HttpAcceptLanguageOptOut' 1
    $c = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    RegSet $c 'RotatingLockScreenEnabled' 0; RegSet $c 'RotatingLockScreenOverlayEnabled' 0 }},
 @{G='PRIVACY'; P=3; L='Raportare erori oprita, consumer features oprite, istoric clipboard (Win+V) oprit'; Do={
    RegSet 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1
    RegSet 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
    RegSet 'HKCU:\Software\Microsoft\Clipboard' 'EnableClipboardHistory' 0 }},

 @{G='POWER PLAN'; P=1; L='Ultimate Performance (refoloseste planul existent)'; Do={
    $rx = '([0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12})'
    $g = powercfg /list | Select-String 'Ultimate Performance' | Select-Object -First 1
    if ($g -and "$g" -match $rx) { $id = $Matches[1] }
    else { $o = "$(powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61)"; if ($o -match $rx) { $id = $Matches[1] } }
    if ($id) { powercfg /setactive $id } else { powercfg /setactive SCHEME_MIN } }},
 @{G='POWER PLAN'; P=2; L='PCIe Link State + USB suspend oprite (mai putin lag)'; Do={
    powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
    powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    powercfg /setactive SCHEME_CURRENT }},
 @{G='POWER PLAN'; P=2; L='Hibernare oprita (elibereaza spatiu pe disc)'; Do={ powercfg /hibernate off }},
 @{G='POWER PLAN'; P=3; L='Power Throttling oprit (CPU la maxim pentru toate procesele)'; Do={
    RegSet 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1 }},

 @{G='GPU SI GAMING'; P=1; L='Game Mode pornit'; Do={
    RegSet 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
    RegSet 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1 }},
 @{G='GPU SI GAMING'; P=1; L='Game DVR / inregistrare in fundal oprite'; Do={
    RegSet 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    RegSet 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0 }},
 @{G='GPU SI GAMING'; P=2; L='GPU Scheduling hardware (HAGS) pornit - necesita restart'; Do={
    RegSet 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2 }},
 @{G='GPU SI GAMING'; P=2; L='Mouse fara acceleratie (dupa relogare)'; Do={
    foreach ($n in 'MouseSpeed','MouseThreshold1','MouseThreshold2') { RegSet 'HKCU:\Control Panel\Mouse' $n '0' 'String' } }},

 @{G='PERFORMANTA WINDOWS'; P=2; L='Efecte vizuale reduse (animatii, transparenta)'; Do={
    RegSet 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    RegSet 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0
    RegSet 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0 }},
 @{G='PERFORMANTA WINDOWS'; P=2; L='Aplicatii in fundal oprite'; Do={
    RegSet 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 1 }},
 @{G='PERFORMANTA WINDOWS'; P=3; L='Telemetrie minima'; Do={
    RegSet 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 }},
 @{G='PERFORMANTA WINDOWS'; P=3; L='Curata fisierele temporare (definitiv)'; Do={
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue }},

 @{G='FPS BOOST'; P=1; I='1F3AE'; L='Game Bar: fara popup-uri si buton controller'; T='Opreste popup-ul de pornire al Game Bar si deschiderea lui cu butonul Xbox al controllerului.'; Do={
    RegSet 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0
    RegSet 'HKCU:\Software\Microsoft\GameBar' 'ShowStartupPanel' 0 }},
 @{G='FPS BOOST'; P=2; I='1F3AF'; L='Prioritate jocuri (MMCSS: GPU si CPU)'; T='Da jocurilor prioritate mai mare la CPU si GPU in planificatorul Windows. Castig mic, dar sigur.'; Do={
    $mm = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    RegSet $mm 'SystemResponsiveness' 0
    $gg = "$mm\Tasks\Games"
    RegSet $gg 'GPU Priority' 8; RegSet $gg 'Priority' 6
    RegSet $gg 'Scheduling Category' 'High' 'String'; RegSet $gg 'SFIO Priority' 'High' 'String' }},
 @{G='FPS BOOST'; P=2; I='1F5A5'; L='Optimizari jocuri windowed / borderless'; T='Windows 11: Optimizations for windowed games. Foloseste flip model, deci latenta si FPS mai bune in borderless (DX10/11).'; Do={
    $kk = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
    $cur = ''; try { $cur = [string](Get-ItemProperty -Path $kk -Name DirectXUserGlobalSettings -ErrorAction Stop).DirectXUserGlobalSettings } catch {}
    if ($cur -and -not $cur.EndsWith(';')) { $cur += ';' }
    if ($cur -match 'SwapEffectUpgradeEnable=\d') { $new = $cur -replace 'SwapEffectUpgradeEnable=\d', 'SwapEffectUpgradeEnable=1' }
    else { $new = $cur + 'SwapEffectUpgradeEnable=1;' }
    RegSet $kk 'DirectXUserGlobalSettings' $new 'String' }},
 @{G='FPS BOOST'; P=2; I='1F4E1'; L='Delivery Optimization fara upload P2P'; T='Windows Update nu mai trimite fisiere catre alte PC-uri: mai putin trafic de retea si CPU in fundal.'; Do={
    RegSet 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0 }},
 @{G='FPS BOOST'; P=3; I='1F9E0'; L='CPU 100% minim, boost agresiv, fara parking'; T='Procesorul nu mai coboara frecventa si nu mai adoarme nuclee. Atentie: consum si temperaturi mai mari si in idle.'; Do={
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100
    powercfg /setactive SCHEME_CURRENT }},
 @{G='FPS BOOST'; P=3; I='1F4F6'; L='Retea: fara throttling multimedia'; T='NetworkThrottlingIndex dezactivat. Util mai ales daca joci si faci stream in acelasi timp.'; Do={
    RegSet 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' ([int]-1) }},
 @{G='FPS BOOST'; P=3; I='26A1'; L='Retea: Nagle oprit (jocuri TCP)'; T='Ping mai mic in jocurile care folosesc TCP (MMO, FiveM). Nu schimba FPS-ul.'; Do={
    foreach ($na in @(Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' })) {
        $kk = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($na.InterfaceGuid)"
        RegSet $kk 'TcpAckFrequency' 1; RegSet $kk 'TCPNoDelay' 1 } }},
 @{G='FPS BOOST'; P=9; I='1F9EA'; L='Optional: MPO oprit (flicker / stutter)'; T='Opreste Multiplane Overlay. Foloseste-l DOAR daca ai flicker, ecran negru scurt sau stutter. Necesita restart.'; Do={
    RegSet 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5 }},
 @{G='FPS BOOST'; P=9; I='23F1'; L='Optional: timer global Windows 11'; T='Restaureaza comportamentul vechi al timerului: frametime mai stabil in unele jocuri, dar consum mai mare.'; Do={
    RegSet 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests' 1 }},
 @{G='FPS BOOST'; P=9; I='1F4FA'; L='Optional: fullscreen optimizations oprite'; T='Poate ajuta in jocuri vechi DX9/DX11. In jocurile moderne poate strica flip model, testeaza inainte.'; Do={
    $cc = 'HKCU:\System\GameConfigStore'
    RegSet $cc 'GameDVR_FSEBehaviorMode' 2; RegSet $cc 'GameDVR_HonorUserFSEBehaviorMode' 1
    RegSet $cc 'GameDVR_DXGIHonorFSEWindowsCompatible' 1; RegSet $cc 'GameDVR_EFSEFeatureFlags' 0 }},

 # P=9: nu este bifat de niciun profil, il activezi doar manual
 @{G='SECURITATE (OPTIONAL)'; P=9; L='Memory Integrity (HVCI) oprit: putin mai multe FPS, dar protectie mai mica (restart)'; Do={
    RegSet 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0 }}
)

# ---------- Curatare aplicatii (dupa Winhance) ----------
# Format: Nume|pachet1,pachet2|flags   S = bifat la tine (steluta, intra la Maxim)   P = definitiv   - = nimic
$star = [string][char]0x2605
$appGroup = "CURATARE APLICATII   ($star = bifat la tine in Winhance)"
$appList = @(
 '3D Viewer|Microsoft.Microsoft3DViewer|S',
 'AI Workload Packages|WindowsWorkload.*|SP',
 'Windows AI Experience|MicrosoftWindows.Client.AIX|SP',
 'Windows Copilot Client|MicrosoftWindows.Client.CoPilot|SP',
 'Bing Search|Microsoft.BingSearch|S',
 'Cortana|Microsoft.549981C3F5F10|SP',
 'Edge Game Assist|Microsoft.Edge.GameAssist|SP',
 'Feedback Hub|Microsoft.WindowsFeedbackHub|S',
 'Get Help|Microsoft.GetHelp|S',
 'Mail and Calendar|microsoft.windowscommunicationsapps|S',
 'Maps|Microsoft.WindowsMaps|SP',
 'Microsoft Family Safety|MicrosoftCorporationII.MicrosoftFamily|S',
 'Microsoft News|Microsoft.BingNews|S',
 'Microsoft Teams|MSTeams,MicrosoftTeams|S',
 'Mixed Reality Portal|Microsoft.MixedReality.Portal|S',
 'MS 365 Copilot (Office Hub)|Microsoft.MicrosoftOfficeHub|S',
 'MSN Weather|Microsoft.BingWeather|S',
 'OneNote|Microsoft.Office.OneNote|S',
 'Outlook for Windows|Microsoft.OutlookForWindows|S',
 'Paint 3D|Microsoft.MSPaint|SP',
 'People|Microsoft.People|SP',
 'Quick Assist|MicrosoftCorporationII.QuickAssist|S',
 'Skype|Microsoft.SkypeApp|SP',
 'Solitaire Collection|Microsoft.MicrosoftSolitaireCollection|S',
 'Sticky Notes|Microsoft.MicrosoftStickyNotes|S',
 'Tips|Microsoft.Getstarted|SP',
 'To Do|Microsoft.Todos|S',
 'Camera|Microsoft.WindowsCamera|-',
 'Media Player|Microsoft.ZuneMusic|-',
 'Movies and TV|Microsoft.ZuneVideo|-',
 'Photos|Microsoft.Windows.Photos|-',
 'Snipping Tool|Microsoft.ScreenSketch|-',
 'Notepad|Microsoft.WindowsNotepad|-',
 'Paint|Microsoft.Paint|-',
 'Calculator|Microsoft.WindowsCalculator|-',
 'Alarms and Clock|Microsoft.WindowsAlarms|-',
 'Sound Recorder|Microsoft.WindowsSoundRecorder|-',
 'Clipchamp|Clipchamp.Clipchamp|-',
 'Phone Link|Microsoft.YourPhone|-',
 'Power Automate|Microsoft.PowerAutomateDesktop|-'
)
$appTweaks = @()
foreach ($line in $appList) {
    $f = $line -split '\|'
    $isStar = $f[2] -match 'S'
    $lbl = $(if ($isStar) { "$star " } else { '' }) + $f[0] + $(if ($f[2] -match 'P') { '  [definitiv]' } else { '' })
    $appTweaks += @{ G = $appGroup; P = $(if ($isStar) { 3 } else { 9 }); L = $lbl; K = ($f[1] -split ','); Do = { param($t) Remove-AppPkg $t.K } }
}
$appTweaks += @{ G = $appGroup; P = 3; L = "$star OneDrive (fisierele locale raman pe PC)"; Do = {
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    $x = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    if (-not (Test-Path $x)) { $x = "$env:SystemRoot\System32\OneDriveSetup.exe" }
    if (Test-Path $x) { Start-Process $x '/uninstall' -Wait } } }
# grupa de aplicatii vine inainte de SECURITATE (OPTIONAL)
$tweaks = @($tweaks | Where-Object { $_.G -notlike 'SECURITATE*' }) + $appTweaks + @($tweaks | Where-Object { $_.G -like 'SECURITATE*' })

# ---------- Privacy AI (dupa Winhance, toate pe OFF) ----------
# Format: Grupa|Nume|IconHex|Profil(2=LOW+ULTRA, 3=doar ULTRA)|cale,nume,valoare;cale,nume,valoare
$pt = @{ W = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; E = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
         P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Paint'; CC = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
         C = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore'
         M = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone'
         S = 'HKCU:\Software\Microsoft\Windows\Shell\Copilot'; I = 'HKCU:\Software\Microsoft\Input\Settings'
         O = 'HKCU:\Software\Policies\Microsoft\office\16.0\common\privacy' }
$WA = 'PRIVACY: WINDOWS AI'; $EA = 'PRIVACY: EDGE AI'; $OA = 'PRIVACY: OFFICE AI'
$aiList = @(
 "$WA|AI Data Analysis|1F9E0|2|W,DisableAIDataAnalysis,1",
 "$WA|Recall Enablement|1F6AB|2|W,AllowRecallEnablement,0",
 "$WA|Recall Saving Snapshots|1F4F7|2|W,TurnOffSavingSnapshots,1",
 "$WA|Click to Do|1F5B1|2|W,DisableClickToDo,1",
 "$WA|AI Settings Agent|2699|2|W,DisableSettingsAgent,1",
 "$WA|AI Agent Connectors|1F50C|2|W,DisableAgentConnectors,1",
 "$WA|AI Agent Workspaces|1F5A5|2|W,DisableAgentWorkspaces,1",
 "$WA|Remote AI Agent Connectors|1F310|2|W,DisableRemoteAgentConnectors,1",
 "$WA|Copilot Availability (Windows Shell)|1F6AB|2|S,IsCopilotAvailable,0",
 "$WA|Bing Chat Eligibility|1F4AC|2|S\BingChat,IsUserEligible,0",
 "$WA|Generative AI Access|2728|2|C\generativeAI,Value,Deny",
 "$WA|System AI Models Access (strica OCR in Snipping Tool)|1F9E9|3|C\systemAIModels,Value,Deny",
 "$WA|Copilot Microphone Access|1F3A4|2|M\Microsoft.Copilot_8wekyb3d8bbwe,Value,Deny;M\Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe,Value,Deny",
 "$WA|Paint AI Image Creator|1F5BC|2|P,DisableImageCreator,1",
 "$WA|Paint AI Cocreator|1F3A8|2|P,DisableCocreator,1",
 "$WA|Paint Generative Fill|1F58C|2|P,DisableGenerativeFill,1",
 "$WA|Paint Generative Erase|1F9FD|2|P,DisableGenerativeErase,1",
 "$WA|Paint Remove Background|2702|2|P,DisableRemoveBackground,1",
 "$WA|Input Insights|2328|2|I,InsightsEnabled,0",
 "$WA|AI Consumer Content|1F464|2|CC,DisableConsumerAccountStateContent,1",
 "$EA|Edge Copilot CDP Page Context|1F310|2|E,CopilotCDPPageContext,0",
 "$EA|Edge Copilot Page Context|1F4C4|2|E,CopilotPageContext,0",
 "$EA|Edge Copilot Sidebar|1F4D1|2|E,HubsSidebarEnabled,0",
 "$EA|Edge Entra Copilot Page Context|1F6E1|2|E,EdgeEntraCopilotPageContext,0",
 "$EA|Edge M365 Copilot Chat Icon|1F4AC|2|E,Microsoft365CopilotChatIconEnabled,0",
 "$EA|Edge AI History Search|1F552|2|E,EdgeHistoryAISearchEnabled,0",
 "$EA|Edge Inline AI Compose|270F|2|E,ComposeInlineEnabled,0",
 "$EA|Edge Local AI Model Settings|1F9E0|2|E,GenAILocalFoundationalModelSettings,1",
 "$EA|Edge Built-in AI APIs|1F50C|2|E,BuiltInAIAPIsEnabled,0",
 "$EA|Edge AI Generated Themes|1F3A8|2|E,AIGenThemesEnabled,0",
 "$EA|Edge DevTools AI|1F6E0|2|E,DevToolsGenAiSettings,2",
 "$OA|Office Connected Services|2601|2|O,controllerconnectedservicesenabled,2;O,usercontentdisabled,2;O,downloadcontentdisabled,2"
)
$aiTweaks = @()
foreach ($line in $aiList) {
    $f = $line -split '\|'
    $ents = @($f[4] -split ';' | ForEach-Object {
        $p = $_ -split ',', 3
        $tok, $sub = $p[0] -split '\\', 2
        $path = $pt[$tok] + $(if ($sub) { "\$sub" } else { '' })
        $isNum = $p[2] -match '^\d+$'
        , @($path, $p[1], $(if ($isNum) { [int]$p[2] } else { $p[2] }), $(if ($isNum) { 'DWord' } else { 'String' }))
    })
    $aiTweaks += @{ G = $f[0]; S = $true; P = [int]$f[3]; L = $f[1]; I = $f[2]; E = $ents; X = ($f[1] -eq 'Recall Enablement')
                    Do = { param($t)
                        foreach ($e in $t.E) { RegSet $e[0] $e[1] $e[2] $e[3] }
                        if ($t.X) { try { Disable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart -ErrorAction Stop | Out-Null } catch {} } } }
}
$tweaks = @($tweaks | Where-Object { $_.G -notlike 'CURATARE*' -and $_.G -notlike 'SECURITATE*' }) + $aiTweaks +
          @($tweaks | Where-Object { $_.G -like 'CURATARE*' }) + @($tweaks | Where-Object { $_.G -like 'SECURITATE*' })

# ---------- Interfata: 5AM Optimizer ----------
Add-Type -AssemblyName PresentationCore, WindowsBase
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="5AM Optimizer" Width="940" Height="980" MinWidth="720"
        WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
  <Window.Background>
    <RadialGradientBrush Center="0.5,0" RadiusX="1.1" RadiusY="0.9" GradientOrigin="0.5,0">
      <GradientStop Color="#3A0612" Offset="0"/><GradientStop Color="#0A0306" Offset="0.55"/><GradientStop Color="#030102" Offset="1"/>
    </RadialGradientBrush>
  </Window.Background>
  <Window.Resources>
    <Style TargetType="CheckBox">
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="CheckBox">
          <Border x:Name="Card" CornerRadius="12" Background="#120609" BorderBrush="#34101A" BorderThickness="1" Padding="11" Cursor="Hand">
            <Grid>
              <ContentPresenter/>
              <Ellipse x:Name="Dot" Width="10" Height="10" Fill="#3A1F27" HorizontalAlignment="Right" VerticalAlignment="Top"/>
            </Grid>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Card" Property="BorderBrush" Value="#FF7A93"/></Trigger>
            <Trigger Property="IsChecked" Value="True">
              <Setter TargetName="Card" Property="BorderBrush" Value="#FF2E4D"/>
              <Setter TargetName="Card" Property="Background" Value="#2A0812"/>
              <Setter TargetName="Dot" Property="Fill" Value="#FF2E4D"/>
              <Setter TargetName="Card" Property="Effect"><Setter.Value>
                <DropShadowEffect Color="#FF2E4D" BlurRadius="18" ShadowDepth="0" Opacity="0.65"/></Setter.Value></Setter>
            </Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="Pill" TargetType="Button">
      <Setter Property="Foreground" Value="White"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="B" CornerRadius="14" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                  BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="B" Property="Opacity" Value="0.85"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="B" Property="Opacity" Value="0.4"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter>
    </Style>
  </Window.Resources>
  <Grid>
    <Grid Margin="22">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="90"/>
      </Grid.RowDefinitions>

      <Grid Margin="0,0,0,12">
        <StackPanel VerticalAlignment="Center">
          <TextBlock x:Name="Title" Text="5AM OPTIMIZER" FontSize="38" FontWeight="Black" Foreground="#FFE4EA" HorizontalAlignment="Left">
            <TextBlock.Effect><DropShadowEffect Color="#FF2E4D" BlurRadius="24" ShadowDepth="0" Opacity="0.95"/></TextBlock.Effect>
          </TextBlock>
          <TextBlock Text="AI OFF  |  MAX PERFORMANCE  |  GAMING EDITION" FontSize="11" Foreground="#FF7A93" Margin="2,2,0,0"/>
        </StackPanel>
        <Grid Width="70" Height="70" HorizontalAlignment="Right">
          <Ellipse><Ellipse.Fill><RadialGradientBrush><GradientStop Color="#FF4D6D" Offset="0"/><GradientStop Color="#B0102A" Offset="1"/></RadialGradientBrush></Ellipse.Fill>
            <Ellipse.Effect><DropShadowEffect Color="#FF2E4D" BlurRadius="30" ShadowDepth="0" Opacity="0.9"/></Ellipse.Effect></Ellipse>
          <TextBlock Text="5" FontSize="34" FontWeight="Black" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Grid>
      </Grid>

      <StackPanel Grid.Row="1">
        <UniformGrid x:Name="Dash" Columns="4"/>
        <Border CornerRadius="10" Background="#1A060C" BorderBrush="#4A1220" BorderThickness="1" Padding="10,7" Margin="0,4,0,0">
          <TextBlock x:Name="Bottle" FontSize="12" Foreground="#FFB7C5" TextWrapping="Wrap"/>
        </Border>
      </StackPanel>

      <UniformGrid Grid.Row="2" Columns="2" Margin="0,14,0,4">
        <Button x:Name="BtnLow" Style="{StaticResource Pill}" Background="#1A070D" BorderThickness="2" BorderBrush="Transparent" Padding="10,13" Margin="0,0,7,0">
          <StackPanel><TextBlock Text="LOW" FontWeight="Bold" FontSize="16" HorizontalAlignment="Center"/>
            <TextBlock Text="Sigur si recomandat" FontSize="11" Foreground="#FF9DB0" HorizontalAlignment="Center"/></StackPanel></Button>
        <Button x:Name="BtnUltra" Style="{StaticResource Pill}" Background="#1A070D" BorderThickness="2" BorderBrush="Transparent" Padding="10,13" Margin="7,0,0,0">
          <StackPanel><TextBlock Text="ULTRA" FontWeight="Bold" FontSize="16" HorizontalAlignment="Center"/>
            <TextBlock Text="Tot, inclusiv definitive" FontSize="11" Foreground="#FF9DB0" HorizontalAlignment="Center"/></StackPanel></Button>
      </UniformGrid>

      <ScrollViewer Grid.Row="3" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Margin="0,8,0,0">
        <StackPanel x:Name="List"/>
      </ScrollViewer>

      <Grid Grid.Row="4" Margin="0,10,0,0">
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <TextBlock x:Name="Count" Foreground="#B98A96" FontSize="12" VerticalAlignment="Center"/>
        <Button x:Name="BtnRevert" Grid.Column="1" Style="{StaticResource Pill}" Content="REVINO LA SETARILE ORIGINALE" Background="#2A1219" Foreground="#FFC9D3" Padding="16,12" Margin="0,0,10,0"/>
        <Button x:Name="BtnApply" Grid.Column="2" Style="{StaticResource Pill}" Content="OPTIMIZEAZA" FontWeight="Bold" FontSize="15" Padding="36,12">
          <Button.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,0"><GradientStop Color="#FF2E4D" Offset="0"/><GradientStop Color="#FF7AA2" Offset="1"/></LinearGradientBrush></Button.Background>
          <Button.Effect><DropShadowEffect Color="#FF2E4D" BlurRadius="24" ShadowDepth="0" Opacity="0.7"/></Button.Effect>
        </Button>
      </Grid>
      <ProgressBar x:Name="Bar" Grid.Row="5" Height="5" Margin="0,10,0,8" Background="#1F0A10" Foreground="#FF2E4D" BorderThickness="0" Minimum="0" Maximum="1" Value="0"/>
      <Border Grid.Row="6" CornerRadius="12" Background="#060203" BorderBrush="#3A0F1A" BorderThickness="1">
        <TextBox x:Name="LogBox" IsReadOnly="True" Background="Transparent" Foreground="#FFB7C5" FontFamily="Consolas" FontSize="11"
                 BorderThickness="0" Padding="10" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"/>
      </Border>
    </Grid>
    <Canvas x:Name="Fx" IsHitTestVisible="False"/>
  </Grid>
</Window>
'@
$w = [Windows.Markup.XamlReader]::Parse($xaml)
$List = $w.FindName('List'); $LogBox = $w.FindName('LogBox'); $Bar = $w.FindName('Bar'); $Count = $w.FindName('Count')
$Dash = $w.FindName('Dash'); $Bottle = $w.FindName('Bottle'); $Title = $w.FindName('Title'); $Fx = $w.FindName('Fx')
$BtnApply = $w.FindName('BtnApply'); $BtnRevert = $w.FindName('BtnRevert')
$cards = @($w.FindName('BtnLow'), $w.FindName('BtnUltra'))
$bc = New-Object Windows.Media.BrushConverter
function Br($h) { $bc.ConvertFromString($h) }
function Emo($c) { [char]::ConvertFromUtf32($c) }
function TB($t, $s, $c, $b) { $x = New-Object Windows.Controls.TextBlock; $x.Text = $t; $x.FontSize = $s; $x.Foreground = (Br $c); if ($b) { $x.FontWeight = 'Bold' }; $x }
function Say($m) { $LogBox.AppendText("$m`r`n"); $LogBox.ScrollToEnd(); $w.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background) }

# ---------- Pictograme ----------
function Get-Icon($t) {
    if ($t.I) { return Emo ([Convert]::ToInt32($t.I, 16)) }
    if ($t.G -like 'CURATARE*') {
        switch -Regex ($t.L) {
            'Mail|Outlook'                                          { return Emo 0x1F4E7 }
            'Teams|Skype|Phone|People'                              { return Emo 0x1F4AC }
            'Weather|News|Maps|Bing'                                { return Emo 0x1F30D }
            'Photos|Camera|Paint|3D|Snipping|Clipchamp|Movies|Media' { return Emo 0x1F3A8 }
            'Solitaire'                                             { return Emo 0x1F0CF }
            'Copilot|AI|Cortana'                                    { return Emo 0x1F916 }
            'OneDrive|OneNote|Notes|To Do'                          { return Emo 0x2601 }
            default                                                 { return Emo 0x1F4E6 }
        }
    }
    $m = @{ 'AI SI COPILOT' = 0x1F916; 'PRIVACY' = 0x1F512; 'POWER PLAN' = 0x26A1; 'GPU SI GAMING' = 0x1F3AE; 'PERFORMANTA WINDOWS' = 0x1F680; 'SECURITATE (OPTIONAL)' = 0x1F6E1; 'FPS BOOST' = 0x1F525 }
    Emo $m[$t.G]
}

# ---------- Dashboard hardware ----------
$ui = @{}
foreach ($k in 'CPU', 'GPU', 'RAM', 'DISCURI') {
    $b = New-Object Windows.Controls.Border
    $b.CornerRadius = 12; $b.Padding = 11; $b.Margin = '0,0,8,0'; $b.BorderThickness = 1
    $b.Background = Br '#12060A'; $b.BorderBrush = Br '#3A0F1A'
    $s = New-Object Windows.Controls.StackPanel
    $n = TB '' 11.5 '#F3E6EA' $false; $n.TextWrapping = 'Wrap'; $n.Margin = '0,3,0,3'
    $l = TB '...' 11.5 '#FF6B86' $true; $l.TextWrapping = 'Wrap'
    $s.Children.Add((TB $k 11 '#FF2E4D' $true)) | Out-Null; $s.Children.Add($n) | Out-Null; $s.Children.Add($l) | Out-Null
    $b.Child = $s; $Dash.Children.Add($b) | Out-Null; $ui[$k] = @{ N = $n; L = $l }
}
$cp = Get-CimInstance Win32_Processor | Select-Object -First 1
$ui.CPU.N.Text = "$($cp.Name.Trim())`n$($cp.NumberOfCores) nuclee / $($cp.NumberOfLogicalProcessors) thread-uri"
function Get-GpuInfo {
    function Rs($v) {
        if ($null -eq $v) { return '' }
        if ($v -is [byte[]]) { $v = [Text.Encoding]::Unicode.GetString($v) }
        ([string]$v).Trim([char]0, ' ')
    }
    $cls = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11cd-be10-08002be10318}'
    $regs = @()
    try { $regs = @(Get-ChildItem -LiteralPath $cls -ErrorAction Stop | Where-Object { $_.PSChildName -match '^\d{4}$' } |
                    ForEach-Object { Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue }) } catch {}
    $out = @()
    foreach ($a in $script:gpuAdapters) {
        $r = $regs | Where-Object { $_.DriverDesc -eq $a.Name } | Select-Object -First 1
        $vram = 0.0; $mt = ''; $adr = ''
        if ($r) {
            try { $q = $r.'HardwareInformation.qwMemorySize'
                  if ($q -is [byte[]]) { $q = [BitConverter]::ToUInt64($q, 0) }
                  if ($q) { $vram = [double]$q } } catch {}
            $mt = Rs $r.'HardwareInformation.MemoryType'
            if ($mt -notmatch '^[A-Za-z0-9 \-\.]{2,20}$') { $mt = '' }
            $adr = Rs $r.RadeonSoftwareVersion
            if ($adr -notmatch '^[0-9\.]{3,20}$') { $adr = '' }
        }
        if ($vram -le 0 -and $a.AdapterRAM) { $vram = [double]$a.AdapterRAM }
        $vtxt = if ($vram -le 0) { 'VRAM ?' } elseif ($vram -lt 2GB) { '{0:N0} MB' -f ($vram / 1MB) } else { '{0:N0} GB' -f ($vram / 1GB) }
        if ($mt) { $vtxt += " $mt" }
        $drv = "driver $($a.DriverVersion)"
        if ($adr) { $drv += " (Adrenalin $adr)" }
        $res = ''
        if ($a.CurrentHorizontalResolution) { $res = "$($a.CurrentHorizontalResolution)x$($a.CurrentVerticalResolution) @ $($a.CurrentRefreshRate) Hz" }
        $lines = @($a.Name, "$vtxt  |  $drv", $res) | Where-Object { $_ }
        $out += [pscustomobject]@{ Name = $a.Name; VramMB = [int]($vram / 1MB); Text = ($lines -join "`n") }
    }
    $out
}
$gpuInfo = @(Get-GpuInfo)
$ui.GPU.N.Text = if ($gpuInfo.Count) { ($gpuInfo | ForEach-Object { $_.Text }) -join "`n`n" } else { 'GPU necunoscut' }
$script:gpuVramMB = [int](($gpuInfo | Sort-Object VramMB -Descending | Select-Object -First 1).VramMB)
$mem = @(Get-CimInstance Win32_PhysicalMemory)
$ui.RAM.N.Text = "$($mem.Count) module, $($mem[0].ConfiguredClockSpeed) MHz"
function Get-DiskInfo {
    $r = @()
    foreach ($d in Get-PhysicalDisk) {
        $t = ''; try { $tc = ($d | Get-StorageReliabilityCounter).Temperature; if ($tc) { $t = "  $tc C" } } catch {}
        $r += "$($d.FriendlyName) [$($d.MediaType)] $([math]::Round($d.Size / 1GB)) GB$t"
    }
    foreach ($v in (Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' })) {
        $r += "$($v.DriveLetter): $([math]::Round($v.SizeRemaining / 1GB)) GB liberi / $([math]::Round($v.Size / 1GB)) GB"
    }
    $r -join "`n"
}
$ui.DISCURI.N.Text = Get-DiskInfo; $ui.DISCURI.L.Text = 'Temp. SSD in dreptul fiecarui disc (daca o ofera)'

# ---------- Citire live in fundal (nu mai blocheaza interfata) ----------
$script:sd = [hashtable]::Synchronized(@{})
$script:sd['VramMB'] = [int]$script:gpuVramMB
$rs = [runspacefactory]::CreateRunspace(); $rs.ApartmentState = 'MTA'; $rs.Open()
$rs.SessionStateProxy.SetVariable('sd', $script:sd)
$worker = [powershell]::Create(); $worker.Runspace = $rs
[void]$worker.AddScript({
    while ($true) {
        try {
            $d = @{}
            $d.Cpu = [int](Get-CimInstance Win32_Processor | Select-Object -First 1).LoadPercentage
            $os = Get-CimInstance Win32_OperatingSystem
            $d.Tot = $os.TotalVisibleMemorySize / 1MB; $d.Use = $d.Tot - $os.FreePhysicalMemory / 1MB
            $d.Gpu = $null
            if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
                try { $q = & nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>$null
                      if ($q) { $p = (@($q)[0]) -split ',\s*'; $d.Gpu = @{ Load = [int]$p[0]; Temp = [int]$p[1]; MU = [int]$p[2]; MT = [int]$p[3] } } } catch {}
            }
            if (-not $d.Gpu) {
                # AMD / Intel: contoare Windows (Task Manager). Alege placa cu cea mai multa memorie dedicata folosita.
                try {
                    $am = @(Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUAdapterMemory -ErrorAction Stop)
                    $best = $am | Sort-Object DedicatedUsage -Descending | Select-Object -First 1
                    if ($best) {
                        $luid = $best.Name -replace '_phys_\d+$', ''
                        $by = @{}
                        foreach ($e in @(Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine -ErrorAction Stop |
                                         Where-Object { $_.Name -like "*$luid*" -and $_.Name -like '*engtype_3D*' })) {
                            if ($e.Name -match '_eng_(\d+)_') { $by[$Matches[1]] = [double]$by[$Matches[1]] + [double]$e.UtilizationPercentage }
                        }
                        $load = 0; if ($by.Count) { $load = [int][math]::Min(100, ($by.Values | Measure-Object -Maximum).Maximum) }
                        $d.Gpu = @{ Load = $load; Temp = $null; MU = [int]($best.DedicatedUsage / 1MB); MT = [int]$sd['VramMB'] }
                    }
                } catch {}
            }
            $d.Ct = $null
            foreach ($ns in 'root/LibreHardwareMonitor', 'root/OpenHardwareMonitor') {
                try { $s = Get-CimInstance -Namespace $ns -ClassName Sensor -ErrorAction Stop |
                           Where-Object { $_.SensorType -eq 'Temperature' -and $_.Name -match 'CPU|Tctl|Package|Tdie' } | Select-Object -First 1
                      if ($s) { $d.Ct = [int]$s.Value; break } } catch {}
            }
            if ($null -eq $d.Ct) { try { $t = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop | Select-Object -First 1
                                         if ($t) { $d.Ct = [int]($t.CurrentTemperature / 10 - 273.15) } } catch {} }
            if ($d.Gpu -and $null -eq $d.Gpu.Temp) {
                foreach ($ns in 'root/LibreHardwareMonitor', 'root/OpenHardwareMonitor') {
                    try { $gs = @(Get-CimInstance -Namespace $ns -ClassName Sensor -ErrorAction Stop |
                                  Where-Object { $_.SensorType -eq 'Temperature' -and $_.Identifier -match 'gpu' })
                          $gt = $gs | Where-Object { $_.Name -match 'GPU Core' } | Select-Object -First 1
                          if (-not $gt) { $gt = $gs | Select-Object -First 1 }
                          if ($gt) { $d.Gpu.Temp = [int]$gt.Value; break } } catch {}
                }
            }
            foreach ($k in @($d.Keys)) { $sd[$k] = $d[$k] }
            $sd['Ready'] = $true
        } catch {}
        Start-Sleep -Seconds 4
    }
})
[void]$worker.BeginInvoke()

# Interfata doar afiseaza datele deja citite (foarte ieftin)
function Update-Live {
    $d = $script:sd
    if (-not $d['Ready']) { return }
    $cpu = $d['Cpu']; $g = $d['Gpu']; $ct = $d['Ct']; $rp = [int](100 * $d['Use'] / $d['Tot'])
    $ui.CPU.L.Text = "Load $cpu%   Temp " + $(if ($null -ne $ct) { "$ct C" } else { 'n/a (porneste LibreHardwareMonitor)' })
    $ui.RAM.L.Text = ('{0:N1} / {1:N1} GB ({2}%)' -f $d['Use'], $d['Tot'], $rp)
    if ($g) {
        $gtxt = if ($null -ne $g.Temp) { "$($g.Temp) C" } else { 'n/a (LibreHardwareMonitor)' }
        $gvr = if ($g.MT) { "$($g.MU)/$($g.MT) MB" } else { "$($g.MU) MB" }
        $ui.GPU.L.Text = "Load $($g.Load)%   Temp $gtxt   VRAM $gvr"
    } else { $ui.GPU.L.Text = 'Load/Temp indisponibile pe acest GPU' }
    $msg = 'Nicio limitare acum. Ruleaza un joc si uita-te aici pentru un test real.'
    if ($g -and $cpu -ge 85 -and $g.Load -lt 70)      { $msg = "BOTTLENECK CPU: procesorul ($cpu%) tine placa video la $($g.Load)%." }
    elseif ($g -and $g.Load -ge 95 -and $cpu -lt 80)  { $msg = "GPU la limita ($($g.Load)%): normal in jocuri, procesorul are rezerva." }
    elseif ($rp -ge 88)                                { $msg = "RAM aproape plin ($rp%): inchide aplicatii sau adauga memorie." }
    $Bottle.Text = "Analiza (momentul curent): $msg"
}
$tm = New-Object Windows.Threading.DispatcherTimer; $tm.Interval = [TimeSpan]::FromSeconds(2)
$tm.Add_Tick({ try { Update-Live } catch {} }); $tm.Start()

# ---------- Optimizari (tile-uri) ----------
function Update-Count { $n = @($script:checks | Where-Object { $_.IsChecked }).Count; $Count.Text = "$n optimizari selectate" }
function Select-Profile($lvl) {
    foreach ($c in $script:checks) { $c.IsChecked = ($c.Tag.P -le $lvl) }
    $cards[0].BorderBrush = Br $(if ($lvl -eq 2) { '#FF2E4D' } else { 'Transparent' })
    $cards[1].BorderBrush = Br $(if ($lvl -eq 3) { '#FF2E4D' } else { 'Transparent' })
    Update-Count
}
$accent = @{ 'AI SI COPILOT' = '#FF4D6D'; 'POWER PLAN' = '#FF8A5B'; 'GPU SI GAMING' = '#FF2E4D'; 'PERFORMANTA WINDOWS' = '#F472B6'
             'PRIVACY' = '#FFB7C5'; 'FPS BOOST' = '#FF9F1C'; 'SECURITATE (OPTIONAL)' = '#B91C1C'; $appGroup = '#FFC857'; 'PRIVACY: WINDOWS AI' = '#FF7AA2'; 'PRIVACY: EDGE AI' = '#FF7AA2'; 'PRIVACY: OFFICE AI' = '#FF7AA2' }
if ($gpuVendors -contains 'AMD') {
    $ac = New-Object Windows.Controls.Border
    $ac.Background = Br '#0C0407'; $ac.BorderBrush = Br '#FF2E4D'; $ac.BorderThickness = 1
    $ac.CornerRadius = 14; $ac.Padding = 14; $ac.Margin = '0,0,0,12'
    $asp = New-Object Windows.Controls.StackPanel
    $asp.Children.Add((TB 'AMD RADEON: SETARI RECOMANDATE IN ADRENALIN (manuale, nu se pot automatiza)' 12 '#FF2E4D' $true)) | Out-Null
    foreach ($ln in @(
        'Smart Access Memory: pornit. In BIOS activeaza Above 4G Decoding si Resizable BAR, apoi in Adrenalin la Performance > Tuning.',
        'Radeon Chill: oprit (limiteaza FPS-ul si adauga latenta).',
        'Enhanced Sync: oprit. Cu monitor FreeSync foloseste FreeSync si o limita de FPS cu 3 sub refresh (ex. 141 la 144 Hz).',
        'Anti-Lag: pornit in jocurile competitive (latenta mai mica). Daca un joc cu anti-cheat da erori, opreste-l pentru acel joc.',
        'Texture Filtering Quality: Performance. Surface Format Optimization: pornit. Tessellation: AMD Optimized.',
        'Shader Cache: AMD Optimized (nu il opri). Radeon Boost, Image Sharpening si AFMF: doar daca accepti calitate mai mica sau latenta mai mare pentru FPS in plus.')) {
        $x = TB ("- " + $ln) 11.5 '#F3E6EA' $false; $x.TextWrapping = 'Wrap'; $x.Margin = '0,5,0,0'
        $asp.Children.Add($x) | Out-Null
    }
    $ac.Child = $asp; $List.Children.Add($ac) | Out-Null
}
$script:checks = @()
foreach ($grp in ($tweaks | Group-Object { $_.G })) {
    $card = New-Object Windows.Controls.Border
    $card.Background = Br '#0C0407'; $card.BorderBrush = Br '#2E0D16'; $card.BorderThickness = 1
    $card.CornerRadius = 14; $card.Padding = 14; $card.Margin = '0,0,0,12'
    $sp = New-Object Windows.Controls.StackPanel
    $sp.Children.Add((TB $grp.Name.ToUpper() 12 $accent[$grp.Name] $true)) | Out-Null
    $sp.Children[0].Margin = '2,0,0,10'
    $wp = New-Object Windows.Controls.WrapPanel
    foreach ($t in $grp.Group) {
        $c = New-Object Windows.Controls.CheckBox
        $c.Tag = $t; $c.Width = 198; $c.Height = 94; $c.Margin = '0,0,10,10'
        if ($t.T) { $c.ToolTip = $t.T }
        $in = New-Object Windows.Controls.StackPanel
        $ic = TB (Get-Icon $t) 22 '#FFFFFF' $false; $ic.FontFamily = 'Segoe UI Emoji'
        $tx = TB ($(if ($t.S) { "$star " }) + $t.L) 11.5 '#F3E6EA' $false; $tx.TextWrapping = 'Wrap'; $tx.Margin = '0,6,14,0'
        $in.Children.Add($ic) | Out-Null; $in.Children.Add($tx) | Out-Null
        $c.Content = $in; $wp.Children.Add($c) | Out-Null; $script:checks += $c
    }
    $sp.Children.Add($wp) | Out-Null; $card.Child = $sp; $List.Children.Add($card) | Out-Null
}
$List.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent, [Windows.RoutedEventHandler]{ Update-Count })
$cards[0].Add_Click({ Select-Profile 2 })
$cards[1].Add_Click({ Select-Profile 3 })

# ---------- Aplicare + revenire la original ----------
$metaFile = "$bkDir\meta.json"
function Save-Meta {
    if (Test-Path $metaFile) { return }
    if (-not (Test-Path $bkDir)) { New-Item $bkDir -ItemType Directory -Force | Out-Null }
    $g = ((powercfg /getactivescheme) -replace '.*: ([0-9a-f-]{36}).*', '$1')
    @{ Scheme = $g; Hiber = [bool](Test-Path "$env:SystemDrive\hiberfil.sys") } | ConvertTo-Json | Set-Content $metaFile
}
$script:bk = [hashtable]::Synchronized($script:bk)
$script:q = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
$script:applyTimer = New-Object Windows.Threading.DispatcherTimer; $script:applyTimer.Interval = [TimeSpan]::FromMilliseconds(150)
$script:applyTimer.Add_Tick({
    $s = $null
    while ($script:q.TryDequeue([ref]$s)) {
        $tag, $txt = $s -split '\|', 2
        switch ($tag) {
            'DONE' { $script:applyTimer.Stop(); Save-Backup; $Bar.Value = $Bar.Maximum
                     Say ''; Say 'GATA! Reporneste PC-ul ca toate modificarile sa se aplice.'
                     $BtnApply.IsEnabled = $true; $BtnRevert.IsEnabled = $true
                     try { $script:wk.Dispose(); $script:wrs.Dispose() } catch {} }
            'OK'   { Say "OK   $txt"; $Bar.Value += 1 }
            'F'    { Say "FAIL $txt"; $Bar.Value += 1 }
            default { Say "INFO $txt" }
        }
    }
})
$BtnApply.Add_Click({
    $sel = @($script:checks | Where-Object { $_.IsChecked })
    if ($sel.Count -eq 0) { Say 'Nu ai selectat nimic.'; return }
    $BtnApply.IsEnabled = $false; $BtnRevert.IsEnabled = $false
    $Bar.Maximum = $sel.Count + 1; $Bar.Value = 0
    Save-Meta
    $items = @($sel | ForEach-Object { @{ L = $_.Tag.L; Do = $_.Tag.Do.ToString(); K = $_.Tag.K; E = $_.Tag.E; X = $_.Tag.X } })
    $defs = 'function RegSet {' + ${function:RegSet} + "}`nfunction Remove-AppPkg {" + ${function:Remove-AppPkg} + '}'
    $script:wrs = [runspacefactory]::CreateRunspace(); $script:wrs.Open()
    $script:wrs.SessionStateProxy.SetVariable('bk', $script:bk)
    $script:wk = [powershell]::Create(); $script:wk.Runspace = $script:wrs
    [void]$script:wk.AddScript({
        param($items, $q, $defs)
        . ([scriptblock]::Create($defs))
        $q.Enqueue('I|Creez punct de restaurare (in fundal)...')
        try { Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
              Checkpoint-Computer -Description '5AM Optimizer' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
              $q.Enqueue('I|punct de restaurare creat') }
        catch { $q.Enqueue('I|nu s-a creat punct nou (Windows permite unul la 24h)') }
        foreach ($it in $items) {
            try { & ([scriptblock]::Create($it.Do)) $it; $q.Enqueue("OK|$($it.L)") }
            catch { $q.Enqueue("F|$($it.L) : $($_.Exception.Message)") }
        }
        $q.Enqueue('DONE|')
    }).AddArgument($items).AddArgument($script:q).AddArgument($defs)
    $script:applyTimer.Start(); [void]$script:wk.BeginInvoke()
})
$BtnRevert.Add_Click({
    if ($script:bk.Count -eq 0 -and -not (Test-Path $metaFile)) { Say 'Nu exista nimic de anulat.'; return }
    foreach ($e in @($script:bk.Values)) {
        try {
            if ($e.Existed) { Set-ItemProperty -Path $e.Path -Name $e.Name -Value $e.Value -Type $e.Kind -Force }
            else { Remove-ItemProperty -Path $e.Path -Name $e.Name -ErrorAction SilentlyContinue }
            Say "UNDO $($e.Name)"
        } catch { Say "FAIL undo $($e.Name)" }
    }
    if (Test-Path $metaFile) {
        $m = Get-Content $metaFile -Raw | ConvertFrom-Json
        try { powercfg /setactive $m.Scheme; Say "UNDO power plan original" } catch {}
        if ($m.Hiber) { powercfg /hibernate on; Say 'UNDO hibernare pornita' }
        Remove-Item $metaFile -Force
    }
    $script:bk.Clear(); Remove-Item $bkFile -Force -ErrorAction SilentlyContinue; $Bar.Value = 0
    Say 'Setarile originale au fost puse la loc. Aplicatiile sterse nu revin de aici (le reinstalezi din Microsoft Store / winget).'
})

# ---------- Petale de cires + efect la click ----------
$rnd = New-Object Random; $ps = New-Object System.Collections.ArrayList; $script:spawn = 0
$petalCols = @('#FFB7C5', '#FF8FAB', '#FFD1DC', '#FF6B9D')
function Add-Petal($x, $y, $vx, $vy) {
    $e = New-Object Windows.Shapes.Ellipse
    $e.Width = 8 + $rnd.Next(6); $e.Height = $e.Width * 0.62; $e.Fill = Br $petalCols[$rnd.Next(4)]; $e.Opacity = 0.92
    $e.RenderTransformOrigin = '0.5,0.5'; $e.RenderTransform = New-Object Windows.Media.RotateTransform($rnd.Next(360))
    [Windows.Controls.Canvas]::SetLeft($e, $x); [Windows.Controls.Canvas]::SetTop($e, $y); $Fx.Children.Add($e) | Out-Null
    [void]$ps.Add(@{ E = $e; X = $x; Y = $y; VX = $vx; VY = $vy; R = ($rnd.NextDouble() * 6 - 3); T = ($rnd.NextDouble() * 6); K = 'p'; Life = 1.0; S = 0 })
}
function Add-Ring($x, $y) {
    $e = New-Object Windows.Shapes.Ellipse
    $e.Width = 10; $e.Height = 10; $e.Stroke = Br '#FF2E4D'; $e.StrokeThickness = 2
    $e.Effect = New-Object Windows.Media.Effects.DropShadowEffect -Property @{ Color = [Windows.Media.Color]::FromRgb(255, 46, 77); BlurRadius = 14; ShadowDepth = 0 }
    [Windows.Controls.Canvas]::SetLeft($e, $x - 5); [Windows.Controls.Canvas]::SetTop($e, $y - 5); $Fx.Children.Add($e) | Out-Null
    [void]$ps.Add(@{ E = $e; X = $x; Y = $y; K = 'r'; Life = 1.0; S = 10 })
}
$fxT = New-Object Windows.Threading.DispatcherTimer; $fxT.Interval = [TimeSpan]::FromMilliseconds(33)
$fxT.Add_Tick({
    for ($i = $ps.Count - 1; $i -ge 0; $i--) {
        $q = $ps[$i]; $dead = $false
        if ($q.K -eq 'p') {
            $q.T += 0.06; $q.X += $q.VX + [Math]::Sin($q.T) * 0.9; $q.VX *= 0.97
            $q.VY = [Math]::Min(2.6, $q.VY + 0.04); $q.Y += $q.VY; $q.E.RenderTransform.Angle += $q.R
            [Windows.Controls.Canvas]::SetLeft($q.E, $q.X); [Windows.Controls.Canvas]::SetTop($q.E, $q.Y)
            if ($q.Y -gt $Fx.ActualHeight) { $dead = $true }
        } else {
            $q.S += 5; $q.Life -= 0.04; $q.E.Width = $q.S; $q.E.Height = $q.S; $q.E.Opacity = [Math]::Max(0, $q.Life)
            [Windows.Controls.Canvas]::SetLeft($q.E, $q.X - $q.S / 2); [Windows.Controls.Canvas]::SetTop($q.E, $q.Y - $q.S / 2)
            if ($q.Life -le 0) { $dead = $true }
        }
        if ($dead) { $Fx.Children.Remove($q.E); $ps.RemoveAt($i) }
    }
    if ($ps.Count -eq 0) { $fxT.Stop() }
})
$w.Add_PreviewMouseLeftButtonDown({
    param($s, $e)
    $pt = $e.GetPosition($Fx); Add-Ring $pt.X $pt.Y; $fxT.Start()
    1..7 | ForEach-Object { $a = $rnd.NextDouble() * 6.28; Add-Petal $pt.X $pt.Y ([Math]::Cos($a) * 3) ([Math]::Sin($a) * 3 - 1) }
})

Select-Profile 2
Say 'Alege LOW sau ULTRA (sau ajusteaza manual), apoi apasa OPTIMIZEAZA.'
$w.ShowDialog() | Out-Null
try { $worker.Stop(); $rs.Close() } catch {}
