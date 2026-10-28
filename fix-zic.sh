#!/bin/sh
# usr.sbin/zic/Makefile (v1.16): TZVERSION!= sed extrakce 's/VERSION=[ \t]*//p'
# z lib/libc/time/Makefile vytahuje krome radku 28 (VERSION= unknown) i recipe
# radky noveho tzcode Makefile (VERSION="$$VERSION" $(MAKE) ...) — bmake pak tyto
# vyrazy rozvine (cesta nbmake, AWK='', $V+ERSION, $@_version -> zic.lo_version)
# a -DTZVERSION rozbije kompilaci zic.c (expected ')' na printf zic %s%s).
# TZVERSION je jen verzeni banner vystupu zic. Fix: staticka hodnota 0 —
# presne jako netbsd-9+ fallback v usr.sbin/zic/Makefile (v1.21/v1.22).
set -e
f=usr.sbin/zic/Makefile
[ -f "$f" ] || { echo "CHYBA: $f nenalezen (spust z minix3 root)"; exit 1; }
if grep -q '^TZVERSION= 0$' "$f"; then
  echo "TZVERSION uz je staticke (0) — nic neni treba"
  exit 0
fi
if ! grep -q '^TZVERSION!=' "$f"; then
  echo "CHYBA: v $f neni TZVERSION!= radka — struktura neodpovida v1.16"
  exit 1
fi
echo "nahrazuji TZVERSION sed extrakci statickou hodnotou 0"
cp -p "$f" "$f.pre-o"
sed 's/^TZVERSION!=.*$/TZVERSION= 0/' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
echo "--- vysledek ---"
grep -n 'TZVERSION' "$f"
