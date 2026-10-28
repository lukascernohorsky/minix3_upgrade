#!/bin/sh
# include/tzfile.h: rename tzh_ttisgmtcnt -> tzh_ttisutcnt (jako v netbsd-11
# v1.14; novy zic.c DO(tzh_ttisutcnt) makro vyuziva novy nazev clena
# struct tzhead; rename je jedina semanticka zmena celeho audit diffu)
set -e
f=include/tzfile.h
[ -f "$f" ] || { echo "CHYBA: $f nenalezen (spust z minix3 root)"; exit 1; }
if ! grep -q tzh_ttisgmtcnt "$f" && grep -q tzh_ttisutcnt "$f"; then
  echo "tzfile.h uz ma tzh_ttisutcnt — nic neni treba"
  exit 0
fi
if ! grep -q tzh_ttisgmtcnt "$f"; then
  echo "CHYBA: v $f neni tzh_ttisgmtcnt — poslat grep -n tzh_ $f"
  exit 1
fi
cnt=$(grep -c tzh_ttisgmtcnt "$f")
echo "prejmenovavam tzh_ttisgmtcnt -> tzh_ttisutcnt ($cnt vyskytu: clen struct tzhead + komentare)"
cp -p "$f" "$f.pre-n"
sed 's/tzh_ttisgmtcnt/tzh_ttisutcnt/g' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
echo "--- vysledek ---"
grep -n 'tzh_ttisutcnt\|tzh_ttisstdcnt' "$f" | head -6
