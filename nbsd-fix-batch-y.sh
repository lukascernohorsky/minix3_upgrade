#!/bin/sh
# davka Y: sync common/lib/libc/Makefile.inc ze stromove v1.16 (2014 matt,
# s __MINIX orezem COMMON_CODEDIRS: bez gmon/sys, bez misc/rpc/hash:sha3 —
# ty tam jeste v 1.16 nebyly) na netbsd-11 v1.21 (2021 skrll, plna sada
# atomic gen gmon inet md misc net rpc stdlib string sys + sha3 +
# -I arch atomic + -I hash/sha3).
# Proc je to nutne: stromove lib/libc podadresare gmon/ misc/ rpc/ sys/
# (a hash/) uz maji NETBSD-11 Makefile.inc (identicke s worktree, diag v3
# sekce 4) a bezpodminevnove referencuji mcount.c, ubsan.c, xdr*.c,
# cpuset.c, sha3.c keccak.c — ty uz po davce X ve stromem common jsou,
# ale .PATH.c na common/{gmon,misc,rpc,sys,hash/sha3} neni aktivni,
# protoze v1.16 __MINIX vetva tyto adresare neuvadi. Bez davky Y:
# dalsi "don't know how to make" hned po ffsl.c.
# Riziko nizke: v1.21 je bezminixova, genericka; kernel se soubory
# nerekompiluje (SRCS se listuji explicitne). Zaloha .pre-y.
# Idempotentni. Spoustet odkudkoliv.

TREE=/usr/home/cerluk/Projekty/minix3
WT=/usr/home/cerluk/Projekty/nbsd-11
F=common/lib/libc/Makefile.inc

[ -f "$TREE/$F" ] || { echo "CHYBA: neni $TREE/$F"; exit 1; }
[ -f "$WT/$F" ] || { echo "CHYBA: neni $WT/$F"; exit 1; }

if cmp -s "$TREE/$F" "$WT/$F"; then
  echo "Uz je netbsd-11 v1.21 — davka Y aplikovana, nic k delani."
  exit 0
fi

grep -q 'Makefile.inc,v 1.21' "$WT/$F" || { echo "CHYBA: worktree $F neni v1.21 (cekam skrll 2021) — poslat diff"; exit 1; }
grep -q 'Makefile.inc,v 1.16' "$TREE/$F" || { echo "POZOR: stromove $F neni v1.16 — manualni kontrola: poslat diff -u pred aplikaci"; exit 1; }

cp "$TREE/$F" "$TREE/$F.pre-y" || { echo "CHYBA: zaloha .pre-y"; exit 1; }
cp "$WT/$F" "$TREE/$F" || { echo "CHYBA: cp nove verze"; exit 1; }

echo "=== sanity ==="
grep -n 'COMMON_CODEDIRS' "$TREE/$F"
echo ""
grep -c '__MINIX' "$TREE/$F" | tr '\n' ' '; echo "vyskytu __MINIX (cekam 0)"
echo ""
echo "=== kontrola .pre-y zalohy ==="
ls -l "$TREE/$F.pre-y"
echo ""
echo "VYSLEDEK: OK — pokracovat build23"
