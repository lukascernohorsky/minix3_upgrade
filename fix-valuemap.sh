#!/bin/sh
# external/bsd/llvm/dist/llvm/include/llvm/IR/ValueMap.h (LLVM 3.6.1):
# `bool hasMD() const { return MDMap; }` — v return statementu se vracena
# hodnota copy-inicializuje a copy-initialization neuvazuje explicitni
# konverzni operatory; unique_ptr::operator bool je explicitni -> clang 19
# hlasi "no viable conversion ... to function return type 'bool'" (stary
# clang 3.x to laxne tolereval, zadny flag to nevraci). Fix: explicitni
# static_cast (legalni C++11, kompiluje se i se starymi kompilatory).
set -e
f=external/bsd/llvm/dist/llvm/include/llvm/IR/ValueMap.h
[ -f "$f" ] || { echo "CHYBA: $f nenalezen (spust z minix3 root)"; exit 1; }
if grep -q 'return static_cast<bool>(MDMap);' "$f"; then
  echo "ValueMap.h uz ma static_cast fix — nic neni treba"
  exit 0
fi
n=$(grep -c 'return MDMap;' "$f" || true)
if [ "$n" != "1" ]; then
  echo "CHYBA: ocekavana 1 shoda 'return MDMap;', nalezeno $n — poslat grep -n MDMap $f"
  exit 1
fi
echo "nahrazuji return MDMap; -> return static_cast<bool>(MDMap);"
cp -p "$f" "$f.pre-r"
sed 's/return MDMap;/return static_cast<bool>(MDMap);/' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
echo "--- vysledek ---"
grep -n 'MDMap' "$f"
