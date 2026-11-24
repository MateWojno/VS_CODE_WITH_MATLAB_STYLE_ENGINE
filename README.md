# VS Code + GNU Octave (`--no-gui`) — MATLAB-Style Learning Environment

> **Language / Język:** [English](#-english-version) | [Polski](#-wersja-polska)

A lightweight, free alternative to MATLAB for academic coursework, numerical computing, and prototyping. It pairs **Visual Studio Code** (syntax highlighting & editing via the official MATLAB extension) with **GNU Octave** running in headless CLI mode (`--no-gui`) directly inside the VS Code integrated terminal.

---

<a id="-english-version"></a>
## 🇬🇧 English Version

### 1. Environment & Prerequisites
* **Host OS:** Windows 11 Pro (x64)
* **Editor:** [Visual Studio Code](https://code.visualstudio.com/)
* **VS Code Extension:** [MATLAB Extension for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=MathWorks.language-matlab) (`MathWorks.language-matlab`) — provides `.m` syntax highlighting, snippets, and code formatting.
* **Computation Engine:** [GNU Octave](https://octave.org/download#ms-windows) (CLI mode `--no-gui`).

### 2. Installation & Setup

#### Step 1: Install GNU Octave
1. Download the Windows 11 x64 installer from the official [GNU Octave Download Page](https://octave.org/download#ms-windows).
2. Run the installer and complete the setup.
3. *(Recommended)* Add the Octave `mingw64\bin` directory (e.g., `C:\Program Files\GNU Octave\Octave-x.x.x\mingw64\bin`) to your Windows `PATH` environment variable so `octave-cli` is accessible globally from any terminal.

#### Step 2: Configure Visual Studio Code
1. Install [Visual Studio Code](https://code.visualstudio.com/).
2. Open the Extensions view (`Ctrl + Shift + X`), search for **MATLAB** (`MathWorks.language-matlab`), and install it.

#### Step 3: Clone & Open the Project
```powershell
git clone <YOUR_REPOSITORY_URL>
cd <PROJECT_FOLDER_NAME>
code .
```

### 3. Launching the Octave CLI Engine
1. Open the integrated terminal in VS Code using `` Ctrl + ` `` (or `` Ctrl + ~ ``).
2. Type `octave-cli` (or type `oc` and press `Tab` for PowerShell autocomplete) and press `Enter`.
3. GNU Octave starts in `--no-gui` mode directly inside your editor workspace.

### 4. Octave CLI Cheat Sheet & Workflow

#### Executing `.m` Scripts
Run scripts located in your current working directory using `source()`:
```octave
% Execute a script file
source("script.m")

% Execute a script in a specific evaluation context (e.g., "base" or "caller")
source("script.m", "base")
```

#### Editing Files from Inside Octave CLI
Launch an external editor or open a file directly in VS Code without leaving the Octave prompt:
```octave
% Open file in Visual Studio Code
system('code "filename.m"')

% Open file in Windows Notepad
system('notepad "filename.m"')
```

#### Navigation & File I/O Commands
| Command | Description | Example |
| :--- | :--- | :--- |
| `pwd` | Print current working directory | `pwd` |
| `cd` | Change current working directory | `cd('C:/path/to/folder')` |
| `ls` | List files in the current directory | `ls` |
| `fopen` | Open or create a file (`'r'`, `'w'`, `'a'`) | `fid = fopen('myfile.txt', 'w');` |
| `fclose` | Close an open file descriptor *(mandatory to flush buffers)* | `fclose(fid);` |
| `delete` | Delete a file from disk | `delete('myfile.txt')` |

> **Important (File I/O):** Always store the file identifier returned by `fopen()` and pass it to `fclose(fid)` (or call `fclose('all')`) to ensure data is written to disk and file locks are released.

#### Graphics Toolkits (Plotting)
If plots do not render or you need to switch backends in `--no-gui` mode, check and set the graphics toolkit:
```octave
% List available toolkits (typically: fltk, gnuplot, qt)
available_graphics_toolkits()

% Switch active toolkit (e.g., qt or gnuplot)
graphics_toolkit("qt")
```

---

<a id="-wersja-polska"></a>
## 🇵🇱 Wersja Polska

Lekka, darmowa alternatywa dla środowiska MATLAB przeznaczona do nauki, zajęć na studiach oraz obliczeń numerycznych. Łączy edytor **Visual Studio Code** (kolorowanie składni dzięki oficjalnej wtyczce MATLAB) z silnikiem **GNU Octave** uruchamianym w trybie tekstowym (`--no-gui`) bezpośrednio w zintegrowanym terminalu VS Code.

### 1. Środowisko i wymagania wstępne
* **System operacyjny:** Windows 11 Pro (x64)
* **Edytor kodu:** [Visual Studio Code](https://code.visualstudio.com/)
* **Wtyczka VS Code:** [MATLAB Extension for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=MathWorks.language-matlab) (`MathWorks.language-matlab`) — zapewnia kolorowanie składni plików `.m`, podpowiedzi oraz formatowanie kodu.
* **Silnik obliczeniowy:** [GNU Octave](https://octave.org/download#ms-windows) (tryb konsolowy `--no-gui`).

### 2. Instalacja i konfiguracja

#### Krok 1: Instalacja GNU Octave
1. Pobierz instalator dla Windows 11 x64 z oficjalnej strony [GNU Octave](https://octave.org/download#ms-windows).
2. Zainstaluj program, przechodząc przez kreator instalacji.
3. *(Zalecane)* Dodaj ścieżkę do katalogu `mingw64\bin` (np. `C:\Program Files\GNU Octave\Octave-x.x.x\mingw64\bin`) do systemowej zmiennej środowiskowej `PATH`, aby uruchamiać `octave-cli` z dowolnego miejsca w terminalu.

#### Krok 2: Konfiguracja Visual Studio Code
1. Pobierz i zainstaluj [Visual Studio Code](https://code.visualstudio.com/).
2. Otwórz zakładkę rozszerzeń (`Ctrl + Shift + X`), wyszukaj **MATLAB** (`MathWorks.language-matlab`) i kliknij **Install**.

#### Krok 3: Pobranie i otwarcie repozytorium
```powershell
git clone <ADRES_REPOZYTORIUM>
cd <NAZWA_FOLDERU_PROJEKTU>
code .
```

### 3. Uruchamianie silnika Octave CLI
1. Otwórz zintegrowany terminal w Visual Studio Code skrótem `` Ctrl + ` `` (lub `` Ctrl + ~ ``).
2. Wpisz `octave-cli` (lub wpisz `oc` i naciśnij klawisz `Tab`, aby skorzystać z autouzupełniania PowerShell) i zatwierdź klawiszem `Enter`.
3. Silnik Octave uruchomi się w trybie `--no-gui` bezpośrednio w katalogu roboczym projektu.

### 4. Instrukcja obsługi i ściągawka Octave CLI

#### Uruchamianie skryptów `.m`
Aby wykonać skrypt znajdujący się w bieżącym katalogu roboczym, użyj funkcji `source()`:
```octave
% Uruchomienie skryptu
source("wpr8.m")

% Uruchomienie skryptu w określonym kontekście (np. "base" lub "caller")
source("wpr8.m", "base")
```

#### Edycja plików bezpośrednio z poziomu Octave CLI
Możesz otworzyć plik w edytorze bez zamykania sesji Octave:
```octave
% Otwarcie pliku w Visual Studio Code
system('code "filename.m"')

% Otwarcie pliku w systemowym Notatniku
system('notepad "filename.m"')
```

#### Nawigacja i operacje na plikach (File I/O)
| Polecenie | Opis | Przykład użycia |
| :--- | :--- | :--- |
| `pwd` | Wyświetla bieżącą ścieżkę roboczą | `pwd` |
| `cd` | Zmienia bieżący katalog roboczy | `cd('C:/sciezka/do/folderu')` |
| `ls` | Wyświetla listę plików w bieżącym katalogu | `ls` |
| `fopen` | Otwiera lub tworzy plik (`'r'`, `'w'`, `'a'`) | `fid = fopen('myfile.txt', 'w');` |
| `fclose` | Zamyka otwarty uchwyt pliku *(wymagane do zapisu danych)* | `fclose(fid);` |
| `delete` | Usuwa plik z dysku | `delete('myfile.txt')` |

> **Ważne (operacje na plikach):** Zawsze przypisuj identyfikator zwracany przez `fopen()` do zmiennej (np. `fid`) i zamykaj plik przez `fclose(fid)` (lub `fclose('all')`), aby zapisać bufor na dysku i zwolnić blokadę pliku.

#### Silniki graficzne (wykresy w trybie `--no-gui`)
Dostępne backendy graficzne w środowisku to `fltk`, `gnuplot` oraz `qt`. W razie problemów z wyświetlaniem wykresów możesz przełączyć silnik:
```octave
% Sprawdzenie dostępnych silników graficznych
available_graphics_toolkits()

% Przełączenie aktywnego silnika (np. na qt lub gnuplot)
graphics_toolkit("qt")
```
