# 5AM Optimizer

Aplicație pentru Windows 11 care optimizează PC-ul pentru gaming: oprește funcțiile AI (Copilot, Recall, Click to Do), reduce telemetria, setează power plan-ul, GPU-ul și alte opțiuni pentru FPS. Are specificațiile PC-ului și temperaturile live (AMD, NVIDIA, Intel).

## Descărcare

1. Intră la [**Releases**](../../releases/latest) și descarcă `5AMOptimizer.exe`.
2. Dă dublu-click. Cere drepturi de administrator (e normal, modifică setări de sistem).
3. Alege **LOW** sau **ULTRA**, bifează sau debifează ce vrei, apoi apasă **OPTIMIZEAZĂ** și repornește PC-ul.

> Windows SmartScreen poate afișa „Windows protected your PC", pentru că programul nu este semnat digital. Apasă **More info → Run anyway**. Codul sursă este în acest repo (`5AMOptimizer.ps1`), iar `.exe`-ul este compilat automat de GitHub Actions din el.

## Ce face

- **AI și Copilot:** Copilot, Recall, Click to Do, AI în Paint, Notepad, Edge și Office.
- **Privacy:** reclame, istoric de activitate, feedback, raportare de erori și altele.
- **Power plan și GPU:** Ultimate Performance, HAGS, Game Mode, Game DVR.
- **FPS BOOST:** prioritate pentru jocuri, optimizări pentru jocuri în fereastră, CPU fără parking și altele. Cele riscante sunt opționale.
- **Curățare aplicații:** elimină aplicațiile Microsoft pe care nu le folosești.
- **Revino la setările originale:** pune înapoi setările de registry, power plan-ul și hibernarea. Aplicațiile șterse se reinstalează din Microsoft Store sau cu winget.

Înainte de orice modificare, aplicația creează un punct de restaurare Windows.

## Actualizare automată

La pornire, aplicația verifică ultima versiune din [Releases](../../releases). Dacă există una mai nouă, o descarcă, verifică suma de control SHA256, se înlocuiește singură și repornește cu mesajul **„Aplicația a fost actualizată la versiunea X"**.

Dacă vrei să decizi tu când se actualizează, creează un fișier gol `noautoupdate.txt` în `%APPDATA%\WinGameOptimizer`. Atunci apare doar un buton **ACTUALIZEAZĂ**.

## Publicarea unei versiuni noi (pentru autor)

1. Modifică codul și scrie schimbările în `RELEASE_NOTES.md`.
2. Fă commit și push.
3. Creează un tag cu versiunea nouă și trimite-l:
   ```
   git tag v1.0.1
   git push origin v1.0.1
   ```
4. GitHub Actions rulează testele, compilează `5AMOptimizer.exe`, generează `5AMOptimizer.exe.sha256` și publică release-ul. Utilizatorii primesc actualizarea la următoarea pornire.

Versiunea din aplicație se setează automat din tag. Nu trebuie schimbată de mână.

## Avertisment

Programul modifică setări de sistem (registry, power plan, aplicații Windows). Folosește-l pe răspunderea ta. Nu este afiliat cu Microsoft, AMD sau NVIDIA. Nu dezactivează Defender, Firewall sau UAC. Memory Integrity (HVCI) poate fi oprit doar din secțiunea opțională, cu risc asumat.
