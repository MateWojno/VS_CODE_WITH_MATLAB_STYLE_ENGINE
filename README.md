# VS Code + GNU Octave (`--no-gui`) — MATLAB-Style Learning Environment

> **Language / Język:** [English](#-english-version) | [Polski](#-wersja-polska)

A lightweight, free alternative to MATLAB for academic coursework, numerical computing, and prototyping. It pairs **Visual Studio Code** (syntax highlighting & editing via the official MATLAB extension) with **GNU Octave** running in headless CLI mode (`--no-gui`) directly inside the VS Code integrated terminal.

---

<a id="-english-version"></a>
## 🇬🇧 English Version

### Table of Contents
1. [Environment & Prerequisites](#en-1-environment--prerequisites)
2. [Installation & Setup](#en-2-installation--setup)
3. [Launching the Octave CLI Engine](#en-3-launching-the-octave-cli-engine)
4. [Octave CLI Cheat Sheet & Workflow](#en-4-octave-cli-cheat-sheet--workflow)
5. [MATLAB vs. GNU Octave Compatibility & Porting Guide](#en-5-matlab-vs-gnu-octave-compatibility--porting-guide-example-octave_dtree_platformer_v5m--p6m)

<a id="en-1-environment--prerequisites"></a>
### 1. Environment & Prerequisites
* **Host OS:** Windows 11 Pro (x64)
* **Editor:** [Visual Studio Code](https://code.visualstudio.com/)
* **VS Code Extension:** [MATLAB Extension for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=MathWorks.language-matlab) (`MathWorks.language-matlab`) — provides `.m` syntax highlighting, snippets, and code formatting.
* **Computation Engine:** [GNU Octave](https://octave.org/download#ms-windows) (CLI mode `--no-gui`).

<a id="en-2-installation--setup"></a>
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

<a id="en-3-launching-the-octave-cli-engine"></a>
### 3. Launching the Octave CLI Engine
1. Open the integrated terminal in VS Code using `` Ctrl + ` `` (or `` Ctrl + ~ ``).
2. Type `octave-cli` (or type `oc` and press `Tab` for PowerShell autocomplete) and press `Enter`.
3. GNU Octave starts in `--no-gui` mode directly inside your editor workspace.

<a id="en-4-octave-cli-cheat-sheet--workflow"></a>
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

<a id="en-5-matlab-vs-gnu-octave-compatibility--porting-guide-example-octave_dtree_platformer_v5m--p6m"></a>
### 5. MATLAB vs. GNU Octave Compatibility & Porting Guide (Example: `octave_dtree_platformer_v5.m` / `p6.m`)

While GNU Octave is largely source-compatible with MATLAB, subtle differences in syntax, graphics backends, and testing frameworks require defensive patterns when writing cross-compatible `.m` files (as demonstrated in `octave_dtree_platformer_v5.m`):

| Feature / Area | MATLAB | GNU Octave | Cross-Compatibility Strategy |
| :--- | :--- | :--- | :--- |
| **Comments & Block Endings** | `%` comments, `end` keyword | `%` or `#` comments; `endif`, `endfor`, `endfunction` | Stick strictly to `%` for comments and universal `end` keywords so MATLAB does not throw syntax errors. |
| **String Quotes** | `'char'` vs. `"string"` (distinct types) | `'char'` and `"string"` are both char arrays | Use single quotes `'...'` for identifiers, property names, and struct fields (`'Visible'`, `'off'`). |
| **Function Ordering** | Local functions allowed at end of scripts (R2016b+) | Functions must be declared before calls in scripts, or use a primary function file | Wrap the file in a primary top-level function (`function varargout = p6(varargin)`) so all helper subfunctions are accessible anywhere in the file. |
| **Unit Testing** | Class-based (`matlab.unittest`) or function-based tests | Inline `%!test` blocks executed via `test <filename>` | Embed `%!test` blocks at the bottom of the file (MATLAB ignores them as comments). Expose private helpers via a dispatcher (`if strncmp(varargin{1}, '__call__', 8)`). |
| **Graphics Toolkits (`--no-gui`)** | Native Java/HG2 rendering engine | `fltk`, `qt`, or `gnuplot` (`qt` can fail in headless CLI mode) | Probe available toolkits (`display_select_toolkit({'fltk', 'qt'})`) and guard Octave-only calls with `if exist('graphics_toolkit', 'file')`. |
| **Argument Validation** | `arguments ... end` blocks (R2019b+) | Partial/limited support depending on Octave version | Use classic `nargin` checks (`if nargin < 1 || isempty(arg)`) for universal compatibility. |

#### Running Cross-Compatible Code Across Environments
* **In GNU Octave CLI (`--no-gui`):**
  ```octave
  test octave_dtree_platformer_v5         % Run embedded %!test unit tests
  octave_dtree_platformer_v5()            % Run primary function
  source('octave_dtree_platformer_v5.m')  % Alternative execution via source()
  ```
* **In MATLAB:**
  Call the entry-point function directly from the Command Window (`octave_dtree_platformer_v5()` or `p6()`). Guard Octave-specific builtins (`graphics_toolkit`, `isguirunning`) with `exist(..., 'builtin')` / `exist(..., 'file')` so MATLAB skips them cleanly.

---

<a id="-wersja-polska"></a>
## 🇵🇱 Wersja Polska

Lekka, darmowa alternatywa dla środowiska MATLAB przeznaczona do nauki, zajęć na studiach oraz obliczeń numerycznych. Łączy edytor **Visual Studio Code** (kolorowanie składni dzięki oficjalnej wtyczce MATLAB) z silnikiem **GNU Octave** uruchamianym w trybie tekstowym (`--no-gui`) bezpośrednio w zintegrowanym terminalu VS Code.

### Spis treści
1. [Środowisko i wymagania wstępne](#pl-1-srodowisko-i-wymagania-wstepne)
2. [Instalacja i konfiguracja](#pl-2-instalacja-i-konfiguracja)
3. [Uruchamianie silnika Octave CLI](#pl-3-uruchamianie-silnika-octave-cli)
4. [Instrukcja obsługi i ściągawka Octave CLI](#pl-4-instrukcja-obslugi-i-sciagawka-octave-cli)
5. [Różnice składniowe MATLAB vs. GNU Octave i przenoszenie kodu](#pl-5-roznice-skladniowe-matlab-vs-gnu-octave-i-przenoszenie-kodu-przyklad-octave_dtree_platformer_v5m--p6m)

<a id="pl-1-srodowisko-i-wymagania-wstepne"></a>
### 1. Środowisko i wymagania wstępne
* **System operacyjny:** Windows 11 Pro (x64)
* **Edytor kodu:** [Visual Studio Code](https://code.visualstudio.com/)
* **Wtyczka VS Code:** [MATLAB Extension for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=MathWorks.language-matlab) (`MathWorks.language-matlab`) — zapewnia kolorowanie składni plików `.m`, podpowiedzi oraz formatowanie kodu.
* **Silnik obliczeniowy:** [GNU Octave](https://octave.org/download#ms-windows) (tryb konsolowy `--no-gui`).

<a id="pl-2-instalacja-i-konfiguracja"></a>
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

<a id="pl-3-uruchamianie-silnika-octave-cli"></a>
### 3. Uruchamianie silnika Octave CLI
1. Otwórz zintegrowany terminal w Visual Studio Code skrótem `` Ctrl + ` `` (lub `` Ctrl + ~ ``).
2. Wpisz `octave-cli` (lub wpisz `oc` i naciśnij klawisz `Tab`, aby skorzystać z autouzupełniania PowerShell) i zatwierdź klawiszem `Enter`.
3. Silnik Octave uruchomi się w trybie `--no-gui` bezpośrednio w katalogu roboczym projektu.

<a id="pl-4-instrukcja-obslugi-i-sciagawka-octave-cli"></a>
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
| `cd` | Zmienia bieżącą ścieżkę roboczą | `cd('C:/sciezka/do/folderu')` |
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

<a id="pl-5-roznice-skladniowe-matlab-vs-gnu-octave-i-przenoszenie-kodu-przyklad-octave_dtree_platformer_v5m--p6m"></a>
### 5. Różnice składniowe MATLAB vs. GNU Octave i przenoszenie kodu (przykład: `octave_dtree_platformer_v5.m` / `p6.m`)

Mimo wysokiej zgodności składniowej, uruchamianie tych samych plików `.m` w MATLAB-ie oraz GNU Octave wymaga stosowania kilku wzorców obronnych (zastosowanych w `octave_dtree_platformer_v5.m`):

| Obszar / Cecha | MATLAB | GNU Octave | Strategia pełnej kompatybilności |
| :--- | :--- | :--- | :--- |
| **Komentarze i zamykanie bloków** | Komentarze `%`, słowo kluczowe `end` | Komentarze `%` lub `#`; bloki `endif`, `endfor`, `endfunction` | Stosuj wyłącznie `%` do komentarzy oraz uniwersalne `end` do zamykania bloków (konstrukcje `#` i `endif` powodują błędy w MATLAB-ie). |
| **Cudzysłowy i ciągi znaków** | `'char'` (tablica znaków) vs. `"string"` (obiekt) | `'...'` oraz `"..."` traktowane są jako tablice `char` | Używaj pojedynczych apostrofów `'...'` dla nazw właściwości, kluczy i parametrów (`'Visible'`, `'off'`). |
| **Kolejność funkcji w pliku** | Funkcje lokalne mogą być na końcu skryptu | W skryptach funkcja musi być zdefiniowana przed jej wywołaniem | Zdefiniuj główną funkcję na samej górze pliku (`function varargout = p6(varargin)`), dzięki czemu wszystkie funkcje pomocnicze są widoczne w całym pliku. |
| **Testy jednostkowe** | Framework `matlab.unittest` lub testy funkcyjne | Bloki `%!test` uruchamiane poleceniem `test <nazwa_pliku>` | Umieszczaj testy w blokach `%!test` na końcu pliku (MATLAB traktuje je jako zwykłe komentarze). W Octave udostępnij funkcje prywatne przez dispatcher (`if strncmp(varargin{1}, '__call__', 8)`). |
| **Silniki graficzne (`--no-gui`)** | Wbudowany silnik graficzny HG2 | Backendy `fltk`, `qt`, `gnuplot` (`qt` bywa niestabilny bez GUI) | Wykrywaj i testuj dostępny silnik przed utworzeniem okna (`display_select_toolkit({'fltk', 'qt'})`), a dla MATLAB-a zabezpiecz wywołania funkcją `exist('graphics_toolkit', 'file')`. |
| **Walidacja argumentów** | Bloki `arguments ... end` (od R2019b) | Ograniczone wsparcie w starszych wersjach Octave | Stosuj klasyczne sprawdzanie `nargin` (`if nargin < 1 || isempty(arg)`), które działa identycznie w obu środowiskach. |

#### Jak uruchamiać kod między środowiskami?
* **W GNU Octave CLI (`--no-gui`):**
  ```octave
  test octave_dtree_platformer_v5         % Uruchomienie testów %!test
  octave_dtree_platformer_v5()            % Wywołanie funkcji głównej
  source('octave_dtree_platformer_v5.m')  % Uruchomienie przez source()
  ```
* **W MATLAB:**
  Wywołaj funkcję główną bezpośrednio w *Command Window* (`octave_dtree_platformer_v5()` lub `p6()`). Funkcje specyficzne dla GNU Octave (`graphics_toolkit`, `isguirunning`) warto owinąć warunkiem `if exist('isguirunning', 'builtin')`, aby MATLAB bezpiecznie je pomijał.
