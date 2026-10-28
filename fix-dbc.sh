#!/bin/sh
set -e
f=lib/libc/db/db/db.c
cp -p "$f" "$f.pre-h"

s=$(grep -n '^#if defined(__minix)$' "$f" | cut -d: -f1)
e=$(grep -n '^#endif  /\* defined(__minix) \*/$' "$f" | cut -d: -f1)
echo "guard block: radky $s..$e"
[ -n "$s" ] && [ -n "$e" ] || { echo "CHYBA: hranice guardu nenalezeny"; exit 1; }
[ "$e" -gt "$s" ] && [ $((e-s)) -eq 6 ] || { echo "CHYBA: neocekavana delka guard bloku ($s..$e)"; exit 1; }

{
  head -n $((s-1)) "$f"
  printf '%b\n' \
    '#if defined(__minix)' \
    '#define\tUSE_OPEN_FLAGS\t\t\t\t\t\t\t\\' \
    '\t(O_CREAT | O_EXCL | O_NONBLOCK | O_RDONLY |\t\t\t\\' \
    '\t O_RDWR | O_TRUNC | O_CLOEXEC)' \
    '#else' \
    '#define\tUSE_OPEN_FLAGS\t\t\t\t\t\t\t\\' \
    '\t(O_CREAT | O_EXCL | O_EXLOCK | O_NONBLOCK | O_RDONLY |\t\t\\' \
    '\t O_RDWR | O_SHLOCK | O_TRUNC | O_CLOEXEC)' \
    '#endif  /* defined(__minix) */'
  tail -n +$((e+1)) "$f"
} > "$f.tmp" && mv "$f.tmp" "$f"

echo "--- vysledek ---"
sed -n "$((s-1)),$((s+9))p" "$f"
echo "--- sanity ---"
echo "define USE_OPEN_FLAGS pocet: $(grep -c 'define\tUSE_OPEN_FLAGS' "$f")"
grep -n 'O_EXLOCK\|O_SHLOCK' "$f"
