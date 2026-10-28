#!/bin/sh
# pax: odstranit nahou globalni definici chdname z bin/pax/extern.h
# (relikvie -fcommon ery, clang -fno-common hazi duplicate symbol)
# a jedinou definici vlozit do bin/pax/options.c za include blok (mirror netbsd-11)
set -e
f=bin/pax/extern.h
o=bin/pax/options.c
[ -f "$f" ] && [ -f "$o" ] || { echo "CHYBA: $f nebo $o nenalezen (spust z minix3 root)"; exit 1; }

# uz je to opravene?
if ! grep -q '^char \*chdname;' "$f" && grep -q '^char \*chdname;' "$o"; then
  echo "extern.h bez naho definice, options.c s definici — uz je to OK"
  exit 0
fi

# extern deklarace musi existovat (jinak by spousta souboru nevidela symbol)
if ! grep -q '^extern char \*chdname;' "$f"; then
  echo "CHYBA: v extern.h chybi 'extern char *chdname;' — poslat grep -n chdname bin/pax/extern.h"
  exit 1
fi

cp -p "$f" "$f.pre-k"
cp -p "$o" "$o.pre-k"

# 1) odstranit nahou definici z extern.h
if grep -q '^char \*chdname;' "$f"; then
  n=$(grep -n '^char \*chdname;' "$f" | head -1 | cut -d: -f1)
  echo "odstranuji nahou definici z $f (radek $n)"
  {
    head -n $((n-1)) "$f"
    tail -n +$((n+1)) "$f"
  } > "$f.tmp" && mv "$f.tmp" "$f"
fi

# 2) pridat jedinou definici do options.c za posledni #include (jako v netbsd-11)
if ! grep -q '^char \*chdname;' "$o"; then
  m=$(grep -n '^#include' "$o" | tail -1 | cut -d: -f1)
  echo "vkladam 'char *chdname;' do $o za radek $m (posledni #include)"
  {
    head -n "$m" "$o"
    printf '\n'
    echo 'char *chdname;'
    tail -n +$((m+1)) "$o"
  } > "$o.tmp" && mv "$o.tmp" "$o"
fi

echo "--- vysledek ---"
grep -n chdname "$f" "$o"
