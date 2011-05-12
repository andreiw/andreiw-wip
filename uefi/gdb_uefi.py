import array
import binascii

class ReloadUefi (gdb.Command):
    """Reload UEFI symbols"""

    def __init__ (self):
        super (ReloadUefi, self).__init__ ("reload-uefi", gdb.COMMAND_OBSCURE)

    def crc32 (self, data):
        return binascii.crc32 (data) & 0xFFFFFFFF

    def set_field (self, value, field_name, data):
        gdb.execute ("set *(%s *) 0x%x = 0x%x" % (str(value[field_name].type), long(value[field_name].address), data))

    def value_data (self, value, bytes=0):
        value_address = gdb.Value (value.address)
        array_type = gdb.lookup_type ('UINT8').pointer()
        value_array = value_address.cast (array_type)
        if bytes == 0:
            bytes = value.type.sizeof
        data = array.array ('B')
        for i in range (0, bytes):
            data.append (value_array[i])
        return data

    def search_est (self):
        address = gdb.parse_and_eval ('(EFI_PHYSICAL_ADDRESS) 0x0')
        estp_type = gdb.lookup_type ('EFI_SYSTEM_TABLE_POINTER').pointer ()
        while True:
            estp = address.cast(estp_type)
            if estp['Signature'] == 0x5453595320494249L:
                oldcrc = long (estp['Crc32'])
                self.set_field (estp, 'Crc32', 0)
                newcrc = self.crc32 (self.value_data (estp.dereference (), 0))
                self.set_field (estp, 'Crc32', long (oldcrc))
                if newcrc == oldcrc:
                    return long (estp['EfiSystemTableBase'])
                          
            address = address - 4*1024*1024
            if long(address) == 0:
                return 0xffffffff
            
    def invoke (self, arg, from_tty):
        est = self.search_est ()
        if est == 0xffffffff:
            print "No EFI_SYSTEM_TABLE..."
        else:
            print "EFI_SYSTEM_TABLE @ 0x%x" % est

ReloadUefi ()


