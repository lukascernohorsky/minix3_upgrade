#!/bin/sh
# davka AC: build26 chyba lib/libc/compat/sys/compat___fhstatvfs140.c:43
# fatal 'compat/sys/statvfs.h'. NetBSD-11 lib/libc/compat/Makefile.inc
# (v1.7 2012 christos) ma na r. 3 CPPFLAGS+= -I${NETBSDSRCDIR}/sys —
# <compat/sys/statvfs.h> se resolvuje ze SOURCE STROMU
# ${NETBSDSRCDIR}/sys/compat/sys/statvfs.h (sys/compat/Makefile v1.7 ma
# vse zakomentovane — includes faze compat hlavicky NEinstaluje do
# /usr/include/compat). Chyba tedy = (a) stromove libc
# compat/Makefile.inc nema -I radku (stara minix-era verze), a/nebo
# (b) ve strome chybi sys/compat/sys/statvfs.h a spol.
# Fix: (1) kontrola + pripadny sync compat/Makefile.inc z wt (napred
# diff vypis, zaloha .pre-ac), (2) cp vsech chybejicich .h z
# wt sys/compat/sys/ (a sys/compat/net/ pojistne) do stromu,
# (3) sanity. Zadny destdir zasah — resolvace je source-tree.
# Idempotentni.

TREE=/usr/home/cerluk/Projekty/minix3
WT=/usr/home/cerluk/Projekty/nbsd-11

[ -d "$TREE/lib/libc/compat" ] || { echo "CHYBA: neni $TREE/lib/libc/compat"; exit 1; }
[ -d "$WT/lib/libc/compat" ] || { echo "CHYBA: neni $WT/lib/libc/compat"; exit 1; }

echo "=== 1. libc compat/Makefile.inc: -I \${NETBSDSRCDIR}/sys ==="
F="$TREE/lib/libc/compat/Makefile.inc"
WF="$WT/lib/libc/compat/Makefile.inc"
if [ ! -f "$F" ]; then
  echo "  CHYBI ve strome — sync z wt:"
  cp "$WF" "$F" || { echo "CHYBA cp"; exit 1; }
  echo "  + zkopirovano"
elif grep -q 'NETBSDSRCDIR}/sys' "$F"; then
  echo "  OK -I radek je:"
  grep -n 'NETBSDSRCDIR}/sys' "$F"
else
  echo "  chybi — diff pred sync:"
  diff -u "$F" "$WF" | head -40
  cp "$F" "$F.pre-ac" || { echo "CHYBA zaloha"; exit 1; }
  cp "$WF" "$F" || { echo "CHYBA cp sync"; exit 1; }
  echo "  + sync z worktree"
  grep -n 'NETBSDSRCDIR}/sys' "$F"
fi
echo ""

echo "=== 2. chybejici sys/compat/sys/*.h ve strome ==="
NS=0
if [ -d "$WT/sys/compat/sys" ]; then
  for f in "$WT"/sys/compat/sys/*.h; do
    b=$(basename "$f")
    if [ ! -f "$TREE/sys/compat/sys/$b" ]; then
      mkdir -p "$TREE/sys/compat/sys" || { echo "CHYBA mkdir"; exit 1; }
      cp "$f" "$TREE/sys/compat/sys/$b" || { echo "CHYBA cp: $b"; exit 1; }
      echo "  + $b"
      NS=$((NS + 1))
    fi
  done
  echo "  zkopirovano: $NS"
else
  echo "  CHYBA: neni $WT/sys/compat/sys"
  exit 1
fi
echo ""

echo "=== 3. pojistne: chybejici sys/compat/net/*.h ==="
NN=0
if [ -d "$WT/sys/compat/net" ]; then
  for f in "$WT"/sys/compat/net/*.h; do
    b=$(basename "$f")
    if [ ! -f "$TREE/sys/compat/net/$b" ]; then
      mkdir -p "$TREE/sys/compat/net" || { echo "CHYBA mkdir"; exit 1; }
      cp "$f" "$TREE/sys/compat/net/$b" || { echo "CHYBA cp: $b"; exit 1; }
      echo "  + $b"
      NN=$((NN + 1))
    fi
  done
  echo "  zkopirovano: $NN"
else
  echo "  (wt sys/compat/net neni — preskakujeme)"
fi
echo ""

echo "=== 4. sanity ==="
fail=0
[ -f "$TREE/sys/compat/sys/statvfs.h" ] && echo "  OK strom sys/compat/sys/statvfs.h" || { echo "  CHYBI statvfs.h"; fail=1; }
grep -q 'NETBSDSRCDIR}/sys' "$F" && echo "  OK compat/Makefile.inc -I" || { echo "  CHYBI -I v compat/Makefile.inc"; fail=1; }
echo ""
if [ "$fail" -eq 1 ]; then
  echo "VYSLEDEK: FAIL"
  exit 1
fi
echo "VYSLEDEK: OK — pokracovat build27"
