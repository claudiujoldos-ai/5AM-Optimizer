<p align="center"><img src="assets/icon.png" width="220" alt="5AM Optimizer"></p>

# 5AM Optimizer - Gaming Edition

> **English:** Windows 11 gaming optimizer with a cherry-blossom UI: turns off AI / Copilot / Recall and telemetry, tunes power, GPU, network and FPS settings, measures real in-game FPS (PresentMon), finds bottlenecks and proves the gain with a before / after card. Everything is reversible and never touches game processes (safe with anti-cheat). Download: [5AMOptimizer.exe](https://github.com/claudiujoldos-ai/5AM-Optimizer/releases/latest/download/5AMOptimizer.exe). Switch the language to English in **APP SETTINGS** (Windows in a language other than Romanian starts in English automatically).

Aplicatie cu interfata grafica (WPF) pentru Windows 11 care dezactiveaza functiile AI / Copilot, reduce telemetria si aplica optimizari pentru gaming.

## Ce face

- **AI si Copilot**: opreste Copilot, Recall, Click to Do, AI in Notepad / Paint / Edge / Office, sugestiile Bing din cautare
- **Privacy**: fara ID de reclame, Timeline, locatie, feedback, tracking in Start, Spotlight pe lockscreen
- **Power plan**: Ultimate Performance, PCIe / USB suspend oprite, hibernare oprita, Power Throttling oprit
- **GPU si gaming**: Game Mode, Game DVR oprit, HAGS, mouse fara acceleratie
- **FPS BOOST**: prioritate pentru jocul din prim-plan, VRR si in jocurile windowed, optimizari jocuri windowed, fara Sticky Keys in jocuri, Game Bar fara popup-uri, fara upload P2P, Nagle oprit, CPU la maxim (optional MPO, timer global, fullscreen optimizations, MSI mode pentru placa video)
- **Performanta Windows**: meniuri instant, aplicatiile de la pornire fara intarziere, Edge oprit in fundal, efecte vizuale reduse (optional: indexare, SysMain, drivere prin Windows Update)
- **Retea**: prioritate jocuri (MMCSS), cache DNS golit, DNS Cloudflare optional, placa de retea fara economie de energie (optional)
- **Curatenie disc**: cache shadere, Windows Update, browsere, Windows.old (optional)
- **Servicii**: telemetrie oprita, servicii rar folosite pe Manual
- **Securitate (optional)**: Memory Integrity, VBS, excluderi Windows Defender pentru folderele cu jocuri
- **Curatare aplicatii**: sterge aplicatii preinstalate (Teams, Bing News, Solitaire, OneDrive etc.)

### Interfata

- **Scor 5AM** (0-100) in antet: cat de pregatit e PC-ul pentru jocuri; apasa pe el pentru lista cu ce ai bun si ce mai poti imbunatati
- **Grafice live** pentru CPU, placa video si RAM
- **Iconite 3D** ([Microsoft Fluent Emoji](https://github.com/microsoft/fluentui-emoji), licenta MIT) si logo-urile reale ale aplicatiilor instalate
- **Teme**: Sakura, Midnight, Neon, Violet
- **Langa ceas**: aplicatia poate ramane in fundal (Mod joc continua sa lucreze) si poate porni odata cu Windows

### Foldere speciale

- **Manager pornire**: alegi ce porneste odata cu Windows (ca in Task Manager)
- **GPU pentru jocuri**: pui jocurile pe placa video dedicata (Performanta inalta)
- **Mod joc**: cand pornesti un joc inchide aplicatiile alese si le redeschide dupa; optional timer 0.5 ms, curatarea memoriei standby (ca ISLC) si prioritate mare pentru joc
- **AMD Radeon Adrenalin** / **NVIDIA GeForce**: setarile recomandate in driver, apar dupa placa ta video
- **Setari aplicatie**: tema, petale de cires, langa ceas, pornire cu Windows
- **Comparatie inainte / dupa**: dupa restart vezi timpul de pornire, RAM, procese, programe la pornire

### Benchmark si bottleneck

- **Test FPS in joc**: pornesti testul, intri in joc, iar aplicatia masoara 30 / 60 / 120 s cu [PresentMon](https://github.com/GameTechDev/PresentMon) (Intel, open-source, fara injectare in joc). Rezultat: FPS mediu, 1% low, 0.1% low, comparatie cu testul anterior pe acelasi joc. PresentMon se descarca la prima folosire si i se verifica SHA256
- **Test la capacitate maxima**: procesor pe un nucleu si pe toate nucleele la 100%, viteza RAM, disc de sistem (scriere / citire reale, fara cache), placa video (scena 3D DirectX cu efecte de shader pe tot ecranul). Scoruri, temperaturi maxime si comparatie cu testul anterior
- **DOVADA 5AM**: flux ghidat test inainte -> optimizare -> restart -> test dupa, cu un card-imagine de impartasit (ex. "128 -> 147 FPS, +15%"), salvat in Imagini sau copiat pentru Discord
- **BOTTLENECK**: bare pentru procesor, cel mai incarcat nucleu, placa video, VRAM si RAM din ultimul test, plus verdictul (limita pe GPU, pe procesor, FPS plafonat, VRAM / RAM plin, temperaturi)

### Dashboard hardware

CPU, GPU (AMD / NVIDIA / Intel: VRAM, driver si Adrenalin, chip, BIOS, PCIe, load, temperatura, frecvente, consum, ventilator), RAM, discuri, analiza de bottleneck si sfaturi rapide (XMP, Hz monitor, Resizable BAR, driver vechi, TRIM). Apasa pe un chip ca sa vezi detaliile.

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

## Siguranta si anti-cheat

Aplicatia nu citeste, nu scrie si nu injecteaza nimic in procesele jocurilor. Toate optimizarile sunt setari Windows / driver, la fel ca cele facute manual din Setari. Masurarea FPS foloseste PresentMon (evenimente Windows ETW), fara acces la joc. Singura optiune care atinge procesul jocului este "Prioritate mare pentru procesul jocului" din Mod joc, oprita implicit.

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

Pentru temperaturi, frecvente, consum si ventilator pe AMD / Intel porneste [LibreHardwareMonitor](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor) in fundal. Pe placile NVIDIA datele vin direct din `nvidia-smi`.

## Cerinte

- Windows 11 (functioneaza partial si pe Windows 10)
- Windows PowerShell 5.1

## Pentru dezvoltare: cum publici o versiune noua

Release-urile se publica automat cu GitHub Actions (`.github/workflows/build.yml`). Nu trebuie creat nimic manual:

1. Modifica `5AMOptimizer.ps1` si scrie noutatile in `RELEASE_NOTES.md`
2. Mareste versiunea pe linia `$AppVersion = '1.1.0'` (de exemplu `1.1.1`)
3. Da push pe `main`

Workflow-ul ruleaza auto-testul, compileaza `.exe`-ul cu ps2exe si publica release-ul `v1.1.1` cu `.exe` + `.sha256`. Aplicatiile deja instalate se actualizeaza singure la urmatoarea pornire. Daca versiunea nu s-a schimbat, se face doar build si test, fara release.

## Licenta

[MIT](LICENSE)
