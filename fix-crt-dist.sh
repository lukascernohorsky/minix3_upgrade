#!/bin/sh
# sys/external/bsd/compiler_rt/dist — stromovy dist je netbsd-7-era LLVM
# import (8.2M), ale lib/libc/compiler_rt/Makefile.inc je netbsd-11 v1.54
# (2025, pro LLVM 17+/19-era dist). Chyba build21: nbmake[5] v lib/libc
# "don't know how to make InstrProfilingPlatformLinux.c. Stop" — novy
# profile zdroj ve starém dist chybi (.PATH ${COMPILER_RT_SRCDIR}/lib/profile).
# diff -rq strom vs worktree: 356 rozdilu (266 differ = verzni LLVM,
# ~90 Only in nbsd-11 = nove soubory: include/, lib/asan/, builtins atomics,
# arm aeabi_*, profile), NULA Only in minix3 -> strom dist je cisty import
# bez minix zasahu, full sync z worktree je bezpecny.
# Fix: mv dist -> dist.pre-w (zaloha) + cp -Rp z netbsd-11 worktree.
set -e
wt=/usr/home/cerluk/Projekty/nbsd-11/sys/external/bsd/compiler_rt/dist
dst=sys/external/bsd/compiler_rt/dist
[ -d "$wt" ] || { echo "CHYBA: chybi worktree zdroj $wt"; exit 1; }
[ -d "$dst" ] || { echo "CHYBA: $dst nenalezen (spust z minix3 root)"; exit 1; }
[ -f "$wt/lib/profile/InstrProfilingPlatformLinux.c" ] || { echo "CHYBA: worktree nema lib/profile/InstrProfilingPlatformLinux.c — poslat ls $wt/lib/profile"; exit 1; }
if [ -f "$dst/lib/profile/InstrProfilingPlatformLinux.c" ] && diff -q "$dst/lib/profile/InstrProfilingPlatformLinux.c" "$wt/lib/profile/InstrProfilingPlatformLinux.c" > /dev/null; then
  echo "dist uz ma syncnutou profile sekci — nic neni treba"
  exit 0
fi
echo "--- pred sync: diff -rq radku (jen informacne) ---"
diff -rq "$dst" "$wt" | wc -l
echo "sync: mv dist -> dist.pre-w + cp -Rp z worktree"
mv "$dst" "$dst.pre-w"
cp -Rp "$wt" "$dst"
echo "--- po sync: diff -rq radku (ocekavano 0) ---"
diff -rq "$dst" "$wt" | wc -l
echo "--- sanity: profile sekce ---"
ls "$dst/lib/profile" | head -25
[ -f "$dst/lib/profile/InstrProfilingPlatformLinux.c" ] || { echo "CHYBA: po syncu chybi InstrProfilingPlatformLinux.c"; exit 1; }
echo "--- sanity: velikost + builtins probe (atomic_flag_clear.c) ---"
du -sh "$dst"
ls "$dst/lib/builtins/atomic_flag_clear.c" > /dev/null || { echo "CHYBA: po syncu chybi builtins atomic_flag_clear.c"; exit 1; }
echo "dist sync OK"
