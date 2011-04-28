/*
 * HVM OVMF UEFI support.
 *
 * Andrei Warkentin, andreiw@motorola.com
 * Leendert van Doorn, leendert@watson.ibm.com
 * Copyright (c) 2005, International Business Machines Corporation.
 * Copyright (c) 2006, Keir Fraser, XenSource Inc.
 * Copyright (c) 2011, Citrix Inc.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 */

#include "config.h"

#include "../rombios/config.h"
#include "util.h"
#include "hypercall.h"

#include <xen/hvm/params.h>
#include <xen/hvm/ioreq.h>
#include <xen/memory.h>

#define ROM_INCLUDE_OVMF32
#define ROM_INCLUDE_OVMF64
#include "roms.inc"

#define OVMF_BEGIN              0xFFF00000ULL
#define OVMF_SIZE               0x00100000ULL
#define OVMF_MAXOFFSET          0x000FFFFFULL
#define OVMF_END                (OVMF_BEGIN + OVMF_SIZE)
#define LOWCHUNK_BEGIN          0x000F0000
#define LOWCHUNK_SIZE           0x00010000
#define LOWCHUNK_MAXOFFSET      0x0000FFFF
#define LOWCHUNK_END            (OVMF_BEGIN + OVMF_SIZE)

/*
 * Set up an empty TSS area for virtual 8086 mode to use.
 * The only important thing is that it musn't have any bits set
 * in the interrupt redirection bitmap, so all zeros will do.
 */
static void ovmf_init_vm86_tss(void)
{
    void *tss;
    struct xen_hvm_param p;

    tss = mem_alloc(128, 128);
    memset(tss, 0, 128);
    p.domid = DOMID_SELF;
    p.index = HVM_PARAM_VM86_TSS;
    p.value = virt_to_phys(tss);
    hypercall_hvm_op(HVMOP_set_param, &p);
    printf("vm86 TSS at %08lx\n", virt_to_phys(tss));
}

static void ovmf_load(const struct bios_config *config)
{
    xen_pfn_t mfn;
    struct xen_add_to_physmap xatp;
    struct xen_memory_reservation xmr;
    int over_allocated = 0;
    uint64_t addr = OVMF_BEGIN;

    /* The Cirrus ROM will probably work elsewhere anyway... */
    virtual_vga = VGA_cirrus;

    /* Copy low-reset vector portion. */
    memcpy((void *) LOWCHUNK_BEGIN, (uint8_t *) config->image
           + OVMF_SIZE
           - LOWCHUNK_SIZE,
           LOWCHUNK_SIZE);


    printf("Copied lowchunk...\n");

    /* Ensure we have backing page prior to moving FD. */
    while ((addr >> PAGE_SHIFT) != (OVMF_END >> PAGE_SHIFT)) {
        printf("mapped addr 0x%x\n", (uint32_t) addr);
        mfn = (uint32_t) (addr >> PAGE_SHIFT);
        addr += PAGE_SIZE;

        if (!over_allocated) {
            xmr.domid = DOMID_SELF;
            xmr.mem_flags = 0;
            xmr.extent_order = 0;
            xmr.nr_extents = 1;
            set_xen_guest_handle(xmr.extent_start, &mfn);
            if ( hypercall_memory_op(XENMEM_populate_physmap, &xmr) == 1 )
                continue;
            over_allocated = 1;
        }

        /* Otherwise, relocate a page from the ordinary RAM map. */
        if (hvm_info->high_mem_pgend) {
            xatp.idx = --hvm_info->high_mem_pgend;
            if ( xatp.idx == (1ull << (32 - PAGE_SHIFT)) )
                hvm_info->high_mem_pgend = 0;
        } else
            xatp.idx = --hvm_info->low_mem_pgend;

        xatp.domid = DOMID_SELF;
        xatp.space = XENMAPSPACE_gmfn;
        xatp.gpfn  = mfn;
        if ( hypercall_memory_op(XENMEM_add_to_physmap, &xatp) != 0 )
            BUG();
    }

    printf("Initialized FD backing pages...\n");

    /* Copy FD. */
    memcpy((void *) OVMF_BEGIN, config->image, OVMF_SIZE);

    printf("Copied FD...\n");
    printf("Load complete!\n");
}

struct bios_config ovmf32_config =  {
    .name = "OVMF32",

    .image = ovmf32,
    .image_size = sizeof(ovmf32),
    .load = ovmf_load,
    .bios_address = 0,

    .smbios_start = 0,
    .smbios_end = 0,

    .optionrom_start = 0,
    .optionrom_end = 0,

    .acpi_start = 0,

    .apic_setup = NULL,
    .pci_setup = NULL,
    .smp_setup = NULL,

    .bios_high_setup = NULL,
    .bios_info_setup = NULL,

    .vm86_setup = ovmf_init_vm86_tss,
    .e820_setup = NULL,

    .acpi_build_tables = NULL,
    .create_mp_tables = NULL,
};

struct bios_config ovmf64_config =  {
    .name = "OVMF64",

    .image = ovmf64,
    .image_size = sizeof(ovmf64),

    .bios_address = 0,
    .load = ovmf_load,
    .smbios_start = 0,
    .smbios_end = 0,

    .optionrom_start = 0,
    .optionrom_end = 0,

    .acpi_start = 0,

    .apic_setup = NULL,
    .pci_setup = NULL,
    .smp_setup = NULL,

    .bios_high_setup = NULL,
    .bios_info_setup = NULL,

    .vm86_setup = ovmf_init_vm86_tss,
    .e820_setup = NULL,

    .acpi_build_tables = NULL,
    .create_mp_tables = NULL,
};

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
