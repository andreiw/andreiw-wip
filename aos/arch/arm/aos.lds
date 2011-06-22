OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_aos_entry)

SECTIONS
{
  . = 0;
  _text = .;

  .text : {
    *(.start)
    *(.text)
    *(.text.*)
    *(.fixup)
    *(.data)
    *(.rodata)
    *(.rodata.*)
    *(.glue_7)
    *(.glue_7t)
    . = ALIGN(4);
  }

  _got_start = .;
  .got			: { *(.got) }
  _got_end = .;

  . = ALIGN(4);
  .bss			: { *(.bss) }
  _end = .;
}
