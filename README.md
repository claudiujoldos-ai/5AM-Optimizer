# 5AM Optimizer (WinGame Optimizer v2 - Gaming Edition)

Aplicatie cu interfata grafica (WPF) pentru Windows 11 care dezactiveaza functiile AI / Copilot, reduce telemetria si aplica optimizari pentru gaming.

## Ce face

- **AI si Copilot**: opreste Copilot, Recall, Click to Do, AI in Notepad / Paint / Edge / Office, sugestiile Bing din cautare
- **Privacy**: fara ID de reclame, Timeline, locatie, feedback, tracking in Start, Spotlight pe lockscreen
- **Power plan**: Ultimate Performance, PCIe / USB suspend oprite, hibernare oprita, Power Throttling oprit
- **GPU si gaming**: Game Mode, Game DVR oprit, HAGS, mouse fara acceleratie, prioritate MMCSS pentru jocuri, optimizari pentru jocuri windowed
- **Retea**: fara throttling multimedia, Nagle oprit (jocuri TCP)
- **Curatare aplicatii**: sterge aplicatii preinstalate (Teams, Bing News, Solitaire, OneDrive etc.)
- **Dashboard hardware live**: CPU, GPU (AMD / NVIDIA / Intel), RAM, discuri, plus o analiza simpla de bottleneck
- **Recomandari AMD Adrenalin** afisate automat daca ai placa Radeon

## Profiluri

| Profil | Ce include |
|--------|-----------|
| **LOW** | Optimizari sigure, recomandat pentru majoritatea utilizatorilor |
| **ULTRA** | Tot, inclusiv stergerea definitiva a unor aplicatii |

Optiunile marcate **Optional** (MPO, timer global, fullscreen optimizations, Memory Integrity) nu sunt bifate de niciun profil, le activezi manual doar daca ai nevoie.

## Cum il rulezi

1. Descarca `WinGameOptimizer.ps1`
2. Click dreapta pe fisier > **Properties** > bifeaza **Unblock** (daca apare) > OK
3. Click dreapta > **Run with PowerShell**

Sau dintr-un terminal PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\WinGameOptimizer.ps1
```

Aplicatia cere singura drepturi de Administrator.

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
