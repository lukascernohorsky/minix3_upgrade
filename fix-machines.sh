#!/bin/sh
# usr.sbin/installboot/machines.c (v1.39): blok tentative definic (zero-filled
# bss pro nezbedovane architektury) definuje take ib_mach_i386 a ib_mach_amd64,
# ktere maji skutecne definice v arch/i386.c — pod -fno-common duplicate symbol
# (ld.lld: duplicate symbol: ib_mach_i386 / ib_mach_amd64). Fix: vypustit tyto
# dva symboly ze seznamu tentative definic; tabulka machines[] (&ib_mach_...)
# se nemeni; ostatni 18 tentative definic zustaava (to je jejich ucel).
set -e
f=usr.sbin/installboot/machines.c
[ -f "$f" ] || { echo "CHYBA: $f nenalezen (spust z minix3 root)"; exit 1; }
a=$(grep -c '^    ib_mach_amd64,$' "$f" || true)
b=$(grep -c '^    ib_mach_i386,$' "$f" || true)
if [ "$a" = "0" ] && [ "$b" = "0" ]; then
  echo "machines.c uz nema tentative definice ib_mach_i386/ib_mach_amd64 — nic neni treba"
  exit 0
fi
if [ "$a" != "1" ] || [ "$b" != "1" ]; then
  echo "CHYBA: neocekavany pocet shod (amd64=$a i386=$b) — poslat cat -A $f"
  exit 1
fi
echo "odstranuji ib_mach_amd64 a ib_mach_i386 ze seznamu tentative definic"
cp -p "$f" "$f.pre-p"
sed '/^    ib_mach_amd64,$/d; /^    ib_mach_i386,$/d' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
echo "--- vysledek (tentative blok) ---"
sed -n '/^struct ib_mach$/,/ib_mach_x68k;/p' "$f"
echo "--- sanity ---"
echo "tentative definice (bez &): $(grep -c '^    ib_mach' "$f" || true) (ocekavano 18)"
echo "tabulka machines[] (s &): $(grep -c '^    &ib_mach' "$f" || true) (ocekavano 20)"
