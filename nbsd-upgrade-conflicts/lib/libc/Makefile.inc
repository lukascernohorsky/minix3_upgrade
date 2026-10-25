#	$NetBSD: Makefile.inc,v 1.22.4.2 2026/02/05 08:18:45 martin Exp $
#	@(#)Makefile	8.2 (Berkeley) 2/3/94
#
# All library objects contain sccsid strings by default; they may be
# excluded as a space-saving measure.  To produce a library that does
# not contain these strings, delete -DLIBC_SCCS and -DSYSLIBC_SCCS
# from CPPFLAGS below.  To remove these strings from just the system call
# stubs, remove just -DSYSLIBC_SCCS from CPPFLAGS.
#
# The NLS (message catalog) functions are always in libc.  To choose that
# strerror(), perror(), strsignal(), psignal(), etc. actually call the NLS
# functions, put -DNLS on the CPPFLAGS line below.
#
# The YP functions are always in libc. To choose that getpwent() and friends
# actually call the YP functions, put -DYP on the CPPFLAGS line below.
#
# The Hesiod functions are always in libc. To choose that getpwent() and friends
# actually call the Hesiod functions, put -DHESIOD on the CPPFLAGS line below.
.if defined(__MINIX)
MKYP=no #requires RPC
USE_JEMALLOC=no
USE_FORT=no
USE_LIBTRE=no

# BJG too many warnings
NOGCCERROR?=    yes
NOCLANGERROR?=  yes
.endif # defined(__MINIX)

NOSANITIZER=	# defined
USE_FORT?=	yes

USE_SHLIBDIR=	yes

.include <bsd.own.mk>

# build libc suitable for rumprun software stack, i.e. are system calls
# rump kernel function calls instead of kernel traps?
RUMPRUN?=	no

WARNS=5
.if !defined(__MINIX)
CPPFLAGS+=	-D_LIBC -DLIBC_SCCS -DSYSLIBC_SCCS -D_REENTRANT
<<<<<<< ours
CPPFLAGS+=	-D_DIAGNOSTIC
.else
CPPFLAGS+=	-D_LIBC
||||||| ancestor
CPPFLAGS+=	-D_DIAGNOSTIC
=======
CPPFLAGS+=	-D_LIBC_INTERNAL

# leave this on its own line for easier switching on release branches
#CPPFLAGS+=	-D_DIAGNOSTIC

>>>>>>> theirs
.if defined(MLIBDIR)
CPPFLAGS+=	-DMLIBDIR=\"${MLIBDIR}\"
.endif
<<<<<<< ours
.endif # !defined(__minix)
||||||| ancestor
=======
# needed for csu_common.h
CPPFLAGS+=	-I${NETBSDSRCDIR}/lib/csu/common
>>>>>>> theirs

.if (${USE_HESIOD} != "no")
CPPFLAGS+=	-DHESIOD
.endif

.if (${USE_INET6} != "no")
CPPFLAGS+=	-DINET6
.endif

CPPFLAGS+=	-DNLS

.if (${USE_YP} != "no")
CPPFLAGS+=	-DYP
.endif

# Set lint to exit on warnings
LINTFLAGS+=	-w
# ignore 'empty translation unit' warnings.
LINTFLAGS+=	-X 272
# XXX: ignore 'missing header declaration' warnings (for now).
LINTFLAGS+=	-X 351

.include "libcincludes.mk"

ARCHDIR=	${.CURDIR}/arch/${ARCHSUBDIR}
AFLAGS+=	-I${ARCHDIR}
CLEANFILES+=	tags

# Don't try to lint the C library against itself when creating llib-lc.ln
LLIBS=

INCSDIR=	/usr/include
child process exited abnormally