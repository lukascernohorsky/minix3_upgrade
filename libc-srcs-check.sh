#!/bin/sh
# Audit v2: SRCS+= reference z i386-AKTIVNI sady makefile v lib/libc:
#   - ./Makefile, ./Makefile.inc, ./<dir>/Makefile.inc (hloubka 1: gen,
#     hash, string, stdlib, stdio, net, compiler_rt, ...)
#   - ./arch/i386/** (jen i386 — v1 falešne hlasilo sparc_v8.S, saveregs.S,
#     arm __aeabi_* z arch/*/Makefile.inc jinych architektur)
#   - ../minix/lib/libc/** (minix sys include retezec)
#   - ./compat/** zvlášť (mozna pro i386 neaktivni — oznaceno [compat])
# Vyladeno proti v1 falešnym poplachum:
#   - SRCS+= ukotveno na zacatku radku (v1 chytilo i NO_SRCS+= / removal
#     mechanismy jako imaxabs.S)
#   - POZOR: netbsd string/Makefile.inc ma mechanismus "SRCS+= <f>.c se
#     odstrani, existuje-li arch/i386/string/<f>.S" (NB komentar) — takove
#     .c referenze mohu byt legitimne "chybeji" jako soubory. Vypis proto
#     pridava [S-exclude] tag, existuje-li .S varianta v arch/i386/string/.
# Vystup: "CHYBI: <jmeno> <- <zdrojove makefile>" — poslat cely vypis.
cd lib/libc 2> /dev/null || { echo "CHYBA: spust z minix3 root (cd lib/libc)"; exit 1; }
rm -f /tmp/srcs-refs.txt /tmp/allfiles.txt
echo "--- sbiram SRCS reference (i386-aktivni sada) ---"
{
    find . -maxdepth 1 -type f -name 'Makefile*' ! -name '*.orig'
    find . -maxdepth 2 -type f -name 'Makefile*' -path './[a-z]*/*' ! -path './arch/*' ! -name '*.orig'
    find ./arch/i386 -type f -name 'Makefile*' ! -name '*.orig'
    find ./compat -type f -name 'Makefile*' ! -name '*.orig'
    find ../../minix/lib/libc -type f -name 'Makefile*' ! -name '*.orig'
} | sort -u | while read -r m; do
    awk '{ if (acc != "") { acc = acc $0 } else { acc = $0 }; if (acc !~ /\\$/) { print acc; acc = "" } else { sub(/\\$/, " ", acc) } }' "$m" \
    | grep -E '^[[:space:]]*SRCS\+=' | sed 's/^[[:space:]]*SRCS*+=//' | tr ' \\' '\n' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -E '^[a-zA-Z0-9_./-]+\.(c|S|s|y|l)$' \
    | while read -r n; do echo "$n $m"; done >> /tmp/srcs-refs.txt
done
sort -u /tmp/srcs-refs.txt > /tmp/srcs-refs2.txt
mv /tmp/srcs-refs2.txt /tmp/srcs-refs.txt
echo "referenci: $(awk '{print $1}' /tmp/srcs-refs.txt | sort -u | wc -l) (z $(wc -l < /tmp/srcs-refs.txt) radku)"
find . ../../minix/lib/libc ../../sys/external/bsd/compiler_rt/dist -type f 2> /dev/null > /tmp/allfiles.txt
echo "--- kontrola existence ---"
miss=0
awk '{ print $1 }' /tmp/srcs-refs.txt | sort -u | while read -r n; do
    found=$(awk -F/ -v n="$n" '$NF == n { print; exit }' /tmp/allfiles.txt)
    if [ -z "$found" ]; then
        refs=$(awk -v n="$n" '$1 == n { printf "%s ", $2 }' /tmp/srcs-refs.txt)
        tag=""
        case "$n" in *.c) b=${n%.c}; [ -f "./arch/i386/string/$b.S" ] && tag=" [S-exclude]";; esac
        echo "CHYBI: $n$tag <- $refs"
    fi
done
echo "--- hotovo ---"
