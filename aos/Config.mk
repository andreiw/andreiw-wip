ARCH ?= arm
PLAT ?= tegra
CROSS_COMPILE = arm-eabi-

#
# If you change any of these configuration options then you must
# 'make clean' before rebuilding.
#

verbose       ?= n
debug         ?= n
frame_pointer ?= n

