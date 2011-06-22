#
# Configuration dependencies.
#

ifeq ($(debug),y)
verbose       := y
frame_pointer := y
else
CFLAGS += -DNDEBUG
endif

#
# Common.
#

CFLAGS-y += -g
CFLAGS-y += -I$(BASEDIR)/include
CFLAGS-y += -I$(BASEDIR)/include/asm
CFLAGS-y += -I$(BASEDIR)/include/plat
CFLAGS-$(verbose) += -DVERBOSE
CFLAGS-$(frame_pointer) += -fno-omit-frame-pointer
CFLAGS-y += -MMD -MF .$(@F).d
DEPS = .*.d
CFLAGS += $(CFLAGS-y)
AFLAGS += $(CFLAGS) -D__ASSEMBLY__

include $(BASEDIR)/arch/$(ARCH)/Rules.mk

AS         = $(CROSS_COMPILE)as
LD         = $(CROSS_COMPILE)ld
CC         = $(CROSS_COMPILE)gcc
CPP        = $(CC) -E
AR         = $(CROSS_COMPILE)ar
RANLIB     = $(CROSS_COMPILE)ranlib
NM         = $(CROSS_COMPILE)nm
STRIP      = $(CROSS_COMPILE)strip
OBJCOPY    = $(CROSS_COMPILE)objcopy
OBJDUMP    = $(CROSS_COMPILE)objdump
SIZEUTIL   = $(CROSS_COMPILE)size

#
# Ordering here is important.
#
ALL_OBJECTS-y += $(BASEDIR)/arch/$(ARCH)/built_in.o
ALL_OBJECTS-y += $(BASEDIR)/plat/$(PLAT)/built_in.o
ALL_OBJECTS-y += $(BASEDIR)/lib/built_in.o

include Makefile

# Ensure each subdirectory has exactly one trailing slash.
subdir-n := $(patsubst %,%/,$(patsubst %/,%,$(subdir-n) $(subdir-)))
subdir-y := $(patsubst %,%/,$(patsubst %/,%,$(subdir-y)))

# Add explicitly declared subdirectories to the object lists.
OBJECTS-y += $(patsubst %/,%/built_in.o,$(subdir-y))

# Add implicitly declared subdirectories (in the object lists) to the
# subdirectory list, and rewrite the object-list entry.
subdir-y += $(filter %/,$(OBJECTS-y))
OBJECTS-y    := $(patsubst %/,%/built-in.o,$(OBJECTS-y))

subdir-all := $(subdir-y) $(subdir-n)

built_in.o: $(OBJECTS-y)
ifeq ($(OBJECTS-y),)
	$(CC) $(CFLAGS) -c -x c /dev/null -o $@
else
	$(LD) $(LDFLAGS) -r -o $@ $^
endif

%.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S Makefile
	$(CC) $(AFLAGS) -c $< -o $@

%.s: %.S Makefile
	$(CPP) $(AFLAGS) $< -o $@

.PHONY: clean
clean:: $(addprefix _clean_, $(subdir-all))
	rm -f *.o *~ $(DEPS)
_clean_%/: FORCE
	$(MAKE) -f $(BASEDIR)/Rules.mk -C $* clean

-include $(DEPS)