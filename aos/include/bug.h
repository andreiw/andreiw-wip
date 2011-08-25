/*
 *  Copyright (C) 2011 Andrei Warkentin <andrey.warkentin@gmail.com>
 *
 * This program is free software ; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef AOS_BUG_H
#define AOS_BUG_H

#include <system.h>

#define BUG()

#define BUG_ON(condition) do { if (unlikely(condition)) BUG(); } while(0)

#endif
