#!/bin/sh
# sbin/newfs_udf/newfs_udf.h: context/layout byly NAHE definice v hlavicce ->
# -fno-common duplicate symbol pri buildu tools/makefs (udf.lo, udf_write.lo).
# Fix: extern v hlavicce + jedine definice v udf_write.c (spolecny pro makefs
# i newfs_udf buildy). Mirror struktury netbsd-11 (externy v udf_core.h,
# definice v udf_core.c r. 74-75 — stary strom udf_core nema).
set -e
h=sbin/newfs_udf/newfs_udf.h
o=sbin/newfs_udf/udf_write.c
[ -f "$h" ] && [ -f "$o" ] || { echo "CHYBA: $h nebo $o nenalezen (spust z minix3 root)"; exit 1; }

naked_h=0
if [ "$(grep -c '^struct udf_create_context context;' "$h")" = 1 ] && [ "$(grep -c '^struct udf_disclayout.*layout;' "$h")" = 1 ]; then
  naked_h=1
fi
hok=0
if grep -q '^extern struct udf_create_context context;' "$h" && grep -q '^extern struct udf_disclayout.*layout;' "$h"; then
  hok=1
fi
if [ "$naked_h" = 0 ] && [ "$hok" = 0 ]; then
  echo "CHYBA: v $h nejsou ani nahle definice, ani externy context/layout"
  echo "poslat: grep -n 'context\\|layout' $h"
  exit 1
fi

if [ "$naked_h" = 1 ]; then
  cp -p "$h" "$h.pre-m"
  echo "pridavam extern k definicim v $h"
  sed -e 's/^struct udf_create_context context;/extern &/' -e 's/^struct udf_disclayout[[:space:]]*layout;/extern &/' "$h" > "$h.tmp" && mv "$h.tmp" "$h"
fi

if grep -q '^struct udf_create_context context;' "$o"; then
  echo "definice uz jsou v $o"
else
  cp -p "$o" "$o.pre-m"
  m=$(grep -n '^#include' "$o" | tail -1 | cut -d: -f1)
  echo "vkladam definice context/layout do $o za radek $m (posledni #include)"
  {
    head -n "$m" "$o"
    printf '\n'
    printf '%s\n' 'struct udf_create_context context;' 'struct udf_disclayout     layout;'
    tail -n +$((m+1)) "$o"
  } > "$o.tmp" && mv "$o.tmp" "$o"
fi

echo "--- vysledek ---"
grep -n 'udf_create_context context\|udf_disclayout.*layout' "$h"
grep -n 'udf_create_context context\|udf_disclayout' "$o" | head -4
