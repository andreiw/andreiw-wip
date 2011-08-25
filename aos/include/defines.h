/*
 *  Copyright (C) 2011 Andrei Warkentin <andrey.warkentin@gmail.com>
 *
 * This program is free software ; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef AOS_DEFINES_H
#define AOS_DEFINES_H

#ifndef likely
#define likely(x)     (__builtin_constant_p(x) ? !!(x) : __builtin_expect(!!(x), 1))
#endif
#ifndef unlikely
#define unlikely(x)   (__builtin_constant_p(x) ? !!(x) : __builtin_expect(!!(x), 0))
#endif

#endif /* AOS_DEFINES_H */
