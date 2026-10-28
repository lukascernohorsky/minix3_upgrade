#!/bin/sh
# diag v3: kde jsou chybejici libc SRCS soubory. NetBSD-11 libc includuje
# common/lib/libc/Makefile.inc, ktery pridava .PATH.c na
# common/lib/libc/{atomic,gen,gmon,inet,md,misc,net,rpc,stdlib,string,sys}
# + hash/sha1..sha3, rmd160, murmurhash. Audit v2.2 hledal existenci JEN v
# lib/libc + minix/lib/libc + compiler_rt dist — common je nevysetrena
# slepa skvrna. Tento diag pro kazdy CHYBI soubor testuje 4 lokace:
#   T  = strom     lib/libc/<f>
#   W  = worktree  lib/libc/<f>
#   cT = strom     common/lib/libc/<f>
#   cW = worktree  common/lib/libc/<f>
# Dale: include common v lib/libc/Makefile (strom vs worktree), diff vsech
# subdir Makefile.inc (strom vs worktree), worktree git stav.
# Spoustet odkudkoliv (cesty absolutni), vystup poslat cely.

TREE=/usr/home/cerluk/Projekty/minix3
WT=/usr/home/cerluk/Projekty/nbsd-11

[ -d "$TREE/lib/libc" ] || { echo "CHYBA: neni $TREE/lib/libc"; exit 1; }
[ -d "$WT/lib/libc" ] || { echo "CHYBA: neni $WT/lib/libc"; exit 1; }

echo "=== 1. common/lib/libc include v lib/libc/Makefile ==="
echo "--- strom:"
grep -n 'common/lib/libc' "$TREE/lib/libc/Makefile" || echo "  (strom NEINCLUDUJE common/lib/libc!)"
echo "--- worktree:"
grep -n 'common/lib/libc' "$WT/lib/libc/Makefile" || echo "  (worktree neincluduje common?!)"
echo ""

echo "=== 2. common/lib/libc adresare (pocet souboru strom/wt) ==="
for d in string gen md stdlib misc net rpc inet sys gmon atomic arch/i386; do
  a=$(ls "$TREE/common/lib/libc/$d" 2>/dev/null | wc -l)
  b=$(ls "$WT/common/lib/libc/$d" 2>/dev/null | wc -l)
  printf '%-12s strom=%s wt=%s\n' "$d" "$a" "$b"
done
echo ""

echo "=== 3. existence CHYBI souboru (T/cT=strom, W/cW=worktree, c*=common) ==="
while IFS= read -r f; do
  [ -z "$f" ] && continue
  flags=""
  [ -f "$TREE/lib/libc/$f" ] && flags="${flags}T"
  [ -f "$WT/lib/libc/$f" ] && flags="${flags}W"
  [ -f "$TREE/common/lib/libc/$f" ] && flags="${flags}cT"
  [ -f "$WT/common/lib/libc/$f" ] && flags="${flags}cW"
  [ -z "$flags" ] && flags="(NICDE)"
  printf '%-32s %s\n' "$f" "$flags"
done << 'EOLIST'
string/bcmp.c
string/bcopy.c
string/bzero.c
string/ffs.c
string/ffsl.c
string/ffsll.c
string/memchr.c
string/memcmp.c
string/memcpy.c
string/memmove.c
string/memset.c
string/strcasecmp.c
string/strcat.c
string/strcmp.c
string/strcpy.c
string/strcspn.c
string/strchr.c
string/strchrnul.c
string/strlcat.c
string/strlcpy.c
string/strlen.c
string/strncasecmp.c
string/strncat.c
string/strncpy.c
string/strnlen.c
string/strpbrk.c
string/strrchr.c
string/strsep.c
string/strspn.c
string/strstr.c
string/strnstr.c
string/consttime_memequal.c
string/explicit_memset.c
string/popcount32.c
string/popcount64.c
arch/i386/string/memcpy.S
arch/i386/string/memchr.S
arch/i386/string/memmove.S
arch/i386/string/memset.S
arch/i386/string/strcat.S
arch/i386/string/strcmp.S
arch/i386/string/strcpy.S
arch/i386/string/strchr.S
arch/i386/string/strlen.S
arch/i386/string/strrchr.S
arch/i386/gen/bswap64.c
gen/bswap64.c
gen/errlist.c
gen/ptree.c
gen/rb.c
stdlib/heapsort.c
stdlib/mi_vector_hash.c
stdlib/random.c
stdlib/strtoi.c
stdlib/strtoimax.c
stdlib/strtoll.c
stdlib/strtou.c
stdlib/strtoul.c
stdlib/strtoull.c
stdlib/strtoumax.c
md/md4c.c
md/md5c.c
cdb/cdbr.c
inet/inet_addr.c
gmon/mcount.c
posix1e/subr_acl_nfs4.c
misc/ubsan.c
sys/cpuset.c
hash/murmurhash/mi_vector_hash.c
EOLIST
echo ""

echo "=== 4. Makefile.inc diff strom vs worktree (jen rozdilne/chybejici) ==="
for d in arch/i386 arch/i386/gen arch/i386/string arch/i386/sys atomic cdb compiler_rt db dlfcn gdtoa gen gmon hash iconv inet isc locale md misc nameser net nls posix1e quad regex resolv rpc ssp stdio stdlib string sys termios thread-stub time tls uuid; do
  a="$TREE/lib/libc/$d/Makefile.inc"
  b="$WT/lib/libc/$d/Makefile.inc"
  if [ -f "$a" ] && [ -f "$b" ]; then
    cmp -s "$a" "$b" || echo "$d/Makefile.inc: LISI SE"
  elif [ -f "$b" ]; then
    echo "$d/Makefile.inc: CHYBI VE STROME (worktree ma)"
  elif [ -f "$a" ]; then
    echo "$d/Makefile.inc: jen ve strome (stary minix?)"
  fi
done
echo ""

echo "=== 5. worktree git stav ==="
git -C "$WT" log -1 --format='HEAD %h %cd %D' --date=short
printf 'wt ls-files lib/libc:        %s\n' "$(git -C "$WT" ls-files lib/libc | wc -l)"
printf 'wt ls-files common/lib/libc: %s\n' "$(git -C "$WT" ls-files common/lib/libc | wc -l)"
echo "--- hotovo ---"
