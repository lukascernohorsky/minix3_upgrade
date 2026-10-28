#!/bin/sh
# etc/mtree/NetBSD.dist.base — stromovy spec (minix adaptace v1.149, 753 r.)
# nema ./usr/include/refuse; netbsd-11 (v1.259, r. 332) ho ma. librefuse
# netbsd-11 (pho 2022 refactor) instaluje refuse/*.h do /usr/include/refuse/,
# adresar vytvari distrib-dirs (mtree z tohoto specu) pred includes fazi ->
# bez radku instalace selze: i586-elf32-minix-install: .../refuse/buf.h.inst.*:
# mkstemp: No such file or directory (buf.h/chan.h, build18, ostatni
# Error code 2 = kaskada paralelniho make). Pridavam JEN refuse — ostatni
# nove nbsd-11 usr/include adresare (cbor, fido, trousers/tss, clang-13.0,
# gcc-10/12, kernel fs/miscfs/dev/uvm hlavicky) patri komponentam, ktere
# strom nema (ls lib: jen librefuse; cbor/fido/trousers nejsou; LLVM 3.6.1).
# Kompletni spec merge (libdata/firmware atd.) az na sets fazi (sets_warnings).
set -e
f=etc/mtree/NetBSD.dist.base
[ -f "$f" ] || { echo "CHYBA: $f nenalezen (spust z minix3 root)"; exit 1; }
if grep -q '^\./usr/include/refuse$' "$f"; then
  echo "spec uz ma ./usr/include/refuse — nic neni treba"
  exit 0
fi
n1=$(grep -n '^\./usr/include/readline$' "$f" | cut -d: -f1)
if [ -z "$n1" ]; then
  echo "CHYBA: nenalezen ./usr/include/readline — poslat grep -n usr/include $f | tail -40"
  exit 1
fi
next=$(awk -v n="$n1" 'NR>n && /^\.\// {print; exit}' "$f")
if [ "$next" != './usr/include/rpcsvc' ]; then
  echo "CHYBA: za readline ocekavam ./usr/include/rpcsvc, nalezeno [$next] — poslat grep -n usr/include $f | tail -40"
  exit 1
fi
echo "pridavam ./usr/include/refuse do mtree specu (za readline, r. $n1)"
cp -p "$f" "$f.pre-u"
{ head -n "$n1" "$f"; echo './usr/include/refuse'; tail -n +"$((n1+1))" "$f"; } > "$f.tmp" && mv "$f.tmp" "$f"
echo "--- vysledek: kontext ---"
grep -n -B1 -A2 '^\./usr/include/refuse$' "$f"
echo "--- sanity: refuse vyskyty + celkem radku ---"
grep -n 'refuse' "$f"
wc -l "$f"
