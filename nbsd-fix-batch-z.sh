#!/bin/sh
# davka Z: dve chybejici hlavicky z libc mkdep (build23, _env.d/_errno.d):
#  1) csu-common.h (stdlib/_env.c #include "csu-common.h" r. 47)
#     - netbsd-11: soubor je v lib/csu/common/csu-common.h a
#       lib/libc/Makefile.inc v1.22.4.2 ma radky:
#         # needed for csu_common.h
#         CPPFLAGS+= -I${NETBSDSRCDIR}/lib/csu/common
#     - fix: cp soubor ze worktree pokud ve strome chybi + append CPPFLAGS
#       radky na konec Makefile.inc pokud tam neni (poradi -I v make
#       nehraje roli, CPPFLAGS se acumuluje)
#  2) pthread.h (lib/libc/include/reentrant.h #include <pthread.h>
#     NEPODMINECNE — potrebuje ho cela rada libc souboru)
#     - netbsd-11: pthread.h pthread_types.h pthread_queue.h threads.h
#       patri do lib/libpthread (INCS -> /usr/include); minix strom nema
#       libpthread, includes faze je nikdy nedostala do destdir
#     - fix: cp 4 hlavicky z worktree lib/libpthread/ do destdir/usr/include
#       (build-artifact fix — pri vytvoreni noveho destdir rerun sekce 3)
#     - pthread.h zavislosti: sys/cdefs.h time.h sched.h sys/featuretest.h
#       pthread_types.h — sanity v sekci 4 je kontroluje v destdir
# Idempotentni. Spoustet odkudkoliv.

TREE=/usr/home/cerluk/Projekty/minix3
WT=/usr/home/cerluk/Projekty/nbsd-11
DSTINC=/usr/home/cerluk/Projekty/destdir/usr/include

[ -d "$TREE" ] || { echo "CHYBA: neni $TREE"; exit 1; }
[ -d "$WT/lib/libpthread" ] || { echo "CHYBA: neni $WT/lib/libpthread"; exit 1; }
[ -d "$DSTINC" ] || { echo "CHYBA: neni $DSTINC"; exit 1; }

echo "=== 1. csu-common.h do lib/csu/common ==="
CSU="$TREE/lib/csu/common/csu-common.h"
if [ -f "$CSU" ]; then
  echo "  strom uz ma (OK)"
elif [ -f "$WT/lib/csu/common/csu-common.h" ]; then
  mkdir -p "$TREE/lib/csu/common" || { echo "CHYBA mkdir"; exit 1; }
  cp "$WT/lib/csu/common/csu-common.h" "$CSU" || { echo "CHYBA cp csu-common.h"; exit 1; }
  echo "  + zkopirovano z worktree"
else
  echo "  CHYBA: neni ani ve worktree lib/csu/common"
  exit 1
fi
echo ""

echo "=== 2. Makefile.inc: CPPFLAGS -I csu/common ==="
MI="$TREE/lib/libc/Makefile.inc"
[ -f "$MI" ] || { echo "CHYBA: neni $MI"; exit 1; }
if grep -q 'csu/common' "$MI"; then
  echo "  uz je (OK):"
  grep -n 'csu/common' "$MI"
else
  cp "$MI" "$MI.pre-z" || { echo "CHYBA zaloha .pre-z"; exit 1; }
  printf '%s\n' '# needed for csu-common.h (netbsd-11 Makefile.inc v1.22.4.2)' 'CPPFLAGS+= -I${NETBSDSRCDIR}/lib/csu/common' >> "$MI" || { echo "CHYBA append"; exit 1; }
  echo "  + pridano na konec:"
  grep -n 'csu/common' "$MI"
fi
echo ""

echo "=== 3. pthread hlavicky do destdir/usr/include ==="
for h in pthread.h pthread_types.h pthread_queue.h threads.h; do
  if [ -f "$WT/lib/libpthread/$h" ]; then
    cp "$WT/lib/libpthread/$h" "$DSTINC/$h" || { echo "CHYBA cp $h"; exit 1; }
    echo "  + $h"
  else
    echo "  POZOR: ve worktree neni lib/libpthread/$h"
  fi
done
echo ""

echo "=== 4. sanity ==="
fail=0
for h in pthread.h pthread_types.h pthread_queue.h sched.h time.h sys/featuretest.h sys/cdefs.h; do
  if [ -f "$DSTINC/$h" ]; then
    echo "  OK destdir $h"
  else
    echo "  CHYBI destdir $h"
    fail=1
  fi
done
[ -f "$CSU" ] && echo "  OK strom csu-common.h" || { echo "  CHYBI strom csu-common.h"; fail=1; }
grep -q 'csu/common' "$MI" && echo "  OK Makefile.inc -I" || { echo "  CHYBI Makefile.inc -I"; fail=1; }
echo ""
if [ "$fail" -eq 1 ]; then
  echo "VYSLEDEK: FAIL — viz CHYBI vyse"
  exit 1
fi
echo "VYSLEDEK: OK — pokracovat build24"
