#!/bin/sh
# mtree create.c: FTS_CONST nesmi byt 'const' na FreeBSD hostu — dcmp pak nesedi
# na fts_open compar (const FTSENT **), clang 16+ to je default error.
set -e
f=usr.sbin/mtree/create.c
[ -f "$f" ] || { echo "CHYBA: $f nenalezen (spust z minix3 root)"; exit 1; }

# varianta 1: FTS_CONST makro s const vetvi (#ifdef __FreeBSD__)
if grep -q '^#define.*FTS_CONST const' "$f"; then
  n=$(grep -n '^#define.*FTS_CONST const' "$f" | head -1 | cut -d: -f1)
  echo "FTS_CONST const je na radku $n"
  cp -p "$f" "$f.pre-i"
  ok=1
  sed -n "$((n-1))p" "$f" | grep -qx '#ifdef __FreeBSD__' || ok=0
  sed -n "$((n+1))p" "$f" | grep -qx '#else' || ok=0
  sed -n "$((n+2))p" "$f" | grep -qx '#define.*FTS_CONST' || ok=0
  sed -n "$((n+3))p" "$f" | grep -qx '#endif' || ok=0
  if [ "$ok" = 1 ]; then
    echo "struktura bloku sedi, nahrazuji celek (radky $((n-1)) az $((n+3))) jednim #define"
    {
      head -n $((n-2)) "$f"
      echo '#define FTS_CONST'
      tail -n +$((n+4)) "$f"
    } > "$f.tmp" && mv "$f.tmp" "$f"
  else
    echo "struktura bloku nesedi, nahrazuji jen radek $n"
    {
      head -n $((n-1)) "$f"
      echo '#define FTS_CONST'
      tail -n +$((n+1)) "$f"
    } > "$f.tmp" && mv "$f.tmp" "$f"
  fi
  echo "--- vysledek ---"
  grep -En 'FTS_CONST|dcmp' "$f"
  exit 0
fi

# varianta 2: literalni const v signature (bez FTS_CONST makra)
if ! grep -q FTS_CONST "$f" && grep -q 'const FTSENT \* const \*' "$f"; then
  cp -p "$f" "$f.pre-i"
  grep -n 'const FTSENT \* const \*' "$f"
  sed 's/const FTSENT \* const \*/const FTSENT **/g' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  echo "opraveno: literalni 'const FTSENT * const *' -> 'const FTSENT **'"
  echo "--- vysledek ---"
  grep -En 'FTS_CONST|dcmp' "$f"
  exit 0
fi

# uz je to opravene?
if grep -q FTS_CONST "$f"; then
  echo "FTS_CONST uz neni const, create.c vypada OK, nic neni treba"
  exit 0
fi
if grep -q 'dcmp(const FTSENT \*\*' "$f"; then
  echo "dcmp uz ma const FTSENT **, create.c vypada OK, nic neni treba"
  exit 0
fi

echo "CHYBA: nenasel se ani '#define FTS_CONST const', ani literalni const, ani opravena signatura"
echo "poslat: sed -n '80,100p' usr.sbin/mtree/create.c"
exit 1
