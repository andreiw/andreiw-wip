OBJECTS-y += entry.o
OBJECTS-y += c_entry.o
OBJECTS-y += div64.o

kernel: $(ALL_OBJECTS-y) aos.lds
	$(LD) $(LDFLAGS) -T aos.lds -N -Map $@.map $(ALL_OBJECTS-y) -o $@.o
	$(OBJCOPY) -O binary $@.o $@

clean::
	rm -f *.map kernel