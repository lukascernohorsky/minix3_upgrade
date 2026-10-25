#!/bin/sh
# Export puvodnich (zaloha s MINIX upravami) a novych (NetBSD 11) verzi
# vsech souboru, ktere maji v zalohou __minix nebo __MINIX guardy.
# Vysledek: nbsd-guard-export.tar.gz (adresare backup/ a current/)

set -e
ROOT="${1:-.}"
BK="$ROOT/nbsd-upgrade-conflicts/backup"
OUT="$ROOT/nbsd-guard-export"

[ -d "$BK" ] || { echo "Nenalezl jsem $BK"; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/backup" "$OUT/current"

grep -rl -e __minix -e __MINIX "$BK" | sort | while IFS= read -r f; do
    rel=${f#"$BK"/}
    mkdir -p "$OUT/backup/$(dirname "$rel")" "$OUT/current/$(dirname "$rel")"
    cp "$f" "$OUT/backup/$rel"
    if [ -f "$ROOT/$rel" ]; then
        cp "$ROOT/$rel" "$OUT/current/$rel"
    else
        echo "CHYBI aktualni verze: $rel" >>"$OUT/missing.txt"
    fi
    echo "$rel" >>"$OUT/MANIFEST.txt"
done

tar -czf "$ROOT/nbsd-guard-export.tar.gz" -C "$ROOT" nbsd-guard-export
echo "Hotovo: $(wc -l <"$OUT/MANIFEST.txt") souboru -> nbsd-guard-export.tar.gz"
