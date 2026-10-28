#!/bin/sh
# lib/libc/Makefile.inc — stromova verze (netbsd-11 v1.22.4.2 + __MINIX
# guardy) ztratila pri merge CHVOST za CPPFLAGS blokem. netbsd-11 original
# ma za nim: r.65 `.include "libcincludes.mk"` (definuje ARCHSUBDIR pres
# exists() testy na arch/*/SYS.h, zalohovne LIBC_MACHINE_ARCH/CPU z
# MACHINE_ARCH/MACHINE_CPU), r.67 `ARCHDIR= ${.CURDIR}/arch/${ARCHSUBDIR}`,
# r.68 `AFLAGS+= -I${ARCHDIR}`, pak CLEANFILES+= tags, LLIBS=, INCSDIR=.
# Bez toho jsou ARCHSUBDIR/ARCHDIR prazdne -> nbmake Fatal errors 5x
# Cannot open: /net/Makefile.inc, /stdlib/Makefile.inc, /string/Makefile.inc,
# minix/lib/libc/arch//sys/Makefile.inc + arch//Makefile.inc (obj-libc).
# Fix: doplnit chvost byte-exact k netbsd-11 (relativni include resi bmake
# v adresari aktualniho makefile). Pri splicu odstranit trailing blank
# linie za .endif (merge relikt). Bez -fno-common zde neni, .pre-s backup.
set -e
f=lib/libc/Makefile.inc
[ -f "$f" ] || { echo "CHYBA: $f nenalezen (spust z minix3 root)"; exit 1; }
grep -q 'NetBSD: Makefile.inc,v 1.22.4.2' "$f" || { echo "CHYBA: $f neni netbsd-11 v1.22.4.2 — poslat head -2 $f"; exit 1; }
if grep -q '^ARCHDIR=' "$f"; then
  echo "Makefile.inc uz ma ARCHDIR — nic neni treba"
  exit 0
fi
# boundary: posledni NEPRZDNY radek (strom ma za .endif trailing blank
# linie — merge relikt po smazanem chvostu; odstranime je pri splicu)
n=$(awk 'NF {n=NR} END {print n}' "$f")
last=$(head -n "$n" "$f" | tail -n 1)
if [ "$last" != '.endif # !defined(__minix)' ]; then
  echo "CHYBA: neocekavany posledni neprazdny radek: [$last] — poslat tail -8 $f"
  exit 1
fi
for dep in lib/libc/libcincludes.mk lib/libc/arch/i386/SYS.h lib/libc/arch/i386/net/Makefile.inc lib/libc/arch/i386/stdlib/Makefile.inc lib/libc/arch/i386/string/Makefile.inc minix/lib/libc/arch/i386/sys/Makefile.inc minix/lib/libc/arch/i386/Makefile.inc; do
  [ -f "$dep" ] || { echo "CHYBA: chybi $dep — poslat ls lib/libc/arch/i386 a ls minix/lib/libc/arch/i386"; exit 1; }
done
echo "doplnuji chvost Makefile.inc (libcincludes.mk + ARCHDIR + AFLAGS + INCSDIR)"
cp -p "$f" "$f.pre-s"
head -n "$n" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
{
  printf '%b' '.include "libcincludes.mk"\n\n'
  printf '%b' 'ARCHDIR=\t${.CURDIR}/arch/${ARCHSUBDIR}\n'
  printf '%b' 'AFLAGS+=\t-I${ARCHDIR}\n\n'
  printf '%b' 'CLEANFILES+=\ttags\n\n'
  echo "# Don't try to lint the C library against itself when creating llib-lc.ln"
  printf '%b' 'LLIBS=\n\n'
  printf '%b' 'INCSDIR=\t/usr/include\n'
} >> "$f"
echo "--- vysledek: chvost (poslednich 12 radku) ---"
tail -n 12 "$f"
echo "--- sanity: ARCHDIR/ARCHSUBDIR/libcincludes v Makefile.inc ---"
grep -n 'ARCHDIR\|ARCHSUBDIR\|libcincludes' "$f" || true
echo "--- sanity: ARCHDIR vyskyty v lib/libc/Makefile ---"
grep -n 'ARCHDIR' lib/libc/Makefile || echo "(zadne — Makefile je stara minix verze bez ARCHDIR usage)"
