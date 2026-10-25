#	$NetBSD: Makefile.inc,v 1.23 2021/10/31 22:24:34 thorpej Exp $

<<<<<<< ours
.if ${RUMPRUN} != "yes" && !defined(__MINIX)
SRCS+=	__sigaction14_sigtramp.c __sigtramp2.S
.endif
||||||| ancestor
.if ${RUMPRUN} != "yes"
SRCS+=	__sigaction14_sigtramp.c __sigtramp2.S
.endif
=======
.if ${RUMPRUN} != "yes"
SRCS+=	__sigtramp2.S
.endif

CPPFLAGS+=	-I.
>>>>>>> theirs
child process exited abnormally