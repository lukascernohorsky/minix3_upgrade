# $NetBSD: Makefile,v 1.16 2022/01/22 08:02:49 pho Exp $

USE_FORT?=	yes	# data driven bugs?

LIB=		refuse
.if !defined(__MINIX)
LIBDPLIBS+=	puffs	${.CURDIR}/../libpuffs		\
		pthread	${.CURDIR}/../libpthread
.else
LIBDPLIBS+=	puffs	${.CURDIR}/../libpuffs
.endif # !defined(__MINIX)

.ifdef DEBUG
FUSE_OPT_DEBUG_FLAGS=	-g -DFUSE_OPT_DEBUG
.endif

CFLAGS+=	${FUSE_OPT_DEBUG_FLAGS}
CPPFLAGS+=	-I${.CURDIR}
SRCS=		refuse.c refuse_compat.c refuse_log.c refuse_lowlevel.c
SRCS+=		refuse_opt.c refuse_signals.c
MAN=		refuse.3
WARNS?=		6
INCS=           fuse.h fuse_opt.h fuse_log.h fuse_lowlevel.h
INCSDIR=        /usr/include

<<<<<<< ours
.include <bsd.lib.mk>
||||||| ancestor
.include <bsd.lib.mk>
=======
.include "${.CURDIR}/refuse/Makefile.inc"

.include <bsd.lib.mk>
>>>>>>> theirs
child process exited abnormally