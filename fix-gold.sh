#!/bin/sh
# tools/binutils/Makefile: nebuildit gold (HAVE_GOLD:Uyes -> HAVE_GOLD:Uno)
# gold = jedina C++ cast binutils; na FreeBSD hostu (libc++ 19+) pada na
# std::char_traits<unsigned short>/<unsigned int> (LLVM 16+ odebralo generickou
# sablonu). ld.bfd pro MINIX staci, netbsd-11 gold ve tools take nebuildi.
set -e
f=tools/binutils/Makefile
[ -f "$f" ] || { echo "CHYBA: $f nenalezen (spust z minix3 root)"; exit 1; }
if grep -q 'HAVE_GOLD:Uno' "$f"; then
  echo "HAVE_GOLD uz je :Uno — nic neni treba"
  exit 0
fi
if ! grep -q 'HAVE_GOLD:Uyes' "$f"; then
  echo "CHYBA: v $f neni HAVE_GOLD:Uyes — poslat grep -n HAVE_GOLD tools/binutils/Makefile"
  exit 1
fi
cp -p "$f" "$f.pre-l"
sed 's/HAVE_GOLD:Uyes/HAVE_GOLD:Uno/' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
echo "gold vypnut (HAVE_GOLD:Uno) — ALL_TARGET bez all-gold, configure bez --enable-gold"
echo "--- vysledek ---"
grep -n 'HAVE_GOLD' "$f"
