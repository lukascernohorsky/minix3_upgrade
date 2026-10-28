/*
 * Minimal C11 <stdalign.h> shim for the minix cross toolchain build.
 * Stock netbsd-11 ships no top-level stdalign.h (compiler-provided);
 * our cross toolchain has none, so route to <sys/stdalign.h>
 * (installed to /usr/include/sys since davka AA).
 */
#ifndef _STDALIGN_H_
#define _STDALIGN_H_
#include <sys/stdalign.h>
#endif /* _STDALIGN_H_ */
