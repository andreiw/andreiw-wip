BITS 64

	;;
	;; Modified from one of the Tiny-PE examples.
	;;
        
	;;
	;;  MZ header
	;;
	;;  The only two fields that matter are e_magic and e_lfanew

mzhdr:
	dw "MZ"		;  e_magic
	dw 0		;  e_cblp UNUSED
	dw 0		;  e_cp UNUSED
	dw 0		;  e_crlc UNUSED
	dw 0		;  e_cparhdr UNUSED
	dw 0		;  e_minalloc UNUSED
	dw 0		;  e_maxalloc UNUSED
	dw 0		;  e_ss UNUSED
	dw 0		;  e_sp UNUSED
	dw 0		;  e_csum UNUSED
	dw 0		;  e_ip UNUSED
	dw 0		;  e_cs UNUSED
	dw 0		;  e_lsarlc UNUSED
	dw 0		;  e_ovno UNUSED
	times 4 dw 0	;  e_res UNUSED
	dw 0		;  e_oemid UNUSED
	dw 0		;  e_oeminfo UNUSED
	times 10 dw 0	;  e_res2 UNUSED
	dd pesig	;  e_lfanew

	;;
	;;  PE signature
	;;

pesig:
	dd "PE"

	;;
	;;  PE header
	;;

pehdr:
	dw 0x8664	;  Machine (AMD64)
	dw 1		;  NumberOfSections
	dd 0x4545BE5D	;  TimeDateStamp UNUSED
	dd 0		;  PointerToSymbolTable UNUSED
	dd 0		;  NumberOfSymbols UNUSED
	dw opthdrsize	;  SizeOfOptionalHeader
	dw 0x3		;  Characteristics (no relocations, executable)

	;;
	;;  PE optional header
	;;

	filealign equ 1
	sectalign equ 1

	%define round(n, r) (((n+(r-1))/r)*r)

opthdr:
	dw 0x20B	;  Magic (PE32+)
	db 8		;  MajorLinkerVersion UNUSED
	db 0		;  MinorLinkerVersion UNUSED
	dd round(codesize, filealign) ;  SizeOfCode UNUSED
	dd 0		;  SizeOfInitializedData UNUSED
	dd 0		;  SizeOfUninitializedData UNUSED
	dd start	;  AddressOfEntryPoint
	dd code		;  BaseOfCode UNUSED

	dq 0x400000	;  ImageBase
	dd sectalign	;  SectionAlignment
	dd filealign	;  FileAlignment
	dw 4		;  MajorOperatingSystemVersion UNUSED
	dw 0		;  MinorOperatingSystemVersion UNUSED
	dw 0		;  MajorImageVersion UNUSED
	dw 0		;  MinorImageVersion UNUSED
	dw 4		;  MajorSubsystemVersion
	dw 0		;  MinorSubsystemVersion UNUSED
	dd 0		;  Win32VersionValue UNUSED
	dd round(filesize, sectalign) ;  SizeOfImage
	dd round(hdrsize, filealign) ;  SizeOfHeaders
	dd 0		;  CheckSum UNUSED
	dw 0		;  Subsystem (Unknown)
	dw 0x400	;  DllCharacteristics UNUSED
	dq 0x100000	;  SizeOfStackReserve UNUSED
	dq 0x1000	;  SizeOfStackCommit
	dq 0x100000	;  SizeOfHeapReserve
	dq 0x1000	;  SizeOfHeapCommit UNUSED
	dd 0		;  LoaderFlags UNUSED
	dd 16		;  NumberOfRvaAndSizes UNUSED

	;;
	;;  Data directories
	;;

	times 16 dd 0, 0

	opthdrsize equ $ - opthdr

	;;
	;;  PE code section
	;;

	db ".text", 0, 0, 0	;  Name
	dd codesize		;  VirtualSize
	dd round(hdrsize, sectalign) ;  VirtualAddress
	dd round(codesize, filealign) ;  SizeOfRawData
	dd code		;  PointerToRawData
	dd 0		;  PointerToRelocations UNUSED
	dd 0		;  PointerToLinenumbers UNUSED
	dw 0		;  NumberOfRelocations UNUSED
	dw 0		;  NumberOfLinenumbers UNUSED
	dd 0x60000020	;  Characteristics (code, execute, read) UNUSED

	hdrsize equ $ - $$

	;;
	;;  PE code section data
	;;

	align filealign, db 0

code:

	;;  Entry point

start:	lea     rsi, [rip + string - next]
next:	mov     rdi, 1
	mov     rax, 1
	mov     rdx, 26
	syscall

	mov     rdi,11
	mov     rax,0x3c
	syscall
string  db  "Hello Linux from PE-32+!",10,0

codesize equ $ - code
filesize equ $ - $$
