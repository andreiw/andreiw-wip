rm -f flash0.img
rm -f flash1.img
rm -f QEMU_EFI.fd
wget http://snapshots.linaro.org/components/kernel/leg-virt-tianocore-edk2-upstream/latest/QEMU-AARCH64/RELEASE_GCC5/QEMU_EFI.fd
dd if=/dev/zero of=flash0.img bs=1M count=64
dd if=QEMU_EFI.fd of=flash0.img conv=notrunc
dd if=/dev/zero of=flash1.img bs=1M count=64
