include Config.mk

export ARCH ?= none
export PLAT ?= none
export CROSS_COMPILE
export BASEDIR=$(CURDIR)

all:
	@echo
	@echo Building for $(ARCH)-$(PLAT)
	@echo ------------------------------------------------------------
	@echo
	ln -sf asm-$(ARCH) include/asm
	ln -sf plat-$(PLAT) include/plat
	$(MAKE) -f $(BASEDIR)/Rules.mk -C lib built_in.o
	$(MAKE) -f $(BASEDIR)/Rules.mk -C plat/$(PLAT) built_in.o
	$(MAKE) -f $(BASEDIR)/Rules.mk -C arch/$(ARCH) built_in.o
	$(MAKE) -f $(BASEDIR)/Rules.mk -C arch/$(ARCH) kernel

clean:
	rm -f *~
	$(MAKE) -f $(BASEDIR)/Rules.mk -C include clean
	$(MAKE) -f $(BASEDIR)/Rules.mk -C lib clean
	$(MAKE) -f $(BASEDIR)/Rules.mk -C plat/$(PLAT) clean
	$(MAKE) -f $(BASEDIR)/Rules.mk -C arch/$(ARCH) clean
