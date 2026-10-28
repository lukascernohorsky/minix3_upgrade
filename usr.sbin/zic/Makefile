#	$NetBSD: Makefile,v 1.16 2015/04/28 17:00:42 christos Exp $

.include "Makefile.inc"
.include <bsd.own.mk>

COPTS.zic.c	+= -Wno-format-nonliteral

PROG=	zic
SRCS=	zic.c
MAN=	zic.8
TZVERSION= 0
CPPFLAGS+=-DPKGVERSION='"(tzcode) "' -DTZVERSION='"${TZVERSION}"'

.PATH: ${NETBSDSRCDIR}/lib/libc/time

.include <bsd.prog.mk>
