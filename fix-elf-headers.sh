#!/bin/sh
# lib/csu/common/crt0-common.c (netbsd-11, static-pie RELR self-reloc na
# i386) potrebuje Elf_Relr/DT_RELR/DT_RELRSZ (sys/sys/exec_elf.h v1.177)
# a R_386_IRELATIVE (sys/arch/i386/include/elf_machdep.h v1.14); strom ma
# exec_elf.h v1.149 (2015) a elf_machdep.h v1.10 (2009). Chyby build20:
# crt0-common.c:201/319 R_386_IRELATIVE, 267-300 Elf_Relr/DT_RELR/DT_RELRSZ/
# relrlim — use of undeclared identifier (gcrt0.o/crt0.o, kaskada
# dependall-csu). RELR kod v crt0 neni guardovany (je v bloku #if
# defined(__x86_64__) || defined(__i386__), na i386 se kompilovat musi).
# Fix: elf_machdep.h cp z worktree (stock, 0 minix zasahu, diff = jen
# pridane definice v1.14). exec_elf.h cp v1.177 z worktree + programovy
# re-insert minix bloku (v1.149 r. 911-922: #if defined(__minix) okolo
# NETBSD note bloku, #else vetva s NAMESZ 6 / "Minix\0\0\0"). Else-vetva
# se extrahuje sedem ze stareho stromoveho souboru BYTE-EXACT (zadna rucni
# transkripce tabu); vse probehne v tempu, strom se prepise az po
# uspesnem splice (guard chyba = zadny zasah do stromu).
set -e
wt=/usr/home/cerluk/Projekty/nbsd-11
fm=sys/arch/i386/include/elf_machdep.h
fe=sys/sys/exec_elf.h

# --- 1) elf_machdep.h: stock v1.10 -> v1.14 (cp z worktree) ---
[ -f "$fm" ] || { echo "CHYBA: $fm nenalezen (spust z minix3 root)"; exit 1; }
[ -f "$wt/$fm" ] || { echo "CHYBA: chybi worktree zdroj $wt/$fm"; exit 1; }
if grep -q 'R_386_IRELATIVE' "$fm"; then
  echo "elf_machdep.h uz ma R_386_IRELATIVE — nic neni treba"
else
  grep -q 'elf_machdep.h,v 1.10 ' "$fm" || { echo "CHYBA: $fm neni v1.10 — poslat head -2 $fm"; exit 1; }
  cp -p "$fm" "$fm.pre-v"
  cp -p "$wt/$fm" "$fm"
  echo "elf_machdep.h: cp v1.14 z worktree OK"
fi
echo "--- elf_machdep.h sanity ---"
grep -n 'elf_machdep.h,v\|R_386_IRELATIVE' "$fm"

# --- 2) exec_elf.h: v1.149 + minix blok -> v1.177 + minix blok ---
[ -f "$fe" ] || { echo "CHYBA: $fe nenalezen"; exit 1; }
[ -f "$wt/$fe" ] || { echo "CHYBA: chybi worktree zdroj $wt/$fe"; exit 1; }
if grep -q 'DT_RELR' "$fe" && grep -q '^#if defined(__minix)$' "$fe" && grep -qF 'Minix\0\0\0' "$fe"; then
  echo "exec_elf.h uz ma RELR i minix blok — nic neni treba"
else
  grep -q 'exec_elf.h,v 1.149 ' "$fe" || { echo "CHYBA: $fe neni v1.149 — poslat head -2 $fe"; exit 1; }
  nmin=$(grep -c '^#if defined(__minix)$' "$fe")
  [ "$nmin" = "1" ] || { echo "CHYBA: ocekavan prave 1 minix blok, nalezeno $nmin — poslat grep -n defined $fe"; exit 1; }
  # extrakce else-vetve minix bloku ze stareho souboru (byte-exact)
  a=$(grep -n '^#if defined(__minix)$' "$fe" | cut -d: -f1)
  e=$(awk -v n="$a" 'NR>n && /^#else$/ {print NR; exit}' "$fe")
  z=$(awk -v n="$e" 'NR>=n && /^#endif \/\* defined\(__minix\) \*\/$/ {print NR; exit}' "$fe")
  if [ -z "$e" ] || [ -z "$z" ]; then echo "CHYBA: minix blok nema #else/#endif — poslat sed -n '905,925p' $fe"; exit 1; fi
  [ "$e" -eq $((a+6)) ] && [ "$z" -eq $((a+11)) ] || { echo "CHYBA: neocekavana struktura minix bloku (a=$a e=$e z=$z) — poslat sed -n '905,925p' $fe"; exit 1; }
  sed -n "${e},${z}p" "$fe" > "$fe.minix-else.tmp"
  grep -qF 'Minix\0\0\0' "$fe.minix-else.tmp" || { echo "CHYBA: extrahovana else-vetva nema Minix name — poslat cat -A $fe.minix-else.tmp"; exit 1; }
  # kotvy na pracovni kopii noveho souboru (strom se nedotkame)
  cp -p "$wt/$fe" "$fe.new.tmp"
  nb=$(awk '/^#define ELF_NOTE_NETBSD_NAMESZ\t/ {c++} END {print c+0}' "$fe.new.tmp")
  nc=$(awk '/^#define ELF_NOTE_NETBSD_NAME\t/ {c++} END {print c+0}' "$fe.new.tmp")
  [ "$nb" = "1" ] && [ "$nc" = "1" ] || { echo "CHYBA: neocekavany pocet kotev NAMESZ/NAME ($nb/$nc) v worktree verzi — poslat grep -n ELF_NOTE_NETBSD $fe.new.tmp"; exit 1; }
  b=$(awk '/^#define ELF_NOTE_NETBSD_NAMESZ\t/ {print NR}' "$fe.new.tmp")
  c=$(awk '/^#define ELF_NOTE_NETBSD_NAME\t/ {print NR}' "$fe.new.tmp")
  [ "$c" -eq $((b+3)) ] || { echo "CHYBA: NAME neni NAMESZ+3 (b=$b c=$c) — poslat grep -n -B3 -A4 ELF_NOTE_NETBSD_NAMESZ $fe.new.tmp"; exit 1; }
  lntag=$(sed -n "$((b-2))p" "$fe.new.tmp")
  case "$lntag" in *ELF_NOTE_TYPE_NETBSD_TAG*) ;; *) echo "CHYBA: nad NAMESZ neni ELF_NOTE_TYPE_NETBSD_TAG — poslat kontext"; exit 1;; esac
  lncmt=$(sed -n "$((b-1))p" "$fe.new.tmp")
  case "$lncmt" in *"NetBSD-specific note name and description sizes"*) ;; *) echo "CHYBA: chybi comment kotva pred NAMESZ — poslat kontext"; exit 1;; esac
  # splice: vse pred TAG + #if + comment..NAME (upstream blok) + else-vetva + zbytek
  { head -n "$((b-2))" "$fe.new.tmp"; echo '#if defined(__minix)'; sed -n "$((b-1)),${c}p" "$fe.new.tmp"; cat "$fe.minix-else.tmp"; tail -n +"$((c+1))" "$fe.new.tmp"; } > "$fe.spliced.tmp"
  # kontrola spliku nez sahneme na strom
  grep -qF 'Minix\0\0\0' "$fe.spliced.tmp" || { echo "CHYBA: splice kontrola selhala — poslat grep -n -A14 ELF_NOTE_TYPE_NETBSD_TAG $fe.spliced.tmp"; exit 1; }
  grep -q 'DT_RELR[[:space:]]*36' "$fe.spliced.tmp" || { echo "POZOR: DT_RELR 36 nenalezen ve spliku — poslat grep -n DT_RELR $fe.spliced.tmp"; exit 1; }
  grep -q 'exec_elf.h,v 1.177 ' "$fe.spliced.tmp" || { echo "POZOR: worktree verze neni v1.177 — poslat head -2 $fe.new.tmp"; exit 1; }
  cp -p "$fe" "$fe.pre-v"
  mv "$fe.spliced.tmp" "$fe"
  rm -f "$fe.new.tmp" "$fe.minix-else.tmp"
  echo "exec_elf.h: v1.177 z worktree + minix blok re-insert OK"
fi
echo "--- exec_elf.h sanity: RELR definice ---"
grep -n 'DT_RELR[[:space:]]*36\|DT_RELRSZ[[:space:]]*35\|Elf_Relr[[:space:]]*Elf' "$fe" | head -6
echo "--- exec_elf.h sanity: minix blok ---"
grep -n -A14 'ELF_NOTE_TYPE_NETBSD_TAG[[:space:]]*1' "$fe" | head -16
