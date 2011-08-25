/*
 *  Copyright (C) 2011 Andrei Warkentin <andrey.warkentin@gmail.com>
 *
 * This program is free software ; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef AOS_ARM_LINKAGE_H
#define AOS_ARM_LINKAGE_H

#define ENDPROC(name) \
  .type name, %function; \
  END(name)

#endif
