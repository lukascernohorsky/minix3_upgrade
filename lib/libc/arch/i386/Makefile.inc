#	$NetBSD: Makefile.inc,v 1.23 2021/10/31 22:24:34 thorpej Exp $

.if ${RUMPRUN} != "yes" && !defined(__MINIX)
SRCS+=	__sigtramp2.S
.endif

CPPFLAGS+=	-I.
