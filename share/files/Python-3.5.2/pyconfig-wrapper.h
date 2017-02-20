#ifndef __STUB__PYCONFIG_H__
#define __STUB__PYCONFIG_H__

#if defined(__x86_64__) || \
    defined(__sparc64__) || \
    defined(__arch64__) || \
    defined(__powerpc64__) || \
    defined (__s390x__)
# include "__incdir_64__/pyconfig.h"
#else
# include "__incdir_32__/pyconfig.h"
#endif

#endif
