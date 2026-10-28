#!/bin/sh
# vlozi #define MPOOL_INUSE za MPOOL_PINNED v include/mpool.h (doplnek davky G, hunk 1)
set -e
f=include/mpool.h
[ -f "$f" ] || { echo "CHYBA: $f nenalezen (spust z minix3 root)"; exit 1; }
if grep -q 'MPOOL_INUSE' "$f"; then
  echo "MPOOL_INUSE uz je definovane, nic neni treba"
  exit 0
fi
n=$(grep -n 'define.*MPOOL_PINNED' "$f" | head -1 | cut -d: -f1)
[ -n "$n" ] || { echo "CHYBA: MPOOL_PINNED nenalezen"; exit 1; }
echo "vkladam MPOOL_INUSE za radek $n"
cp -p "$f" "$f.pre-g2"
{
  head -n "$n" "$f"
  printf '%b\n' '#define\tMPOOL_INUSE\t0x04\t\t/* page address is valid */'
  tail -n +$((n+1)) "$f"
} > "$f.tmp" && mv "$f.tmp" "$f"
echo "--- vysledek ---"
grep -n 'MPOOL_DIRTY\|MPOOL_PINNED\|MPOOL_INUSE' "$f"
