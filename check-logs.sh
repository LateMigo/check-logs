#!/bin/bash
set -euo pipefail
katalog="${1:-.}"
if [ -z "$(find ${katalog} -name *.log" -type f)" ]; then
    echo "Nie ma zadnego pliku z rozszerzeniem .log (0)"
    exit 0
fi
zmienna=$(grep -r --include="*.log" "ERROR" "${katalog}" | wc -l || true)
echo "Liczba ERROROW to ${zmienna}"
if [ "${zmienna}" -eq 0 ]; then
    exit 0
else
    exit 1
fi


