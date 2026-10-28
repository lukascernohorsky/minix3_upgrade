#!/bin/sh
# davka X: pricina build22 "don't know how to make ffsl.c" = stromovy
# common/lib/libc je minix-era orezana verze; netbsd-11 bere MI .c
# (ffsl.c ffsll.c strchrnul.c ubsan.c rpc/* atomic/* stdlib/*) prave
# odtud (.PATH.c z common/lib/libc/Makefile.inc v1.21). Fix: cp souboru
# ktere worktree common MA a strom NEMA — jen chybejici, nikdy se
# neprepisuji existujici soubory (mozne minix mody / libkern zustava
# intaktni). Navic: sys/kern/subr_acl_nfs4.c (posix1e .PATH
# ${NETBSDSRCDIR}/sys/kern — v libc ani common nikdy nebyl).
# Info vypisy: errlist generovani, diff LISI SE Makefile.inc (pro davku Y),
# diff common/lib/libc/Makefile.inc. Idempotentni: opakovany beh = 0 cp.
# Spoustet odkudkoliv (cesty absolutni), vystup poslat cely.

TREE=/usr/home/cerluk/Projekty/minix3
WT=/usr/home/cerluk/Projekty/nbsd-11
SRC="$WT/common/lib/libc"
DST="$TREE/common/lib/libc"

[ -d "$SRC" ] || { echo "CHYBA: neni $SRC"; exit 1; }
[ -d "$DST" ] || { echo "CHYBA: neni $DST"; exit 1; }
[ -d "$TREE/sys" ] || { echo "CHYBA: neni $TREE/sys"; exit 1; }
[ -d "$WT/sys/kern" ] || { echo "CHYBA: neni $WT/sys/kern"; exit 1; }

echo "=== 1. cp chybejicich souboru do common/lib/libc (jen chybejici) ==="
cd "$SRC" || exit 1
n=0
for rel in $(find . -type f | sort); do
  if [ ! -f "$DST/$rel" ]; then
    mkdir -p "$(dirname "$DST/$rel")" || exit 1
    cp "$SRC/$rel" "$DST/$rel" || { echo "CHYBA cp: $rel"; exit 1; }
    echo "  + $rel"
    n=$((n + 1))
  fi
done
echo "  zkopirovano: $n"
if [ "$n" -eq 0 ]; then
  echo "  (nic chybelo — davka X uz aplikovana)"
fi
echo ""

echo "=== 2. info: existujici A LISI SE soubory v common (NEeditovano) ==="
m=0
for rel in $(find . -type f | sort); do
  if [ -f "$DST/$rel" ] && ! cmp -s "$rel" "$DST/$rel"; then
    echo "  ~ $rel"
    m=$((m + 1))
  fi
done
echo "  lisi se celkem: $m (neminimalne — jen info, zadny zasah)"
echo ""

echo "=== 3. sys/kern/subr_acl_nfs4.c ==="
if [ -f "$TREE/sys/kern/subr_acl_nfs4.c" ]; then
  echo "  strom uz ma (OK)"
elif [ -f "$WT/sys/kern/subr_acl_nfs4.c" ]; then
  mkdir -p "$TREE/sys/kern" || { echo "CHYBA mkdir sys/kern"; exit 1; }
  cp "$WT/sys/kern/subr_acl_nfs4.c" "$TREE/sys/kern/subr_acl_nfs4.c" || { echo "CHYBA cp subr_acl_nfs4.c"; exit 1; }
  echo "  + zkopirovano z worktree sys/kern (adresar sys/kern ve strome nebyl — vytvoren)"
else
  echo "  POZOR: neni ani ve worktree sys/kern!"
fi
echo ""

echo "=== 4. errlist generovani (info) ==="
grep -n 'errlist' "$TREE/lib/libc/gen/Makefile.inc" | head -10
if [ -f "$TREE/lib/libc/gen/errlist.awk" ]; then
  echo "  errlist.awk: OK"
else
  echo "  POZOR: chybi lib/libc/gen/errlist.awk"
fi
if [ -f "$TREE/sys/sys/errno.h" ]; then
  echo "  sys/sys/errno.h: OK"
else
  echo "  POZOR: chybi sys/sys/errno.h"
fi
echo ""

echo "=== 5. sanity: kriticke soubory po cp ==="
fail=0
for f in string/ffsl.c string/ffsll.c string/strchrnul.c misc/ubsan.c; do
  if [ -f "$DST/$f" ]; then
    echo "  OK $f"
  else
    echo "  CHYBI $f"
    fail=1
  fi
done
echo ""

echo "=== 6. diff LISI SE Makefile.inc — info pro dalsi davku (head -60) ==="
for p in common/lib/libc/Makefile.inc lib/libc/arch/i386/Makefile.inc lib/libc/arch/i386/gen/Makefile.inc lib/libc/compiler_rt/Makefile.inc lib/libc/gdtoa/Makefile.inc lib/libc/gen/Makefile.inc lib/libc/resolv/Makefile.inc lib/libc/stdlib/Makefile.inc lib/libc/sys/Makefile.inc; do
  echo "--- $p ---"
  diff -u "$TREE/$p" "$WT/$p" | head -60
  echo ""
done
echo "--- hotovo ---"
if [ "$fail" -eq 1 ]; then
  echo "VYSLEDEK: FAIL — chybi kriticke soubory"
  exit 1
fi
echo "VYSLEDEK: OK"
