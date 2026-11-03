check-logs

Skrypt w bashu, który liczy linie z ERROR w plikach .log, oraz pipeline w GitHub Actions, który go uruchamia.

Co jest w repo
check-logs.sh - skrypt
logs/ - przykładowe logi do testów
.github/workflows/check-logs.yaml – pipeline
Co robi skrypt

./check-logs.sh - katalog

szuka plików .log w katalogu z pierwszego argumentu (jak go nie ma, to w .), razem z podkatalogami
wypisuje, ile jest linii z ERROR
jak jest przynajmniej jedna, kończy się kodem 1, jak nie ma żadnej kodem 0
jak nie ma żadnych plików .log, to wypisuje 0 i kończy się kodem 0 (bez błędu)
ma set -euo pipefail na początku
Jak do tego doszedłem

Najpierw problem z grep. Z set -e i pipefail skrypt kończył się błędem, gdy grep niczego nie znalazł. Okazało się, że grep zwraca kod 1, gdy nic nie znajdzie (0 = znalazł, 1 = nic, 2 = prawdziwy błąd). A brak ERROR albo brak plików .log to normalna sytuacja, więc dodałem || true w środku $(...), żeby ten kod 1 nie zabijał skryptu.

Sprawdzanie, czy są pliki .log. Najpierw myślałem, żeby użyć -f z *.log, ale to sprawdza jeden plik i tylko w bieżącym katalogu, a ja szukam rekurencyjnie. Dowiedziałem się, że do tego jest find "$katalog" -name "*.log" -type f. Jak wynik jest pusty, wypisuję 0 i kończę z kodem 0. (Sam grep -r --include w takiej sytuacji też zwróciłby kod 1, więc to sprawdzenie jest głównie dla czytelności.)

Błędy, które po drodze zrobiłem:

w grep brakowało -r, więc nie wchodził do katalogów
na końcu dałem | echo i | $zmienna zamiast zapisać wynik do zmiennej przez zmienna=$(...)
nie miałem cudzysłowów przy $katalog (rozwala się, jak jest spacja w ścieżce)
w if miałem [ zmienna -eq 0 ] bez $
zamiast exit z liczbą dałem exit 1, bo kod wyjścia ma max 255 i się zawija (256 błędów dałoby kod 0, czyli „sukces”). Liczba jest wypisywana osobno.
w linii 4 pomyliłem cudzysłowy wokół $(find ...) – dopiero pierwszy run w GitHub Actions pokazał błąd składni
Pipeline

Odpala się przy pushu i pull requeście na main / master. Kroki:

actions/checkout@v4 – bez tego maszyna jest pusta i nie ma skryptu
chmod +x check-logs.sh
./check-logs.sh ./logs | tee output.txt z shell: bash – tee zapisuje wynik do pliku i pokazuje go w logu. shell: bash jest po to, żeby działał pipefail, bo inaczej tee ukryłby kod wyjścia skryptu i krok byłby zielony mimo błędów
actions/upload-artifact@v4 z if: always() – żeby output.txt zapisał się też wtedy, gdy poprzedni krok jest czerwony

Po drodze: folder .github/workflows musi nazywać się dokładnie tak (najpierw zrobiłem workflow bez „s”), a w YAML-u wcięcia muszą być równe, tylko spacje.

Jak sprawdziłem

Lokalnie na trzech katalogach: z ERROR (liczba i kod 1), bez ERROR (0 i kod 0), bez plików .log (0 i kod 0).

W GitHub Actions: pierwszy run był czerwony przez błąd składni w skrypcie, po poprawce czerwony już przez 2 linie ERROR (kod 1, artefakt zapisany). Po usunięciu ERROR z logu run jest zielony.

Czego nie zrobiłem / ograniczenia:
jak katalog nie istnieje, find wypisze błąd, ale skrypt i tak powie 0 i skończy z kodem 0. Dałoby się to naprawić sprawdzeniem [ -d "$katalog" ] na początku
liczone są tylko pliki .log, pliki .txt z ERROR są pomijane (celowo)