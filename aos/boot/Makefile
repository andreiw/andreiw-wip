OBJECTS-y += entry.o
OBJECTS-y += c_entry.o

TARGET = aos

all: built_in.o $(TARGET)

$(TARGET): $(ALL_OBJECTS-y) aos.lds
	$(LD) $(LDFLAGS) -T aos.lds -N -Map $@.map $(ALL_OBJECTS-y) -o $@.o
	$(OBJCOPY) -O binary $@.o $@

clean::
	rm -f *.map $(TARGET)