#!/bin/sh
# davka AB v2 (puvodni v1 selhala na kotve .include <bsd.inc.mk> —
# stromovy include/Makefile v1.141 (netbsd-7, minix-era) pouziva
# bsd.prog.mk a ma INCSDIR= radku — koted na INCSDIR=).
# Rozbor build25: c16rtomb.c/c8rtomb.c includuji <stdalign.h>,
# c32rtomb.c <uchar.h>. NETBSD-11 NEMA top-level stdalign.h vubec
# (ani soubor, ani INCS zaznam) — v stock buildu ho poskytuje
# KOMPILATOR (gcc ginclude / clang resource dir). Minix cross
# toolchain ho nema -> fatal error. Stejne tak INCS diff wt vs
# strom: chybi jen endian.h stdnoreturn.h uchar.h (uchar.h soubor
# ve strome JE, jen nebyl v INCS -> includes ho nikdy
# nenainstalovala do destdir).
# Fix:
#   1) doplnit chybejici soubory do stromu (endian.h stdnoreturn.h
#      uchar.h — cp z wt jen kdyz ve strome chybi)
#   2) VYTVORIT include/stdalign.h jako shim na <sys/stdalign.h>
#      (sys verze nainstalovana davkou AA, v1.1 2024 christos)
#   3) INCS+= endian.h stdalign.h stdnoreturn.h uchar.h za INCSDIR=
#      radku stromoveho include/Makefile (zaloha .pre-ab)
#   4) pojistka: cp vsech 4 do destdir/usr/include
# Idempotentni. Spoustet odkudkoliv.

TREE=/usr/home/cerluk/Projekty/minix3
WT=/usr/home/cerluk/Projekty/nbsd-11
DSTINC=/usr/home/cerluk/Projekty/destdir/usr/include
M="$TREE/include/Makefile"

[ -d "$TREE/include" ] || { echo "CHYBA: neni $TREE/include"; exit 1; }
[ -d "$WT/include" ] || { echo "CHYBA: neni $WT/include"; exit 1; }
[ -d "$DSTINC" ] || { echo "CHYBA: neni $DSTINC"; exit 1; }
[ -f "$M" ] || { echo "CHYBA: neni $M"; exit 1; }

echo "=== 1. soubory endian.h stdnoreturn.h uchar.h ve strome ==="
for f in endian.h stdnoreturn.h uchar.h; do
  if [ -f "$TREE/include/$f" ]; then
    echo "  OK $f (strom ma)"
  elif [ -f "$WT/include/$f" ]; then
    cp "$WT/include/$f" "$TREE/include/$f" || { echo "CHYBA cp: $f"; exit 1; }
    echo "  + $f zkopirovan z worktree"
  else
    echo "  CHYBA: $f neni ani ve worktree include/"
    exit 1
  fi
done
echo ""

echo "=== 2. stdalign.h shim ==="
if [ -f "$TREE/include/stdalign.h" ]; then
  echo "  uz existuje"
else
  cat > "$TREE/include/stdalign.h" << 'EOSTDALIGN'
/*
 * Minimal C11 <stdalign.h> shim for the minix cross toolchain build.
 * Stock netbsd-11 ships no top-level stdalign.h (compiler-provided);
 * our cross toolchain has none, so route to <sys/stdalign.h>
 * (installed to /usr/include/sys since davka AA).
 */
#ifndef _STDALIGN_H_
#define _STDALIGN_H_
#include <sys/stdalign.h>
#endif /* _STDALIGN_H_ */
EOSTDALIGN
  echo "  + vytvoren shim na sys/stdalign.h"
fi
echo ""

echo "=== 3. INCS+= do include/Makefile ==="
if grep -q 'INCS+=.*stdalign.h' "$M"; then
  echo "  uz je:"
  grep -n 'INCS+=.*stdalign.h' "$M"
else
  cp "$M" "$M.pre-ab" || { echo "CHYBA zaloha .pre-ab"; exit 1; }
  ADDLINE="INCS+= endian.h stdalign.h stdnoreturn.h uchar.h"
  awk -v add="$ADDLINE" '/^INCSDIR=/ { print; print add; next } { print }' "$M" > /tmp/ab-mk.tmp || { echo "CHYBA awk"; exit 1; }
  if ! grep -q "^$ADDLINE" /tmp/ab-mk.tmp; then
    echo "  CHYBA: INCS+= se nevlozilo (neni INCSDIR= radka?)"
    rm -f /tmp/ab-mk.tmp
    exit 1
  fi
  mv /tmp/ab-mk.tmp "$M" || { echo "CHYBA mv"; exit 1; }
  echo "  + vlozeno:"
  grep -n '^INCS+= endian' "$M"
fi
echo ""

echo "=== 4. pojistka: cp do destdir/usr/include ==="
for f in endian.h stdalign.h stdnoreturn.h uchar.h; do
  if [ ! -f "$DSTINC/$f" ]; then
    cp "$TREE/include/$f" "$DSTINC/$f" || { echo "CHYBA cp destdir: $f"; exit 1; }
    echo "  + destdir $f"
  else
    echo "  OK destdir $f"
  fi
done
echo ""

echo "=== 5. sanity ==="
fail=0
for f in endian.h stdalign.h stdnoreturn.h uchar.h; do
  if [ -f "$TREE/include/$f" ]; then echo "  OK strom $f"; else echo "  CHYBI strom $f"; fail=1; fi
  if [ -f "$DSTINC/$f" ]; then echo "  OK destdir $f"; else echo "  CHYBI destdir $f"; fail=1; fi
done
if grep -q 'INCS+=.*stdalign.h' "$M"; then echo "  OK INCS+ zaznam"; else echo "  CHYBI INCS+ zaznam"; fail=1; fi
echo ""
if [ "$fail" -eq 1 ]; then
  echo "VYSLEDEK: FAIL — viz CHYBI vyse"
  exit 1
fi
echo "VYSLEDEK: OK — pokracovat build26"
