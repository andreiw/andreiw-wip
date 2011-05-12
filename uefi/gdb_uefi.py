"""
Allows loading TianoCore symbols into a GDB session attached to EFI
Firmware.
"""

import array
import getopt
import binascii

__license__ = "BSD"
__version = "1.0.0"
__maintainer__ = "Andrei Warkentin"
__email__ = "andrey.warkentin@gmail.com"
__status__ = "Beta"

class ReloadUefi (gdb.Command):
    """Reload UEFI symbols"""

    #
    # If the images were built as ELF/MACH-O and then converted to PE,
    # then the base address needs to be offset by PE headers.
    #

    offset_by_headers = False

    def __init__ (self):
        super (ReloadUefi, self).__init__ ("reload-uefi", gdb.COMMAND_OBSCURE)

    #
    # Computes CRC32 on an array of data.
    #

    def crc32 (self, data):
        return binascii.crc32 (data) & 0xFFFFFFFF

    #
    # Sets a field in a struct to a value, i.e.
    #      value->field_name = data.
    #
    # Newer Py bindings to Gdb provide access to the inferior
    # memory, but not all, so have to do it this awkward way.
    #

    def set_field (self, value, field_name, data):
        gdb.execute ("set *(%s *) 0x%x = 0x%x" % \
                         (str (value[field_name].type), \
                              long (value[field_name].address), \
                              data))

    #
    # Returns data backing a gdb.Value as an array.
    # Same comment as above regarding newer Py bindings...
    #

    def value_data (self, value, bytes=0):
        value_address = gdb.Value (value.address)
        array_t = gdb.lookup_type ('UINT8').pointer()
        value_array = value_address.cast (array_t)
        if bytes == 0:
            bytes = value.type.sizeof
        data = array.array ('B')
        for i in range (0, bytes):
            data.append (value_array[i])
        return data

    #
    # Locates the EFI_SYSTEM_TABLE as per UEFI spec 17.4.
    # Returns base address or -1.
    #

    def search_est (self):
        address = gdb.parse_and_eval ('(EFI_PHYSICAL_ADDRESS) 0x0')
        estp_t = gdb.lookup_type ('EFI_SYSTEM_TABLE_POINTER').pointer ()
        while True:
            estp = address.cast(estp_t)
            if estp['Signature'] == 0x5453595320494249L:
                oldcrc = long (estp['Crc32'])
                self.set_field (estp, 'Crc32', 0)
                newcrc = self.crc32 (self.value_data (estp.dereference (), 0))
                self.set_field (estp, 'Crc32', long (oldcrc))
                if newcrc == oldcrc:
                    return estp['EfiSystemTableBase']

            address = address + 4*1024*1024
            if long (address) == 0:
                return gdb.Value(0xffffffff)

    #
    # Searches for a vendor-specific configuration table (in EST),
    # given a vendor-specific table GUID. GUID is a list like -
    # [32-bit, 16-bit, 16-bit, [8 bytes]]
    #

    def search_config (self, cfg_table, count, guid):
        index = 0
        while index != count:
            cfg_entry = cfg_table[index]['VendorGuid']
            if cfg_entry['Data1'] == guid[0] and \
                    cfg_entry['Data2'] == guid[1] and \
                    cfg_entry['Data3'] == guid[2] and \
                    self.value_data (cfg_entry['Data4']).tolist () == guid[3]:
                return cfg_table[index]['VendorTable']
            index = index + 1
        return gdb.Value(0xffffffff)

    #
    # Returns a UTF16 string corresponding to a (CHAR16 *) value in EFI.
    #

    def parse_utf16 (self, value):
        index = 0
        data = array.array ('H')
        while value[index] != 0:
            data.append (value[index])
            index = index + 1
        return data.tostring ().decode ('utf-16')

    #
    # Returns offset of a field within structure. Useful
    # for getting container of a structure.
    #

    def offsetof (self, typename, field):
        t = gdb.Value (0).cast (gdb.lookup_type (typename).pointer ())
        return long (t[field].address)

    #
    # Parses an EFI_LOADED_IMAGE_PROTOCOL, figuring out the symbol file name.
    # This file name is then appended to list of loaded symbols.
    #
    # This right now relies on EDK LOADED_IMAGE_PRIVATE_DATA and does
    # not parse PE itself. This should be fixed, as otherwise you
    # cannot load DXE Core symbols :-(.
    #

    def parse_image (self, image, syms):
        priv_type = gdb.lookup_type ('LOADED_IMAGE_PRIVATE_DATA').pointer ()
        priv_offset = self.offsetof ('LOADED_IMAGE_PRIVATE_DATA',
                                     'Info')
        priv = gdb.Value (long (image) - priv_offset).cast (priv_type)
        sym_name = priv['ImageContext']['PdbPointer']
        base = long (image['ImageBase'])

        # For ELF and Mach-O-derived images...
        if self.offset_by_headers:
            base = base + priv['ImageContext']['SizeOfHeaders']
        if sym_name != 0:
            syms.append ("add-symbol-file %s 0x%x" % \
                             (sym_name.string (),
                              base))

    #
    # Parses table EFI_DEBUG_IMAGE_INFO structures, builds
    # a list of add-symbol-file commands, and reloads debugger
    # symbols.
    #

    def parse_edii (self, edii, count):
        index = 0
        syms = []
        while index != count:
            entry = edii[index]
            if entry['ImageInfoType'].dereference () == 1:
                entry = entry['NormalImage']
                self.parse_image(entry['LoadedImageProtocolInstance'], syms)
            else:
                print "Skipping unknown EFI_DEBUG_IMAGE_INFO (Type 0x%x)" % \
                entry['ImageInfoType'].dereference ()
            index = index + 1
        print "Unloading existing symbols..."
        gdb.execute ("symbol-file")
        print "Loading new symbols..."
        for sym in syms:
            gdb.execute (sym)

    #
    # Parses EFI_DEBUG_IMAGE_INFO_TABLE_HEADER, in order to load
    # image symbols.
    #

    def parse_dh (self, dh):
        dh_t = gdb.lookup_type ('EFI_DEBUG_IMAGE_INFO_TABLE_HEADER').pointer ()
        dh = dh.cast (dh_t)
        print "DebugImageInfoTable @ 0x%x, 0x%x entries" \
            % (long (dh['EfiDebugImageInfoTable']), dh['TableSize'])
        if dh['UpdateStatus'] & 1:
            print "EfiDebugImageInfoTable update in progress, retry later"
            return
        self.parse_edii (dh['EfiDebugImageInfoTable'], dh['TableSize'])

    #
    # Parses EFI_SYSTEM_TABLE, in order to load image symbols.
    #

    def parse_est (self, est):
        est_t = gdb.lookup_type ('EFI_SYSTEM_TABLE').pointer ()
        est = est.cast (est_t)
        print "Connected to %s (Rev. 0x%x)" % \
            (self.parse_utf16 (est['FirmwareVendor']), \
                 long (est['FirmwareRevision']))
        print "ConfigurationTable @ 0x%x, 0x%x entries" \
            % (long (est['ConfigurationTable']), est['NumberOfTableEntries'])

        dh = self.search_config(est['ConfigurationTable'],
                                    est['NumberOfTableEntries'],
                                    [0x49152E77, 0x1ADA, 0x4764,
                                     [0xB7,0xA2,0x7A,0xFE,
                                      0xFE,0xD9,0x5E, 0x8B]])
        if dh == 0xffffffff:
            print "No EFI_DEBUG_IMAGE_INFO_TABLE_HEADER"
            return
        self.parse_dh (dh)

    #
    # Handler for reload-uefi.
    #

    def invoke (self, arg, from_tty):
        args = arg.split(' ')
        try:
            opts, args = getopt.getopt(args, "o", ["offset-by-headers"])
        except getopt.GetoptError, err:
            print str(err)
            return
        for opt, arg in opts:
            if opt == "-o":
                self.offset_by_headers = True

        est = self.search_est ()
        if est == 0xffffffff:
            print "No EFI_SYSTEM_TABLE..."
            return

        print "EFI_SYSTEM_TABLE @ 0x%x" % est
        self.parse_est (est)

ReloadUefi ()


