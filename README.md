# 5AM Optimizer - Gaming Edition

Aplicatie cu interfata grafica (WPF) pentru Windows 11 care dezactiveaza functiile AI / Copilot, reduce telemetria si aplica optimizari pentru gaming.

## Ce face

- **AI si Copilot**: opreste Copilot, Recall, Click to Do, AI in Notepad / Paint / Edge / Office, sugestiile Bing din cautare
- **Privacy**: fara ID de reclame, Timeline, locatie, feedback, tracking in Start, Spotlight pe lockscreen
- **Power plan**: Ultimate Performance, PCIe / USB suspend oprite, hibernare oprita, Power Throttling oprit
- **GPU si gaming**: Game Mode, Game DVR oprit, HAGS, mouse fara acceleratie
- **FPS BOOST**: Game Bar fara popup-uri, optimizari jocuri windowed, fara upload P2P, Nagle oprit, CPU la maxim (optional MPO, timer global, fullscreen optimizations)
- **Retea**: prioritate jocuri (MMCSS), cache DNS golit, DNS Cloudflare optional
- **Curatenie disc**: cache shadere, Windows Update, browsere, Windows.old (optional)
- **Servicii**: telemetrie oprita, servicii rar folosite pe Manual
- **Curatare aplicatii**: sterge aplicatii preinstalate (Teams, Bing News, Solitaire, OneDrive etc.)

### Foldere speciale

- **Manager pornire**: alegi ce porneste odata cu Windows (ca in Task Manager)
- **GPU pentru jocuri**: pui jocurile pe placa video dedicata (Performanta inalta)
- **Mod joc**: cand pornesti un joc inchide aplicatiile alese si le redeschide dupa
- **AMD Radeon Adrenalin**: setarile recomandate, apare doar daca ai placa AMD
- **Comparatie inainte / dupa**: dupa restart vezi timpul de pornire, RAM, procese, programe la pornire

### Dashboard hardware

CPU, GPU (AMD / NVIDIA / Intel: VRAM, driver, load, temperatura), RAM, discuri, analiza de bottleneck si sfaturi rapide (XMP, Hz monitor, Resizable BAR, driver vechi, TRIM). Apasa pe un chip ca sa vezi detaliile.

## Selectie

Optimizarile sunt grupate in foldere. Apasa pe un folder ca sa vezi ce e inauntru.

- **CU STELUTA**: doar cele recomandate (selectia implicita)
- **TOT** / **NIMIC**: bifeaza sau debifeaza tot
- In fiecare folder: **BIFEAZA TOT** / **DEBIFEAZA TOT**

Optiunile marcate **Optional** si **SECURITATE** nu sunt bifate implicit, le activezi manual doar daca ai nevoie. Treci cu mouse-ul peste optimizarile din FPS BOOST ca sa vezi ce fac.

## Descarcare si rulare

**Varianta recomandata (.exe):**

1. Intra la [Releases](https://github.com/claudiujoldos-ai/5AM-Optimizer/releases/latest) si descarca `5AMOptimizer.exe`
2. Ruleaza-l. Cere singur drepturi de Administrator
3. Daca Windows SmartScreen il blocheaza: **More info** > **Run anyway** (aplicatia nu este semnata digital)

Langa `.exe` gasesti si `5AMOptimizer.exe.sha256`, cu care poti verifica fisierul descarcat:

```powershell
(Get-FileHash .\5AMOptimizer.exe -Algorithm SHA256).Hash
```

**Varianta script (.ps1):**

1. Descarca `5AMOptimizer.ps1`
2. Click dreapta pe fisier > **Properties** > bifeaza **Unblock** (daca apare) > OK
3. Click dreapta > **Run with PowerShell**, sau din PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\5AMOptimizer.ps1
```

## Actualizare automata

La pornire, aplicatia verifica ultimul release de pe GitHub. Varianta `.exe` descarca singura versiunea noua, verifica suma SHA256 si se reporneste actualizata. Varianta `.ps1` doar te anunta ca exista o versiune noua.

Pentru a opri actualizarea automata, creeaza fisierul gol `%APPDATA%\WinGameOptimizer\noautoupdate.txt`. Aplicatia va afisa atunci doar un buton **ACTUALIZEAZA**.

## Siguranta si revenire

- Inainte de aplicare se incearca un **punct de restaurare** (Windows permite unul la 24h)
- Fiecare valoare din registry modificata este salvata in `%APPDATA%\WinGameOptimizer\backup.json`
- Butonul **REVINO LA SETARILE ORIGINALE** pune la loc registry-ul, power plan-ul si hibernarea
- **Aplicatiile sterse NU revin** prin acest buton; le reinstalezi din Microsoft Store sau cu `winget`

## Atentie

- Oprirea **Memory Integrity (HVCI)** scade protectia sistemului
- Optiunea **CPU 100% minim** creste consumul si temperaturile si in idle
- Unele optiuni necesita restart sau relogare
- Folosesti aplicatia pe propria raspundere

## Temperaturi CPU / GPU

Pentru citirea temperaturilor porneste [LibreHardwareMonitor](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor) in fundal. Pe placile NVIDIA datele vin direct din `nvidia-smi`.

## Cerinte

- Windows 11 (functioneaza partial si pe Windows 10)
- Windows PowerShell 5.1

## Pentru dezvoltare: cum publici o versiune noua

Release-urile se construiesc automat cu GitHub Actions (`.github/workflows/build.yml`):

1. Scrie noutatile in `RELEASE_NOTES.md`
2. Creeaza un tag nou, de exemplu `v1.0.1`, si da push
3. Workflow-ul ruleaza auto-testul, compileaza `.exe`-ul cu ps2exe si publica release-ul cu `.exe` + `.sha256`

## Licenta

[MIT](LICENSE)
