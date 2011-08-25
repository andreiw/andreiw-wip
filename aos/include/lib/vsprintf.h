/*
 *  Copyright (C) 2011 Andrei Warkentin <andrey.warkentin@gmail.com>
 *
 * This program is free software ; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef AOS_LIB_VSPRINTF_H
#define AOS_LIB_VSPRINTF_H

struct va_format {
        const char *fmt;
        va_list *va;
};

#endif
