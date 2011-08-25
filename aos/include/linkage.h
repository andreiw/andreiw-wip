/*
 *  Copyright (C) 2011 Andrei Warkentin <andrey.warkentin@gmail.com>
 *
 * This program is free software ; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef AOS_LINKAGE_H
#define AOS_LINKAGE_H

#include <asm/linkage.h>

#ifdef __ASSEMBLY__

#ifndef ALIGN
#define ALIGN		.align 4,0x90
#define ALIGN_STR	".align 4,0x90"
#endif

#ifndef ENTRY
#define ENTRY(name) \
  .globl name; \
  ALIGN; \
  name:
#endif

#ifndef END
#define END(name) \
  .size name, .-name
#endif

#ifndef ENDPROC
#define ENDPROC(name) \
  .type name, @function; \
  END(name)
#endif
#endif

#endif /* AOS_LINKAGE_H */
