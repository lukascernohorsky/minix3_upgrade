#!/bin/sh
# sys/external/bsd/compiler_rt/abi.mk — v netbsd-11 ho pridal rin (2021,
# v1.1, 6 radku): pro earm*hf definuje -DCOMPILER_RT_ARMHF_TARGET, pro i386
# no-op. Netbsd-7-era strom ho nema (ls sys/external/bsd/compiler_rt: jen
# dist + prepare-import.sh). Upgrade zkopiroval netbsd-11
# lib/libc/compiler_rt/Makefile.inc v1.54, ktery na konci (r. 444/445)
# includuje ${COMPILER_RT_DIR}/abi.mk -> nbmake Fatal: Cannot open
# .../sys/external/bsd/compiler_rt/abi.mk (obj-libc, build17; ostatni
# Error code 2 = kaskada paralelniho make).
# Fix: cp z netbsd-11 worktree (byte-exact transport, zadne rucni editace).
set -e
src=/usr/home/cerluk/Projekty/nbsd-11/sys/external/bsd/compiler_rt/abi.mk
dst=sys/external/bsd/compiler_rt/abi.mk
[ -f "$src" ] || { echo "CHYBA: chybi worktree zdroj $src"; exit 1; }
[ -d "$(dirname "$dst")" ] || { echo "CHYBA: chybi adresar $(dirname "$dst") (spust z minix3 root)"; exit 1; }
if [ -f "$dst" ]; then
  echo "abi.mk uz existuje — nic neni treba"
  exit 0
fi
echo "kopiruji abi.mk z netbsd-11 worktree"
cp -p "$src" "$dst"
echo "--- vysledek: cat abi.mk ---"
cat "$dst"
echo "--- sanity: ls sys/external/bsd/compiler_rt ---"
ls sys/external/bsd/compiler_rt
