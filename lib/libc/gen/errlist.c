/* Automatically generated file; do not edit */
#include <sys/cdefs.h>
__RCSID("$NetBSD: errlist.awk,v 1.4 2010/12/16 22:52:32 joerg Exp $");
#include <errno.h>
static const char *const errlist[] = {
	"Undefined error: 0",			/* 0 - ENOERROR */
};

const int sys_nerr = sizeof(errlist) / sizeof(errlist[0]);
const char * const *sys_errlist = errlist;
