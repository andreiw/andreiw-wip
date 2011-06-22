#
# Arch.
#

CFLAGS += -march=armv7-a -mlittle-endian -mabi=aapcs -mapcs
CLFAGS += -fpic
CFLAGS += -fno-builtin -fno-common
CFLAGS += -iwithprefix include -pipe
CFLAGS += -msoft-float
CFLAGS += -Wa,--fatal-warnings -Werror -Wno-uninitialized
LDFLAGS += -nostdlib
