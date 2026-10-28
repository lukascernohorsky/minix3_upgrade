#!/bin/sh
# davka AE: build28 chyba — libc mkdep gen/errlist.c
#   i586-elf32-minix-clang: error: no such file or directory: 'errlist.c'
#   nbmkdep dostal relativni 'errlist.c' = .PATH nic nenasel, soubor
#   neexistuje a strom nema pravidlo generace.
# V netbsd-11 se errlist.c NEkontroluje do stromu — generuje ho make:
#   errlist.c: errlist.awk ${NETBSDSRCDIR}/sys/sys/errno.h
#   (recipe: ${TOOL_AWK} -f ${.ALLSRC} > ${.TARGET}, uvodni tab)
#   CLEANFILES+= errlist.c
# Strom (minix-era) pravdepodobne pravidlo nema a errlist.c v nem
# chybi. Davka:
#   1. errlist.awk — cp z wt do stromu lib/libc/gen (jen chybi-li).
#   2. Pravidlo generace do stromoveho gen/Makefile.inc (jen chybi-li,
#      zaloha .pre-ae; recipe tab generuje printf, zadne literální
#      taby ve skriptu).
#   3. Predgeneruje gen/errlist.c hostitelskym awk ze stromoveho
#      sys/sys/errno.h — zaroven validace: errlist.awk vyzaduje
#      souvislou ciselnou radu #define EFOO cislo /* popis */ a na
#      mezerach tvrde selze ("error number mismatch"). Kdyz stromove
#      minix-era errno.h ma mezery v cislech, awk krici — poslat
#      vystup, resi se zvlast.
# Idempotentni. Spoustet odkudkoliv.

TREE=/usr/home/cerluk/Projekty/minix3
WT=/usr/home/cerluk/Projekty/nbsd-11

MKINC="$TREE/lib/libc/gen/Makefile.inc"
AWKF="$TREE/lib/libc/gen/errlist.awk"
ERRNO="$TREE/sys/sys/errno.h"
OUT="$TREE/lib/libc/gen/errlist.c"

command -v awk > /dev/null || { echo "CHYBA: host nema awk"; exit 1; }
[ -f "$MKINC" ] || { echo "CHYBA: neni $MKINC"; exit 1; }
[ -f "$ERRNO" ] || { echo "CHYBA: neni $ERRNO"; exit 1; }

echo "=== 1. errlist.awk ==="
if [ -f "$AWKF" ]; then
  echo "  strom ma vlastni errlist.awk — nechavame"
else
  if [ ! -f "$WT/lib/libc/gen/errlist.awk" ]; then
    echo "CHYBA: errlist.awk neni ani ve wt"
    exit 1
  fi
  cp "$WT/lib/libc/gen/errlist.awk" "$AWKF" || { echo "CHYBA cp errlist.awk"; exit 1; }
  echo "  + errlist.awk (z wt)"
fi

echo "=== 2. pravidlo generace v gen/Makefile.inc ==="
if grep -Eq '^errlist\.c[[:space:]]*:' "$MKINC"; then
  echo "  pravidlo uz existuje — nechavame:"
  grep -n '^errlist\.c[[:space:]]*:' "$MKINC" | sed 's/^/    /'
else
  cp "$MKINC" "$MKINC.pre-ae" || { echo "CHYBA: zaloha selhala"; exit 1; }
  {
    printf '\n# errlist.c generation (davka AE, format netbsd-11)\n'
    printf 'errlist.c: errlist.awk ${NETBSDSRCDIR}/sys/sys/errno.h\n'
    printf '\t${TOOL_AWK} -f ${.ALLSRC} > ${.TARGET}\n'
    printf '\nCLEANFILES+= errlist.c\n'
  } >> "$MKINC"
  echo "  + pravidlo pridano, zaloha: gen/Makefile.inc.pre-ae"
fi

echo "=== 3. predgenerovani gen/errlist.c ==="
if [ -s "$OUT" ]; then
  echo "  errlist.c existuje ($(wc -l < "$OUT" | tr -d ' ') radku) — nechavame"
else
  awk -f "$AWKF" "$ERRNO" > "$OUT" || { echo "CHYBA: awk generace selhala"; exit 1; }
  [ -s "$OUT" ] || { echo "CHYBA: awk vyprodukoval prazdny soubor"; exit 1; }
  echo "  + errlist.c vygenerovan ($(wc -l < "$OUT" | tr -d ' ') radku)"
fi

echo "=== sanity ==="
fail=0
grep -q 'sys_errlist' "$OUT" || { echo "  CHYBI sys_errlist v errlist.c"; fail=1; }
grep -q 'sys_nerr' "$OUT" || { echo "  CHYBI sys_nerr v errlist.c"; fail=1; }
grep -q 'EPERM' "$ERRNO" || { echo "  CHYBI EPERM v sys/sys/errno.h"; fail=1; }
echo "  prvnich 3 radky errlist.c:"
head -3 "$OUT" | sed 's/^/    /'
echo ""
if [ "$fail" -eq 1 ]; then
  echo "VYSLEDEK: FAIL"
  exit 1
fi
echo "VYSLEDEK: OK — pokracovat build29"
