#!/bin/sh
# davka AD: build27 chyba lib/libc/compat/sys/compat_lfs_segwait.c:49
# fatal 'compat/ufs/lfs/lfs_extern.h'. Libc compat kod resolvuje
# <compat/...> hlavicky pres globalni -I${NETBSDSRCDIR}/sys (z
# compat/Makefile.inc r. 3) ze SOURCE STROMU: sys/compat/ufs/lfs/...
# Minix-era strom LFS nemel — adresar chybi.
# Davka AC kryla sys/compat/sys + sys/compat/net (ne-rekurzivne);
# ted rekurzivni sync chybejicich souboru v adresarich, ktere libc
# compat kod referencuje:
#   sys/compat/sys    (rekurzivne — podadresare)
#   sys/compat/ufs    (lfs a spol.)
#   sys/compat/net    (pojistne, rekurzivne)
#   sys/compat/common (syscall compat helper hlavicky, pojistne)
# Jen chybejici soubory — existujici (minix mody) se NIKDY
# neprepisuji. Zadny destdir zasah (source-tree resolvace).
# Idempotentni. Spoustet odkudkoliv.

TREE=/usr/home/cerluk/Projekty/minix3
WT=/usr/home/cerluk/Projekty/nbsd-11

[ -d "$TREE/sys/compat" ] || { echo "CHYBA: neni $TREE/sys/compat"; exit 1; }
[ -d "$WT/sys/compat" ] || { echo "CHYBA: neni $WT/sys/compat"; exit 1; }

NT=0
for d in sys ufs net common; do
  echo "=== $d: chybejici soubory (rekurzivne) ==="
  if [ ! -d "$WT/sys/compat/$d" ]; then
    echo "  (wt sys/compat/$d neni — preskakujeme)"
    continue
  fi
  n=0
  for src in $(find "$WT/sys/compat/$d" -type f | sort); do
    rel=${src#"$WT"/sys/compat/}
    if [ ! -f "$TREE/sys/compat/$rel" ]; then
      dst="$TREE/sys/compat/$rel"
      mkdir -p "$(dirname "$dst")" || { echo "CHYBA mkdir: $rel"; exit 1; }
      cp "$src" "$dst" || { echo "CHYBA cp: $rel"; exit 1; }
      echo "  + $rel"
      n=$((n + 1))
      NT=$((NT + 1))
    fi
  done
  echo "  $d: zkopirovano $n"
  echo ""
done

echo "=== sanity ==="
fail=0
for f in ufs/lfs/lfs_extern.h sys/statvfs.h; do
  if [ -f "$TREE/sys/compat/$f" ]; then
    echo "  OK sys/compat/$f"
  else
    echo "  CHYBI sys/compat/$f"
    fail=1
  fi
done
echo ""
echo "celkem zkopirovano: $NT"
if [ "$fail" -eq 1 ]; then
  echo "VYSLEDEK: FAIL"
  exit 1
fi
if [ "$NT" -eq 0 ]; then
  echo "VYSLEDEK: OK — nic chybelo (davka uz aplikovana)"
else
  echo "VYSLEDEK: OK — pokracovat build28"
fi
