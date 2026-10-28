#!/bin/sh
# davka AA: build24 chyba 'sys/acl.h file not found' (posix1e acl_*.c).
# NetBSD-11 sys/sys/Makefile INCS (v1.185 2024 christos) instaluje do
# /usr/include/sys i "kernel" hlavicky s userland guardy (acl.h kmem.h
# proc.h sched.h atomic.h lock.h stdarg.h gmon.h rbtree.h cdbr.h ...).
# Stromovy sys/sys/Makefile je minix-era (stary INCS seznam) — acl.h
# neni v INCS a soubor ve strome chybi; includes-sys faze ho nikdy
# nedostala do destdir (netbsd top-level: includes-lib: includes-include
# includes-sys; destdir/usr/include/sys se plni ze stromoveho
# sys/sys/Makefile).
# Fix (pokryje celou tridu najednou, ne jen acl.h):
#   1) diff INCS slov wt vs strom -> chybejici INCS zaznamy
#   2) chybejici SOUBORY cp z wt sys/sys/ do stromu (jen chybejici)
#   3) INCS+= <chybejici zaznamy> vlozeny za INCSDIR= radku stromoveho
#      Makefile (zaloha .pre-aa) — INCS se musi pridat PRED vyhodnoceni
#      bsd.inc.mk (append na konec by byl pozde)
#   4) pojistka: tez cp chybejici hlavicky rovnou do
#      destdir/usr/include/sys (a by includes faze nezdrzovala)
# Idempotentni: opakovany beh = prazdny diff, zadny zasah.

TREE=/usr/home/cerluk/Projekty/minix3
WT=/usr/home/cerluk/Projekty/nbsd-11
DSTSYS=/usr/home/cerluk/Projekty/destdir/usr/include/sys

M="$TREE/sys/sys/Makefile"
WS="$WT/sys/sys/Makefile"

[ -f "$M" ] || { echo "CHYBA: neni $M"; exit 1; }
[ -f "$WS" ] || { echo "CHYBA: neni $WS"; exit 1; }

inc_words() {
    awk '
    /^INCS[+:]?[[:space:]]*=/ { inside=1 }
    inside {
        line=$0
        sub(/^INCS[+:]?[[:space:]]*=/, "", line)
        gsub(/\\/, "", line)
        n=split(line, a)
        for (i=1; i<=n; i++) if (a[i] != "") print a[i]
        if ($0 !~ /\\$/) inside=0
    }
    ' "$1" | sort -u
}

inc_words "$WS" > /tmp/aa-wt.txt
inc_words "$M" > /tmp/aa-tree.txt
[ -s /tmp/aa-wt.txt ] || { echo "CHYBA: wt INCS seznam prazdny (awk parse?)"; exit 1; }

MISSING=$(comm -23 /tmp/aa-wt.txt /tmp/aa-tree.txt)

echo "=== 1. chybejici INCS zaznamy (wt ma, strom nema) ==="
if [ -z "$MISSING" ]; then
  echo "  (zadne — davka AA uz aplikovana)"
  rm -f /tmp/aa-wt.txt /tmp/aa-tree.txt
  echo "VYSLEDEK: OK — nic k delani"
  exit 0
fi
LIST=""
SKIPPED=""
NC=0
for f in $MISSING; do
  if [ ! -f "$WT/sys/sys/$f" ]; then
    SKIPPED="$SKIPPED $f"
    continue
  fi
  LIST="$LIST $f"
  if [ ! -f "$TREE/sys/sys/$f" ]; then
    cp "$WT/sys/sys/$f" "$TREE/sys/sys/$f" || { echo "CHYBA cp: $f"; exit 1; }
    echo "  + soubor $f"
    NC=$((NC + 1))
  fi
done
echo "  nove INCS zaznamy:$LIST"
[ -n "$SKIPPED" ] && echo "  preskocene (neni ve wt sys/sys):$SKIPPED"
echo "  zkopirovano souboru: $NC"
echo ""

echo "=== 2. INCS+= vlozeni do stromoveho sys/sys/Makefile ==="
cp "$M" "$M.pre-aa" || { echo "CHYBA zaloha .pre-aa"; exit 1; }
ADDLINE="INCS+=$LIST"
awk -v add="$ADDLINE" '/^INCSDIR=/ { print; print add; next } { print }' "$M" > /tmp/aa-mk.tmp || { echo "CHYBA awk"; exit 1; }
mv /tmp/aa-mk.tmp "$M" || { echo "CHYBA mv"; exit 1; }
grep -n 'INCS+=' "$M" | tail -2
echo ""

echo "=== 3. pojistka: cp chybejicich hlavicek do destdir ==="
if [ -d "$DSTSYS" ]; then
  ND=0
  for f in $LIST; do
    if [ ! -f "$DSTSYS/$f" ]; then
      cp "$TREE/sys/sys/$f" "$DSTSYS/$f" || { echo "CHYBA cp destdir: $f"; exit 1; }
      echo "  + destdir $f"
      ND=$((ND + 1))
    fi
  done
  echo "  do destdir zkopirovano: $ND (zbydek donainstaluje includes-sys)"
else
  echo "  POZOR: neni $DSTSYS — destdir neexistuje?"
fi
echo ""

echo "=== 4. sanity ==="
[ -f "$TREE/sys/sys/acl.h" ] && echo "  OK strom sys/sys/acl.h" || echo "  CHYBI strom sys/sys/acl.h"
[ -f "$DSTSYS/acl.h" ] && echo "  OK destdir sys/acl.h" || echo "  CHYBI destdir sys/acl.h"
inc_words "$M" > /tmp/aa-tree2.txt
comm -23 /tmp/aa-wt.txt /tmp/aa-tree2.txt > /tmp/aa-resid.txt
if [ -s /tmp/aa-resid.txt ]; then
  echo "  CHYBA: INCS diff neni prazdny:"
  cat /tmp/aa-resid.txt
  rm -f /tmp/aa-wt.txt /tmp/aa-tree.txt /tmp/aa-tree2.txt /tmp/aa-resid.txt
  exit 1
fi
rm -f /tmp/aa-wt.txt /tmp/aa-tree.txt /tmp/aa-tree2.txt /tmp/aa-resid.txt
echo "VYSLEDEK: OK — pokracovat build25"
